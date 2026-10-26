/*
  HPSDR - High Performance Software Defined Radio

  Hermes code. 

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

 Polyphase decimating filter

 Based on firX8R8 by James Ahlstrom, N2ADR,  (C) 2011
 Modified for use with HPSDR and DC spur removed by Phil Harman, VK6(A)PH, (C) 2013, 2016


 This is a decimate by 2 dual bank Polyphase FIR filter. 

 The coefficients are initially generated for a basic CIC compensating FIR designed for  256 TAPs, 0.01dB ripple, 110dB ultimate 
 rejection FIR. The FIR compensates for the passband droop of the preceding CIC filter. The coefficients were 
 calculated using Matlab (see filter_2.m).
 
 The Matlab coefficients are fractional so are converted to 18 bit integers by scalling the largest coefficient
 to  2^17 - 1. 
 
 Note that when designing the basic FIR that it decimates by 2 hence the output bandwith will be 1/4 the design
 sampling rate and the output will be 50% of the input levels. 
 
 The coefficients are then split into two files, one containing the even  coefficients (0 - 254) and the other
 the odd (1 - 255).  Conventionally these would then be used as the coeffients for the two FIRs that comprise the polyhase FIR.
 
 However, doing so would restrict the maximum sampling rate at the FIR output to 768ksps.  In order to double this, each set of
 coefficients is again split into two files. The even coefficients are then (0 - 126) and (128 - 254) and the odd (1 - 127) and 
 (129 - 255).  

 The coefficents are then converted to *.mif files so they can be loaded into a ROM. The files are 
 
 (0 - 126) 		= coefFa.mif
 (128 - 254) 	= coefFb.mif
 (1 - 127)     = coefEa.mif
 (129 - 255)	= coefEb.mif

 The generation of the mif files is done via an Excel spreadsheet (see Coeffficients.xlsx) 
 
 Hence each ROM needs to hold 18 x 64 coefficients.  However, due to the need to pipline the ROM addresses in practice a 
 18 x 128 ROM is used with the values > 64 equal to zero.  
 
 Note that the mif files are passed to each  ROM as a parameter.  This not supported by the Quartus ROM Megafunction the output
 of which needed to be  edited (against Altera's recommendations!) in order to be used.

 The speed increase is obtained by operating the Ea/Fa and Eb/Fb FIRs in paralled.  Hence a new input sample is fed to both a and b FIRs. 
 
 In order that the input data is multipled by the coefficients in the correct sequence the sample fed to Eb and Fb is sent
 to a RAM address that is equal to the Fa and Ea address plus the mumber of taps.  
 
 A (24+24) x 128 RAM is required due to the intial address offset of the Eb and Fb FIRs. 

   
   Each FIR works as follows:
   
    RAM address     0     1     2     3     4     5     6     7   etc
						-----------------------------------------------
						|     |     |     |     |     |     |     |     
						|	   |     |     |     |     |     |     |     
						------------------------------------------------
				
    Coeff address    0     1     2     3     4     5     6     7   etc
						-----------------------------------------------
						|     |     |     |     |     |     |     |     
						| h0  |  h1 | h2  | h3  | h4  | h5  | h6  | h7    
						------------------------------------------------	
				  
				  
    At reset the ROM and RAM addresses are set to 0 (64 in the case of the Eb/Fb RAM bank)
    The first sample is written to RAM address 0 (64). This cause the sample to be multiplied
    by h0 and accumulated. The RAM address is then decremented and the ROM address incremented.
    The sample in the new RAM address is multiplied by the coefficient from the new ROM address.  
    This process is repeated TAPS times. The code then waits for the next sample to arrive which 
    is written to RAM address + 1. This sample is then multiplied by h0 etc and the process is
    continued TAPS times.	
	 12 Dec 2016 - modified to use 4 ROM files so not necessary to modify ROM Megafunction.
	 What's fixed:
   
2026 May 05 - (eu2av) - Removed invalid wire declarations within always - in Verilog, wires are only declared at the module level.
    Fixed a typo: I mult_trunc → Imult_trunc (removed extra space).
    Updated comments - they now correctly describe the rounding scheme.
    Fixed the module instance in fir256b/c/d - from firromHa to firromHb/c/d.
2026 Jun 14 - (eu2av-Yurij) - Widened final accumulator Racc/Iacc to 26 bits
    (ABITS+2) so the sum of four 24-bit sub-filter outputs cannot wrap.
    Added sign-extension wires for the sub-filter outputs and hard saturation
    on y_real/y_imag to prevent overload wrap-around.
*/


