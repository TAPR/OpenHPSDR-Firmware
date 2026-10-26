## Generated SDC file "Angelia.out.sdc"

## Copyright (C) 1991-2013 Altera Corporation
## Your use of Altera Corporation's design tools, logic functions 
## and other software and tools, and its AMPP partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Altera Program License 
## Subscription Agreement, Altera MegaCore Function License 
## Agreement, or other applicable license agreement, including, 
## without limitation, that your use is for the sole purpose of 
## programming logic devices manufactured by Altera and sold by 
## Altera or its authorized distributors.  Please refer to the 
## applicable agreement for further details.


## VENDOR  "Altera"
## PROGRAM "Quartus II"
## VERSION "Version 13.1.0 Build 162 10/23/2013 SJ Web Edition"

## DATE    "Thu Mar 17 19:31:39 2016"

##
## DEVICE  "EP4CE115F29C8"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {_122MHz} -period 8.138 -waveform { 0.000 4.069 } [get_ports {_122MHz}]
create_clock -name {virt_122MHz} -period 8.138 -waveform { 0.000 4.069 } 
create_clock -name {virt_CBCLK} -period 325.520 -waveform { 0.000 162.760 } 


#**************************************************************
# Create Generated Clock
#**************************************************************

create_generated_clock -name {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[0]} -source [get_pins {PLL_IF_inst|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50.000 -multiply_by 1 -divide_by 10 -master_clock {_122MHz} [get_pins {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[0]}] 
create_generated_clock -name {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[1]} -source [get_pins {PLL_IF_inst|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50.000 -multiply_by 1 -divide_by 40 -phase 180.000 -master_clock {_122MHz} [get_pins {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[1]}] 
create_generated_clock -name {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[2]} -source [get_pins {PLL_IF_inst|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50.000 -multiply_by 1 -divide_by 2560 -master_clock {_122MHz} [get_pins {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[2]}] 
create_generated_clock -name {PLL_inst|altpll_component|auto_generated|pll1|clk[0]} -source [get_pins {PLL_inst|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50.000 -multiply_by 1 -divide_by 1536 -master_clock {_122MHz} [get_pins {PLL_inst|altpll_component|auto_generated|pll1|clk[0]}] 
create_generated_clock -name {PLL_inst|altpll_component|auto_generated|pll1|clk[1]} -source [get_pins {PLL_inst|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50.000 -multiply_by 1 -phase 90.000 -master_clock {_122MHz} [get_pins {PLL_inst|altpll_component|auto_generated|pll1|clk[1]}] 
create_generated_clock -name {CBCLK} -source [get_pins {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[1]}] -master_clock {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[1]} [get_ports {CBCLK}] 
create_generated_clock -name {CMCLK} -source [get_pins {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[0]}] -master_clock {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[0]} [get_ports {CMCLK}] 
create_generated_clock -name {CLRCIN} -source [get_pins {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[2]}] -master_clock {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[2]} [get_ports {CLRCIN}] 
create_generated_clock -name {CLRCOUT} -source [get_pins {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[2]}] -master_clock {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[2]} [get_ports {CLRCOUT}] 


#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************

set_clock_uncertainty -rise_from [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[2]}] -rise_to [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[2]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[2]}] -fall_to [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[2]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[2]}] -rise_to [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[1]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[2]}] -fall_to [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[1]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[2]}] -rise_to [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[2]}] -fall_to [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[2]}] -rise_to [get_clocks {_122MHz}] -setup 0.100  
set_clock_uncertainty -rise_from [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[2]}] -rise_to [get_clocks {_122MHz}] -hold 0.070  
set_clock_uncertainty -rise_from [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[2]}] -fall_to [get_clocks {_122MHz}] -setup 0.100  
set_clock_uncertainty -rise_from [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[2]}] -fall_to [get_clocks {_122MHz}] -hold 0.070  
set_clock_uncertainty -fall_from [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[2]}] -rise_to [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[2]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[2]}] -fall_to [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[2]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[2]}] -rise_to [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[1]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[2]}] -fall_to [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[1]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[2]}] -rise_to [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[2]}] -fall_to [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[2]}] -rise_to [get_clocks {_122MHz}] -setup 0.100  
set_clock_uncertainty -fall_from [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[2]}] -rise_to [get_clocks {_122MHz}] -hold 0.070  
set_clock_uncertainty -fall_from [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[2]}] -fall_to [get_clocks {_122MHz}] -setup 0.100  
set_clock_uncertainty -fall_from [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[2]}] -fall_to [get_clocks {_122MHz}] -hold 0.070  
set_clock_uncertainty -rise_from [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[1]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[1]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[1]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[1]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[2]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[2]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {_122MHz}] -setup 0.100  
set_clock_uncertainty -rise_from [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {_122MHz}] -hold 0.070  
set_clock_uncertainty -rise_from [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {_122MHz}] -setup 0.100  
set_clock_uncertainty -rise_from [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {_122MHz}] -hold 0.070  
set_clock_uncertainty -fall_from [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[2]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[2]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {_122MHz}] -setup 0.100  
set_clock_uncertainty -fall_from [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {_122MHz}] -hold 0.070  
set_clock_uncertainty -fall_from [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {_122MHz}] -setup 0.100  
set_clock_uncertainty -fall_from [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {_122MHz}] -hold 0.070  
set_clock_uncertainty -rise_from [get_clocks {_122MHz}] -rise_to [get_clocks {_122MHz}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {_122MHz}] -fall_to [get_clocks {_122MHz}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {_122MHz}] -rise_to [get_clocks {_122MHz}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {_122MHz}] -fall_to [get_clocks {_122MHz}]  0.020  


