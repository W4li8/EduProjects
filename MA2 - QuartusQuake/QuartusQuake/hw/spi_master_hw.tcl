# TCL File Generated by Component Editor 18.1
# Fri May 21 18:47:10 CEST 2021
# DO NOT MODIFY


# 
# spi_master "spi_master" v2.0
#  2021.05.21.18:47:10
# 
# 

# 
# request TCL package from ACDS 16.1
# 
package require -exact qsys 16.1


# 
# module spi_master
# 
set_module_property DESCRIPTION ""
set_module_property NAME spi_master
set_module_property VERSION 2.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR ""
set_module_property DISPLAY_NAME spi_master
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
add_fileset_file spi_master.vhd VHDL PATH vhd/spi_master.vhd TOP_LEVEL_FILE


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
# connection point conduit_end
# 
add_interface conduit_end conduit end
set_interface_property conduit_end associatedClock clock
set_interface_property conduit_end associatedReset ""
set_interface_property conduit_end ENABLED true
set_interface_property conduit_end EXPORT_OF ""
set_interface_property conduit_end PORT_NAME_MAP ""
set_interface_property conduit_end CMSIS_SVD_VARIABLES ""
set_interface_property conduit_end SVD_ADDRESS_GROUP ""

add_interface_port conduit_end mosi din Output 1
add_interface_port conduit_end ss_n cs Output slaves
add_interface_port conduit_end sclk clk Output 1


# 
# connection point clock
# 
add_interface clock clock end
set_interface_property clock clockRate 0
set_interface_property clock ENABLED true
set_interface_property clock EXPORT_OF ""
set_interface_property clock PORT_NAME_MAP ""
set_interface_property clock CMSIS_SVD_VARIABLES ""
set_interface_property clock SVD_ADDRESS_GROUP ""

add_interface_port clock clock clk Input 1


# 
# connection point avalon_slave
# 
add_interface avalon_slave avalon end
set_interface_property avalon_slave addressUnits WORDS
set_interface_property avalon_slave associatedClock clock
set_interface_property avalon_slave associatedReset reset
set_interface_property avalon_slave bitsPerSymbol 8
set_interface_property avalon_slave burstOnBurstBoundariesOnly false
set_interface_property avalon_slave burstcountUnits WORDS
set_interface_property avalon_slave explicitAddressSpan 0
set_interface_property avalon_slave holdTime 0
set_interface_property avalon_slave linewrapBursts false
set_interface_property avalon_slave maximumPendingReadTransactions 0
set_interface_property avalon_slave maximumPendingWriteTransactions 0
set_interface_property avalon_slave readLatency 0
set_interface_property avalon_slave readWaitTime 1
set_interface_property avalon_slave setupTime 0
set_interface_property avalon_slave timingUnits Cycles
set_interface_property avalon_slave writeWaitTime 0
set_interface_property avalon_slave ENABLED true
set_interface_property avalon_slave EXPORT_OF ""
set_interface_property avalon_slave PORT_NAME_MAP ""
set_interface_property avalon_slave CMSIS_SVD_VARIABLES ""
set_interface_property avalon_slave SVD_ADDRESS_GROUP ""

add_interface_port avalon_slave enable write Input 1
add_interface_port avalon_slave tx_data writedata Input d_width
set_interface_assignment avalon_slave embeddedsw.configuration.isFlash 0
set_interface_assignment avalon_slave embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment avalon_slave embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment avalon_slave embeddedsw.configuration.isPrintableDevice 0

