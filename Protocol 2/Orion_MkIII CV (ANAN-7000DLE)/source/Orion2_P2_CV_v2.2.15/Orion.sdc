# Orion.sdc

#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3

#**************************************************************
# Create Clock (base clocks, external to the FPGA)
#**************************************************************

create_clock -name {_122MHz} -period 8.138 -waveform { 0.000 4.069 } [get_ports {_122MHz}]
create_clock -name {LTC2208_122MHz} -period 8.138 -waveform { 0.000 4.069 } [get_ports {LTC2208_122MHz}]
create_clock -name {LTC2208_122MHz_2} -period 8.138 -waveform { 0.000 4.069 } [get_ports {LTC2208_122MHz_2}]
create_clock -name {OSC_10MHZ} -period 100.000 -waveform { 0.000 50.000 } [get_ports {OSC_10MHZ}]
create_clock -name {CLOCK_25MHZ} -period 40.000 -waveform { 0.000 20.000 } [get_ports {CLOCK_25MHZ}]

set_clock_groups -exclusive -group {CLOCK_25MHZ}

#virtual base clocks on required inputs
create_clock -name {virt_PHY_RX_CLOCK} -period 8.000 -waveform { 0.000 4.000 } 
create_clock -name {virt_122MHz} -period 8.138 -waveform { 0.000 4.069 } 
create_clock -name {virt_CBCLK} -period 325.520 -waveform { 0.000 162.760 } 

set_clock_groups -exclusive -group {virt_PHY_RX_CLOCK}

#derive_pll_clocks

## Clocks in Eth TX Domain
create_clock -name phy_clk125 -period 125.000MHz	[get_ports PHY_CLK125]

set_clock_groups -asynchronous -group [get_clocks {phy_clk125}] -group [get_clocks {LTC2208_122MHz}]

create_generated_clock -source {network_inst|tx_pll_inst|tx_pllv_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|vco0ph[0]} -duty_cycle 50.00 -name clock_125MHz {network_inst|tx_pll_inst|tx_pllv_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk} -add
create_generated_clock -source {network_inst|tx_pll_inst|tx_pllv_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|vco0ph[0]} -phase 63.00 -duty_cycle 50.00 -name clock_90_125MHz {network_inst|tx_pll_inst|tx_pllv_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk} -add
create_generated_clock -source {network_inst|tx_pll_inst|tx_pllv_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|vco0ph[0]} -divide_by 50 -duty_cycle 50.00 -name clock_2_5MHz {network_inst|tx_pll_inst|tx_pllv_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|divclk} -add
create_generated_clock -source {network_inst|tx_pll_inst|tx_pllv_inst|altera_pll_i|general[3].gpll~PLL_OUTPUT_COUNTER|vco0ph[0]} -divide_by 10 -duty_cycle 50.00 -name clock_12p5MHz {network_inst|tx_pll_inst|tx_pllv_inst|altera_pll_i|general[3].gpll~PLL_OUTPUT_COUNTER|divclk} -add


## Clocks in Eth RX Domain
create_clock -name phy_rx_clk -period 8.000	-waveform {2.0 6.0} [get_ports {PHY_RX_CLOCK}]
set_clock_groups -exclusive -group {phy_rx_clk}

## Clocks in DSP C122 Domain
create_generated_clock -source {PLL_IFV_inst|pll_ifv_inst|altera_pll_i|cyclonev_pll|fpll_0|fpll|refclkin} -duty_cycle 50.00 -phase 90.00 -name _122_90 {PLL_IFV_inst|pll_ifv_inst|altera_pll_i|cyclonev_pll|counter[0].output_counter|divclk}
create_generated_clock -source {PLL_IFV_inst|pll_ifv_inst|altera_pll_i|cyclonev_pll|fpll_0|fpll|refclkin} -duty_cycle 50.00 -divide_by 10 -name CMCLK {PLL_IFV_inst|pll_ifv_inst|altera_pll_i|cyclonev_pll|counter[1].output_counter|divclk} -add
create_generated_clock -source {PLL_IFV_inst|pll_ifv_inst|altera_pll_i|cyclonev_pll|fpll_0|fpll|refclkin} -duty_cycle 50.00 -phase 180.00 -divide_by 40 -name CBCLK {PLL_IFV_inst|pll_ifv_inst|altera_pll_i|cyclonev_pll|counter[2].output_counter|divclk} -add
create_generated_clock -source {PLL_IFV_inst|pll_ifv_inst|altera_pll_i|cyclonev_pll|fpll_0|fpll|refclkin} -duty_cycle 50.00 -divide_by 2560 -name CLRCLK {PLL_IFV_inst|pll_ifv_inst|altera_pll_i|cyclonev_pll|counter[4].output_counter|divclk} -add

