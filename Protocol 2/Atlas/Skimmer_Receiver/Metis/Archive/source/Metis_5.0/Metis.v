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


module Metis (
			  ATLAS_A11,ATLAS_A12,ATLAS_A13,ATLAS_A20,ATLAS_A21,
			  ATLAS_A4,ATLAS_A3,ATLAS_A2,ATLAS_A15,ATLAS_A14,ATLAS_A10,ATLAS_A9,ATLAS_A8,ATLAS_A7,ATLAS_A5,
			  ATLAS_C2,ATLAS_C15,ATLAS_C19,ATLAS_C20,ATLAS_C21,ATLAS_C22,ATLAS_C23,ATLAS_C24,
			  RAM_A0,RAM_A1,RAM_A2,RAM_A3,RAM_A4,RAM_A5,RAM_A6,RAM_A7,RAM_A8,RAM_A9,RAM_A10,RAM_A11,RAM_A12,RAM_A13,HEART_BEAT,
			  PHY_TX,PHY_RX,PHY_DV,PHY_TX_CLOCK,PHY_TX_EN,
			  PHY_RX_CLOCK,PHY_CLK125,PHY_MDIO,PHY_MDC,PHY_INT_N,PHY_RESET_N,CLK_25MHZ,
			  MODE2, IN2, IN1, IN0, SCK, SI, CONFIG, NODE_ADDR_CS, NCONFIG, USEROUT0,USEROUT1,USEROUT2,USEROUT3
			  );

		   
// Atlas Bus

input	wire	 ATLAS_A4;  // MDOUT[9], pin 118
input	wire	 ATLAS_A3;  // MDOUT[8], pin 127
input	wire	 ATLAS_A2;  // MDOUT[7], pin 131
input	wire	 ATLAS_A15; // MDOUT[6], pin 80
input	wire	 ATLAS_A14; // MDOUT[5], pin 82
input	wire	 ATLAS_A10; // MDOUT[4], pin 98
input	wire	 ATLAS_A9;  // MDOUT[3], pin 100
input	wire	 ATLAS_A8;  // MDOUT[2], pin 106
input	wire	 ATLAS_A7;  // MDOUT[1], pin 110
input	wire	 ATLAS_A5;  // MDOUT[0], pin 114

input	wire	 ATLAS_A11; // CDOUT_P		Mic from TLV320 on Penelope

input	wire	 ATLAS_A12; 	// SP_DATA		NWire spectrum data from Mercury
input wire   ATLAS_A13;    // 1PPS from GPS receiver to time stamp data for Chirp signals
output wire  ATLAS_A20; 	// I2C SCL
inout wire   ATLAS_A21; 	// I2C SDA
output wire  ATLAS_C2;     // reset Mercury boards
input	wire	 ATLAS_C15; 	// PTT_in		PTT input from Atlas bus - active high
// ATLAS_A19 is not connected since POR chip 
output wire	 ATLAS_C19; 	// P_IQ_data to Penelope
output wire	 ATLAS_C20; 	// CC			Command & Control
output wire	 ATLAS_C21; 	// trigger		Spectrum data Trigger signal to Mercury
input	wire	 ATLAS_C22; 	// P_IQ_sync	P_IQ_sync from Penelope
input	wire	 ATLAS_C23; 	// M_LR_sync	M_LR_sync from Mercury
output wire	 ATLAS_C24; 	// M_LR_data	M_LR_data to Mercury and Penny in nWire format

// user IO
input wire        IN0;
input wire        IN1;
input wire 	      IN2;


// MAC EEPROM
output wire		SCK; 						// clock on MAC EEPROM
output wire		SI;						// serial in on MAC EEPROM
input  wire 	CONFIG; 					// SO on MAC EEPROM
output wire 	NODE_ADDR_CS;			// CS on MAC EEPROM
wire SO;	assign SO = CONFIG;			// serial out on MAC EEPROM
wire CS;	assign NODE_ADDR_CS = CS; 	// Chip select on MAC EEPROM

// CW key and PTT
wire dash_n;	assign dash_n 	= IN0; 	// CW dash key, DP9 pin 6, active low
wire dot_n;		assign dot_n 	= IN1; 	// CW dot key, DB9 pin 7, active low
wire PTT_n; 	assign PTT_n  	= IN2; 	// PTT from DB9 pin 8, active low

// Reload FPGA 
output wire 	NCONFIG;				// when high causes FPGA to reload from EPCS16 
assign NCONFIG = IP_write_done || reset_FPGA;

//DB-9 connector output connections
output wire		USEROUT0;				// DB-9 pin 1, FPGA pin 134 open drain output
output wire		USEROUT1;				// DB-9 pin 2, FPGA pin 135 open drain output
output wire		USEROUT2;				// DB-9 pin 3, FPGA pin 137 3.3V TTL output
output wire		USEROUT3;				// DB-9 pin 4, FPGA pin 173 3.3V TTL output

// Assign Atlas pins to signals
wire PTT_in;	assign PTT_in   	= ATLAS_C15;  	// PTT from Atlas, Active high
wire CC;	    assign ATLAS_C20	= CC;			// Command & Control data
wire CDOUT_P;	assign CDOUT_P  	= ATLAS_A11;	// Mic data from Penelope


// RAM
output	wire     RAM_A0;		
output	wire     RAM_A1;
output	wire     RAM_A2;
output	wire     RAM_A3;
output	wire     RAM_A4;
output	wire     RAM_A5;
output	wire     RAM_A6;
output	wire     RAM_A7;
output	wire     RAM_A8;
output	wire     RAM_A9;
output	wire     RAM_A10;
output	wire     RAM_A11;
output	wire     RAM_A12;
output	wire     RAM_A13;