module firX2R2 (
   input reset,	
   input clock,
   input x_avail,                                   // new sample is available
   input signed [INBITS-1:0] x_real,                // x is the sample input
   input signed [INBITS-1:0] x_imag,
   output y_avail,                                  // new output is available
   output wire signed [OBITS-1:0] y_real,           // y is the filtered output
   output wire signed [OBITS-1:0] y_imag);
	
   localparam ADDRBITS = 7;                         // Address bits for 48 x 128 RAM blocks
   localparam INBITS   = 24;                        // width of I and Q input samples	
	
   parameter
      TAPS     = 64,                                // Number of coefficients per FIR - total is 64 * 4 = 256
      ABITS    = 24,                                // adder bits
      OBITS    = 24;                                // output bits
	
   reg [4:0] wstate;                                // state machine for write samples
	
   reg  [ADDRBITS-1:0] waddr, raddr;               // write sample memory address
   wire weA, weB, weC, weD;
   // Accumulator is widened to 26 bits (ABITS+2) so the sum of four 24-bit
   // sub-filter outputs cannot wrap internally.  The final 24-bit output is
   // saturated back to the required width.
   reg  signed [ABITS+2:0] Racc, Iacc;
   wire signed [ABITS-1:0] RaccAa, RaccBa, RaccAb, RaccBb;
   wire signed [ABITS-1:0] IaccAa, IaccBa, IaccAb, IaccBb;

   // Sign-extend the 24-bit sub-filter outputs to the 26-bit accumulator width.
   wire signed [ABITS+2:0] RaccAa_ext = {{3{RaccAa[ABITS-1]}}, RaccAa};
   wire signed [ABITS+2:0] RaccAb_ext = {{3{RaccAb[ABITS-1]}}, RaccAb};
   wire signed [ABITS+2:0] RaccBa_ext = {{3{RaccBa[ABITS-1]}}, RaccBa};
   wire signed [ABITS+2:0] RaccBb_ext = {{3{RaccBb[ABITS-1]}}, RaccBb};
   wire signed [ABITS+2:0] IaccAa_ext = {{3{IaccAa[ABITS-1]}}, IaccAa};
   wire signed [ABITS+2:0] IaccAb_ext = {{3{IaccAb[ABITS-1]}}, IaccAb};
   wire signed [ABITS+2:0] IaccBa_ext = {{3{IaccBa[ABITS-1]}}, IaccBa};
   wire signed [ABITS+2:0] IaccBb_ext = {{3{IaccBb[ABITS-1]}}, IaccBb};

   localparam signed [ABITS-1:0] MAX_24 = 24'sd8388607;  //  2^23 - 1
   localparam signed [ABITS-1:0] MIN_24 = 24'sh800000;   // -2^23

   assign y_real = (Racc > MAX_24) ? MAX_24 :
                   (Racc < MIN_24) ? MIN_24 : Racc[ABITS-1:0];
   assign y_imag = (Iacc > MAX_24) ? MAX_24 :
                   (Iacc < MIN_24) ? MIN_24 : Iacc[ABITS-1:0];
	
   initial
   begin
      wstate = 0;
      waddr = 0;
      raddr = 0;
      Racc  = 0;
      Iacc  = 0;
   end
	
   always @(posedge clock)
   begin
      if (reset) 
      begin 
         wstate <= 0;
         waddr <= 0;
         raddr <= 0;
         Racc <= 0;
         Iacc <= 0;		
      end 
      else
      begin 
         if (wstate == 2) wstate <= wstate + 1'd1;   // used to set y_avail
         if (wstate == 3) begin
            wstate <= 0;                              // reset state machine and increment RAM write address
            waddr <= waddr + 1'd1;
            raddr <= waddr;
         end
         if (x_avail)
         begin
            wstate <= wstate + 1'd1;
            case (wstate)
               0: begin                                          // wait for the first x input
                     Racc <= RaccAa_ext + RaccAb_ext;    // add accumulators from 'a' and 'b' FIRs
                     Iacc <= IaccAa_ext + IaccAb_ext;
                  end
               1: begin                                          // wait for the next x input
                     Racc <= Racc + RaccBa_ext + RaccBb_ext;
                     Iacc <= Iacc + IaccBa_ext + IaccBb_ext;
                  end
            endcase
         end
      end
   end
	
	
   // Enable each FIR in sequence
   assign weA = (x_avail && wstate == 0);
   assign weB = (x_avail && wstate == 1);

   // at end of sequence indicate new data is available
   assign y_avail = (wstate == 2);
	
   // Dual bank polyphase decimate by 2 FIR. Note that second bank needs a RAM write offset of TAPS.

   fir256a #( ABITS, TAPS) A (reset, clock, waddr, raddr, weA, x_real, x_imag, RaccAa, IaccAa);                    // first bank odd coeff
   fir256b #( ABITS, TAPS) B (reset, clock, (waddr + 7'd64), raddr, weA, x_real, x_imag, RaccAb, IaccAb);         // second bank 
   fir256c #( ABITS, TAPS) C (reset, clock, waddr, raddr, weB, x_real, x_imag, RaccBa, IaccBa);                   // first bank even coeff
   fir256d #( ABITS, TAPS) D (reset, clock, (waddr + 7'd64), raddr, weB, x_real, x_imag, RaccBb, IaccBb);         // second bank  

