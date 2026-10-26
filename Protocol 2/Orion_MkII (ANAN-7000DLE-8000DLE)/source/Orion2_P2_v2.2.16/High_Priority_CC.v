//-----------------------------------------------------------------------------
//                          High_Priority_CC.v
//-----------------------------------------------------------------------------

//
//  HPSDR - High Performance Software Defined Radio
//
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


//  Copyright 2010, 2011, 2012, 2013, 2014  Phil Harman VK6(A)PH

// ***** need to check sequence error 

/*
	The maximum payload length in a UDP frame is 1444 bytes (without fragmentation).
	We use 4 bytes to hold the sequency number so 1440 bytes are avaialble for data.
	In which case we count the frame from 0 to 1443.
	
	When the code detects that the frame is for the High_Priority_CC port (1027) then the MSB
	of the sequence number is received.  We then read the next 3 bytes to complete the 
	sequence number.  Tt the end of the sequence number the byte_number is 3.
	
	Note that udp_rx_active will drop once the UDP packet has been received. In which case there is 
	no need to detect the end of packet. 
	
	
		 Byte Data
			0	Seq #	[31:24]
			1	Seq #	[23:16]
			2	Seq #	[15:8]
			3	Seq #	[7:0]
			4	Bits  [0] = run, [1] = PTT0…[4] = PTT3
			5	CWX0	[0] = CWX, [1] = Dot, [2] = Dash
			6	CWX1	[0] = CWX, [1] = Dot, [2] = Dash
			7	CWX2	[0] = CWX, [1] = Dot, [2] = Dash
			8	CWX3	[0] = CWX, [1] = Dot, [2] = Dash
			9	RX0 (Hz)/Mercury0 - Rx0	[31:24]
			10									[23:16]
			11									[15:8]
			12									[7:0]
			13	RX1/Mercury0 - Rx1		[31:24]
			14									[23:16]
			15									[15:8]
			16									[7:0]

        345	Tx0 Drive Level			0-255
	
	    1430 Alex 1						[47:40]  //Orion MkII uses a 48-bit Alex data word
		 1431 Alex 1						[39:32]
		 1432	Alex 0						[31:24]
		 1433	Alex 0						[23:16]
		 1434	Alex 0						[15:8]
		 1435	Alex 0						[7:0]
		 
       1442	Step Attenuator 1 		(0 - 31dB)
       1443	Step Attenuator 0 		(0 - 31dB)
	
	

*/


module High_Priority_CC 
			( 	
				input clock,
				input [15:0] to_port,
				input udp_rx_active,
				input [7:0] udp_rx_data,
				input HW_timeout,
				input [15:0] High_Priority_from_PC_port,
				output reg run,
				output reg PC_PTT,
				output reg CWX,
				output reg Dot,
				output reg Dash,
				output reg [31:0]Rx_frequency[0:NR-1] /* ramstyle = "logic" */,		
				output reg [31:0]Tx0_frequency,
				output reg [47:0]Alex_data,
				output reg [15:0]Alex_Tx_data,
				output reg  [7:0]drive_level,
				output reg  [4:0]Attenuator0,
				output reg  [4:0]Attenuator1,
				output reg  [7:0]Open_Collector,
				output reg  [7:0]User_Outputs,
				output reg  [7:0]Mercury_Attenuator,				
				output reg Alex_data_ready,
				output  HW_reset,
				output reg [31:0]sequence_errors,
				output reg  [7:0]DLE_outputs  // XVTR_enable & IO1 output
			);
			
parameter NR;

localparam 
				IDLE = 1'd0,
				PROCESS = 1'd1;
			
reg [31:0] sequence_number;
reg [31:0] last_sequence_number;
reg [10:0] byte_number;
reg state;

