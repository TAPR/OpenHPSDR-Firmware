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
//           Copyright (c) 2008 Alex Shovkoplyas, VE3NEA
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//           Copyright (c) 2013,2015 Phil Harman, VK6(A)PH 
//------------------------------------------------------------------------------

// 2013 Jan 26 - varcic now accepts 2...40 as decimation and CFIR
//               replaced with Polyphase FIR - VK6APH
// 2015 Apr 20 - cic now by Jeremy McDermond, NH6Z
//					- single polyphase FIR Filter
//      Jul 25 - add reset to CORDIC, CIC and FIR for Sync operation
//05/05/2026//eu2av//========================================================
// Module: tPDF_dither_22bit
//14/06/2026//eu2av-Yurij//=================================================
// - Registered rate0/rate1 (sample_rate decoder outputs) to break the long
//   combinational path from the C&C CDC output to the CIC control logic.
//   This was required to close timing after adding CIC output saturation.
// - rate0 widened to [6:0] earlier to match the 7-bit CIC decimation port.
//=============================================================

module receiver2(
  input reset,
  input clock,                  //122.88 MHz
  input [31:0] frequency,
  input [15:0] sample_rate,
  output out_strobe,
  input signed [15:0] in_data,
  output signed [23:0] out_data_I,
  output signed [23:0] out_data_Q
  );

wire signed [21:0] cordic_outdata_I;
wire signed [21:0] cordic_outdata_Q;

// [1.2] Wires for dithered CORDIC output (22-bit)
wire signed [21:0] cordic_dithered_I;
wire signed [21:0] cordic_dithered_Q;

reg [6:0] rate0;
reg [5:0] rate1;
reg [6:0] rate0_next;   // combinational decoder output
reg [5:0] rate1_next;

//------------------------------------------------------------------------------
//                               cordic
//------------------------------------------------------------------------------

cordic cordic_inst(
  .reset(reset),
  .clock(clock),
  .in_data(in_data),             //16 bit 
  .frequency(frequency),         //32 bit
  .out_data_I(cordic_outdata_I), //22 bit
  .out_data_Q(cordic_outdata_Q)
  );

//------------------------------------------------------------------------------
// [1.2] TPDF Dither insertion (after CORDIC, before first CIC)
//------------------------------------------------------------------------------
// Breaks up quantization correlation before decimation
tPDF_dither_22bit dither_I(
   .clock(clock), 
   .reset(reset),
   .in_data(cordic_outdata_I), 
   .out_data(cordic_dithered_I)
);

tPDF_dither_22bit dither_Q(
   .clock(clock), 
   .reset(reset),
   .in_data(cordic_outdata_Q), 
   .out_data(cordic_dithered_Q)
);
  
//------------------------------------------------------------------------------
// Select CIC decimation rates based on sample_rate
//------------------------------------------------------------------------------
// Combinational decoder produces the next rate values...
always @ (*)
begin
	case (sample_rate)
	 16'd48: begin rate0_next = 7'd40; rate1_next = 6'd32; end
	 16'd96: begin rate0_next = 7'd20; rate1_next = 6'd32; end
	 16'd192: begin rate0_next = 7'd10; rate1_next = 6'd32; end
	 16'd384: begin rate0_next = 7'd5;  rate1_next = 6'd32; end
	 16'd768: begin rate0_next = 7'd5;  rate1_next = 6'd16; end
	 16'd1536: begin rate0_next = 7'd5;  rate1_next = 6'd8;  end
  default: begin rate0_next = 7'd40; rate1_next = 6'd32; end
	endcase
end

// ...registered to break the long combinational path from the C&C sample_rate
// CDC output to the CIC control logic.
always @ (posedge clock)
begin
	if (reset) begin
		rate0 <= 7'd40;
		rate1 <= 6'd32;
	end else begin
		rate0 <= rate0_next;
		rate1 <= rate1_next;
	end
end
  
