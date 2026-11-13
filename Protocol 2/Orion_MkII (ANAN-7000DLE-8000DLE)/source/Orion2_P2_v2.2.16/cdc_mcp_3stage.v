//  HPSDR - High Performance Software Defined Radio
//
//  Metis code. 
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
//  new module 7/2026 - eu2av
//  new module with 3 stages 9/2026 - n1gp

`timescale 1 ns/100 ps

module cdc_mcp_3stage #(parameter SIZE=1)
  (input  wire            a_rst, a_clk,
   input  wire [SIZE-1:0] a_data,
   input  wire            a_data_rdy,
   input  wire            b_rst, b_clk, 
   output reg  [SIZE-1:0] b_data,
   output reg             b_data_ack);

reg  a_rdy;
wire a_data_ack, b_data_rdy;
reg  b_data_rdy_d1;
wire b_data_rdy_pulse;

// Domain A: Ready flag logic
always @(posedge a_clk or posedge a_rst) begin
  if (a_rst)
    a_rdy <= 1'b0;
  else if (a_data_rdy)
    a_rdy <= 1'b1;
  else if (a_data_ack)
    a_rdy <= 1'b0;
end

// 3-Stage Synchronization into Domain B
sync_3stage rdy_sync (
    .clk(b_clk),
    .rst(b_rst),
    .async_in(a_rdy),
    .sync_out(b_data_rdy)
);

// Inline pulse generator for Domain B to catch the rising edge of the ready flag
always @(posedge b_clk or posedge b_rst) begin
  if (b_rst)
    b_data_rdy_d1 <= 1'b0;
  else
    b_data_rdy_d1 <= b_data_rdy;
end
assign b_data_rdy_pulse = b_data_rdy && !b_data_rdy_d1;

// 3-Stage Acknowledgement back to Domain A
sync_3stage ack_sync (
    .clk(a_clk),
    .rst(a_rst),
    .async_in(b_data_ack),
    .sync_out(a_data_ack)
);

// Domain B: Data capture and acknowledgement generation
always @(posedge b_clk or posedge b_rst) begin
  if (b_rst) begin
    b_data     <= {SIZE{1'b0}};
    b_data_ack <= 1'b0;
  end else begin
    if (b_data_rdy_pulse) begin
      b_data   <= a_data; // Safe to sample: Domain A data is completely stable here
    end
    b_data_ack <= b_data_rdy;
  end
end

endmodule

// Helper Module: 3-Stage Single-Bit Synchronizer
module sync_3stage (
    input  wire clk,
    input  wire rst,
    input  wire async_in,
    output wire sync_out
);
    (* altera_attribute = "-name ADV_NETLIST_OPT_ALLOWED NEVER_ALLOW; -name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS" *) reg [2:0] sync_reg;


    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sync_reg <= 3'b000;
        end else begin
            sync_reg <= {sync_reg[1:0], async_in};
        end
    end

    assign sync_out = sync_reg[2];
endmodule