// PHY
output  wire [3:0]PHY_TX;
input   wire [3:0]PHY_RX;		   
input	wire     PHY_DV;					// PHY has data flag
output	wire     PHY_TX_CLOCK;		// PHY Tx data clock
output	wire	 PHY_TX_EN;				// PHY Tx enable
input	wire	 PHY_RX_CLOCK;      		// PHY Rx data clock
input	wire     PHY_CLK125;				// 125MHz clock from PHY PLL
inout	wire     PHY_MDIO;				// data line to PHY MDIO
output	wire 	 PHY_MDC;				// 2.5MHz clock to PHY MDIO
input	wire 	 PHY_INT_N;	
output	wire     PHY_RESET_N;
input	wire 	 CLK_25MHZ;					// 25MHz clock 

// Heart beat LED
output wire 	  HEART_BEAT;			// LED, flashes, runs off PHY 125MHz clock.

// speed select via JP2
input wire MODE2;							// high with jumper off

parameter M_TPD   = 4;
parameter IF_TPD  = 2;

localparam board_type = 8'h00;		  	// 00 for Metis, 01 for Hermes, 02 for ANAN-10E, 03 for Angelia, and 05 for Orion
parameter  Metis_version = 8'd50;	// FPGA code version
parameter  beta_version = 8'd0;	// Should be 0 for official release
parameter  protocol_version = 8'd39;	// openHPSDR protocol version implemented

localparam NR = 8;                  //Maximum number of receiver channels
localparam master_clock = 122880000; 	// DSP  master clock in Hz.

localparam TX_FIFO_SZ  = 1024; 		// 16 by 1024 deep TX FIFO  
localparam SP_FIFO_SZ  = 1024; 		// 16 by 1024 deep SP FIFO

wire [9:0] MDOUT;      			// I&Q data from Mercury 
//assign MDOUT = {ATLAS_A4,ATLAS_A3,ATLAS_A2,ATLAS_A15,ATLAS_A14,ATLAS_A10,ATLAS_A9,ATLAS_A8,ATLAS_A7,ATLAS_A5};
assign MDOUT = {ATLAS_A4,ATLAS_A9,ATLAS_A2,ATLAS_A15,ATLAS_A14,ATLAS_A10,ATLAS_A3,ATLAS_A8,ATLAS_A7,ATLAS_A5};
//6,9 assign MDOUT = {ATLAS_A4,ATLAS_A14,ATLAS_A2,ATLAS_A15,ATLAS_A3,ATLAS_A10,ATLAS_A9,ATLAS_A8,ATLAS_A7,ATLAS_A5};
assign ATLAS_C2 = 1'b0;

wire PPS;									// 1PPS from GPS receiver to time stamp data
assign PPS = ATLAS_A13;

// Deadman timer - clears run if HW_timer_enable and no C&C commands received for ~2 seconds.
wire timer_reset = (HW_reset1 | HW_reset2 | HW_reset3 | HW_reset4);