create_generated_clock -source {PLL_30MHzV_inst|pll_30mhzv_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|refclkin} -duty_cycle 50.00 -divide_by 4 -name userADC_clock {PLL_30MHzV_inst|pll_30mhzv_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}
create_generated_clock -source {PLL_30MHzV_inst|pll_30mhzv_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|vco0ph[0]} -duty_cycle 50.00 -divide_by 1536 -multiply_by 125 -name pll_osc_10MHz {PLL_30MHzV_inst|pll_30mhzv_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}

#**************************************************************
# Create Generated Clock (internal to the FPGA)
#**************************************************************
# NOTE: Whilst derive_pll_clocks constrains PLL clocks if these are connected to an FPGA output pin then a generated
# clock needs to be attached to the pin and a false path set to it

# data_clock = CMCLK/2  used by TLV320 SPI
create_generated_clock -name data_clk -source {PLL_IFV_inst|pll_ifv_inst|altera_pll_i|cyclonev_pll|counter[1].output_counter|divclk} -divide 2

# data_clk2 = CBCLK/4 used by Attenuator
create_generated_clock -name data_clk2 -source {PLL_IFV_inst|pll_ifv_inst|altera_pll_i|cyclonev_pll|counter[2].output_counter|divclk} -divide 4


derive_clock_uncertainty

#**************************************************************
# Set Clock Groups
#**************************************************************
set_clock_groups -asynchronous  -group { \
					phy_clk125 \
					clock_125MHz clock_90_125MHz clock_2_5MHz \
				       } \
				-group { \
					phy_rx_clk \
				       } \
				-group {LTC2208_122MHz_2} \
				-group { \
					LTC2208_122MHz \
					_122MHz \
					_122_90 CMCLK CBCLK CLRCLK \
					userADC_clock \
					pll_osc_10MHz \
					data_clk data_clk2 \
				       } \
				-group {OSC_10MHZ}
		
## Ethernet PHY TX per AN477, with PHY delay for TX disabled

set_output_delay  -max 1.0  -clock clock_90_125MHz [get_ports {PHY_TX[*]}] -add_delay
set_output_delay  -min -0.8 -clock clock_90_125MHz [get_ports {PHY_TX[*]}]  -add_delay
set_output_delay  -max 1.0  -clock clock_90_125MHz [get_ports {PHY_TX[*]}]  -clock_fall -add_delay
set_output_delay  -min -0.8 -clock clock_90_125MHz [get_ports {PHY_TX[*]}]  -clock_fall -add_delay 

set_output_delay  -max 1.0  -clock clock_90_125MHz [get_ports {PHY_TX_EN}] -add_delay
set_output_delay  -min -0.8 -clock clock_90_125MHz [get_ports {PHY_TX_EN}]  -add_delay
set_output_delay  -max 1.0  -clock clock_90_125MHz [get_ports {PHY_TX_EN}]  -clock_fall -add_delay
set_output_delay  -min -0.8 -clock clock_90_125MHz [get_ports {PHY_TX_EN}]  -clock_fall -add_delay 

# Set false paths to remove irrelevant setup and hold analysis
set_false_path -fall_from [get_clocks clock_125MHz] -rise_to [get_clocks clock_90_125MHz] -setup
set_false_path -rise_from [get_clocks clock_125MHz] -fall_to [get_clocks clock_90_125MHz] -setup
set_false_path -fall_from [get_clocks clock_125MHz] -fall_to [get_clocks clock_90_125MHz] -hold
set_false_path -rise_from [get_clocks clock_125MHz] -rise_to [get_clocks clock_90_125MHz] -hold


## Ethernet PHY RX per AN477, with PHY delay for RX enabled
## Clock delay added by KSZ9031 is 1.0 to 2.6 per datasheet table 7-1
## Clock is 90deg shifted, 2ns
## Max delay is 2.6-2.0 = 0.6
## Min delay is 1.0-2.0 = -1.0

