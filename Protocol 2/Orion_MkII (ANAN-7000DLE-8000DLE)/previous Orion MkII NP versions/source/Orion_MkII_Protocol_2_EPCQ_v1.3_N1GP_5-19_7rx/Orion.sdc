# Orion.sdc

#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3

#**************************************************************
# Create Clock (base clocks, external to the FPGA)
#**************************************************************

#create_clock -name _122MHz 				-period 8.138 	[get_ports {_122MHz}]
#create_clock -name LTC2208_122MHz 		-period 8.138 	[get_ports {LTC2208_122MHz}]
#create_clock -name LTC2208_122MHz_2 	-period 8.138 	[get_ports {LTC2208_122MHz_2}]
#create_clock -name OSC_10MHZ 				-period 100.000 [get_ports {OSC_10MHZ}]
#create_clock -name PHY_CLK125				-period 8.000 	[get_ports {PHY_CLK125}]
#create_clock -name PHY_RX_CLOCK 			-period 8.000  -waveform {2 6} [get_ports {PHY_RX_CLOCK}]

#virtual base clocks on required inputs
#create_clock -name virt_PHY_RX_CLOCK 	-period 8.000
#create_clock -name virt_122MHz 			-period 8.138
#create_clock -name virt_CBCLK				-period 325.52

# from Altera Engineer - same as mine but fully defined.

create_clock -name {_122MHz} -period 8.138 -waveform { 0.000 4.069 } [get_ports {_122MHz}]
create_clock -name {LTC2208_122MHz} -period 8.138 -waveform { 0.000 4.069 } [get_ports {LTC2208_122MHz}]
create_clock -name {LTC2208_122MHz_2} -period 8.138 -waveform { 0.000 4.069 } [get_ports {LTC2208_122MHz_2}]
create_clock -name {OSC_10MHZ} -period 100.000 -waveform { 0.000 50.000 } [get_ports {OSC_10MHZ}]
create_clock -name {PHY_CLK125} -period 8.000 -waveform { 0.000 4.000 } [get_ports {PHY_CLK125}]
create_clock -name {PHY_RX_CLOCK} -period 8.000 -waveform { 2.000 6.000 } [get_ports {PHY_RX_CLOCK}]

#virtual base clocks on required inputs
create_clock -name {virt_PHY_RX_CLOCK} -period 8.000 -waveform { 0.000 4.000 } 
create_clock -name {virt_122MHz} -period 8.138 -waveform { 0.000 4.069 } 
create_clock -name {virt_CBCLK} -period 325.520 -waveform { 0.000 162.760 } 


derive_pll_clocks

derive_clock_uncertainty

#assign more familiar names!
set CMCLK  PLL_IF_inst|altpll_component|auto_generated|pll1|clk[0]
set CBCLK  PLL_IF_inst|altpll_component|auto_generated|pll1|clk[1]
set CLRCLK PLL_IF_inst|altpll_component|auto_generated|pll1|clk[2]

set clock_12_5MHz network_inst|rgmii_send_inst|tx_pll_inst|altpll_component|auto_generated|pll1|clk[2]

set clock_2_5MHz  network_inst|rgmii_send_inst|tx_pll_inst|altpll_component|auto_generated|pll1|clk[3]


#**************************************************************
# Create Generated Clock (internal to the FPGA)
#**************************************************************
# NOTE: Whilst derive_pll_clocks constrains PLL clocks if these are connected to an FPGA output pin then a generated
# clock needs to be attached to the pin and a false path set to it

#create genenerated clock for internal PHY Tx data clock.
create_generated_clock -name tx_clock   -source [get_pins {network_inst|rgmii_send_inst|tx_pll_inst|altpll_component|auto_generated|pll1|inclk[0]}]  [get_pins {network_inst|rgmii_send_inst|tx_pll_inst|altpll_component|auto_generated|pll1|clk[0]}] -add

#create generated clock for PLL transmit clock output with 90 phase shift
create_generated_clock -source [get_pins {network_inst|rgmii_send_inst|tx_pll_inst|altpll_component|auto_generated|pll1|inclk[0]}] [get_pins {network_inst|rgmii_send_inst|tx_pll_inst|altpll_component|auto_generated|pll1|clk[1]}] -phase 90

