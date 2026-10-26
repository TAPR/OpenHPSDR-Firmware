//
// cic - A Cascaded Integrator-Comb filter
//
// Copyright (c) 2008 Alex Shovkoplyas, VE3NEA
// Copyright (c) 2013 Phil Harman, VK6PH
// Copyright (c) 2015 Jeremy McDermond, NH6Z
//
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Library General Public
// License as published by the Free Software Foundation; either
// version 2 of the License, or (at your option) any later version.
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Library General Public License for more details.
// You should have received a copy of the GNU Library General Public
// License along with this library; if not, write to the
// Free Software Foundation, Inc., 51 Franklin St, Fifth Floor,
// Boston, MA  02110-1301, USA.


// 2013 Jan 26	- Modified to accept decimation values from 1-40. VK6APH 
// 2026 Jun 14	- (eu2av-Yurij) Added output saturation limits and simple
//				  round-half-up to prevent wrap-around on full-scale signals.
//				  Convergent rounding was tested but rejected because it cost
//				  ~5k LE and broke timing.

module cic(reset, decimation, clock, in_strobe,  out_strobe, in_data, out_data);

  //design parameters
  parameter STAGES = 6; //  Sections of both Comb and Integrate
  parameter MIN_DECIMATION = 2;  // If MIN = MAX, we are single-rate filter
  parameter MAX_DECIMATION = 40;
  parameter IN_WIDTH = 18;
  parameter OUT_WIDTH = 18;

  // derived parameters
  parameter ACC_WIDTH = IN_WIDTH + (STAGES * $clog2(MAX_DECIMATION));
  
  input [$clog2(MAX_DECIMATION):0] decimation; 
  input reset;
  input clock;
  input in_strobe;
  output reg out_strobe;

  input signed [IN_WIDTH-1:0] in_data;
  output signed [OUT_WIDTH-1:0] out_data;

  // Saturation limits for the final output width.
  localparam signed [OUT_WIDTH-1:0] MAX_OUT = {1'b0, {(OUT_WIDTH-1){1'b1}}};
  localparam signed [OUT_WIDTH-1:0] MIN_OUT = {1'b1, {(OUT_WIDTH-1){1'b0}}};

//------------------------------------------------------------------------------
//                               control
//------------------------------------------------------------------------------
reg [$clog2(MAX_DECIMATION)-1:0] sample_no = 0;

generate
if(MIN_DECIMATION == MAX_DECIMATION)
	always @(posedge clock)
		if (in_strobe) 
			if (sample_no == (MAX_DECIMATION - 1'd1)) begin
				sample_no <= 0;
				out_strobe <= 1;
			end else begin
				sample_no <= sample_no + 1'd1;
     				out_strobe <= 0;
			end
		else
			out_strobe <= 0;
else
	always @(posedge clock)
		if (in_strobe) 
			if (sample_no == (decimation - 1'd1)) begin
				sample_no <= 0;
				out_strobe <= 1;
			end else begin
				sample_no <= sample_no + 1'd1;
     				out_strobe <= 0;
			end
		else
			out_strobe <= 0;
endgenerate

//------------------------------------------------------------------------------
//                                stages
//------------------------------------------------------------------------------

wire signed [ACC_WIDTH-1:0] integrator_data [0:STAGES];
wire signed [ACC_WIDTH-1:0] comb_data [0:STAGES];


assign integrator_data[0] = in_data;
assign comb_data[0] = integrator_data[STAGES];


genvar j;
generate
  for (j=0; j<STAGES; j=j+1)
    begin : cic_stages

    cic_integrator #(ACC_WIDTH) cic_integrator_inst(
      .clock(clock),
      .strobe(in_strobe),
      .in_data(integrator_data[j]),
      .out_data(integrator_data[j+1])
      );


    cic_comb #(ACC_WIDTH) cic_comb_inst(
      .clock(clock),
      .strobe(out_strobe),
      .in_data(comb_data[j]),
      .out_data(comb_data[j+1])
      );
    end
endgenerate




//------------------------------------------------------------------------------
//                            output rounding
//------------------------------------------------------------------------------

genvar i;
generate
	if(MIN_DECIMATION == MAX_DECIMATION) begin
		// Simple round-half-up using the bit just below the output LSB, then
		// saturate to the output width to avoid wrap-around.
		wire signed [OUT_WIDTH:0] rounded = $signed(comb_data[STAGES][ACC_WIDTH - 1 -: OUT_WIDTH])
		                                  + comb_data[STAGES][ACC_WIDTH - OUT_WIDTH - 1];

		assign out_data = (rounded > MAX_OUT) ? MAX_OUT :
		                  (rounded < MIN_OUT) ? MIN_OUT :
						  rounded[OUT_WIDTH-1:0];
	end else begin
		wire [31:0] msb [MAX_DECIMATION:MIN_DECIMATION];
		for(i = MIN_DECIMATION; i <= MAX_DECIMATION; i = i + 1) begin: round_position
			assign msb[i] = IN_WIDTH + ($clog2(i) * STAGES) - 1 ;
		end

		// Simple round-half-up using the bit just below the output LSB, then
		// saturate to the output width to avoid wrap-around.
		wire signed [OUT_WIDTH:0] rounded = $signed(comb_data[STAGES][msb[decimation] -: OUT_WIDTH])
		                                  + comb_data[STAGES][msb[decimation] - OUT_WIDTH];

		assign out_data = (rounded > MAX_OUT) ? MAX_OUT :
		                  (rounded < MIN_OUT) ? MIN_OUT :
						  rounded[OUT_WIDTH-1:0];
	end
endgenerate

endmodule

