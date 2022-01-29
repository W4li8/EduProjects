# TCL File Generated by Component Editor 18.1
# Fri May 21 22:26:40 CEST 2021
# DO NOT MODIFY


# 
# spi_adapter "spi_adapter" v1.0
#  2021.05.21.22:26:40
# 
# 

# 
# request TCL package from ACDS 16.1
# 
package require -exact qsys 16.1


# 
# module spi_adapter
# 
set_module_property DESCRIPTION ""
set_module_property NAME spi_adapter
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR ""
set_module_property DISPLAY_NAME spi_adapter
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL spi_master
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file spi_adapter.vhd VHDL PATH vhd/spi_adapter.vhd TOP_LEVEL_FILE


# 
# parameters
# 
add_parameter slaves INTEGER 1
set_parameter_property slaves DEFAULT_VALUE 1
set_parameter_property slaves DISPLAY_NAME slaves
set_parameter_property slaves TYPE INTEGER
set_parameter_property slaves UNITS None
set_parameter_property slaves ALLOWED_RANGES -2147483648:2147483647
set_parameter_property slaves HDL_PARAMETER true
add_parameter d_width INTEGER 8
set_parameter_property d_width DEFAULT_VALUE 8
set_parameter_property d_width DISPLAY_NAME d_width
set_parameter_property d_width TYPE INTEGER
set_parameter_property d_width UNITS None
set_parameter_property d_width ALLOWED_RANGES -2147483648:2147483647
set_parameter_property d_width HDL_PARAMETER true
add_parameter clk_div INTEGER 3
set_parameter_property clk_div DEFAULT_VALUE 3
set_parameter_property clk_div DISPLAY_NAME clk_div
set_parameter_property clk_div TYPE INTEGER
set_parameter_property clk_div UNITS None
set_parameter_property clk_div ALLOWED_RANGES -2147483648:2147483647
set_parameter_property clk_div HDL_PARAMETER true
add_parameter addr INTEGER 0
set_parameter_property addr DEFAULT_VALUE 0
set_parameter_property addr DISPLAY_NAME addr
set_parameter_property addr TYPE INTEGER
set_parameter_property addr UNITS None
set_parameter_property addr ALLOWED_RANGES -2147483648:2147483647
set_parameter_property addr HDL_PARAMETER true
add_parameter cpol STD_LOGIC 0
set_parameter_property cpol DEFAULT_VALUE 0
set_parameter_property cpol DISPLAY_NAME cpol
set_parameter_property cpol TYPE STD_LOGIC
set_parameter_property cpol UNITS None
set_parameter_property cpol ALLOWED_RANGES 0:1
set_parameter_property cpol HDL_PARAMETER true
add_parameter cpha STD_LOGIC 0
set_parameter_property cpha DEFAULT_VALUE 0
set_parameter_property cpha DISPLAY_NAME cpha
set_parameter_property cpha TYPE STD_LOGIC
set_parameter_property cpha UNITS None
set_parameter_property cpha ALLOWED_RANGES 0:1
set_parameter_property cpha HDL_PARAMETER true
add_parameter cont STD_LOGIC 0
set_parameter_property cont DEFAULT_VALUE 0
set_parameter_property cont DISPLAY_NAME cont
set_parameter_property cont TYPE STD_LOGIC
set_parameter_property cont UNITS None
set_parameter_property cont ALLOWED_RANGES 0:1
set_parameter_property cont HDL_PARAMETER true


# 
# display items
# 


# 
# connection point reset
# 
add_interface reset reset end
set_interface_property reset associatedClock clock
set_interface_property reset synchronousEdges DEASSERT
set_interface_property reset ENABLED true
set_interface_property reset EXPORT_OF ""
set_interface_property reset PORT_NAME_MAP ""
set_interface_property reset CMSIS_SVD_VARIABLES ""
set_interface_property reset SVD_ADDRESS_GROUP ""

add_interface_port reset reset_n reset_n Input 1


# 
# connection point avalon_slave_0
# 
add_interface avalon_slave_0 avalon end
set_interface_property avalon_slave_0 addressUnits WORDS
set_interface_property avalon_slave_0 associatedClock clock
set_interface_property avalon_slave_0 associatedReset reset
set_interface_property avalon_slave_0 bitsPerSymbol 8
set_interface_property avalon_slave_0 burstOnBurstBoundariesOnly false
set_interface_property avalon_slave_0 burstcountUnits WORDS
set_interface_property avalon_slave_0 explicitAddressSpan 0
set_interface_property avalon_slave_0 holdTime 0
set_interface_property avalon_slave_0 linewrapBursts false
set_interface_property avalon_slave_0 maximumPendingReadTransactions 0
set_interface_property avalon_slave_0 maximumPendingWriteTransactions 0
set_interface_property avalon_slave_0 readLatency 0
set_interface_property avalon_slave_0 readWaitTime 1
set_interface_property avalon_slave_0 setupTime 0
set_interface_property avalon_slave_0 timingUnits Cycles
set_interface_property avalon_slave_0 writeWaitTime 0
set_interface_property avalon_slave_0 ENABLED true
set_interface_property avalon_slave_0 EXPORT_OF ""
set_interface_property avalon_slave_0 PORT_NAME_MAP ""
set_interface_property avalon_slave_0 CMSIS_SVD_VARIABLES ""
set_interface_property avalon_slave_0 SVD_ADDRESS_GROUP ""

add_interface_port avalon_slave_0 enable write Input 1
add_interface_port avalon_slave_0 tx_data writedata Input d_width
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isFlash 0
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isPrintableDevice 0


# 
# connection point clock
# 
add_interface clock clock end
set_interface_property clock clockRate 50000000
set_interface_property clock ENABLED true
set_interface_property clock EXPORT_OF ""
set_interface_property clock PORT_NAME_MAP ""
set_interface_property clock CMSIS_SVD_VARIABLES ""
set_interface_property clock SVD_ADDRESS_GROUP ""

add_interface_port clock clock clk Input 1


# 
# connection point disregard
# 
add_interface disregard conduit end
set_interface_property disregard associatedClock ""
set_interface_property disregard associatedReset ""
set_interface_property disregard ENABLED true
set_interface_property disregard EXPORT_OF ""
set_interface_property disregard PORT_NAME_MAP ""
set_interface_property disregard CMSIS_SVD_VARIABLES ""
set_interface_property disregard SVD_ADDRESS_GROUP ""

add_interface_port disregard busy idk_busy Output 1
add_interface_port disregard rx_data readdata Output d_width


# 
# connection point led_matrix
# 
add_interface led_matrix conduit end
set_interface_property led_matrix associatedClock ""
set_interface_property led_matrix associatedReset ""
set_interface_property led_matrix ENABLED true
set_interface_property led_matrix EXPORT_OF ""
set_interface_property led_matrix PORT_NAME_MAP ""
set_interface_property led_matrix CMSIS_SVD_VARIABLES ""
set_interface_property led_matrix SVD_ADDRESS_GROUP ""

add_interface_port led_matrix mosi din Output 1
add_interface_port led_matrix sclk clk Output 1
add_interface_port led_matrix ss_n cs Output slaves
add_interface_port led_matrix miso notreq Input 1