#create generated clock for PHY Tx clock
create_generated_clock -name PHY_TX_CLOCK  -source [get_pins {network_inst|rgmii_send_inst|tx_pll_inst|altpll_component|auto_generated|pll1|clk[1]}] [get_ports PHY_TX_CLOCK]

# data_clock = CMCLK/2 used by Attenuator and TLV320 SPI
create_generated_clock -name data_clk -source $CMCLK -divide 2

# data_clk2 = CBCLK/4 
create_generated_clock -name data_clk2 -source $CBCLK -divide 4

# PLL generated clocks feeding output pins 
create_generated_clock -name CBCLK   -source $CBCLK  [get_ports CBCLK]
create_generated_clock -name CMCLK   -source $CMCLK  [get_ports CMCLK]
create_generated_clock -name CLRCIN  -source $CLRCLK [get_ports CLRCIN]
create_generated_clock -name CLRCOUT -source $CLRCLK [get_ports CLRCOUT]


#************************************************************** 
# Set Input Delay
#**************************************************************

# If setup and hold delays are equal then only need to specify once without max or min 

#12.5MHz clock for Config EEPROM  +/- 10nS setup and hold
set_input_delay 10  -clock  $clock_12_5MHz { ASMI_interface:ASMI_int_inst|ASMI:ASMI_inst|ASMI_altasmi_parallel_smm2:ASMI_altasmi_parallel_smm2_component|cycloneii_asmiblock2~ALTERA_DATA0 }

# data from LTC2208 +/- 2nS setup and hold 
#set_input_delay 2.000 -clock virt_122MHz  { INA*}
set_input_delay -add_delay  -clock [get_clocks {virt_122MHz}]  2.000 [get_ports {INA[*]}]
set_input_delay -add_delay  -clock [get_clocks {virt_122MHz}]  2.000 [get_ports {INA_2[*]}]


# data from PHY
set_input_delay  -max 0.8  -clock virt_PHY_RX_CLOCK -add_delay [get_ports {PHY_RX[*] RX_DV}] 
set_input_delay  -min -0.8 -clock virt_PHY_RX_CLOCK -add_delay [get_ports {PHY_RX[*] RX_DV}] 				
set_input_delay  -max 0.8 -clock virt_PHY_RX_CLOCK  -clock_fall -add_delay [get_ports {PHY_RX[*] RX_DV}]	
set_input_delay  -min -0.8 -clock virt_PHY_RX_CLOCK -clock_fall -add_delay [get_ports {PHY_RX[*] RX_DV}]	

#TLV320 Data in +/- 20nS setup and hold
set_input_delay  20  -clock virt_CBCLK  {CDOUT} -add_delay

#EEPROM Data in +/- 40nS setup and hold
set_input_delay  40  -clock $clock_2_5MHz {SO} -add_delay 

#PHY PHY_MDIO Data in +/- 10nS setup and hold
set_input_delay  10  -clock $clock_2_5MHz {PHY_MDIO PHY_INT_N} -add_delay

#ADC78H90 Data in +/- 10nS setup and hold
set_input_delay  10  -clock data_clk2 {ADCMISO} -add_delay


#**************************************************************
# Set Output Delay
#**************************************************************

# If setup and hold delays are equal then only need to specify once without max or min 

#12.5MHz clock for Config EEPROM  +/- 10nS
set_output_delay  10 -clock $clock_12_5MHz {ASMI_interface:ASMI_int_inst|ASMI:ASMI_inst|ASMI_altasmi_parallel_smm2:ASMI_altasmi_parallel_smm2_component|cycloneii_asmiblock2~ALTERA_DCLK ASMI_interface:ASMI_int_inst|ASMI:ASMI_inst|ASMI_altasmi_parallel_smm2:ASMI_altasmi_parallel_smm2_component|cycloneii_asmiblock2~ALTERA_SCE ASMI_interface:ASMI_int_inst|ASMI:ASMI_inst|ASMI_altasmi_parallel_smm2:ASMI_altasmi_parallel_smm2_component|cycloneii_asmiblock2~ALTERA_SDO }

