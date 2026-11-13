//eu2av//05/05/2026//==============================================================================
// Module: tPDF_dither
// Description: Triangular Probability Density Function dither generator
//              Breaks up quantization correlation before CIC/FIR filtering
//==============================================================================
module tPDF_dither(
   input  clock,
   input  reset,
   input  signed [15:0] in_data,
   output signed [15:0] out_data
);

   reg [7:0] lfsr;
   wire [2:0] dither;

   // 8-bit LFSR (polynomial x^8 + x^6 + x^5 + x^4 + 1)
   // Period = 255 states. At 122.88MHz repeats every ~2µs, 
   // which is far beyond audio/baseband filter response.
   always @(posedge clock) begin
      if (reset) lfsr <= 8'b00000001;
      else       lfsr <= {lfsr[6:0], lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3]};
   end

   // TPDF = uniform1 - uniform2 (3-bit range: -4 .. +4)
   assign dither = lfsr[7:5] - lfsr[2:0];

   // Add dither to 16-bit signal. 
   // Sign-extend dither to match 16-bit width before addition.
   assign out_data = in_data + {{13{dither[2]}}, dither};

endmodule
