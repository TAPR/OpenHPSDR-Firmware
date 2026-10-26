/*
--------------------------------------------------------------------------------
This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Library General Public
License as published by the Free Software Foundation; either
version 2 of the License, or (at your option) any later version.
This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Library General Public License for more details.
You should have received a copy of the GNU Library General Public
License along with this library; if not, write to the
Free Software Foundation, Inc., 51 Franklin St, Fifth Floor,
Boston, MA  02110-1301, USA.
--------------------------------------------------------------------------------
*/


//------------------------------------------------------------------------------
//           Algorithm by Darrell Harmon modified by Cathy Moss
//            Code Copyright (c) 2008 Alex Shovkoplyas, VE3NEA
//------------------------------------------------------------------------------
/*2026 May 05 - (eu2av)What's changed:
Added an LFSR (8-bit shift register) for pseudo-random noise generation
TPDF dither generation (3 bits, range -4..+4)
Added dither to the frequency before the phase adder*/


module cordic( reset, clock, frequency, in_data, out_data_I, out_data_Q );

parameter IN_WIDTH   = 16;
parameter EXTRA_BITS = 5;

localparam WR =  IN_WIDTH + EXTRA_BITS + 1;
localparam OUT_WIDTH = WR;
localparam WZ =  IN_WIDTH + EXTRA_BITS - 1;
localparam STG = IN_WIDTH + EXTRA_BITS - 2;
localparam WO = OUT_WIDTH;

localparam WF = 32;
localparam WP = WF;

input reset;
input clock;
input signed [WF-1:0] frequency;
input signed [IN_WIDTH-1:0] in_data;
output signed [WO-1:0] out_data_I;
output signed [WO-1:0] out_data_Q;

//------------------------------------------------------------------------------
// arctan table
//------------------------------------------------------------------------------
localparam WT = 32;
wire signed [WT-1:0] atan_table [1:WT-1];

assign atan_table[01] = 32'b00100101110010000000101000111011;
assign atan_table[02] = 32'b00010011111101100111000010110111;
assign atan_table[03] = 32'b00001010001000100010001110101000;
assign atan_table[04] = 32'b00000101000101100001101010000110;
assign atan_table[05] = 32'b00000010100010111010111111000011;
assign atan_table[06] = 32'b00000001010001011110110000111101;
assign atan_table[07] = 32'b00000000101000101111100010101010;
assign atan_table[08] = 32'b00000000010100010111110010100111;
assign atan_table[09] = 32'b00000000001010001011111001011101;
assign atan_table[10] = 32'b00000000000101000101111100110000;
assign atan_table[11] = 32'b00000000000010100010111110011000;
assign atan_table[12] = 32'b00000000000001010001011111001100;
assign atan_table[13] = 32'b00000000000000101000101111100110;
assign atan_table[14] = 32'b00000000000000010100010111110011;
assign atan_table[15] = 32'b00000000000000001010001011111010;
assign atan_table[16] = 32'b00000000000000000101000101111101;
assign atan_table[17] = 32'b00000000000000000010100010111110;
assign atan_table[18] = 32'b00000000000000000001010001011111;
assign atan_table[19] = 32'b00000000000000000000101000110000;
assign atan_table[20] = 32'b00000000000000000000010100011000;
assign atan_table[21] = 32'b00000000000000000000001010001100;
assign atan_table[22] = 32'b00000000000000000000000101000110;
assign atan_table[23] = 32'b00000000000000000000000010100011;
assign atan_table[24] = 32'b00000000000000000000000001010001;
assign atan_table[25] = 32'b00000000000000000000000000101001;
assign atan_table[26] = 32'b00000000000000000000000000010100;
assign atan_table[27] = 32'b00000000000000000000000000001010;
assign atan_table[28] = 32'b00000000000000000000000000000101;
assign atan_table[29] = 32'b00000000000000000000000000000011;
assign atan_table[30] = 32'b00000000000000000000000000000001;
assign atan_table[31] = 32'b00000000000000000000000000000001;

//------------------------------------------------------------------------------
// registers
//------------------------------------------------------------------------------
reg [WP-1:0] phase;

// [2.1] Phase Dither LFSR
reg [7:0] phase_lfsr;
wire signed [3:0] phase_dither;  // TPDF: -4..+4