#122.88MHz clock for Tx DAC 
set_output_delay 0.8 -clock _122MHz {DACD[*]} -add_delay

# Altera suggestion

set_output_delay  -max 1.0  -clock PHY_TX_CLOCK [get_ports {PHY_TX[*] PHY_TX_EN}] -add_delay

set_output_delay  -min -0.8 -clock PHY_TX_CLOCK [get_ports {PHY_TX[*] PHY_TX_EN}]  -add_delay

set_output_delay  -max 1.0  -clock PHY_TX_CLOCK [get_ports {PHY_TX[*] PHY_TX_EN}]  -clock_fall -add_delay

set_output_delay  -min -0.8 -clock PHY_TX_CLOCK [get_ports {PHY_TX[*] PHY_TX_EN}]  -clock_fall -add_delay 

# Attenuators - min is referenced to falling edge of clock 
set_output_delay  10  -clock data_clk { ATTN_DATA* ATTN_LE* MICBIAS_ENABLE MICBIAS_SELECT MIC_SIG_SELECT PTT_SELECT } -add_delay
set_output_delay  10  -clock data_clk { ATTN_DATA* ATTN_LE* MICBIAS_ENABLE MICBIAS_SELECT MIC_SIG_SELECT PTT_SELECT } -clock_fall -add_delay

#TLV320 SPI  
set_output_delay  20 -clock data_clk { MOSI nCS} -add_delay

#TLV320 Data out 
set_output_delay  10 -clock $CBCLK {CDIN CMODE} -add_delay

#Alex  uses CBCLK/4
set_output_delay  10 -clock data_clk2 { SPI_SDO J15_5 J15_6} -add_delay

#EEPROM (2.5MHz)
set_output_delay  40 -clock $clock_2_5MHz {SCK SI CS} -add_delay

#ADC78H90 
set_output_delay  10 -clock data_clk2 {ADCMOSI nADCCS} -add_delay

#PHY (2.5MHz)
set_output_delay  10 -clock $clock_2_5MHz {PHY_MDIO} -add_delay


#**************************************************************
# Set Clock Groups
#**************************************************************
set_clock_groups -asynchronous  -group { \
					LTC2208_122MHz \
					LTC2208_122MHz_2 \
					_122MHz \
					PLL_IF_inst|altpll_component|auto_generated|pll1|clk[0] \
					PLL_IF_inst|altpll_component|auto_generated|pll1|clk[1] \
					PLL_IF_inst|altpll_component|auto_generated|pll1|clk[2] \
					PLL_inst|altpll_component|auto_generated|pll1|clk[0] \
					PLL_30MHz_inst|altpll_component|auto_generated|pll1|clk[0] \
					data_clk \
					data_clk2 \
					CBCLK \
					CMCLK \
					CLRCIN \
					CLRCOUT \
				       } \
				-group { \
					PHY_CLK125 \
					network_inst|rgmii_send_inst|tx_pll_inst|altpll_component|auto_generated|pll1|clk[0] \
					network_inst|rgmii_send_inst|tx_pll_inst|altpll_component|auto_generated|pll1|clk[1] \
					network_inst|rgmii_send_inst|tx_pll_inst|altpll_component|auto_generated|pll1|clk[2] \
					tx_clock \
					PHY_TX_CLOCK \
				       } \
				-group {OSC_10MHZ } \
				-group {PHY_RX_CLOCK } \
				-group {network_inst|rgmii_send_inst|tx_pll_inst|altpll_component|auto_generated|pll1|clk[3]}				
				
		
#**************************************************************
# Set Maximum Delay
#************************************************************** 

set_max_delay -from _122MHz -to PLL_IF_inst|altpll_component|auto_generated|pll1|clk[3] 5
set_max_delay -from _122MHz -to _122MHz 10

set_max_delay -from LTC2208_122MHz -to LTC2208_122MHz 15