//------------------------------------------------------------------------------
// Receive CIC filters followed by FIR filter
//------------------------------------------------------------------------------
wire decimA_avail, decimB_avail;
wire signed [17:0] decimA_real;
wire signed [17:0] decimA_imag;
wire signed [23:0] decimB_real, decimB_imag;

wire cic_outstrobe_2;
wire signed [23:0] cic_outdata_I2;
wire signed [23:0] cic_outdata_Q2;

//I channel - [1.2] Use dithered input instead of direct CORDIC output
cic #(.STAGES(3), .MIN_DECIMATION(5), .MAX_DECIMATION(40), .IN_WIDTH(22), .OUT_WIDTH(18))
 cic_inst_I2(.reset(reset),
			 .decimation(rate0),
			 .clock(clock), 
			 .in_strobe(1'b1),
			 .out_strobe(decimA_avail),
			 .in_data(cordic_dithered_I),  // [1.2] Changed from cordic_outdata_I
			 .out_data(decimA_real)
			 );
			 
//Q channel - [1.2] Use dithered input
cic #(.STAGES(3), .MIN_DECIMATION(5), .MAX_DECIMATION(40), .IN_WIDTH(22), .OUT_WIDTH(18)) 
 cic_inst_Q2(.reset(reset),
			 .decimation(rate0),
			 .clock(clock), 
			 .in_strobe(1'b1),
			 .out_strobe(),
			 .in_data(cordic_dithered_Q),  // [1.2] Changed from cordic_outdata_Q
			 .out_data(decimA_imag)
			 );			
			

wire cic_outstrobe_1;
wire signed [22:0] cic_outdata_I1;
wire signed [22:0] cic_outdata_Q1;

cic #(.STAGES(11), .MIN_DECIMATION(8), .MAX_DECIMATION(32), .IN_WIDTH(18), .OUT_WIDTH(24)) 
 varcic_inst_I1(.reset(reset),
			 .decimation(rate1),
			 .clock(clock), 
			 .in_strobe(decimA_avail),
			 .out_strobe(decimB_avail),
			 .in_data(decimA_real),
			 .out_data(decimB_real)
			 );
				 

//Q channel
cic #(.STAGES(11), .MIN_DECIMATION(8), .MAX_DECIMATION(32), .IN_WIDTH(18), .OUT_WIDTH(24)) 
 varcic_inst_Q1(.reset(reset),
			 .decimation(rate1),
			 .clock(clock), 
			 .in_strobe(decimA_avail),
			 .out_strobe(),
			 .in_data(decimA_imag),
			 .out_data(decimB_imag)
			 );
				 

wire signed [23:0]temp_out_I;
wire signed [23:0]temp_out_Q;	

// Polyphase decimate by 2 FIR Filter
firX2R2 fir3 (reset, clock, decimB_avail, decimB_real, decimB_imag, out_strobe, out_data_I, out_data_Q);

endmodule


//05/05/2026//eu2av//==============================================================================
// Module: tPDF_dither_22bit
// Description: TPDF dither for 22-bit signed data
//              Adds triangular noise (-4..+4 LSB) to decorrelate quantization
//==============================================================================
module tPDF_dither_22bit(
   input  clock,
   input  reset,
   input  signed [21:0] in_data,   // 22-bit input
   output signed [21:0] out_data   // 22-bit output
);

   reg [7:0] lfsr;
   wire signed [3:0] dither;  // Range -4..+4 (TPDF)

   // 8-bit LFSR (polynomial x^8 + x^6 + x^5 + x^4 + 1)
   // Period = 255 states, sufficient for audio/baseband applications
   always @(posedge clock) begin
      if (reset) 
         lfsr <= 8'b00000001;
      else 
         lfsr <= {lfsr[6:0], lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3]};
   end

   // TPDF generation: difference of two 3-bit uniform sequences
   // Result range: -4 .. +4 (4-bit signed)
   assign dither = $signed(lfsr[7:5]) - $signed(lfsr[2:0]);

   // Add dither to input signal with proper sign extension
   // dither[3] is the sign bit, extend it to match 22-bit width
   assign out_data = in_data + {{18{dither[3]}}, dither[3:0]};

endmodule

