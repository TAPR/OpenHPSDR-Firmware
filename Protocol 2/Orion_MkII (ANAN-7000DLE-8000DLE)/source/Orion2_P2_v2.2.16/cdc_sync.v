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
module cdc_sync (siga, rstb, clkb, sigb);

    parameter SIZE = 1;
    
    input [SIZE-1:0] siga;
    input rstb;
    input clkb;
    output [SIZE-1:0] sigb;
    
    reg [SIZE-1:0] sigb;
    reg [SIZE-1:0] q1;
    
    integer i;
    
    always @(posedge clkb)
    begin
        if (rstb)
        begin
            for (i = 0; i < SIZE; i = i + 1)
            begin
                sigb[i] <= 1'b0;
                q1[i] <= 1'b0;
            end
        end
        else
        begin
            for (i = 0; i < SIZE; i = i + 1)
            begin
                sigb[i] <= q1[i];
                q1[i] <= siga[i];
            end
        end
    end

endmodule