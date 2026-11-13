# Example.sdc
# 

#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3


#**************************************************************
# Create Clock (base clocks, external to the FPGA)
#**************************************************************

create_clock -name _122MHz 				-period 8.138 	[get_ports {_122MHz}]

#virtual base clock on required input
create_clock -name virt_122MHz 			-period 8.138
create_clock -name virt_CBCLK				-period 325.52


derive_pll_clocks

derive_clock_uncertainty

#assign more familiar names!
set CMCLK  PLL_IF_inst|altpll_component|auto_generated|pll1|clk[0]
set CBCLK  PLL_IF_inst|altpll_component|auto_generated|pll1|clk[1]
set CLRCLK PLL_IF_inst|altpll_component|auto_generated|pll1|clk[2]

#**************************************************************
# Create Generated Clock (internal to the FPGA)
#**************************************************************
# NOTE: Whilst derive_pll_clocks constrains PLL clocks if these are connected to an FPGA output pin then a generated
# clock needs to be attached to the pin and a false path set to it

# PLL generated clocks feeding output pins 
create_generated_clock -name CBCLK   -source $CBCLK  [get_ports CBCLK]
create_generated_clock -name CMCLK   -source $CMCLK  [get_ports CMCLK]
create_generated_clock -name CLRCIN  -source $CLRCLK [get_ports CLRCIN]
create_generated_clock -name CLRCOUT -source $CLRCLK [get_ports CLRCOUT]


#************************************************************** 
# Set Input Delay
#**************************************************************

# If setup and hold delays are equal then only need to specify once without max or min 

#TLV320 Data in +/- 20nS setup and hold
set_input_delay  20  -clock virt_CBCLK  [get_ports {CDOUT}]


#**************************************************************
# Set Output Delay
#**************************************************************

# If setup and hold delays are equal then only need to specify once without max or min 

#TLV320 Data out 
set_output_delay  10 -clock $CBCLK [get_ports {CDIN}]


#**************************************************************
# Set Clock Groups
#**************************************************************
set_clock_groups -asynchronous  -group { \
					_122MHz \
					PLL_IF_inst|altpll_component|auto_generated|pll1|clk[0] \
					PLL_IF_inst|altpll_component|auto_generated|pll1|clk[1] \
					PLL_IF_inst|altpll_component|auto_generated|pll1|clk[2] \
					CBCLK \
					CMCLK \
					CLRCIN \
					CLRCOUT \
				       }

		
#**************************************************************
# Set Maximum Delay
#************************************************************** 


#**************************************************************
# Set Minimum Delay
#**************************************************************


#**************************************************************
# Set False Paths
#**************************************************************

# Set false path to generated clocks that feed output pins
set_false_path -to [get_ports {CMCLK CBCLK CLRCIN CLRCOUT}]