# data from PHY
set_input_delay  -max 0.8  -clock [get_clocks virt_PHY_RX_CLOCK] -add_delay [get_ports {PHY_RX[*]}] 
set_input_delay  -min -0.8 -clock [get_clocks virt_PHY_RX_CLOCK] -add_delay [get_ports {PHY_RX[*]}] 				
set_input_delay  -max 0.8 -clock_fall -clock [get_clocks virt_PHY_RX_CLOCK] -add_delay [get_ports {PHY_RX[*]}]	
set_input_delay  -min -0.8 -clock_fall -clock [get_clocks virt_PHY_RX_CLOCK] -add_delay [get_ports {PHY_RX[*]}]	

set_input_delay  -max 0.8  -clock [get_clocks virt_PHY_RX_CLOCK] -add_delay [get_ports {RX_DV}] 
set_input_delay  -min -0.8 -clock [get_clocks virt_PHY_RX_CLOCK] -add_delay [get_ports {RX_DV}] 				
set_input_delay  -max 0.8 -clock_fall -clock [get_clocks virt_PHY_RX_CLOCK] -add_delay [get_ports {RX_DV}]	
set_input_delay  -min -0.8 -clock_fall -clock [get_clocks virt_PHY_RX_CLOCK] -add_delay [get_ports {RX_DV}]	

# Set false paths to remove irrelevant setup and hold analysis
set_false_path -fall_from [get_clocks virt_PHY_RX_CLOCK] -rise_to [get_clocks {phy_rx_clk}] -setup
set_false_path -rise_from [get_clocks virt_PHY_RX_CLOCK] -fall_to [get_clocks {phy_rx_clk}] -setup
set_false_path -fall_from [get_clocks virt_PHY_RX_CLOCK] -fall_to [get_clocks {phy_rx_clk}] -hold
set_false_path -rise_from [get_clocks virt_PHY_RX_CLOCK] -rise_to [get_clocks {phy_rx_clk}] -hold

## Misc PHY

#PHY PHY_MDIO Data in +/- 10nS setup and hold
set_input_delay  10  -clock clock_2_5MHz -reference_pin [get_ports PHY_MDC] {PHY_MDIO}

#PHY (2.5MHz)
set_output_delay  10 -clock clock_2_5MHz -reference_pin [get_ports PHY_MDC] {PHY_MDIO}

#**************************************************************
# Set Output Delay
#**************************************************************

# If setup and hold delays are equal then only need to specify once without max or min 

#122.88MHz clock for Tx DAC 
set_output_delay 0.8 -clock _122MHz {DACD[*]} -add_delay

# Attenuators - min is referenced to falling edge of clock 
set_output_delay  10  -clock data_clk { ATTN_DATA* ATTN_LE* MICBIAS_ENABLE MICBIAS_SELECT MIC_SIG_SELECT PTT_SELECT } -add_delay
set_output_delay  10  -clock data_clk { ATTN_DATA* ATTN_LE* MICBIAS_ENABLE MICBIAS_SELECT MIC_SIG_SELECT PTT_SELECT } -clock_fall -add_delay

#TLV320 SPI  
set_output_delay  20 -clock data_clk { MOSI nCS} -add_delay

#TLV320 Data out 
set_output_delay  10 -clock CBCLK {CDIN CMODE} -add_delay

#Alex  uses CBCLK/4
set_output_delay  10 -clock data_clk2 { SPI_SDO J15_5 J15_6} -add_delay

#EEPROM (2.5MHz)
set_output_delay  40 -clock clock_2_5MHz {SCK SI CS} -add_delay

#ADC78H90 
set_output_delay  10 -clock data_clk2 {ADCMOSI nADCCS} -add_delay

#************************************************************** 
# Set Input Delay
#**************************************************************

# If setup and hold delays are equal then only need to specify once without max or min 

# data from LTC2208 +/- 2nS setup and hold 
set_input_delay -add_delay  -clock [get_clocks {virt_122MHz}]  2.000 [get_ports {INA[*]}]
set_input_delay -add_delay  -clock [get_clocks {virt_122MHz}]  2.000 [get_ports {INA_2[*]}]

#TLV320 Data in +/- 20nS setup and hold
set_input_delay  20  -clock virt_CBCLK  {CDOUT} -add_delay

#EEPROM Data in +/- 40nS setup and hold
set_input_delay  40  -clock clock_2_5MHz {SO} -add_delay 

#PHY PHY_MDIO Data in +/- 10nS setup and hold
set_input_delay  10  -clock clock_2_5MHz -reference_pin [get_ports PHY_MDC] {PHY_MDIO} -add_delay

#ADC78H90 Data in +/- 10nS setup and hold
set_input_delay  10  -clock data_clk2 {ADCMISO} -add_delay