#**************************************************************
# Set Input Delay
#**************************************************************

set_input_delay -add_delay  -clock [get_clocks {virt_CBCLK}]  20.000 [get_ports {CDOUT}]


#**************************************************************
# Set Output Delay
#**************************************************************

set_output_delay -add_delay  -clock [get_clocks {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[1]}]  10.000 [get_ports {CDIN}]


#**************************************************************
# Set Clock Groups
#**************************************************************

set_clock_groups -asynchronous -group [get_clocks {  _122MHz  PLL_IF_inst|altpll_component|auto_generated|pll1|clk[0]  PLL_IF_inst|altpll_component|auto_generated|pll1|clk[1]  PLL_IF_inst|altpll_component|auto_generated|pll1|clk[2]  CBCLK  CMCLK  CLRCIN  CLRCOUT  }] 
set_clock_groups -asynchronous -group [get_clocks {  _122MHz  PLL_IF_inst|altpll_component|auto_generated|pll1|clk[0]  PLL_IF_inst|altpll_component|auto_generated|pll1|clk[1]  PLL_IF_inst|altpll_component|auto_generated|pll1|clk[2]  CBCLK  CMCLK  CLRCIN  CLRCOUT  }] 


#**************************************************************
# Set False Path
#**************************************************************

set_false_path -from [get_keepers {*rdptr_g*}] -to [get_keepers {*ws_dgrp|dffpipe_8f9:dffpipe8|dffe9a*}]
set_false_path -from [get_keepers {*delayed_wrptr_g*}] -to [get_keepers {*rs_dgwp|dffpipe_7f9:dffpipe5|dffe6a*}]
set_false_path -from [get_keepers {*rdptr_g*}] -to [get_keepers {*ws_dgrp|dffpipe_6f9:dffpipe9|dffe10a*}]
set_false_path -from [get_keepers {*delayed_wrptr_g*}] -to [get_keepers {*rs_dgwp|dffpipe_5f9:dffpipe6|dffe7a*}]
set_false_path -from [get_keepers {*rdptr_g*}] -to [get_keepers {*ws_dgrp|dffpipe_ue9:dffpipe13|dffe14a*}]
set_false_path -from [get_keepers {*delayed_wrptr_g*}] -to [get_keepers {*rs_dgwp|dffpipe_te9:dffpipe10|dffe11a*}]
set_false_path -from [get_keepers {*rdptr_g*}] -to [get_keepers {*ws_dgrp|dffpipe_se9:dffpipe16|dffe17a*}]
set_false_path -from [get_keepers {*delayed_wrptr_g*}] -to [get_keepers {*rs_dgwp|dffpipe_re9:dffpipe13|dffe14a*}]
set_false_path -from [get_keepers {*rdptr_g*}] -to [get_keepers {*ws_dgrp|dffpipe_4f9:dffpipe16|dffe17a*}]
set_false_path -from [get_keepers {*delayed_wrptr_g*}] -to [get_keepers {*rs_dgwp|dffpipe_3f9:dffpipe13|dffe14a*}]
set_false_path -from [get_keepers {*rdptr_g*}] -to [get_keepers {*ws_dgrp|dffpipe_1f9:dffpipe18|dffe19a*}]
set_false_path -from [get_keepers {*delayed_wrptr_g*}] -to [get_keepers {*rs_dgwp|dffpipe_ve9:dffpipe14|dffe15a*}]
set_false_path -to [get_ports {CMCLK CBCLK CLRCIN CLRCOUT}]


#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