// Yurij-eu2av - 2026-06-26 (Sol A+B+C): robust sequence-error gating.
//   A — last_sequence_number is poisoned (0xFFFFFFFF) on every (re)start, so the
//       first comparison after a run never sees a stale value from the previous
//       session.
//   B — seq_locked decouples sequence validity from run. It is set only after the
//       grace window closes. A large backward jump (Thetis reconnect within the
//       ~2s HW_timeout window restarts seq at 0 while run stays 1) re-arms the
//       grace window instead of counting a false error.
//   C — seq_grace absorbs the first GRACE_LIMIT packets of every (re)start,
//       hiding connect/reconnect transients.
localparam [2:0] GRACE_LIMIT = 3'd3;
reg        seq_locked;
reg [2:0]  seq_grace;

reg [31:0]temp_Rx_frequency[0:NR-1];
reg [47:0]temp_Alex_data;
reg [15:0]temp_Alex_Tx_data;
reg [31:0]temp_Tx0_frequency;  // Yurij-eu2av - 2026-06-09: Pipeline register for Tx0_frequency
reg [15:0]to_port_pipe;        // Yurij-eu2av - 2026-06-09: Pipeline to_port to break critical path from udp_recv|to_port
reg [15:0]High_Priority_from_PC_port_pipe; // Yurij-eu2av - 2026-06-09: Pipeline to break critical path from General_CC|High_Priority_from_PC_port

always @(posedge clock)
    to_port_pipe <= to_port;

always @(posedge clock)
    High_Priority_from_PC_port_pipe <= High_Priority_from_PC_port;

// per NR number
genvar i;
generate
for (i=0; i<NR; i=i+1) begin : rxloop
	always @(posedge clock)
	begin
		if (udp_rx_active && to_port_pipe == High_Priority_from_PC_port_pipe)	// default port is 1027
			case (state)
				PROCESS:
				case (byte_number)
						i*4 + 9:	temp_Rx_frequency [i][31:24] <= udp_rx_data; 
						i*4 + 10:	temp_Rx_frequency [i][23:16] <= udp_rx_data;
						i*4 + 11:	temp_Rx_frequency [i][15:8]  <= udp_rx_data;
						i*4 + 12:	temp_Rx_frequency [i][7:0]   <= udp_rx_data; 
						350:		Rx_frequency[i] <= temp_Rx_frequency[i];
		    		endcase
	    		endcase
	end
end
endgenerate