endmodule


//==============================================================================
// Module: fir256a
//==============================================================================
module fir256a(
   input reset,
   input clock,
   input [ADDRBITS-1:0] waddr,
   input [ADDRBITS-1:0] raddr,
   input we,
   input signed [INBITS-1:0] x_real,
   input signed [INBITS-1:0] x_imag,
   output reg signed [ABITS-1:0] Raccum,
   output reg signed [ABITS-1:0] Iaccum
   );

   localparam ADDRBITS = 7;
   localparam COEFBITS = 18;
   localparam INBITS   = 24;
	
   parameter ABITS = 0;
   parameter TAPS  = 0;

   reg [ADDRBITS-1:0] caddr;
   wire [INBITS*2-1:0] q;
   reg  [INBITS*2-1:0] reg_q;
   wire signed [INBITS-1:0] q_real, q_imag;
   wire signed [COEFBITS-1:0] coef;
   reg signed  [COEFBITS-1:0] reg_coef;
   reg signed  [41:0] Rmult, Imult;
   reg [ADDRBITS:0] counter;
   reg [ADDRBITS-1:0] read_address;
	
   assign q_real = reg_q[INBITS*2-1:INBITS];
   assign q_imag = reg_q[INBITS-1:0];

   firromHa roma (caddr, clock, coef);
   firram48 rama (clock, {x_real, x_imag}, read_address, waddr, we, q);

   always @(posedge clock)
   begin
      if(reset) begin
         Rmult <= 0; Imult <= 0; Raccum <= 0; Iaccum <= 0;
      end 
      else if (we) begin
         counter <= TAPS[ADDRBITS:0] + 7'd3;
         read_address <= raddr;
         caddr <= 1'd0;
         Raccum <= 0; Iaccum <= 0;
      end
      else begin
         if (counter < (TAPS[ADDRBITS:0]) + 7'd1) begin
            Rmult <= q_real * reg_coef;
            Imult <= q_imag * reg_coef;
            
            // [1.1] Round-to-nearest: extract bits [39:16] and add rounding bit [15]
            // This prevents DC spur and improves SNR by ~3 dB vs simple truncation
            Raccum <= Raccum + Rmult[39:16] + Rmult[15];
            Iaccum <= Iaccum + Imult[39:16] + Imult[15];
         end
         if (counter > 0) begin
            counter <= counter - 1'd1;
            read_address <= read_address - 1'd1;
            caddr <= caddr + 1'd1;
            reg_q <= q;
            reg_coef <= coef;
         end
      end
   end
endmodule	


//==============================================================================
// Module: fir256b
//==============================================================================
module fir256b(
   input reset,
   input clock,
   input [ADDRBITS-1:0] waddr,
   input [ADDRBITS-1:0] raddr,
   input we,
   input signed [INBITS-1:0] x_real,
   input signed [INBITS-1:0] x_imag,
   output reg signed [ABITS-1:0] Raccum,
   output reg signed [ABITS-1:0] Iaccum
   );

   localparam ADDRBITS = 7;
   localparam COEFBITS = 18;
   localparam INBITS   = 24;
	
   parameter ABITS = 0;
   parameter TAPS  = 0;

   reg [ADDRBITS-1:0] caddr;
   wire [INBITS*2-1:0] q;
   reg  [INBITS*2-1:0] reg_q;
   wire signed [INBITS-1:0] q_real, q_imag;
   wire signed [COEFBITS-1:0] coef;
   reg signed  [COEFBITS-1:0] reg_coef;
   reg signed  [41:0] Rmult, Imult;
   reg [ADDRBITS:0] counter;
   reg [ADDRBITS-1:0] read_address;
	
   assign q_real = reg_q[INBITS*2-1:INBITS];
   assign q_imag = reg_q[INBITS-1:0];

   // [FIX] Correct ROM instance name for bank B
   firromHb romb (caddr, clock, coef);
   firram48 ramb (clock, {x_real, x_imag}, read_address, waddr, we, q);

   always @(posedge clock)
   begin
      if(reset) begin
         Rmult <= 0; Imult <= 0; Raccum <= 0; Iaccum <= 0;
      end 
      else if (we) begin
         counter <= TAPS[ADDRBITS:0] + 7'd3;
         read_address <= raddr;
         caddr <= 1'd0;
         Raccum <= 0; Iaccum <= 0;
      end
      else begin
         if (counter < (TAPS[ADDRBITS:0]) + 7'd1) begin
            Rmult <= q_real * reg_coef;
            Imult <= q_imag * reg_coef;
            
            // [1.1] Round-to-nearest: extract bits [39:16] and add rounding bit [15]
            Raccum <= Raccum + Rmult[39:16] + Rmult[15];
            Iaccum <= Iaccum + Imult[39:16] + Imult[15];
         end
         if (counter > 0) begin
            counter <= counter - 1'd1;
            read_address <= read_address - 1'd1;
            caddr <= caddr + 1'd1;
            reg_q <= q;
            reg_coef <= coef;
         end
      end
   end
endmodule	


//==============================================================================
// Module: fir256c
//==============================================================================
module fir256c(
   input reset,
   input clock,
   input [ADDRBITS-1:0] waddr,
   input [ADDRBITS-1:0] raddr,
   input we,
   input signed [INBITS-1:0] x_real,
   input signed [INBITS-1:0] x_imag,
   output reg signed [ABITS-1:0] Raccum,
   output reg signed [ABITS-1:0] Iaccum
   );

   localparam ADDRBITS = 7;
   localparam COEFBITS = 18;
   localparam INBITS   = 24;
	
   parameter ABITS = 0;
   parameter TAPS  = 0;

   reg [ADDRBITS-1:0] caddr;
   wire [INBITS*2-1:0] q;
   reg  [INBITS*2-1:0] reg_q;
   wire signed [INBITS-1:0] q_real, q_imag;
   wire signed [COEFBITS-1:0] coef;
   reg signed  [COEFBITS-1:0] reg_coef;
   reg signed  [41:0] Rmult, Imult;
   reg [ADDRBITS:0] counter;
   reg [ADDRBITS-1:0] read_address;
	
   assign q_real = reg_q[INBITS*2-1:INBITS];
   assign q_imag = reg_q[INBITS-1:0];

   // [FIX] Correct ROM instance name for bank C
   firromHc romc (caddr, clock, coef);
   firram48 ramc (clock, {x_real, x_imag}, read_address, waddr, we, q);

   always @(posedge clock)
   begin
      if(reset) begin
         Rmult <= 0; Imult <= 0; Raccum <= 0; Iaccum <= 0;
      end 
      else if (we) begin
         counter <= TAPS[ADDRBITS:0] + 7'd3;
         read_address <= raddr;
         caddr <= 1'd0;
         Raccum <= 0; Iaccum <= 0;
      end
      else begin
         if (counter < (TAPS[ADDRBITS:0]) + 7'd1) begin
            Rmult <= q_real * reg_coef;
            Imult <= q_imag * reg_coef;
            
            // [1.1] Round-to-nearest: extract bits [39:16] and add rounding bit [15]
            Raccum <= Raccum + Rmult[39:16] + Rmult[15];
            Iaccum <= Iaccum + Imult[39:16] + Imult[15];
         end
         if (counter > 0) begin
            counter <= counter - 1'd1;
            read_address <= read_address - 1'd1;
            caddr <= caddr + 1'd1;
            reg_q <= q;
            reg_coef <= coef;
         end
      end
   end
endmodule	


//==============================================================================
// Module: fir256d
//==============================================================================
module fir256d(
   input reset,
   input clock,
   input [ADDRBITS-1:0] waddr,
   input [ADDRBITS-1:0] raddr,
   input we,
   input signed [INBITS-1:0] x_real,
   input signed [INBITS-1:0] x_imag,
   output reg signed [ABITS-1:0] Raccum,
   output reg signed [ABITS-1:0] Iaccum
   );

   localparam ADDRBITS = 7;
   localparam COEFBITS = 18;
   localparam INBITS   = 24;
	
   parameter ABITS = 0;
   parameter TAPS  = 0;

   reg [ADDRBITS-1:0] caddr;
   wire [INBITS*2-1:0] q;
   reg  [INBITS*2-1:0] reg_q;
   wire signed [INBITS-1:0] q_real, q_imag;
   wire signed [COEFBITS-1:0] coef;
   reg signed  [COEFBITS-1:0] reg_coef;
   reg signed  [41:0] Rmult, Imult;
   reg [ADDRBITS:0] counter;
   reg [ADDRBITS-1:0] read_address;
	
   assign q_real = reg_q[INBITS*2-1:INBITS];
   assign q_imag = reg_q[INBITS-1:0];

   // [FIX] Correct ROM instance name for bank D
   firromHd romd (caddr, clock, coef);
   firram48 ramd (clock, {x_real, x_imag}, read_address, waddr, we, q);

   always @(posedge clock)
   begin
      if(reset) begin
         Rmult <= 0; Imult <= 0; Raccum <= 0; Iaccum <= 0;
      end 
      else if (we) begin
         counter <= TAPS[ADDRBITS:0] + 7'd3;
         read_address <= raddr;
         caddr <= 1'd0;
         Raccum <= 0; Iaccum <= 0;
      end
      else begin
         if (counter < (TAPS[ADDRBITS:0]) + 7'd1) begin
            Rmult <= q_real * reg_coef;
            Imult <= q_imag * reg_coef;
            
            // [1.1] Round-to-nearest: extract bits [39:16] and add rounding bit [15]
            Raccum <= Raccum + Rmult[39:16] + Rmult[15];
            Iaccum <= Iaccum + Imult[39:16] + Imult[15];
         end
         if (counter > 0) begin
            counter <= counter - 1'd1;
            read_address <= read_address - 1'd1;
            caddr <= caddr + 1'd1;
            reg_q <= q;
            reg_coef <= coef;
         end
      end
   end
endmodule