reg [27:0] sec_count;
wire HW_timeout;
always @ (posedge rx_clock)
begin
	if (HW_timer_enable) begin
		if (timer_reset) sec_count <= 28'b0;
		else if (sec_count < 28'd250_000_000) 	// approx 2 secs. 
			sec_count <= sec_count + 28'b1;
	end
	else sec_count <= 28'd0;
end

assign HW_timeout = (sec_count >= 28'd250_000_000) ? 1'd1 : 1'd0;

//------------------------------------------------------------
//		Clocks
//------------------------------------------------------------

wire C125_clk;
wire C125_div2_clk;
assign C125_clk = PHY_CLK125;	// use PHY 125MHz clock for system clock
wire C125_locked; // high when PLL locked
wire IF_clk;
wire I2C_clock;
wire pro_clock, iambic_clk;	

//   IF clock     CW clocks
// C0 = 48MHz, C1 = profile clock 192kHz, C2 = iambic_clk = 30kHz
PLL_clocks PLL_inst(.areset(), .inclk0(C125_clk), .c0(IF_clk), .c1(pro_clock), .c2(iambic_clk), .locked(C125_locked));
PLL_2 PLL_2_inst(.areset(), .inclk0(C125_clk), .c0(C125_div2_clk), .c1(I2C_clock));


//--------------------------------------------------------------
// Reset Lines - C125_rst, IF_rst
//--------------------------------------------------------------

wire  C125_rst;
wire  IF_rst;

assign PHY_RESET_N = 1'bz;
assign C125_rst  = !C125_locked;
assign IF_rst = (C125_rst || network_state);

//-----------------------------------------------------------------------------
//                           network module
//-----------------------------------------------------------------------------
wire network_state;
wire speed_1Gbit;

//-----------------------------------------------------------------------------
//                               sdr rx, tx & IF clock domain transfers
//-----------------------------------------------------------------------------
wire run_sync;
wire wideband_sync;
wire discovery_reply_sync;

// transfer tx clock domain signals to rx clock domain
sync sync_inst1(.clock(rx_clock), .sig_in(udp_tx_active), .sig_out(sending_sync));   
sync sync_inst2(.clock(rx_clock), .sig_in(discovery_ACK), .sig_out(discovery_ACK_sync));

// transfer rx clock domain signals to tx clock domain  
sync sync_inst5(.clock(tx_clock), .sig_in(discovery_reply), .sig_out(discovery_reply_sync)); 
sync sync_inst6(.clock(tx_clock), .sig_in(run), .sig_out(run_sync)); 
sync sync_inst7(.clock(tx_clock), .sig_in(wideband), .sig_out(wideband_sync));


//----------------------------------------------------------------------------------
//  I2C Master to setup TLV320 DAC on Penny(Lane), select mic gain and input source, line-in gain and line-in source, obtain
//  firmware version numbers from Penny and multiple Mercury boards, update Penny output power level, FWD power level, REV
//  power level and Mercury ADC overload status values.
//----------------------------------------------------------------------------------

i2c_interface interface_inst(.Tx_clock_2(clock_12_5MHz), 
										.I2C_clock(I2C_clock), 
										.reset_n(IF_rst),
										.Penny_version(Penny_serialno), 
										.sda(ATLAS_A21), 
										.scl(ATLAS_A20), 
										.probe(probe), 
										.mic_boost(IF_Mic_boost), 
										.line_in(IF_Line_in), 
										.line_gain(IF_line_boost), 
										.Penny_ALC(Penny_ALC),
										.FWD(FWD), 
										.REV(REV), 
										.Merc1_ver(Merc_serialno), .Merc1_overload(ADC_OVERLOAD), 
										.Merc2_ver(Merc2_version), .Merc2_overload(ADC_OVERLOAD2),
										.Merc3_ver(Merc3_version), .Merc3_overload(ADC_OVERLOAD3), 
										.Merc4_ver(Merc4_version), .Merc4_overload(ADC_OVERLOAD4)
										);

wire [3:0] Mercs_installed;
assign Mercs_installed[0] = (Merc_serialno != 8'h00 && Merc_serialno != 8'hff);
assign Mercs_installed[1] = (Merc2_version != 8'h00 && Merc2_version != 8'hff);
assign Mercs_installed[2] = (Merc3_version != 8'h00 && Merc3_version != 8'hff);
assign Mercs_installed[3] = (Merc4_version != 8'h00 && Merc4_version != 8'hff);
wire wide_spectrum;
wire Tx_fifo_rdreq;
wire [10:0] PHY_Tx_rdused;
wire Rx_enable;
wire clock_12_5MHz;
wire [7:0] network_status;
wire rx_clock;
wire tx_clock;
wire udp_rx_active;
wire [7:0] udp_rx_data;
wire udp_tx_active;
wire [47:0] local_mac;	
wire broadcast;
wire [15:0] udp_tx_length;
wire [7:0] udp_tx_data;
wire udp_tx_request;
wire udp_tx_enable;
wire set_ip;
wire IP_write_done;	
wire static_ip_assigned;
wire dhcp_timeout;
wire dhcp_success;
wire icmp_rx_enable;

wire probe;

network network_inst (

	// inputs
  .speed(speed),	
  .udp_tx_request(udp_tx_request),
  .udp_tx_data(udp_tx_data),  
  .set_ip(set_ip),
  .assign_ip(assign_ip),
  .port_ID(port_ID), 
  
  // outputs
  .clock_12_5MHz(clock_12_5MHz),
  .rx_clock(rx_clock),
  .tx_clock(tx_clock),
  .broadcast(broadcast),
  .udp_rx_active(udp_rx_active),
  .udp_rx_data(udp_rx_data),
  .udp_tx_length(udp_tx_length),
  .udp_tx_active(udp_tx_active),
  .local_mac(local_mac),
  .udp_tx_enable(udp_tx_enable), 
  .IP_write_done(IP_write_done),
  .icmp_rx_enable(icmp_rx_enable),   // test for ping bug
  .to_port(to_port),   					// UDP port the PC is sending to

  // status outputs
  .speed_1Gbit(speed_1Gbit),	
  .network_state(network_state),	
  .network_status(network_status),
  .static_ip_assigned(static_ip_assigned),
  .dhcp_timeout(dhcp_timeout),
  .dhcp_success(dhcp_success),

  //make hardware pins available inside this module
  .MODE2(1'b1),
  .PHY_TX(PHY_TX),
  .PHY_TX_EN(PHY_TX_EN),            
  .PHY_TX_CLOCK(PHY_TX_CLOCK),         
  .PHY_RX(PHY_RX),     
  .PHY_DV(PHY_DV),    					// use PHY_DV to be consistent with Metis            
  .PHY_RX_CLOCK(PHY_RX_CLOCK),         
  .PHY_CLK125(PHY_CLK125),           
  .PHY_MDIO(PHY_MDIO),             
  .PHY_MDC(PHY_MDC),

   // MAC eeprom
  .SCK(SCK),                  
  .SI(SI),                   
  .SO(SO), 				
  .CS(CS)
  );

//-----------------------------------------------------------------------------
//                          sdr receive
//-----------------------------------------------------------------------------
wire sending_sync;
wire discovery_reply;
wire pc_send;
wire debug;
wire seq_error;
wire erase_ACK;
wire EPCS_FIFO_enable;
wire erase;	
wire send_more;
wire send_more_ACK;
wire set_up;
wire [31:0] assign_ip;
wire [15:0]to_port;
wire [31:0] PC_seq_number;				// sequence number sent by PC when programming
wire discovery_ACK;
wire discovery_ACK_sync;


sdr_receive sdr_receive_inst(
	//inputs 
	.rx_clock(rx_clock),
	.udp_rx_data(udp_rx_data),
	.udp_rx_active(udp_rx_active),
	.sending_sync(sending_sync),
	.broadcast(broadcast),
	.erase_ACK(busy),						// busy is set when erase command is active in ASMI_interface
	.EPCS_wrused(EPCS_wrused),
	.local_mac(local_mac),
	.to_port(to_port),
	.discovery_ACK(discovery_ACK_sync),	// set when discovery reply request received by sdr_send
	
	//outputs
	.discovery_reply(discovery_reply),
	.seq_error(seq_error),
	.erase(erase),
	.num_blocks(num_blocks),
	.EPCS_FIFO_enable(EPCS_FIFO_enable),
	.set_ip(set_ip),
	.assign_ip(assign_ip),
	.sequence_number(PC_seq_number)
	);

wire [7:0] port_ID;
wire [7:0]Mic_data;
wire mic_fifo_rdreq;
wire [8:0]Rx_data[0:NR-1];
reg fifo_ready[0:NR-1];
wire fifo_rdreq[0:NR-1];
logic [15:0] checksum;
wire CC_ack;
wire CC_data_ready;
wire [7:0] CC_data[0:55];
reg frequency_change[0:NR-1];


sdr_send #(board_type, NR, master_clock, protocol_version) sdr_send_inst(
	//inputs
	.tx_clock(tx_clock),
	.udp_tx_active(udp_tx_active),
	.discovery(discovery_reply_sync),
	.run(run_sync),
	.wideband(wideband_sync),
	.sp_data_ready(sp_data_ready),
	.sp_fifo_rddata(sp_fifo_rddata),		// **** why the odd name - use spectrum_data ?
	.local_mac(local_mac),
	.code_version(Metis_version),
	.beta_version(beta_version),
	.Rx_data(Rx_data),						// Rx I&Q data to send to PHY
	.udp_tx_enable(udp_tx_enable),
	.erase_done(erase_done | erase),    // send ACK when erase command received and when erase complete
	.send_more(send_more),
	.Mic_data(Mic_data),						// mic data to send to PHY
	.fifo_ready(fifo_ready),				// data available in Rx fifo
	.mic_fifo_ready(mic_fifo_ready),		// data avaiable in mic fifo
	.CC_data_ready(CC_data_ready),      // C&C data availble 
	.CC_data(CC_data),
	.sequence_number(PC_seq_number),		// sequence number to send when programming and requesting more data
	.Wideband_packets_per_frame(Wideband_packets_per_frame),  
	.checksum(checksum),  
	
	//outputs
	.udp_tx_data(udp_tx_data),
	.udp_tx_length(udp_tx_length),
	.udp_tx_request(udp_tx_request),
	.fifo_rdreq(fifo_rdreq),				// high to indicate read from Rx fifo required
	.sp_fifo_rdreq	(sp_fifo_rdreq	),		// high to indicate read from spectrum fifo required
	.erase_done_ACK(erase_done_ACK),		
	.send_more_ACK(send_more_ACK),
	.port_ID(port_ID),
	.mic_fifo_rdreq(mic_fifo_rdreq),		// high to indicate read from mic fifo required
	.CC_ack(CC_ack),							// ack to CC_encoder that send request received
	.WB_ack(WB_ack),							// ack to WB controller that send request received	
	.phy_ready(phy_ready),					// set when PHY is not sending DDC data
	.discovery_ACK(discovery_ACK) 		// set to acknowlege discovery reply received
	 ); 		

CC_encoder #(50, NR) CC_encoder_inst (				// 50mS update rate
					//	inputs
					.clock(tx_clock),					// tx_clock  125MHz
					.ACK (CC_ack),
					.PTT ((break_in & CW_PTT) | debounce_PTT),
					.Dot (debounce_DOT),
					.Dash(debounce_DASH),
					.frequency_change(frequency_change),
					.locked_10MHz(locked_10MHz),
					.ADC0_overload (OVERFLOW),
					.Exciter_power (Exciter_power),			
					.FWD_power (FWD_power),
					.REV_power (REV_power),
					.Supply_volts ({4'b0,AIN6}),  
					.User_ADC1 (user_analog1),
					.User_ADC2 (user_analog2),
					.User_IO ({3'b0, IO4}),
					.Debug_data(16'd0),
					//.Debug_data({6'b000000,~DEBUG_LED10,~DEBUG_LED9,~DEBUG_LED8,~DEBUG_LED7,~DEBUG_LED6,~DEBUG_LED5,~DEBUG_LED4,~DEBUG_LED3,~DEBUG_LED2,~DEBUG_LED1}),
					.sequence_errors(ALL_sequence_errors_tx),
					.pk_detect_ack(pk_detect_ack),			// from Hermes_ADC
					.FPGA_PTT(FPGA_PTT),				// when set change update rate to 1mS

					//	outputs
					.CC_data (CC_data),
					.ready (CC_data_ready),
					.pk_detect_reset(pk_detect_reset) 			// to Hermes_ADC
				);
 
 
General_CC #(1024) General_CC_inst // parameter is port number  ***** this data is in rx_clock domain *****
			(
				// inputs
				.clock(rx_clock),
				.to_port(to_port),
				.udp_rx_active(udp_rx_active),
				.udp_rx_data(udp_rx_data),
				// outputs
			   .Rx_Specific_port(Rx_Specific_port),
				.Tx_Specific_port(Tx_Specific_port),
				.High_Prioirty_from_PC_port(High_Prioirty_from_PC_port),
				.High_Prioirty_to_PC_port(High_Prioirty_to_PC_port),			
				.Rx_Audio_port(Rx_Audio_port),
				.Tx_IQ_port(Tx_IQ_port),
				.Rx0_port(Rx0_port),
				.Mic_port(Mic_port),
				.Wideband_ADC0_port(Wideband_ADC0_port),
				.Wideband_enable(Wideband_enable),
				.Wideband_samples_per_packet(Wideband_samples_per_packet),				
				.Wideband_sample_size(Wideband_sample_size),
				.Wideband_update_rate(Wideband_update_rate),
				.Wideband_packets_per_frame(Wideband_packets_per_frame),
				.VNA(VNA),
				.PA_enable(PA_enable),
				.Alex_enable(Alex_enable),			
				.data_ready(data_ready),
				.HW_reset(HW_reset1),
				.HW_timer_enable(HW_timer_enable)
				);



High_Priority_CC #(1027, NR) High_Priority_CC_inst  // parameter is port number 1027  ***** this data is in rx_clock domain *****
			(
				// inputs
				.clock(rx_clock),
				.to_port(to_port),
				.udp_rx_active(udp_rx_active),
				.udp_rx_data(udp_rx_data),
				.HW_timeout(HW_timeout),					// used to clear run if HW timeout.
				// outputs
				.run(run),
				.PC_PTT(PC_PTT),
				.CWX(CWX),
				.Dot(Dot),
				.Dash(Dash),
				.Rx_phase_word(Rx_phase_word),
				.Tx0_phase_word(Tx0_phase_word),
				.Alex_data(Alex_data),
				.drive_level(Drive_Level),
				.Attenuator0(Attenuator0),
				.Open_Collector(Open_Collector),			// open collector outputs on Hermes
				.Alex_data_ready(Alex_data_ready),
				.HW_reset(HW_reset2),
				.sequence_errors(HP_sequence_errors)
			);

Tx_specific_CC #(1026)Tx_specific_CC_inst //   // parameter is port number  ***** this data is in rx_clock domain *****
			( 	
				// inputs
				.clock (rx_clock),
				.to_port (to_port),
				.udp_rx_active (udp_rx_active),
				.udp_rx_data (udp_rx_data),
				// outputs
				.EER() ,
				.internal_CW (internal_CW),
				.key_reverse (key_reverse), 
				.iambic (iambic),					
				.sidetone (sidetone), 			
				.keyer_mode (keyer_mode), 		
				.keyer_spacing(keyer_spacing),
				.break_in(break_in), 						
				.sidetone_level(sidetone_level), 
				.tone_freq(tone_freq), 
				.keyer_speed(keyer_speed),	
				.keyer_weight(keyer_weight),
				.hang(hang), 
				.RF_delay(RF_delay),
				.Line_In(Line_In),
				.Line_In_Gain(Line_In_Gain),
				.Mic_boost(Mic_boost),
				.Angelia_atten_Tx0(atten0_on_Tx),	
				.data_ready(Tx_data_ready),
				.HW_reset(HW_reset3)
			);


Rx_specific_CC #(1025, NR) Rx_specific_CC_inst // parameter is port number  *** not all data is in correct clock domain
			( 	
				// inputs
				.clock(rx_clock),
				.to_port(to_port),
				.udp_rx_active(udp_rx_active),
				.udp_rx_data(udp_rx_data),
				// outputs
				.dither(dither),
				.random(random),
				.RxSampleRate(RxSampleRate),
				.RxADC(RxADC),	
				.SyncRx(SyncRx),
				.EnableRx0_7(EnableRx0_7),
				.Rx_data_ready(Rx_data_ready),
				.Mux(Mux),
				.HW_reset(HW_reset4)
			);			
			
			        
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Receive MDOUT and CDOUT_P data to put in TX FIFO
//
///////////////////////////////////////////////////////////////////////////////////////////////////////

wire [11:0] mic_rdused; 
							  
Mic_fifo Mic_fifo_inst(.wrclk (IF_clk),.rdreq (mic_fifo_rdreq),.rdclk (tx_clock),.wrreq (IF_P_mic_Data_rdy), 
                       .data ({IF_mic_Data[7:0], IF_mic_Data[15:8]}), .q (Mic_data), .wrfull(),
                       .rdusedw(mic_rdused), .aclr(!run)); 

reg mic_fifo_ready;
assign mic_fifo_ready = mic_rdused > 12'd131 ? 1'b1 : 1'b0; // used to indicate that fifo has enough data to send to PC.					  

reg [9:0] mic_samples_count;
always @ (posedge IF_clk) begin
  if (run) begin
    if (mic_samples_count == 10'd998) begin // 48k
      IF_P_mic_Data_rdy <= 1'b1;
      IF_mic_Data <= 16'd0;
      mic_samples_count <= mic_samples_count + 1'b1;
    end
    else if (mic_samples_count == 10'd999) begin
      IF_P_mic_Data_rdy <= 1'b0;
      mic_samples_count <= 10'd0;
    end
    else  mic_samples_count <= mic_samples_count + 1'b1;
  end
end


wire          IF_P_mic_Data_rdy;
wire   [47:0] IF_M_IQ_Data [0:NR-1];
wire [NR-1:0] IF_M_IQ_Data_rdy;
wire [NR-1:0] IF_M_IQ_Data_ack;
reg     [2:0] IF_clock_s;
wire   [63:0] IF_tx_IQ_mic_data;
reg           IF_tx_IQ_mic_rdy;
wire          IF_tx_IQ_mic_ack;
wire   [47:0] IF_IQ_Data;
wire   [15:0] IF_mic_Data;
wire    [3:0] IF_chan; 			// which Mercury receiver channel Tx_fifo_ctrl.v is interested in

`ifdef DONT
NWire_rcv #(.DATA_BITS(16), .ICLK_FREQ(125000000), .XCLK_FREQ(48000000), .SLOWEST_FREQ(20000))
    P_MIC (.irst(C125_rst), .iclk(C125_clk), .xrst(IF_rst), .xclk(IF_clk),
           .xrcv_rdy(IF_P_mic_Data_rdy), .xrcv_ack(IF_M_IQ_Data_ack[0]),
           .xrcv_data(IF_mic_Data), .din(CDOUT_P) );
`endif

generate
  genvar c;
  for (c = 0; c < NR; c = c + 1) // max of 9 receivers
  begin: MDC // NR Mercury Data Channels/Receivers
    NWire_rcv #(.DATA_BITS(48), .ICLK_FREQ(125000000), .XCLK_FREQ(48000000), .SLOWEST_FREQ(20000))
          M_IQ (.irst(C125_rst), .iclk(C125_clk), .xrst(IF_rst), .xclk(IF_clk),
                .xrcv_rdy(IF_M_IQ_Data_rdy[c]), .xrcv_ack(IF_M_IQ_Data_ack[c]),
                .xrcv_data(IF_M_IQ_Data[c]), .din(MDOUT[c]) );
  end
endgenerate

reg       [7:0] Penny_serialno;
reg       [7:0] Merc_serialno;   // up to 4 Mercury boards
reg       [7:0] Merc2_version;
reg       [7:0] Merc3_version;
reg       [7:0] Merc4_version;

reg      [11:0] Penny_ALC;			// Output power from Penny(Lane)
wire 		[11:0] FWD;					// FWD power from AIN4 on Penny(Lane)
wire 		[11:0] REV;					// REV power from AIN3 on Penny(Lane)

reg             ADC_OVERLOAD;    // up to 4 Mercury boards
reg             ADC_OVERLOAD2;
reg             ADC_OVERLOAD3;
reg             ADC_OVERLOAD4;

wire 			Rx_fifo_wreq[0:NR-1];
wire [8:0]  Rx_fifo_data[0:NR-1];
wire        Rx_fifo_full[0:NR-1];
wire [11:0] Rx_used[0:NR-1];
wire        Rx_fifo_clr[0:NR-1];
wire 			Rx_fifo_empty[0:NR-1];
wire 			write_enable;
wire 			phy_ready;
wire 			convert_state;
wire 			IF_run;

// move flags into correct clock domains
cdc_sync #(1) IF_run_sync  (.siga(run), .rstb(IF_rst), .clkb(IF_clk), .sigb(IF_run));
cdc_sync #(8) IF_EnableRx0_7_sync  (.siga(EnableRx0_7), .rstb(IF_rst), .clkb(IF_clk), .sigb(IF_EnableRx0_7));

generate
genvar d;

for (d = 0 ; d < NR; d++)
	begin:p
		Rx_fifo RxX_fifo_inst(.wrclk (IF_clk),.rdreq (fifo_rdreq[d]),.rdclk (tx_clock),.wrreq (Rx_fifo_wreq[d]), .rdempty(Rx_fifo_empty[d]),
							 .data (Rx_fifo_data[d]), .q (Rx_data[d]), .wrfull(Rx_fifo_full[d]),
							 .rdusedw(Rx_used[d]), .aclr (IF_rst || Rx_fifo_clr[d] || !IF_run));

                // Convert 48 bit Rx I&Q data (24bit I, 24 bit Q) into 8 bits to feed Tx FIFO. Only run if IF_EnableRx0_7 is set.
		Rx_fifo_ctrl #(NR) RxX_fifo_ctrl_inst( .reset(!IF_run || !IF_EnableRx0_7[d]), .clock(IF_clk),
							.spd_rdy(IF_M_IQ_Data_rdy[d]), .fifo_full(Rx_fifo_full[d]), .ack(IF_M_IQ_Data_ack[d]),
							.wrenable(Rx_fifo_wreq[d]), .data_out(Rx_fifo_data[d]), .fifo_clear(Rx_fifo_clr[d]),
							.Sync_data_in_I(IF_M_IQ_Data[d][47:24]), .Sync_data_in_Q(IF_M_IQ_Data[d][23:0]));
		always @ (posedge tx_clock)    
			fifo_ready[d] = (Rx_used[d] > 12'd1427) ? 1'b1 : 1'b0;  // used to signal that fifo has enough data to send to PC

                cdc_mcp #(32) cdc_sync_PHASE 
                  (.a_rst(C125_rst), .a_clk(rx_clock), .a_data(Rx_phase_word[d]), .a_data_rdy(Alex_data_ready), .b_rst(IF_rst), .b_clk(IF_clk), .b_data(IF_phase_word[d+1]));
	end
endgenerate

wire [7:0]EPCS_data;
wire [9:0]EPCS_Rx_used;
wire  EPCS_rdreq;
wire [31:0] num_blocks;  
wire EPCS_full;
wire [9:0] EPCS_wrused;


EPCS_fifo EPCS_fifo_inst(.wrclk (rx_clock),.rdreq (EPCS_rdreq),.rdclk (clock_12_5MHz),.wrreq(EPCS_FIFO_enable),  
                .data (udp_rx_data),.q (EPCS_data), .rdusedw(EPCS_Rx_used), .aclr(IF_rst), .wrusedw(EPCS_wrused));

//----------------------------
// 			ASMI Interface
//----------------------------
wire busy;				 // drives LED
wire erase_done;
wire erase_done_ACK;
wire reset_FPGA;

ASMI_interface  ASMI_int_inst(.clock(clock_12_5MHz), .busy(busy), .erase(erase), .erase_ACK(erase_ACK), .IF_PHY_data(EPCS_data),
					 .IF_Rx_used(EPCS_Rx_used), .rdreq(EPCS_rdreq), .erase_done(erase_done), .num_blocks(num_blocks), .checksum(checksum),
					 .send_more(send_more), .send_more_ACK(send_more_ACK), .erase_done_ACK(erase_done_ACK), .NCONFIG(reset_FPGA)); 


//---------------------------------------------------------
//              Decode Command & Control data
//---------------------------------------------------------

wire         mode;     			// normal or Class E PA operation 
wire         Attenuator;		// selects input attenuator setting, 1 = 20dB, 0 = 0dB 
wire         IF_duplex;
wire   [7:0] Drive_Level; 		// Tx drive level
wire         Mic_boost;			// Mic boost 0 = 0dB, 1 = 20dB
wire         Line_In;				// Selects input, mic = 0, line = 1
wire			 common_Merc_freq;		// when set forces Rx2 freq to Rx1 freq
wire   [4:0] Line_In_Gain;		// Sets Line-In Gain value (00000=-32.4 dB to 11111=+12 dB in 1.5 dB steps)
wire         Apollo;				// Selects Alex (0) or Apollo (1)
wire   [4:0] Attenuator0;			// 0-31 dB Heremes attenuator value
wire			 TR_relay_disable;		// Alex T/R relay disable option
wire         internal_CW;			// set when internal CW generation selected
wire   [7:0] sidetone_level;		// 0 - 100, sets internal sidetone level
wire 			 sidetone;				// Sidetone enable, 0 = off, 1 = on
wire   [7:0] RF_delay;				// 0 - 255, sets delay in mS from CW Key activation to RF out
wire   [9:0] hang;					// 0 - 1000, sets delay in mS from release of CW Key to dropping of PTT
wire  [11:0] tone_freq;				// 200 to 1000 Hz, sets sidetone frequency.
wire         key_reverse;		   // reverse CW keyes if set
wire   [5:0] keyer_speed; 			// CW keyer speed 0-60 WPM
wire         keyer_mode;			// 0 = Mode A, 1 = Mode B
wire 			 iambic;					// 0 = external/straight/bug  1 = iambic
wire   [7:0] keyer_weight;			// keyer weight 33-66
wire         keyer_spacing;		// 0 = off, 1 = on
wire 			 break_in;				// if set then use break in mode
wire   [4:0] atten0_on_Tx;			// ADC0 attenuation value to use when Tx is active
wire  [31:0] Rx_phase_word[0:NR-1];	// Rx(n) receive frequency
wire  [31:0] Tx0_phase_word;		// Tx0 transmit frequency
wire  [31:0] Alex_data;				// control data to Alex board
wire         run;						// set when run active 
wire 		    PC_PTT;					// set when PTT from PC active
wire 	 [7:0] dither;					// Dither for ADC0
wire   [7:0] random;					// Random for ADC0[
wire   [7:0] RxADC[0:NR-1];			// ADC or DAC that Rx(n) is connected to
wire 	[15:0] RxSampleRate[0:NR-1];	// Rxn Sample rate 48/96/192 etc
wire 			 Alex_data_ready;		// indicates Alex data available
wire         Rx_data_ready;		// indicates Rx_specific data available
wire 			 Tx_data_ready;		// indicated Tx_specific data available
wire   [7:0] Mux;						// Rx in mux mode when bit set, [0] = Rx0, [1] = Rx1 etc 
wire   [7:0] SyncRx[0:NR-1];			// bit set selects Rx to sync or mux with
wire 	 [7:0] EnableRx0_7;			// Rx enabled when bit set, [0] = Rx0, [1] = Rx1 etc
wire 	 [7:0] IF_EnableRx0_7;
wire  [15:0] Rx_Specific_port;	// 
wire  [15:0] Tx_Specific_port;
wire  [15:0] High_Prioirty_from_PC_port;
wire  [15:0] High_Prioirty_to_PC_port;			
wire  [15:0] Rx_Audio_port;
wire  [15:0] Tx_IQ_port;
wire  [15:0] Rx0_port;
wire  [15:0] Mic_port;
wire  [15:0] Wideband_ADC0_port;
wire   [7:0] Wideband_enable;					// [0] set enables ADC0, [1] set enables ADC1
wire  [15:0] Wideband_samples_per_packet;				
wire   [7:0] Wideband_sample_size;
wire   [7:0] Wideband_update_rate;
wire   [7:0] Wideband_packets_per_frame; 
wire  [15:0] Envelope_PWM_max;
wire  [15:0] Envelope_PWM_min;
wire   [7:0] Open_Collector;
wire   [7:0] User_Outputs;
wire   [7:0] Mercury_Attenuator;	
wire 			 CWX;						// CW keyboard from PC 
wire         Dot;						// CW dot key from PC
wire         Dash;					// CW dash key from PC]
wire freq_data_ready;


///////////////////////////////////////////////////////////////
//
//              Implements Command & Control  encoder 
//
///////////////////////////////////////////////////////////////
/*
	The C&C encoder broadcasts data over the Atlas bus C20 for
	use by other cards e.g. Mercury and Penelope.
	
	The data format is as follows:
	
	<[90:89]DFS1,DFS0><[88]PTT><[87:84]address><[83:52]frequency><[51:49]clock_source><[48:42]OC>
	<[41]Mode><[40]PREAMP><[39]DITHER><[38]RAND><[37:36]ATTEN><[35:34]TX_relay><[33]Rout><[32:31]RX_relay>
	<[30:16]Alex><[15:8]Drive_Level><[7:5]multiRx_mode><[4:1]RxN_preamps><[0]common_Merc_freq> 
	
	
	Total of 91 bits. Frequency is in Hz and OC is the open collector data on Penelope.
	The clock source decodes as follows:
	
	x00  = 10MHz reference from Atlas bus ie Gibraltar
	x01  = 10MHz reference from Penelope
	x10  = 10MHz reference from Mercury
	0xx  = 122.88MHz source from Penelope 
	1xx  = 122.88MHz source from Mercury

		
	For future expansion the three bit address enables specific C&C data to be send to individual boards.
	For the present for use with Mercury and Penelope the address is ignored. 

*/

reg  [31:0] IF_phase_word [0:NR];
wire [90:0] IF_xmit_data;
reg   [3:0] CC_address;     // C&C address  0 - 7 
reg   [2:0] multiRx_mode;   // 000 = single receiver; 001 = two receivers, 002 = three receivers, 003 = four receivers
wire        IF_CC_rdy, IF_CC_pulse;


////////////////////////////////////////////////////////////////////////////////
// Mercury preamp (attenuator) control 
// note legacy control of Merc1 preamp via IF_preamp and RxN_preamps for control of up to 4 Mercury boards
// Turn preamp(s) OFF on Tx when Merc_atten_on_Tx is set; preamp OFF = 20 dB attenuation on Mercury

wire Merc1_preamp;
wire [3:0] MercN_preamps;
reg   [6:0] IF_OC;
reg     IF_mode;                    // normal or Class E PA operation 
reg   [1:0] IF_ATTEN;                   // decode attenuator setting on Alex
reg   [1:0] IF_TX_relay; 		// Tx relay setting on Alex
reg         IF_Rout;     		// Rx1 out on Alex
reg   [1:0] IF_RX_relay; 		// Rx relay setting on Alex 
reg  [14:0] IF_Alex[0:3];		// Alex auto/manual mode select and HPF/LPF relay switching when in manual mode

pulsegen CC_p   (.sig(IF_CC_rdy), .rst(IF_rst), .clk(IF_clk), .pulse(IF_CC_pulse));

// change address each data transmission 
always @ (posedge IF_clk)
begin
  if (IF_rst)
    CC_address <= #IF_TPD 4'd0;
  else if (IF_CC_pulse) // occurs at each rising edge of IF_CC_rdy
  begin
    if (CC_address == NR+1)
      CC_address <= #IF_TPD 4'd0; // Penny = 0
    else
      CC_address <= #IF_TPD CC_address + 1'b1; // 1 <= Mercury <= NR
  end
end

/*
	<[90:89]DFS1,DFS0><[88]PTT><[87:84]address><[83:52]frequency><[51:49]clock_source><[48:42]OC>
	<[41]Mode><[40]PREAMP><[39]DITHER><[38]RAND><[37:36]ATTEN><[35:34]TX_relay><[33]Rout><[32:31]RX_relay>
	<[30:16]Alex><[15:8]Drive_Level><[7:5]multiRx_mode><[4:1]RxN_preamps><[0]common_Merc_freq> 
*/
//assign IF_xmit_data = {IF_DFS[CC_address],1'b0,CC_address,Rx_frequency[CC_address],3'b110,IF_OC,IF_mode,Merc1_preamp,
//assign IF_xmit_data = {2'b10,1'b0,CC_address,32'd7200000,3'b110,IF_OC,IF_mode,Merc1_preamp,
//                       dither, random, IF_ATTEN, IF_TX_relay, IF_Rout, IF_RX_relay, IF_Alex[CC_address], Drive_Level, 
//							  multiRx_mode, MercN_preamps, common_Merc_freq};

//assign IF_xmit_data = {RxSampleRate[CC_address],IF_run,CC_address,IF_phase_word[CC_address],Open_Collector[6:1],27'hd0,4'b1111,1'b0};
assign IF_xmit_data = {2'b10,1'b0,CC_address,IF_phase_word_swap[CC_address],3'b110,44'd0,4'b1111,1'b0};

NWire_xmit  #(.DATA_BITS(91), .ICLK_FREQ(48000000), .XCLK_FREQ(48000000), .SEND_FREQ(10000)) 
      CCxmit (.irst(IF_rst), .iclk(IF_clk), .xrst(IF_rst), .xclk(IF_clk),
              .xdata(IF_xmit_data), .xreq(1'b1), .xrdy(IF_CC_rdy), .xack(), .dout(CC));

// NOTE: 4 and 9 are swapped in MDOUT
wire  [31:0] IF_phase_word_swap [0:NR+1];
assign IF_phase_word_swap[1] = IF_phase_word[1];
assign IF_phase_word_swap[2] = IF_phase_word[2];
assign IF_phase_word_swap[3] = IF_phase_word[3];
assign IF_phase_word_swap[4] = IF_phase_word[4];
assign IF_phase_word_swap[5] = IF_phase_word[5];
assign IF_phase_word_swap[6] = IF_phase_word[6];
assign IF_phase_word_swap[7] = IF_phase_word[7];
assign IF_phase_word_swap[8] = IF_phase_word[8];
assign IF_phase_word_swap[9] = IF_phase_word[4];  // so far the best
//6,9 assign IF_phase_word_swap[9] = IF_phase_word[6];

//-----------------------------------------------------------
//  Debounce PTT from Atlas bus OR pin 6 of DB9 (active low)
//-----------------------------------------------------------

debounce de_PTT(.clean_pb(clean_PTT_in), .pb(PTT_in || ~PTT_n), .clk(IF_clk));


//-----------------------------------------------------------
//  Debounce dot key - active low
//-----------------------------------------------------------


debounce de_dot(.clean_pb(clean_dot), .pb(~dot_n), .clk(IF_clk));

//-----------------------------------------------------------
//  Debounce dash key - active low
//-----------------------------------------------------------

debounce de_dash(.clean_pb(clean_dash), .pb(~dash_n), .clk(IF_clk));

//-----------------------------------------------------------
// LEDs are active low
//-----------------------------------------------------------
assign RAM_A1 = ~Open_Collector[1];
assign RAM_A2 = ~Open_Collector[2];
assign RAM_A3 = ~Open_Collector[3];
assign RAM_A4 = ~Open_Collector[4];
assign RAM_A5 = ~Open_Collector[5];
assign RAM_A6 = ~Open_Collector[6];

reg [26:0]HB_counter;
always @(posedge C125_clk) HB_counter = HB_counter + 1'b1;
assign HEART_BEAT = HB_counter[25];

function integer clogb2;
input [31:0] depth;
begin
  for(clogb2=0; depth>0; clogb2=clogb2+1)
  depth = depth >> 1;
end
endfunction

endmodule