#**************************************************************
# Set Maximum Delay (for setup or recovery; low-level, over-riding timing adjustments)
#************************************************************** 
set_max_delay -from clock_125MHz -to clock_90_125MHz 11
set_max_delay -from clock_125MHz -to clock_125MHz 19
set_max_delay -from _122_90 -to _122MHz 18
set_max_delay -from _122_90 -to LTC2208_122MHz 10
set_max_delay -from LTC2208_122MHz -to LTC2208_122MHz 18
set_max_delay -from CLRCLK -to LTC2208_122MHz 14
set_max_delay -from CMCLK -to _122_90 4
set_max_delay -from CMCLK -to LTC2208_122MHz 11
set_max_delay -from phy_rx_clk -to phy_rx_clk 9

#**************************************************************
# Set Minimum Delay (for hold or removal; low-level, over-riding timing adjustments)
#**************************************************************
set_min_delay -from CLRCLK -to CBCLK -4


#**************************************************************
# Set Multicycle Path
#************************************************************** 

set_multicycle_path -from [get_keepers {network:network_inst|dhcp:dhcp_inst|length[*]}] -to [get_keepers {network:network_inst|ip_send:ip_send_inst|shift_reg[*]}] -setup -start 3
set_multicycle_path -from [get_keepers {network:network_inst|dhcp:dhcp_inst|length[*]}] -to [get_keepers {network:network_inst|ip_send:ip_send_inst|shift_reg[*]}] -hold -start 2

set_multicycle_path -from [get_keepers {network:network_inst|tx_protocol*}] -to [get_keepers {network:network_inst|ip_send:ip_send_inst|shift_reg[*]}] -setup -start 3
set_multicycle_path -from [get_keepers {network:network_inst|tx_protocol*}] -to [get_keepers {network:network_inst|ip_send:ip_send_inst|shift_reg[*]}] -hold -start 2

set_multicycle_path -from [get_keepers {network:network_inst|arp:arp_inst|tx_byte_no[*]}] -to [get_keepers {network:network_inst|mac_send:mac_send_inst|shift_reg[*]}] -setup -start 2
set_multicycle_path -from [get_keepers {network:network_inst|arp:arp_inst|tx_byte_no[*]}] -to [get_keepers {network:network_inst|mac_send:mac_send_inst|shift_reg[*]}] -hold -start 1

set_multicycle_path -from [get_keepers {sdr_send:sdr_send_inst|udp_tx_length[*]}] -to [get_keepers {network:network_inst|ip_send:ip_send_inst|shift_reg[*]}] -setup -start 3
set_multicycle_path -from [get_keepers {sdr_send:sdr_send_inst|udp_tx_length[*]}] -to [get_keepers {network:network_inst|ip_send:ip_send_inst|shift_reg[*]}] -hold -start 2

#**************************************************************
# Set False Paths
#**************************************************************
 
set_false_path -from [get_clocks {LTC2208_122MHz}] -to [get_clocks {LTC2208_122MHz_2}]
set_false_path -from [get_ports {PHY_RESET_N}]

# Set false path to generated clocks that feed output pins
set_false_path -to [get_ports {CMCLK CBCLK CLRCIN CLRCOUT ATTN_CLK* SSCK ADCCLK SPI_SCK PHY_MDC PHY_TX_CLOCK CLOCK_25MHZ}]

# 'get_keepers' denotes either ports or registers
# don't need fast paths to the LEDs and adhoc outputs so set false paths so Timing will be ignored
set_false_path -to [get_keepers { Status_LED DEBUG_LED* DITH* FPGA_PTT  NCONFIG  RAND*  USEROUT* FPGA_PLL DAC_ALC DRIVER_PA_EN CTRL_TRSW IO1 TX_ATTEN* atu_ctrl}]

#don't need fast paths from the following inputs
set_false_path -from [get_keepers  {ANT_TUNE IO2 IO4 IO5 IO6 IO8 KEY_DASH KEY_DOT OVERFLOW* PTT MODE2 TX_ATTEN_SELECT SW1}]

#these registers are set long before they are used
set_false_path -from [get_registers {network:network_inst|eeprom:eeprom_inst|mac[*]}] -to [all_registers]
set_false_path -from [get_registers {network:network_inst|eeprom:eeprom_inst|ip[*]}] -to [all_registers]
set_false_path -from [get_registers {network:network_inst|local_ip[*]}] -to [all_registers]
set_false_path -from [get_registers {network:network_inst|arp:arp_inst|destination_mac[*]}] -to [all_registers]
