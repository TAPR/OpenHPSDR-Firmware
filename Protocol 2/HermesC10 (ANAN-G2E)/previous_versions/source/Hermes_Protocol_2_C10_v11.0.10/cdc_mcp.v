//
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
//  new modyle 2026- eu2av
`timescale 1 ns/100 ps

module cdc_mcp #(parameter SIZE=1)
  (input  wire            a_rst, a_clk,
   input  wire [SIZE-1:0] a_data,
   input  wire            a_data_rdy,
   input  wire            b_rst, b_clk, 
   output reg  [SIZE-1:0] b_data,
   output reg             b_data_ack);

reg  a_rdy;
wire a_data_ack, b_data_rdy;
wire b_data_rdy_pulse;

// Домен A: флаг готовности
always @(posedge a_clk) begin
  if (a_rst)
    a_rdy <= 1'b0;
  else if (a_data_rdy)
    a_rdy <= 1'b1;
  else if (a_data_ack)
    a_rdy <= 1'b0;
end

// Синхронизация в домен B (позиционные параметры!)
cdc_sync #(1) rdy (a_rdy, b_rst, b_clk, b_data_rdy);

// Импульс для захвата данных
pulsegen pls (b_data_rdy, b_rst, b_clk, b_data_rdy_pulse);

// Подтверждение обратно в домен A
cdc_sync #(1) ack (b_data_ack, a_rst, a_clk, a_data_ack);

// Домен B: захват данных и подтверждение
always @(posedge b_clk) begin
  if (b_rst) begin
    b_data <= {SIZE{1'b0}};
    b_data_ack <= 1'b0;
  end else begin
    if (b_data_rdy_pulse)
      b_data <= a_data;
    b_data_ack <= b_data_rdy;
  end
end

endmodule