// [2.1] TPDF generation (COMBINATIONAL - outside always block!)
assign phase_dither = $signed(phase_lfsr[7:5]) - $signed(phase_lfsr[2:0]);

reg signed [WR-1:0] X [0:STG-1];
reg signed [WR-1:0] Y [0:STG-1];
reg signed [WZ-1:0] Z [0:STG-1];

//------------------------------------------------------------------------------
// stage 0
//------------------------------------------------------------------------------
wire signed [WR-1:0] in_data_ext = {in_data[IN_WIDTH-1], in_data, {EXTRA_BITS{1'b0}}};
wire [1:0] quadrant = phase[WP-1:WP-2];

always @(posedge clock)
begin
  if (reset) begin 
    X[0] <= 0; Y[0] <= 0; Z[0] <= 0;
  end 
  else begin
    case (quadrant)
      0: begin X[0] <=  in_data_ext;   Y[0] <=  in_data_ext; end
      1: begin X[0] <= -in_data_ext;   Y[0] <=  in_data_ext; end
      2: begin X[0] <= -in_data_ext;   Y[0] <= -in_data_ext; end
      3: begin X[0] <=  in_data_ext;   Y[0] <= -in_data_ext; end
    endcase
    Z[0] <= {~phase[WP-3], ~phase[WP-3], phase[WP-4:WP-WZ-1]};
  end 

  // [2.1] Phase Dither LFSR update (SEQUENTIAL - inside always block)
  if (reset)
    phase_lfsr <= 8'b00000001;
  else
    phase_lfsr <= {phase_lfsr[6:0], phase_lfsr[7] ^ phase_lfsr[5] ^ phase_lfsr[4] ^ phase_lfsr[3]};

  //advance NCO with phase dither
  if (reset || frequency == 1'b0) 
    phase <= 0;
  else
    // [2.1] Add phase dither to frequency
    phase <= 32'(phase + frequency + {{29{phase_dither[3]}}, phase_dither[3:0]});
end

//------------------------------------------------------------------------------
// stages 1 to STG-1
//------------------------------------------------------------------------------
genvar n;
generate
  for (n=0; n<=(STG-2); n=n+1) begin : stages
    wire signed [WR-1:0] X_shr = {{(n+1){X[n][WR-1]}}, X[n][WR-1:n+1]};
    wire signed [WR-1:0] Y_shr = {{(n+1){Y[n][WR-1]}}, Y[n][WR-1:n+1]};
    wire [WZ-2-n:0] atan = atan_table[n+1][WT-2-n:WT-WZ] + atan_table[n+1][WT-WZ-1];
    wire Z_sign = Z[n][WZ-1-n];
    
    always @(posedge clock) begin
      X[n+1] <= reset ? {WR{1'b0}} : (Z_sign ? X[n] + Y_shr + Y[n][n] : X[n] - Y_shr - Y[n][n]);
      Y[n+1] <= reset ? {WR{1'b0}} : (Z_sign ? Y[n] - X_shr - X[n][n] : Y[n] + X_shr + X[n][n]);
      if (n < STG-2) begin : angles
        Z[n+1][WZ-2-n:0] <= reset ? {WZ-1-n{1'b0}} : (Z_sign ? Z[n][WZ-2-n:0] + atan : Z[n][WZ-2-n:0] - atan);
      end
    end
  end
endgenerate

//------------------------------------------------------------------------------
// output
//------------------------------------------------------------------------------
generate
  if (OUT_WIDTH == WR) begin
    assign out_data_I = X[STG-1];
    assign out_data_Q = Y[STG-1];
  end
  else begin
    reg signed [WR-1:0] rounded_I = 0;
    reg signed [WR-1:0] rounded_Q = 0;
    always @(posedge clock) begin
      if (reset) begin 
        rounded_I <= 0; rounded_Q <= 0;
      end else begin
        rounded_I <= X[STG-1][WR-1:0] + {{(WO){1'b0}}, X[STG-1][WR-WO], {(WR-WO-1){!X[STG-1][WR-WO]}}};
        rounded_Q <= Y[STG-1][WR-1:0] + {{(WO){1'b0}}, Y[STG-1][WR-WO], {(WR-WO-1){!Y[STG-1][WR-WO]}}};
      end
    end
    assign out_data_I = rounded_I[WR-1:WR-WO];
    assign out_data_Q = rounded_Q[WR-1:WR-WO];
  end
endgenerate

endmodule