set_max_delay -from PLL_IF_inst|altpll_component|auto_generated|pll1|clk[0] -to PLL_IF_inst|altpll_component|auto_generated|pll1|clk[3] 3

set_max_delay -from network_inst|rgmii_send_inst|tx_pll_inst|altpll_component|auto_generated|pll1|clk[0] -to tx_clock 18
set_max_delay -from network_inst|rgmii_send_inst|tx_pll_inst|altpll_component|auto_generated|pll1|clk[0] -to network_inst|rgmii_send_inst|tx_pll_inst|altpll_component|auto_generated|pll1|clk[0] 18

set_max_delay -from tx_clock -to network_inst|rgmii_send_inst|tx_pll_inst|altpll_component|auto_generated|pll1|clk[0] 18
set_max_delay -from tx_clock -to tx_clock 18

set_max_delay -from PHY_RX_CLOCK -to PHY_RX_CLOCK 8

#**************************************************************
# Set Multicycle Path
#************************************************************** 



#**************************************************************
# Set Minimum Delay
#**************************************************************

set_min_delay -from virt_PHY_RX_CLOCK -to PHY_RX_CLOCK -3
set_min_delay -from PHY_RX_CLOCK -to PHY_RX_CLOCK -1
set_min_delay -from PLL_IF_inst|altpll_component|auto_generated|pll1|clk[2] -to PLL_IF_inst|altpll_component|auto_generated|pll1|clk[1] -1


#**************************************************************
# Set False Paths
#**************************************************************
 
#set false paths for PHY Tx 
set_false_path -setup -rise_from [get_clocks tx_clock] -fall_to [get_clocks PHY_TX_CLOCK]
set_false_path -setup -fall_from [get_clocks tx_clock] -rise_to [get_clocks PHY_TX_CLOCK]
set_false_path -setup -rise_from [get_clocks tx_clock] -rise_to [get_clocks PHY_TX_CLOCK]
set_false_path -setup -fall_from [get_clocks tx_clock] -fall_to [get_clocks PHY_TX_CLOCK]

#set false paths for PHY Rx
set_false_path -setup -rise_from [get_clocks virt_PHY_RX_CLOCK] -fall_to [get_clocks PHY_RX_CLOCK]
set_false_path -setup -fall_from [get_clocks virt_PHY_RX_CLOCK] -rise_to [get_clocks PHY_RX_CLOCK]
set_false_path -setup -rise_from [get_clocks virt_PHY_RX_CLOCK] -rise_to [get_clocks PHY_RX_CLOCK]
set_false_path -setup -fall_from [get_clocks virt_PHY_RX_CLOCK] -fall_to [get_clocks PHY_RX_CLOCK]

set_false_path -from [get_clocks {LTC2208_122MHz}] -to [get_clocks {LTC2208_122MHz_2}]

# Set false path to generated clocks that feed output pins
set_false_path -to [get_ports {CMCLK CBCLK CLRCIN CLRCOUT ATTN_CLK* SSCK ADCCLK SPI_SCK PHY_MDC PHY_TX_CLOCK}]

# 'get_keepers' denotes either ports or registers
# don't need fast paths to the LEDs and adhoc outputs so set false paths so Timing will be ignored
set_false_path -to [get_keepers { Status_LED DEBUG_LED* DITH* FPGA_PTT  NCONFIG  RAND*  USEROUT* FPGA_PLL DAC_ALC DRIVER_PA_EN CTRL_TRSW IO1 TX_ATTEN*}]

#don't need fast paths from the following inputs
set_false_path -from [get_keepers  {ANT_TUNE IO2 IO4 IO5 IO6 IO8 KEY_DASH KEY_DOT OVERFLOW* PTT MODE2 TX_ATTEN_SELECT}]

#these registers are set long before they are used
set_false_path -from [get_registers {network:network_inst|eeprom:eeprom_inst|mac[*]}] -to [all_registers]
set_false_path -from [get_registers {network:network_inst|local_ip[*]}] -to [all_registers]
set_false_path -from [get_registers {network:network_inst|arp:arp_inst|destination_mac[*]}] -to [all_registers]