always @(posedge clock)
begin
  if (!run) begin
	sequence_errors <= 32'd0;
	// Yurij-eu2av - 2026-06-26 (Sol A): poison last_sequence_number so the first
	// comparison after a (re)start can never match a stale value.
	last_sequence_number <= 32'hFFFFFFFF;
	seq_locked <= 1'b0;          // Yurij-eu2av - 2026-06-26 (Sol B)
	seq_grace  <= GRACE_LIMIT;   // Yurij-eu2av - 2026-06-26 (Sol C)
  end

  if(HW_timeout)
	begin
	   run <= 1'b0;		// reset run if HW timeout
	   PC_PTT <= 1'b0;
	   last_sequence_number <= 32'hFFFFFFFF;  // Yurij-eu2av - 2026-06-26 (Sol A)
	   seq_locked <= 1'b0;                    // Yurij-eu2av - 2026-06-26 (Sol B)
	   seq_grace  <= GRACE_LIMIT;             // Yurij-eu2av - 2026-06-26 (Sol C)
	end

  else if (udp_rx_active && to_port_pipe == High_Priority_from_PC_port_pipe)	// default port is 1027
    case (state)
		IDLE:
			begin
				byte_number <= 11'd1;
				Alex_data_ready <= 1'b0;
				sequence_number[31:24] <= udp_rx_data;  //save MSB of sequence number
				state <= PROCESS;
			end 

		PROCESS:
			begin
				case (byte_number) 	//save balance of sequence number
						1: begin 
							sequence_number[23:16] <= udp_rx_data;
							Alex_data_ready <= 1'b0;
						//	HW_reset <= 1'b1;						
						   end
						2: 	sequence_number[15:8] <= udp_rx_data;
						3: 	sequence_number[7:0] <= udp_rx_data;
						4: begin 
							run <= udp_rx_data[0];
							PC_PTT <= udp_rx_data[1]; //PTT0
							// 2-4 = PTT1-PTT3
							// Yurij-eu2av - 2026-06-26 (Sol A+B+C): robust sequence-error gating.
							//  B) Detect a backward sequence jump (seq < last): Thetis restarts
							//     seq at 0 on every connect. While run stays 1 across a fast
							//     reconnect (< HW_timeout window), the old first_pkt fix still
							//     counted a false error. A backward jump re-arms the grace
							//     window instead.
							//  C) While seq_locked is 0 (grace window open) we swallow the error
							//     and decrement seq_grace; once seq_grace reaches 1, seq_locked is
							//     set and normal monotonicity checking resumes.
							if (sequence_number < last_sequence_number) begin
								// reconnect/reset -> re-arm grace window
								seq_grace  <= GRACE_LIMIT;
								seq_locked <= 1'b0;
							end
							else if (!seq_locked) begin
								// C) swallow the first GRACE_LIMIT packets after (re)start
								seq_grace <= seq_grace - 3'd1;
								if (seq_grace == 3'd1)
									seq_locked <= 1'b1;  // window closes after this packet
							end
							else if (sequence_number != last_sequence_number + 1'b1) begin
								sequence_errors <= sequence_errors + 1'b1;
							end
							last_sequence_number <= sequence_number;
						   end
						5: begin
							CWX  <= udp_rx_data[0];
							Dot  <= udp_rx_data[1]; 
							Dash <= udp_rx_data[2]; 
						   end

						 329:	temp_Tx0_frequency [31:24]  <= udp_rx_data;
						 330:	temp_Tx0_frequency [23:16]  <= udp_rx_data;					
						 331:	temp_Tx0_frequency [15:8]   <= udp_rx_data;
						 332:	temp_Tx0_frequency [7:0]    <= udp_rx_data;
						 333:	Tx0_frequency <= temp_Tx0_frequency;

						 345: drive_level <= udp_rx_data;

						1400:	DLE_outputs		  <=  udp_rx_data; // for ANAN-8000DLE (XVTR_enable & user IO1 output)
						1401:	Open_Collector 		  <=  udp_rx_data;
						1402:	User_Outputs 			  <=  udp_rx_data;
						1403:	Mercury_Attenuator     <=  udp_rx_data;	
						
						// parse the Alex data bytes into temp_Alex_data
						// NOTE: Tx filters data is on top 16 bits for ANAN-7000-8000
						1428: temp_Alex_Tx_data [15:8]	<= udp_rx_data; // Tx filters data high byte with Tx ANT selection
						1429: temp_Alex_Tx_data [7:0]	<= udp_rx_data; // Tx filters data low byte with Tx ANT selection
						1430: temp_Alex_data [31:24]	<= udp_rx_data; // Rx1 filters high byte
						1431: temp_Alex_data [23:16]	<= udp_rx_data; // Rx1 filters low byte
						1432:	temp_Alex_data [47:40]  <= udp_rx_data; // Tx filters data high byte
						1433:	temp_Alex_data [39:32]  <= udp_rx_data; // Tx filters data low byte
						1434:	temp_Alex_data [15:8]   <= udp_rx_data; // Rx0 filters data high byte
						1435:	temp_Alex_data [7:0]    <= udp_rx_data; // Rx0 filters data low byte	
		
						1437: begin
									Alex_data <= temp_Alex_data;
									Alex_Tx_data <= temp_Alex_Tx_data;
								end 
		
						1442: begin 
									Attenuator1 <= udp_rx_data[4:0];
									Alex_data_ready <= 1'b1;
								end 
						1443: begin 
									Attenuator0 <= udp_rx_data[4:0]; 
									Alex_data_ready <= 1'b0;
									//HW_reset <= 1'b0;
								end
										  
			   default: if (byte_number > 11'd1443) state <= IDLE;  
			   endcase  
		  
				byte_number <= byte_number + 11'd1;
			end
		endcase 
	else state <= IDLE;	

end		
		
// inhibit HW_reset if Ethernet data stops 
assign HW_reset = (byte_number > 4  && udp_rx_active);	
	
endmodule			
