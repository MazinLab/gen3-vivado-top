
################################################################
# This is a generated script based on design: top_basics
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2020.1
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source top_basics_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xczu28dr-ffvg1517-2-e
   set_property BOARD_PART xilinx.com:zcu111:part0:1.2 [current_project]
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name top_basics

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_gid_msg -ssname BD::TCL -id 2001 -severity "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_gid_msg -ssname BD::TCL -id 2002 -severity "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

  # Add USER_COMMENTS on $design_name
  set_property USER_COMMENTS.comment_0 "There Seem to be two options for clocking this DMA:
1 The streams clock, removing the closk crossings in the interconnect.
2 The DDR clock, necessitating clock crossings in the interconnect but slowing down this core
3 Probably no good would be the low speed clock." [get_bd_designs $design_name]
  set_property USER_COMMENTS.comment_1 "I'm thinking that the processr system reset interconnect should be used for the interconnects and stream infrastructure.
The documentation says that the number of resets out may be increased to help with fanout and routing
The difference seems to be that the PSR sequences the interconnect and periph resets" [get_bd_designs $design_name]
  set_property USER_COMMENTS.comment_2 "I suspect that the addition of the AXI-LITE clock on each HLS core adds complexity that could best be concentrated in the primary periphrial interconnect" [get_bd_designs $design_name]
  set_property USER_COMMENTS.comment_3 "I suspect that the addition of the AXI-LITE clock on each HLS core adds complexity that could best be concentrated in the primary periphrial interconnect" [get_bd_designs $design_name]

common::send_gid_msg -ssname BD::TCL -id 2005 -severity "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_gid_msg -ssname BD::TCL -id 2006 -severity "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
MazinLab:mkidgen3:adc_to_opfb:1.1\
MazinLab:mkidgen3:fir_to_fft:1.11\
xilinx.com:ip:xlconstant:1.1\
xilinx.com:ip:axi_fifo_mm_s:4.2\
xilinx.com:ip:axis_broadcaster:1.1\
xilinx.com:ip:axis_combiner:1.1\
MazinLab:mkidgen3:lowpass_to_phase:1.0\
xilinx.com:ip:fir_compiler:7.2\
MazinLab:mkidgen3:phasematch_fir_cfg:1.0\
xilinx.com:ip:xlconcat:2.1\
MazinLab:mkidgen3:bin_to_res:1.0\
MazinLab:mkidgen3:resonator_dds:1.0\
MazinLab:mkidgen3:pkg_fft_output:0.2\
MazinLab:mkidgen3:ssrfft_16x4096_axis:1.0\
xilinx.com:ip:axis_register_slice:1.1\
MazinLab:mkidgen3:opfb_fir_cfg:0.1\
"

   set list_ips_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

if { $bCheckIPsPassed != 1 } {
  common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################


# Hierarchical cell: register_slice
proc create_hier_cell_register_slice { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_register_slice() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS2

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS3

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS4

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS5

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS6

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS7

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS8

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS9

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS10

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS11

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS12

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS13

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS14

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS15

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS2

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS3

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS4

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS5

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS6

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS7

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS8

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS9

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS10

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS11

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS12

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS13

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS14

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS15


  # Create pins
  create_bd_pin -dir I -type clk aclk
  create_bd_pin -dir I -type rst aresetn

  # Create interface connections
  connect_bd_intf_net -intf_net S_AXIS10_1 [get_bd_intf_pins M_AXIS10] [get_bd_intf_pins S_AXIS10]
  connect_bd_intf_net -intf_net S_AXIS11_1 [get_bd_intf_pins M_AXIS11] [get_bd_intf_pins S_AXIS11]
  connect_bd_intf_net -intf_net S_AXIS12_1 [get_bd_intf_pins M_AXIS12] [get_bd_intf_pins S_AXIS12]
  connect_bd_intf_net -intf_net S_AXIS13_1 [get_bd_intf_pins M_AXIS13] [get_bd_intf_pins S_AXIS13]
  connect_bd_intf_net -intf_net S_AXIS14_1 [get_bd_intf_pins M_AXIS14] [get_bd_intf_pins S_AXIS14]
  connect_bd_intf_net -intf_net S_AXIS15_1 [get_bd_intf_pins M_AXIS15] [get_bd_intf_pins S_AXIS15]
  connect_bd_intf_net -intf_net S_AXIS1_1 [get_bd_intf_pins M_AXIS1] [get_bd_intf_pins S_AXIS1]
  connect_bd_intf_net -intf_net S_AXIS2_1 [get_bd_intf_pins M_AXIS2] [get_bd_intf_pins S_AXIS2]
  connect_bd_intf_net -intf_net S_AXIS3_1 [get_bd_intf_pins M_AXIS3] [get_bd_intf_pins S_AXIS3]
  connect_bd_intf_net -intf_net S_AXIS4_1 [get_bd_intf_pins M_AXIS4] [get_bd_intf_pins S_AXIS4]
  connect_bd_intf_net -intf_net S_AXIS5_1 [get_bd_intf_pins M_AXIS5] [get_bd_intf_pins S_AXIS5]
  connect_bd_intf_net -intf_net S_AXIS6_1 [get_bd_intf_pins M_AXIS6] [get_bd_intf_pins S_AXIS6]
  connect_bd_intf_net -intf_net S_AXIS7_1 [get_bd_intf_pins M_AXIS7] [get_bd_intf_pins S_AXIS7]
  connect_bd_intf_net -intf_net S_AXIS8_1 [get_bd_intf_pins M_AXIS8] [get_bd_intf_pins S_AXIS8]
  connect_bd_intf_net -intf_net S_AXIS9_1 [get_bd_intf_pins M_AXIS9] [get_bd_intf_pins S_AXIS9]
  connect_bd_intf_net -intf_net S_AXIS_1 [get_bd_intf_pins M_AXIS] [get_bd_intf_pins S_AXIS]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: filters
proc create_hier_cell_filters { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_filters() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS_DATA

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS_DATA1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS_DATA2

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS_DATA3

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS_DATA4

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS_DATA5

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS_DATA6

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS_DATA7

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS_DATA8

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS_DATA9

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS_DATA10

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS_DATA11

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS_DATA12

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS_DATA13

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS_DATA14

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS_DATA15

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS_DATA

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS_DATA1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS_DATA2

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS_DATA3

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS_DATA4

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS_DATA5

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS_DATA6

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS_DATA7

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS_DATA8

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS_DATA9

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS_DATA10

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS_DATA11

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS_DATA12

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS_DATA13

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS_DATA14

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS_DATA15


  # Create pins
  create_bd_pin -dir I -type clk aclk
  create_bd_pin -dir I -type rst aresetn

  # Create instance: axis_broadcaster_0, and set properties
  set axis_broadcaster_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_broadcaster:1.1 axis_broadcaster_0 ]
  set_property -dict [ list \
   CONFIG.M02_TDATA_REMAP {tdata[7:0]} \
   CONFIG.M03_TDATA_REMAP {tdata[7:0]} \
   CONFIG.M04_TDATA_REMAP {tdata[7:0]} \
   CONFIG.M05_TDATA_REMAP {tdata[7:0]} \
   CONFIG.M06_TDATA_REMAP {tdata[7:0]} \
   CONFIG.M07_TDATA_REMAP {tdata[7:0]} \
   CONFIG.M08_TDATA_REMAP {tdata[7:0]} \
   CONFIG.M09_TDATA_REMAP {tdata[7:0]} \
   CONFIG.M10_TDATA_REMAP {tdata[7:0]} \
   CONFIG.M11_TDATA_REMAP {tdata[7:0]} \
   CONFIG.M12_TDATA_REMAP {tdata[7:0]} \
   CONFIG.M13_TDATA_REMAP {tdata[7:0]} \
   CONFIG.M14_TDATA_REMAP {tdata[7:0]} \
   CONFIG.M15_TDATA_REMAP {tdata[7:0]} \
   CONFIG.NUM_MI {16} \
 ] $axis_broadcaster_0

  # Create instance: axis_register_slice_0, and set properties
  set axis_register_slice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axis_register_slice_0 ]

  # Create instance: fir_compiler_0, and set properties
  set fir_compiler_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:fir_compiler:7.2 fir_compiler_0 ]
  set_property -dict [ list \
   CONFIG.BestPrecision {true} \
   CONFIG.Clock_Frequency {300.0} \
   CONFIG.CoefficientSource {COE_File} \
   CONFIG.Coefficient_Buffer_Type {Automatic} \
   CONFIG.Coefficient_File {../../../../../../../data/lane0.coe} \
   CONFIG.Coefficient_Fractional_Bits {26} \
   CONFIG.Coefficient_Sets {256} \
   CONFIG.Coefficient_Sign {Signed} \
   CONFIG.Coefficient_Structure {Inferred} \
   CONFIG.Coefficient_Width {16} \
   CONFIG.ColumnConfig {8} \
   CONFIG.DATA_Has_TLAST {Vector_Framing} \
   CONFIG.Data_Buffer_Type {Block} \
   CONFIG.Data_Fractional_Bits {15} \
   CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} \
   CONFIG.Filter_Selection {1} \
   CONFIG.Has_ARESETn {false} \
   CONFIG.M_DATA_Has_TUSER {Not_Required} \
   CONFIG.Number_Channels {512} \
   CONFIG.Number_Paths {2} \
   CONFIG.Output_Rounding_Mode {Truncate_LSBs} \
   CONFIG.Output_Width {16} \
   CONFIG.Quantization {Quantize_Only} \
   CONFIG.RateSpecification {Input_Sample_Period} \
   CONFIG.Reset_Data_Vector {true} \
   CONFIG.S_CONFIG_Method {By_Channel} \
   CONFIG.S_DATA_Has_FIFO {false} \
   CONFIG.S_DATA_Has_TUSER {Not_Required} \
   CONFIG.SamplePeriod {1} \
   CONFIG.Sample_Frequency {0.001} \
   CONFIG.Select_Pattern {All} \
 ] $fir_compiler_0

  # Create instance: fir_compiler_1, and set properties
  set fir_compiler_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:fir_compiler:7.2 fir_compiler_1 ]
  set_property -dict [ list \
   CONFIG.BestPrecision {true} \
   CONFIG.Blank_Output {false} \
   CONFIG.Clock_Frequency {300.0} \
   CONFIG.CoefficientSource {COE_File} \
   CONFIG.Coefficient_Buffer_Type {Block} \
   CONFIG.Coefficient_File {../../../../../../../data/lane1.coe} \
   CONFIG.Coefficient_Fractional_Bits {26} \
   CONFIG.Coefficient_Sets {256} \
   CONFIG.Coefficient_Sign {Signed} \
   CONFIG.Coefficient_Structure {Inferred} \
   CONFIG.Coefficient_Width {16} \
   CONFIG.ColumnConfig {8} \
   CONFIG.DATA_Has_TLAST {Vector_Framing} \
   CONFIG.Data_Fractional_Bits {15} \
   CONFIG.Data_Width {16} \
   CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} \
   CONFIG.Filter_Selection {1} \
   CONFIG.Has_ARESETn {false} \
   CONFIG.M_DATA_Has_TUSER {Not_Required} \
   CONFIG.Number_Channels {512} \
   CONFIG.Number_Paths {2} \
   CONFIG.Output_Rounding_Mode {Truncate_LSBs} \
   CONFIG.Output_Width {16} \
   CONFIG.Quantization {Quantize_Only} \
   CONFIG.RateSpecification {Input_Sample_Period} \
   CONFIG.Reset_Data_Vector {true} \
   CONFIG.S_CONFIG_Method {By_Channel} \
   CONFIG.S_DATA_Has_FIFO {false} \
   CONFIG.S_DATA_Has_TUSER {Not_Required} \
   CONFIG.SamplePeriod {1} \
   CONFIG.Sample_Frequency {0.001} \
   CONFIG.Select_Pattern {All} \
 ] $fir_compiler_1

  # Create instance: fir_compiler_2, and set properties
  set fir_compiler_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:fir_compiler:7.2 fir_compiler_2 ]
  set_property -dict [ list \
   CONFIG.BestPrecision {true} \
   CONFIG.Blank_Output {false} \
   CONFIG.Clock_Frequency {300.0} \
   CONFIG.CoefficientSource {COE_File} \
   CONFIG.Coefficient_File {../../../../../../../data/lane2.coe} \
   CONFIG.Coefficient_Fractional_Bits {26} \
   CONFIG.Coefficient_Sets {256} \
   CONFIG.Coefficient_Sign {Signed} \
   CONFIG.Coefficient_Structure {Inferred} \
   CONFIG.Coefficient_Width {16} \
   CONFIG.ColumnConfig {8} \
   CONFIG.DATA_Has_TLAST {Vector_Framing} \
   CONFIG.Data_Fractional_Bits {15} \
   CONFIG.Data_Width {16} \
   CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} \
   CONFIG.Filter_Selection {1} \
   CONFIG.Has_ARESETn {false} \
   CONFIG.M_DATA_Has_TUSER {Not_Required} \
   CONFIG.Number_Channels {512} \
   CONFIG.Number_Paths {2} \
   CONFIG.Output_Rounding_Mode {Truncate_LSBs} \
   CONFIG.Output_Width {16} \
   CONFIG.Preference_For_Other_Storage {Block} \
   CONFIG.Quantization {Quantize_Only} \
   CONFIG.RateSpecification {Input_Sample_Period} \
   CONFIG.Reset_Data_Vector {true} \
   CONFIG.S_CONFIG_Method {By_Channel} \
   CONFIG.S_DATA_Has_FIFO {false} \
   CONFIG.S_DATA_Has_TUSER {Not_Required} \
   CONFIG.SamplePeriod {1} \
   CONFIG.Sample_Frequency {0.001} \
   CONFIG.Select_Pattern {All} \
 ] $fir_compiler_2

  # Create instance: fir_compiler_3, and set properties
  set fir_compiler_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:fir_compiler:7.2 fir_compiler_3 ]
  set_property -dict [ list \
   CONFIG.BestPrecision {true} \
   CONFIG.Blank_Output {false} \
   CONFIG.Clock_Frequency {300.0} \
   CONFIG.CoefficientSource {COE_File} \
   CONFIG.Coefficient_File {../../../../../../../data/lane3.coe} \
   CONFIG.Coefficient_Fractional_Bits {26} \
   CONFIG.Coefficient_Sets {256} \
   CONFIG.Coefficient_Sign {Signed} \
   CONFIG.Coefficient_Structure {Inferred} \
   CONFIG.Coefficient_Width {16} \
   CONFIG.ColumnConfig {8} \
   CONFIG.DATA_Has_TLAST {Vector_Framing} \
   CONFIG.Data_Fractional_Bits {15} \
   CONFIG.Data_Width {16} \
   CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} \
   CONFIG.Filter_Selection {1} \
   CONFIG.Has_ARESETn {false} \
   CONFIG.Input_Buffer_Type {Block} \
   CONFIG.M_DATA_Has_TUSER {Not_Required} \
   CONFIG.Number_Channels {512} \
   CONFIG.Number_Paths {2} \
   CONFIG.Output_Rounding_Mode {Truncate_LSBs} \
   CONFIG.Output_Width {16} \
   CONFIG.Quantization {Quantize_Only} \
   CONFIG.RateSpecification {Input_Sample_Period} \
   CONFIG.Reset_Data_Vector {true} \
   CONFIG.S_CONFIG_Method {By_Channel} \
   CONFIG.S_DATA_Has_FIFO {false} \
   CONFIG.S_DATA_Has_TUSER {Not_Required} \
   CONFIG.SamplePeriod {1} \
   CONFIG.Sample_Frequency {0.001} \
   CONFIG.Select_Pattern {All} \
 ] $fir_compiler_3

  # Create instance: fir_compiler_4, and set properties
  set fir_compiler_4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:fir_compiler:7.2 fir_compiler_4 ]
  set_property -dict [ list \
   CONFIG.BestPrecision {true} \
   CONFIG.Blank_Output {false} \
   CONFIG.Clock_Frequency {300.0} \
   CONFIG.CoefficientSource {COE_File} \
   CONFIG.Coefficient_File {../../../../../../../data/lane4.coe} \
   CONFIG.Coefficient_Fractional_Bits {26} \
   CONFIG.Coefficient_Sets {256} \
   CONFIG.Coefficient_Sign {Signed} \
   CONFIG.Coefficient_Structure {Inferred} \
   CONFIG.Coefficient_Width {16} \
   CONFIG.ColumnConfig {8} \
   CONFIG.DATA_Has_TLAST {Vector_Framing} \
   CONFIG.Data_Fractional_Bits {15} \
   CONFIG.Data_Width {16} \
   CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} \
   CONFIG.Filter_Selection {1} \
   CONFIG.Has_ARESETn {false} \
   CONFIG.M_DATA_Has_TUSER {Not_Required} \
   CONFIG.Number_Channels {512} \
   CONFIG.Number_Paths {2} \
   CONFIG.Output_Buffer_Type {Block} \
   CONFIG.Output_Rounding_Mode {Truncate_LSBs} \
   CONFIG.Output_Width {16} \
   CONFIG.Quantization {Quantize_Only} \
   CONFIG.RateSpecification {Input_Sample_Period} \
   CONFIG.Reset_Data_Vector {true} \
   CONFIG.S_CONFIG_Method {By_Channel} \
   CONFIG.S_DATA_Has_FIFO {false} \
   CONFIG.S_DATA_Has_TUSER {Not_Required} \
   CONFIG.SamplePeriod {1} \
   CONFIG.Sample_Frequency {0.001} \
   CONFIG.Select_Pattern {All} \
 ] $fir_compiler_4

  # Create instance: fir_compiler_5, and set properties
  set fir_compiler_5 [ create_bd_cell -type ip -vlnv xilinx.com:ip:fir_compiler:7.2 fir_compiler_5 ]
  set_property -dict [ list \
   CONFIG.BestPrecision {true} \
   CONFIG.Blank_Output {false} \
   CONFIG.Clock_Frequency {300.0} \
   CONFIG.CoefficientSource {COE_File} \
   CONFIG.Coefficient_Buffer_Type {Block} \
   CONFIG.Coefficient_File {../../../../../../../data/lane5.coe} \
   CONFIG.Coefficient_Fractional_Bits {26} \
   CONFIG.Coefficient_Sets {256} \
   CONFIG.Coefficient_Sign {Signed} \
   CONFIG.Coefficient_Structure {Inferred} \
   CONFIG.Coefficient_Width {16} \
   CONFIG.ColumnConfig {8} \
   CONFIG.DATA_Has_TLAST {Vector_Framing} \
   CONFIG.Data_Buffer_Type {Block} \
   CONFIG.Data_Fractional_Bits {15} \
   CONFIG.Data_Width {16} \
   CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} \
   CONFIG.Filter_Selection {1} \
   CONFIG.Has_ARESETn {false} \
   CONFIG.Input_Buffer_Type {Block} \
   CONFIG.M_DATA_Has_TUSER {Not_Required} \
   CONFIG.Number_Channels {512} \
   CONFIG.Number_Paths {2} \
   CONFIG.Output_Buffer_Type {Block} \
   CONFIG.Output_Rounding_Mode {Truncate_LSBs} \
   CONFIG.Output_Width {16} \
   CONFIG.Preference_For_Other_Storage {Block} \
   CONFIG.Quantization {Quantize_Only} \
   CONFIG.RateSpecification {Input_Sample_Period} \
   CONFIG.Reset_Data_Vector {true} \
   CONFIG.S_CONFIG_Method {By_Channel} \
   CONFIG.S_DATA_Has_FIFO {false} \
   CONFIG.S_DATA_Has_TUSER {Not_Required} \
   CONFIG.SamplePeriod {1} \
   CONFIG.Sample_Frequency {0.001} \
   CONFIG.Select_Pattern {All} \
 ] $fir_compiler_5

  # Create instance: fir_compiler_6, and set properties
  set fir_compiler_6 [ create_bd_cell -type ip -vlnv xilinx.com:ip:fir_compiler:7.2 fir_compiler_6 ]
  set_property -dict [ list \
   CONFIG.BestPrecision {true} \
   CONFIG.Blank_Output {false} \
   CONFIG.Clock_Frequency {300.0} \
   CONFIG.CoefficientSource {COE_File} \
   CONFIG.Coefficient_File {../../../../../../../data/lane6.coe} \
   CONFIG.Coefficient_Fractional_Bits {26} \
   CONFIG.Coefficient_Sets {256} \
   CONFIG.Coefficient_Sign {Signed} \
   CONFIG.Coefficient_Structure {Inferred} \
   CONFIG.Coefficient_Width {16} \
   CONFIG.ColumnConfig {8} \
   CONFIG.DATA_Has_TLAST {Vector_Framing} \
   CONFIG.Data_Fractional_Bits {15} \
   CONFIG.Data_Width {16} \
   CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} \
   CONFIG.Filter_Selection {1} \
   CONFIG.Has_ARESETn {false} \
   CONFIG.M_DATA_Has_TUSER {Not_Required} \
   CONFIG.Number_Channels {512} \
   CONFIG.Number_Paths {2} \
   CONFIG.Output_Rounding_Mode {Truncate_LSBs} \
   CONFIG.Output_Width {16} \
   CONFIG.Quantization {Quantize_Only} \
   CONFIG.RateSpecification {Input_Sample_Period} \
   CONFIG.Reset_Data_Vector {true} \
   CONFIG.S_CONFIG_Method {By_Channel} \
   CONFIG.S_DATA_Has_FIFO {false} \
   CONFIG.S_DATA_Has_TUSER {Not_Required} \
   CONFIG.SamplePeriod {1} \
   CONFIG.Sample_Frequency {0.001} \
   CONFIG.Select_Pattern {All} \
 ] $fir_compiler_6

  # Create instance: fir_compiler_7, and set properties
  set fir_compiler_7 [ create_bd_cell -type ip -vlnv xilinx.com:ip:fir_compiler:7.2 fir_compiler_7 ]
  set_property -dict [ list \
   CONFIG.BestPrecision {true} \
   CONFIG.Blank_Output {false} \
   CONFIG.Clock_Frequency {300.0} \
   CONFIG.CoefficientSource {COE_File} \
   CONFIG.Coefficient_File {../../../../../../../data/lane7.coe} \
   CONFIG.Coefficient_Fractional_Bits {26} \
   CONFIG.Coefficient_Sets {256} \
   CONFIG.Coefficient_Sign {Signed} \
   CONFIG.Coefficient_Structure {Inferred} \
   CONFIG.Coefficient_Width {16} \
   CONFIG.ColumnConfig {8} \
   CONFIG.DATA_Has_TLAST {Vector_Framing} \
   CONFIG.Data_Fractional_Bits {15} \
   CONFIG.Data_Width {16} \
   CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} \
   CONFIG.Filter_Selection {1} \
   CONFIG.Has_ARESETn {false} \
   CONFIG.M_DATA_Has_TUSER {Not_Required} \
   CONFIG.Number_Channels {512} \
   CONFIG.Number_Paths {2} \
   CONFIG.Output_Rounding_Mode {Truncate_LSBs} \
   CONFIG.Output_Width {16} \
   CONFIG.Quantization {Quantize_Only} \
   CONFIG.RateSpecification {Input_Sample_Period} \
   CONFIG.Reset_Data_Vector {true} \
   CONFIG.S_CONFIG_Method {By_Channel} \
   CONFIG.S_DATA_Has_FIFO {false} \
   CONFIG.S_DATA_Has_TUSER {Not_Required} \
   CONFIG.SamplePeriod {1} \
   CONFIG.Sample_Frequency {0.001} \
   CONFIG.Select_Pattern {All} \
 ] $fir_compiler_7

  # Create instance: fir_compiler_8, and set properties
  set fir_compiler_8 [ create_bd_cell -type ip -vlnv xilinx.com:ip:fir_compiler:7.2 fir_compiler_8 ]
  set_property -dict [ list \
   CONFIG.BestPrecision {true} \
   CONFIG.Blank_Output {false} \
   CONFIG.Clock_Frequency {300.0} \
   CONFIG.CoefficientSource {COE_File} \
   CONFIG.Coefficient_File {../../../../../../../data/lane8.coe} \
   CONFIG.Coefficient_Fractional_Bits {26} \
   CONFIG.Coefficient_Sets {256} \
   CONFIG.Coefficient_Sign {Signed} \
   CONFIG.Coefficient_Structure {Inferred} \
   CONFIG.Coefficient_Width {16} \
   CONFIG.ColumnConfig {8} \
   CONFIG.DATA_Has_TLAST {Vector_Framing} \
   CONFIG.Data_Fractional_Bits {15} \
   CONFIG.Data_Width {16} \
   CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} \
   CONFIG.Filter_Selection {1} \
   CONFIG.Has_ARESETn {false} \
   CONFIG.M_DATA_Has_TUSER {Not_Required} \
   CONFIG.Number_Channels {512} \
   CONFIG.Number_Paths {2} \
   CONFIG.Output_Rounding_Mode {Truncate_LSBs} \
   CONFIG.Output_Width {16} \
   CONFIG.Quantization {Quantize_Only} \
   CONFIG.RateSpecification {Input_Sample_Period} \
   CONFIG.Reset_Data_Vector {true} \
   CONFIG.S_CONFIG_Method {By_Channel} \
   CONFIG.S_DATA_Has_FIFO {false} \
   CONFIG.S_DATA_Has_TUSER {Not_Required} \
   CONFIG.SamplePeriod {1} \
   CONFIG.Sample_Frequency {0.001} \
   CONFIG.Select_Pattern {All} \
 ] $fir_compiler_8

  # Create instance: fir_compiler_9, and set properties
  set fir_compiler_9 [ create_bd_cell -type ip -vlnv xilinx.com:ip:fir_compiler:7.2 fir_compiler_9 ]
  set_property -dict [ list \
   CONFIG.BestPrecision {true} \
   CONFIG.Blank_Output {false} \
   CONFIG.Clock_Frequency {300.0} \
   CONFIG.CoefficientSource {COE_File} \
   CONFIG.Coefficient_File {../../../../../../../data/lane9.coe} \
   CONFIG.Coefficient_Fractional_Bits {26} \
   CONFIG.Coefficient_Sets {256} \
   CONFIG.Coefficient_Sign {Signed} \
   CONFIG.Coefficient_Structure {Inferred} \
   CONFIG.Coefficient_Width {16} \
   CONFIG.ColumnConfig {8} \
   CONFIG.DATA_Has_TLAST {Vector_Framing} \
   CONFIG.Data_Fractional_Bits {15} \
   CONFIG.Data_Width {16} \
   CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} \
   CONFIG.Filter_Selection {1} \
   CONFIG.Has_ARESETn {false} \
   CONFIG.M_DATA_Has_TUSER {Not_Required} \
   CONFIG.Number_Channels {512} \
   CONFIG.Number_Paths {2} \
   CONFIG.Output_Rounding_Mode {Truncate_LSBs} \
   CONFIG.Output_Width {16} \
   CONFIG.Quantization {Quantize_Only} \
   CONFIG.RateSpecification {Input_Sample_Period} \
   CONFIG.Reset_Data_Vector {true} \
   CONFIG.S_CONFIG_Method {By_Channel} \
   CONFIG.S_DATA_Has_FIFO {false} \
   CONFIG.S_DATA_Has_TUSER {Not_Required} \
   CONFIG.SamplePeriod {1} \
   CONFIG.Sample_Frequency {0.001} \
   CONFIG.Select_Pattern {All} \
 ] $fir_compiler_9

  # Create instance: fir_compiler_10, and set properties
  set fir_compiler_10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:fir_compiler:7.2 fir_compiler_10 ]
  set_property -dict [ list \
   CONFIG.BestPrecision {true} \
   CONFIG.Blank_Output {false} \
   CONFIG.Clock_Frequency {300.0} \
   CONFIG.CoefficientSource {COE_File} \
   CONFIG.Coefficient_File {../../../../../../../data/lane10.coe} \
   CONFIG.Coefficient_Fractional_Bits {26} \
   CONFIG.Coefficient_Sets {256} \
   CONFIG.Coefficient_Sign {Signed} \
   CONFIG.Coefficient_Structure {Inferred} \
   CONFIG.Coefficient_Width {16} \
   CONFIG.ColumnConfig {8} \
   CONFIG.DATA_Has_TLAST {Vector_Framing} \
   CONFIG.Data_Fractional_Bits {15} \
   CONFIG.Data_Width {16} \
   CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} \
   CONFIG.Filter_Selection {1} \
   CONFIG.Has_ARESETn {false} \
   CONFIG.M_DATA_Has_TUSER {Not_Required} \
   CONFIG.Number_Channels {512} \
   CONFIG.Number_Paths {2} \
   CONFIG.Output_Rounding_Mode {Truncate_LSBs} \
   CONFIG.Output_Width {16} \
   CONFIG.Quantization {Quantize_Only} \
   CONFIG.RateSpecification {Input_Sample_Period} \
   CONFIG.Reset_Data_Vector {true} \
   CONFIG.S_CONFIG_Method {By_Channel} \
   CONFIG.S_DATA_Has_FIFO {false} \
   CONFIG.S_DATA_Has_TUSER {Not_Required} \
   CONFIG.SamplePeriod {1} \
   CONFIG.Sample_Frequency {0.001} \
   CONFIG.Select_Pattern {All} \
 ] $fir_compiler_10

  # Create instance: fir_compiler_11, and set properties
  set fir_compiler_11 [ create_bd_cell -type ip -vlnv xilinx.com:ip:fir_compiler:7.2 fir_compiler_11 ]
  set_property -dict [ list \
   CONFIG.BestPrecision {true} \
   CONFIG.Blank_Output {false} \
   CONFIG.Clock_Frequency {300.0} \
   CONFIG.CoefficientSource {COE_File} \
   CONFIG.Coefficient_File {../../../../../../../data/lane11.coe} \
   CONFIG.Coefficient_Fractional_Bits {26} \
   CONFIG.Coefficient_Sets {256} \
   CONFIG.Coefficient_Sign {Signed} \
   CONFIG.Coefficient_Structure {Inferred} \
   CONFIG.Coefficient_Width {16} \
   CONFIG.ColumnConfig {8} \
   CONFIG.DATA_Has_TLAST {Vector_Framing} \
   CONFIG.Data_Fractional_Bits {15} \
   CONFIG.Data_Width {16} \
   CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} \
   CONFIG.Filter_Selection {1} \
   CONFIG.Has_ARESETn {false} \
   CONFIG.M_DATA_Has_TUSER {Not_Required} \
   CONFIG.Number_Channels {512} \
   CONFIG.Number_Paths {2} \
   CONFIG.Output_Rounding_Mode {Truncate_LSBs} \
   CONFIG.Output_Width {16} \
   CONFIG.Quantization {Quantize_Only} \
   CONFIG.RateSpecification {Input_Sample_Period} \
   CONFIG.Reset_Data_Vector {true} \
   CONFIG.S_CONFIG_Method {By_Channel} \
   CONFIG.S_DATA_Has_FIFO {false} \
   CONFIG.S_DATA_Has_TUSER {Not_Required} \
   CONFIG.SamplePeriod {1} \
   CONFIG.Sample_Frequency {0.001} \
   CONFIG.Select_Pattern {All} \
 ] $fir_compiler_11

  # Create instance: fir_compiler_12, and set properties
  set fir_compiler_12 [ create_bd_cell -type ip -vlnv xilinx.com:ip:fir_compiler:7.2 fir_compiler_12 ]
  set_property -dict [ list \
   CONFIG.BestPrecision {true} \
   CONFIG.Blank_Output {false} \
   CONFIG.Clock_Frequency {300.0} \
   CONFIG.CoefficientSource {COE_File} \
   CONFIG.Coefficient_File {../../../../../../../data/lane12.coe} \
   CONFIG.Coefficient_Fractional_Bits {26} \
   CONFIG.Coefficient_Sets {256} \
   CONFIG.Coefficient_Sign {Signed} \
   CONFIG.Coefficient_Structure {Inferred} \
   CONFIG.Coefficient_Width {16} \
   CONFIG.ColumnConfig {8} \
   CONFIG.DATA_Has_TLAST {Vector_Framing} \
   CONFIG.Data_Fractional_Bits {15} \
   CONFIG.Data_Width {16} \
   CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} \
   CONFIG.Filter_Selection {1} \
   CONFIG.Has_ARESETn {false} \
   CONFIG.M_DATA_Has_TUSER {Not_Required} \
   CONFIG.Number_Channels {512} \
   CONFIG.Number_Paths {2} \
   CONFIG.Output_Rounding_Mode {Truncate_LSBs} \
   CONFIG.Output_Width {16} \
   CONFIG.Quantization {Quantize_Only} \
   CONFIG.RateSpecification {Input_Sample_Period} \
   CONFIG.Reset_Data_Vector {true} \
   CONFIG.S_CONFIG_Method {By_Channel} \
   CONFIG.S_DATA_Has_FIFO {false} \
   CONFIG.S_DATA_Has_TUSER {Not_Required} \
   CONFIG.SamplePeriod {1} \
   CONFIG.Sample_Frequency {0.001} \
   CONFIG.Select_Pattern {All} \
 ] $fir_compiler_12

  # Create instance: fir_compiler_13, and set properties
  set fir_compiler_13 [ create_bd_cell -type ip -vlnv xilinx.com:ip:fir_compiler:7.2 fir_compiler_13 ]
  set_property -dict [ list \
   CONFIG.BestPrecision {true} \
   CONFIG.Blank_Output {false} \
   CONFIG.Clock_Frequency {300.0} \
   CONFIG.CoefficientSource {COE_File} \
   CONFIG.Coefficient_File {../../../../../../../data/lane13.coe} \
   CONFIG.Coefficient_Fractional_Bits {26} \
   CONFIG.Coefficient_Sets {256} \
   CONFIG.Coefficient_Sign {Signed} \
   CONFIG.Coefficient_Structure {Inferred} \
   CONFIG.Coefficient_Width {16} \
   CONFIG.ColumnConfig {8} \
   CONFIG.DATA_Has_TLAST {Vector_Framing} \
   CONFIG.Data_Fractional_Bits {15} \
   CONFIG.Data_Width {16} \
   CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} \
   CONFIG.Filter_Selection {1} \
   CONFIG.Has_ARESETn {false} \
   CONFIG.M_DATA_Has_TUSER {Not_Required} \
   CONFIG.Number_Channels {512} \
   CONFIG.Number_Paths {2} \
   CONFIG.Output_Rounding_Mode {Truncate_LSBs} \
   CONFIG.Output_Width {16} \
   CONFIG.Quantization {Quantize_Only} \
   CONFIG.RateSpecification {Input_Sample_Period} \
   CONFIG.Reset_Data_Vector {true} \
   CONFIG.S_CONFIG_Method {By_Channel} \
   CONFIG.S_DATA_Has_FIFO {false} \
   CONFIG.S_DATA_Has_TUSER {Not_Required} \
   CONFIG.SamplePeriod {1} \
   CONFIG.Sample_Frequency {0.001} \
   CONFIG.Select_Pattern {All} \
 ] $fir_compiler_13

  # Create instance: fir_compiler_14, and set properties
  set fir_compiler_14 [ create_bd_cell -type ip -vlnv xilinx.com:ip:fir_compiler:7.2 fir_compiler_14 ]
  set_property -dict [ list \
   CONFIG.BestPrecision {true} \
   CONFIG.Blank_Output {false} \
   CONFIG.Clock_Frequency {300.0} \
   CONFIG.CoefficientSource {COE_File} \
   CONFIG.Coefficient_File {../../../../../../../data/lane14.coe} \
   CONFIG.Coefficient_Fractional_Bits {26} \
   CONFIG.Coefficient_Sets {256} \
   CONFIG.Coefficient_Sign {Signed} \
   CONFIG.Coefficient_Structure {Inferred} \
   CONFIG.Coefficient_Width {16} \
   CONFIG.ColumnConfig {8} \
   CONFIG.DATA_Has_TLAST {Vector_Framing} \
   CONFIG.Data_Fractional_Bits {15} \
   CONFIG.Data_Width {16} \
   CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} \
   CONFIG.Filter_Selection {1} \
   CONFIG.Has_ARESETn {false} \
   CONFIG.M_DATA_Has_TUSER {Not_Required} \
   CONFIG.Number_Channels {512} \
   CONFIG.Number_Paths {2} \
   CONFIG.Output_Rounding_Mode {Truncate_LSBs} \
   CONFIG.Output_Width {16} \
   CONFIG.Quantization {Quantize_Only} \
   CONFIG.RateSpecification {Input_Sample_Period} \
   CONFIG.Reset_Data_Vector {true} \
   CONFIG.S_CONFIG_Method {By_Channel} \
   CONFIG.S_DATA_Has_FIFO {false} \
   CONFIG.S_DATA_Has_TUSER {Not_Required} \
   CONFIG.SamplePeriod {1} \
   CONFIG.Sample_Frequency {0.001} \
   CONFIG.Select_Pattern {All} \
 ] $fir_compiler_14

  # Create instance: fir_compiler_15, and set properties
  set fir_compiler_15 [ create_bd_cell -type ip -vlnv xilinx.com:ip:fir_compiler:7.2 fir_compiler_15 ]
  set_property -dict [ list \
   CONFIG.BestPrecision {true} \
   CONFIG.Blank_Output {false} \
   CONFIG.Clock_Frequency {300.0} \
   CONFIG.CoefficientSource {COE_File} \
   CONFIG.Coefficient_File {../../../../../../../data/lane15.coe} \
   CONFIG.Coefficient_Fractional_Bits {26} \
   CONFIG.Coefficient_Sets {256} \
   CONFIG.Coefficient_Sign {Signed} \
   CONFIG.Coefficient_Structure {Inferred} \
   CONFIG.Coefficient_Width {16} \
   CONFIG.ColumnConfig {8} \
   CONFIG.DATA_Has_TLAST {Vector_Framing} \
   CONFIG.Data_Fractional_Bits {15} \
   CONFIG.Data_Width {16} \
   CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} \
   CONFIG.Filter_Selection {1} \
   CONFIG.Has_ARESETn {false} \
   CONFIG.M_DATA_Has_TUSER {Not_Required} \
   CONFIG.Number_Channels {512} \
   CONFIG.Number_Paths {2} \
   CONFIG.Output_Rounding_Mode {Truncate_LSBs} \
   CONFIG.Output_Width {16} \
   CONFIG.Quantization {Quantize_Only} \
   CONFIG.RateSpecification {Input_Sample_Period} \
   CONFIG.Reset_Data_Vector {true} \
   CONFIG.S_CONFIG_Method {By_Channel} \
   CONFIG.S_DATA_Has_FIFO {false} \
   CONFIG.S_DATA_Has_TUSER {Not_Required} \
   CONFIG.SamplePeriod {1} \
   CONFIG.Sample_Frequency {0.001} \
   CONFIG.Select_Pattern {All} \
 ] $fir_compiler_15

  # Create instance: opfb_fir_cfg_0, and set properties
  set opfb_fir_cfg_0 [ create_bd_cell -type ip -vlnv MazinLab:mkidgen3:opfb_fir_cfg:0.1 opfb_fir_cfg_0 ]

  # Create interface connections
  connect_bd_intf_net -intf_net S_AXIS_DATA10_1 [get_bd_intf_pins S_AXIS_DATA10] [get_bd_intf_pins fir_compiler_10/S_AXIS_DATA]
  connect_bd_intf_net -intf_net S_AXIS_DATA11_1 [get_bd_intf_pins S_AXIS_DATA11] [get_bd_intf_pins fir_compiler_11/S_AXIS_DATA]
  connect_bd_intf_net -intf_net S_AXIS_DATA12_1 [get_bd_intf_pins S_AXIS_DATA12] [get_bd_intf_pins fir_compiler_12/S_AXIS_DATA]
  connect_bd_intf_net -intf_net S_AXIS_DATA13_1 [get_bd_intf_pins S_AXIS_DATA13] [get_bd_intf_pins fir_compiler_13/S_AXIS_DATA]
  connect_bd_intf_net -intf_net S_AXIS_DATA14_1 [get_bd_intf_pins S_AXIS_DATA14] [get_bd_intf_pins fir_compiler_14/S_AXIS_DATA]
  connect_bd_intf_net -intf_net S_AXIS_DATA15_1 [get_bd_intf_pins S_AXIS_DATA15] [get_bd_intf_pins fir_compiler_15/S_AXIS_DATA]
  connect_bd_intf_net -intf_net S_AXIS_DATA1_1 [get_bd_intf_pins S_AXIS_DATA1] [get_bd_intf_pins fir_compiler_1/S_AXIS_DATA]
  connect_bd_intf_net -intf_net S_AXIS_DATA2_1 [get_bd_intf_pins S_AXIS_DATA2] [get_bd_intf_pins fir_compiler_2/S_AXIS_DATA]
  connect_bd_intf_net -intf_net S_AXIS_DATA3_1 [get_bd_intf_pins S_AXIS_DATA3] [get_bd_intf_pins fir_compiler_3/S_AXIS_DATA]
  connect_bd_intf_net -intf_net S_AXIS_DATA4_1 [get_bd_intf_pins S_AXIS_DATA4] [get_bd_intf_pins fir_compiler_4/S_AXIS_DATA]
  connect_bd_intf_net -intf_net S_AXIS_DATA5_1 [get_bd_intf_pins S_AXIS_DATA5] [get_bd_intf_pins fir_compiler_5/S_AXIS_DATA]
  connect_bd_intf_net -intf_net S_AXIS_DATA6_1 [get_bd_intf_pins S_AXIS_DATA6] [get_bd_intf_pins fir_compiler_6/S_AXIS_DATA]
  connect_bd_intf_net -intf_net S_AXIS_DATA7_1 [get_bd_intf_pins S_AXIS_DATA7] [get_bd_intf_pins fir_compiler_7/S_AXIS_DATA]
  connect_bd_intf_net -intf_net S_AXIS_DATA8_1 [get_bd_intf_pins S_AXIS_DATA8] [get_bd_intf_pins fir_compiler_8/S_AXIS_DATA]
  connect_bd_intf_net -intf_net S_AXIS_DATA9_1 [get_bd_intf_pins S_AXIS_DATA9] [get_bd_intf_pins fir_compiler_9/S_AXIS_DATA]
  connect_bd_intf_net -intf_net S_AXIS_DATA_1 [get_bd_intf_pins S_AXIS_DATA] [get_bd_intf_pins fir_compiler_0/S_AXIS_DATA]
  connect_bd_intf_net -intf_net axis_broadcaster_0_M00_AXIS [get_bd_intf_pins axis_broadcaster_0/M00_AXIS] [get_bd_intf_pins fir_compiler_0/S_AXIS_CONFIG]
  connect_bd_intf_net -intf_net axis_broadcaster_0_M01_AXIS [get_bd_intf_pins axis_broadcaster_0/M01_AXIS] [get_bd_intf_pins fir_compiler_1/S_AXIS_CONFIG]
  connect_bd_intf_net -intf_net axis_broadcaster_0_M02_AXIS [get_bd_intf_pins axis_broadcaster_0/M02_AXIS] [get_bd_intf_pins fir_compiler_2/S_AXIS_CONFIG]
  connect_bd_intf_net -intf_net axis_broadcaster_0_M03_AXIS [get_bd_intf_pins axis_broadcaster_0/M03_AXIS] [get_bd_intf_pins fir_compiler_3/S_AXIS_CONFIG]
  connect_bd_intf_net -intf_net axis_broadcaster_0_M04_AXIS [get_bd_intf_pins axis_broadcaster_0/M04_AXIS] [get_bd_intf_pins fir_compiler_4/S_AXIS_CONFIG]
  connect_bd_intf_net -intf_net axis_broadcaster_0_M05_AXIS [get_bd_intf_pins axis_broadcaster_0/M05_AXIS] [get_bd_intf_pins fir_compiler_5/S_AXIS_CONFIG]
  connect_bd_intf_net -intf_net axis_broadcaster_0_M06_AXIS [get_bd_intf_pins axis_broadcaster_0/M06_AXIS] [get_bd_intf_pins fir_compiler_6/S_AXIS_CONFIG]
  connect_bd_intf_net -intf_net axis_broadcaster_0_M07_AXIS [get_bd_intf_pins axis_broadcaster_0/M07_AXIS] [get_bd_intf_pins fir_compiler_7/S_AXIS_CONFIG]
  connect_bd_intf_net -intf_net axis_broadcaster_0_M08_AXIS [get_bd_intf_pins axis_broadcaster_0/M08_AXIS] [get_bd_intf_pins fir_compiler_8/S_AXIS_CONFIG]
  connect_bd_intf_net -intf_net axis_broadcaster_0_M09_AXIS [get_bd_intf_pins axis_broadcaster_0/M09_AXIS] [get_bd_intf_pins fir_compiler_9/S_AXIS_CONFIG]
  connect_bd_intf_net -intf_net axis_broadcaster_0_M10_AXIS [get_bd_intf_pins axis_broadcaster_0/M10_AXIS] [get_bd_intf_pins fir_compiler_10/S_AXIS_CONFIG]
  connect_bd_intf_net -intf_net axis_broadcaster_0_M11_AXIS [get_bd_intf_pins axis_broadcaster_0/M11_AXIS] [get_bd_intf_pins fir_compiler_11/S_AXIS_CONFIG]
  connect_bd_intf_net -intf_net axis_broadcaster_0_M12_AXIS [get_bd_intf_pins axis_broadcaster_0/M12_AXIS] [get_bd_intf_pins fir_compiler_12/S_AXIS_CONFIG]
  connect_bd_intf_net -intf_net axis_broadcaster_0_M13_AXIS [get_bd_intf_pins axis_broadcaster_0/M13_AXIS] [get_bd_intf_pins fir_compiler_13/S_AXIS_CONFIG]
  connect_bd_intf_net -intf_net axis_broadcaster_0_M14_AXIS [get_bd_intf_pins axis_broadcaster_0/M14_AXIS] [get_bd_intf_pins fir_compiler_14/S_AXIS_CONFIG]
  connect_bd_intf_net -intf_net axis_broadcaster_0_M15_AXIS [get_bd_intf_pins axis_broadcaster_0/M15_AXIS] [get_bd_intf_pins fir_compiler_15/S_AXIS_CONFIG]
  connect_bd_intf_net -intf_net axis_register_slice_0_M_AXIS [get_bd_intf_pins axis_broadcaster_0/S_AXIS] [get_bd_intf_pins axis_register_slice_0/M_AXIS]
  connect_bd_intf_net -intf_net fir_compiler_0_M_AXIS_DATA [get_bd_intf_pins M_AXIS_DATA] [get_bd_intf_pins fir_compiler_0/M_AXIS_DATA]
  connect_bd_intf_net -intf_net fir_compiler_10_M_AXIS_DATA [get_bd_intf_pins M_AXIS_DATA10] [get_bd_intf_pins fir_compiler_10/M_AXIS_DATA]
  connect_bd_intf_net -intf_net fir_compiler_11_M_AXIS_DATA [get_bd_intf_pins M_AXIS_DATA11] [get_bd_intf_pins fir_compiler_11/M_AXIS_DATA]
  connect_bd_intf_net -intf_net fir_compiler_12_M_AXIS_DATA [get_bd_intf_pins M_AXIS_DATA12] [get_bd_intf_pins fir_compiler_12/M_AXIS_DATA]
  connect_bd_intf_net -intf_net fir_compiler_13_M_AXIS_DATA [get_bd_intf_pins M_AXIS_DATA13] [get_bd_intf_pins fir_compiler_13/M_AXIS_DATA]
  connect_bd_intf_net -intf_net fir_compiler_14_M_AXIS_DATA [get_bd_intf_pins M_AXIS_DATA14] [get_bd_intf_pins fir_compiler_14/M_AXIS_DATA]
  connect_bd_intf_net -intf_net fir_compiler_15_M_AXIS_DATA [get_bd_intf_pins M_AXIS_DATA15] [get_bd_intf_pins fir_compiler_15/M_AXIS_DATA]
  connect_bd_intf_net -intf_net fir_compiler_1_M_AXIS_DATA [get_bd_intf_pins M_AXIS_DATA1] [get_bd_intf_pins fir_compiler_1/M_AXIS_DATA]
  connect_bd_intf_net -intf_net fir_compiler_2_M_AXIS_DATA [get_bd_intf_pins M_AXIS_DATA2] [get_bd_intf_pins fir_compiler_2/M_AXIS_DATA]
  connect_bd_intf_net -intf_net fir_compiler_3_M_AXIS_DATA [get_bd_intf_pins M_AXIS_DATA3] [get_bd_intf_pins fir_compiler_3/M_AXIS_DATA]
  connect_bd_intf_net -intf_net fir_compiler_4_M_AXIS_DATA [get_bd_intf_pins M_AXIS_DATA4] [get_bd_intf_pins fir_compiler_4/M_AXIS_DATA]
  connect_bd_intf_net -intf_net fir_compiler_5_M_AXIS_DATA [get_bd_intf_pins M_AXIS_DATA5] [get_bd_intf_pins fir_compiler_5/M_AXIS_DATA]
  connect_bd_intf_net -intf_net fir_compiler_6_M_AXIS_DATA [get_bd_intf_pins M_AXIS_DATA6] [get_bd_intf_pins fir_compiler_6/M_AXIS_DATA]
  connect_bd_intf_net -intf_net fir_compiler_7_M_AXIS_DATA [get_bd_intf_pins M_AXIS_DATA7] [get_bd_intf_pins fir_compiler_7/M_AXIS_DATA]
  connect_bd_intf_net -intf_net fir_compiler_8_M_AXIS_DATA [get_bd_intf_pins M_AXIS_DATA8] [get_bd_intf_pins fir_compiler_8/M_AXIS_DATA]
  connect_bd_intf_net -intf_net fir_compiler_9_M_AXIS_DATA [get_bd_intf_pins M_AXIS_DATA9] [get_bd_intf_pins fir_compiler_9/M_AXIS_DATA]
  connect_bd_intf_net -intf_net opfb_fir_cfg_0_config_r [get_bd_intf_pins axis_register_slice_0/S_AXIS] [get_bd_intf_pins opfb_fir_cfg_0/config_r]

  # Create port connections
  connect_bd_net -net Net [get_bd_pins aclk] [get_bd_pins axis_broadcaster_0/aclk] [get_bd_pins axis_register_slice_0/aclk] [get_bd_pins fir_compiler_0/aclk] [get_bd_pins fir_compiler_1/aclk] [get_bd_pins fir_compiler_10/aclk] [get_bd_pins fir_compiler_11/aclk] [get_bd_pins fir_compiler_12/aclk] [get_bd_pins fir_compiler_13/aclk] [get_bd_pins fir_compiler_14/aclk] [get_bd_pins fir_compiler_15/aclk] [get_bd_pins fir_compiler_2/aclk] [get_bd_pins fir_compiler_3/aclk] [get_bd_pins fir_compiler_4/aclk] [get_bd_pins fir_compiler_5/aclk] [get_bd_pins fir_compiler_6/aclk] [get_bd_pins fir_compiler_7/aclk] [get_bd_pins fir_compiler_8/aclk] [get_bd_pins fir_compiler_9/aclk] [get_bd_pins opfb_fir_cfg_0/ap_clk]
  connect_bd_net -net aresetn_1 [get_bd_pins aresetn] [get_bd_pins axis_broadcaster_0/aresetn] [get_bd_pins axis_register_slice_0/aresetn] [get_bd_pins opfb_fir_cfg_0/ap_rst_n]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: fft
proc create_hier_cell_fft { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_fft() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 output_r


  # Create pins
  create_bd_pin -dir I -type clk aclk
  create_bd_pin -dir I -type rst ap_rst_n

  # Create instance: pkg_fft_output_0, and set properties
  set pkg_fft_output_0 [ create_bd_cell -type ip -vlnv MazinLab:mkidgen3:pkg_fft_output:0.2 pkg_fft_output_0 ]

  # Create instance: ssrfft_16x4096_axis_0, and set properties
  set ssrfft_16x4096_axis_0 [ create_bd_cell -type ip -vlnv MazinLab:mkidgen3:ssrfft_16x4096_axis:1.0 ssrfft_16x4096_axis_0 ]

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
   CONFIG.CONST_WIDTH {12} \
 ] $xlconstant_0

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins output_r] [get_bd_intf_pins pkg_fft_output_0/output_r]

  # Create port connections
  connect_bd_net -net rst_ps8_0_99M_peripheral_aresetn [get_bd_pins ap_rst_n] [get_bd_pins pkg_fft_output_0/ap_rst_n]
  connect_bd_net -net ssrfft_16x4096_axis_0_biniq_1 [get_bd_pins pkg_fft_output_0/iq_1] [get_bd_pins ssrfft_16x4096_axis_0/biniq_1]
  connect_bd_net -net ssrfft_16x4096_axis_0_biniq_2 [get_bd_pins pkg_fft_output_0/iq_2] [get_bd_pins ssrfft_16x4096_axis_0/biniq_2]
  connect_bd_net -net ssrfft_16x4096_axis_0_biniq_3 [get_bd_pins pkg_fft_output_0/iq_3] [get_bd_pins ssrfft_16x4096_axis_0/biniq_3]
  connect_bd_net -net ssrfft_16x4096_axis_0_biniq_4 [get_bd_pins pkg_fft_output_0/iq_4] [get_bd_pins ssrfft_16x4096_axis_0/biniq_4]
  connect_bd_net -net ssrfft_16x4096_axis_0_biniq_5 [get_bd_pins pkg_fft_output_0/iq_5] [get_bd_pins ssrfft_16x4096_axis_0/biniq_5]
  connect_bd_net -net ssrfft_16x4096_axis_0_biniq_6 [get_bd_pins pkg_fft_output_0/iq_6] [get_bd_pins ssrfft_16x4096_axis_0/biniq_6]
  connect_bd_net -net ssrfft_16x4096_axis_0_biniq_7 [get_bd_pins pkg_fft_output_0/iq_7] [get_bd_pins ssrfft_16x4096_axis_0/biniq_7]
  connect_bd_net -net ssrfft_16x4096_axis_0_biniq_8 [get_bd_pins pkg_fft_output_0/iq_8] [get_bd_pins ssrfft_16x4096_axis_0/biniq_8]
  connect_bd_net -net ssrfft_16x4096_axis_0_biniq_9 [get_bd_pins pkg_fft_output_0/iq_9] [get_bd_pins ssrfft_16x4096_axis_0/biniq_9]
  connect_bd_net -net ssrfft_16x4096_axis_0_biniq_10 [get_bd_pins pkg_fft_output_0/iq_10] [get_bd_pins ssrfft_16x4096_axis_0/biniq_10]
  connect_bd_net -net ssrfft_16x4096_axis_0_biniq_11 [get_bd_pins pkg_fft_output_0/iq_11] [get_bd_pins ssrfft_16x4096_axis_0/biniq_11]
  connect_bd_net -net ssrfft_16x4096_axis_0_biniq_12 [get_bd_pins pkg_fft_output_0/iq_12] [get_bd_pins ssrfft_16x4096_axis_0/biniq_12]
  connect_bd_net -net ssrfft_16x4096_axis_0_biniq_13 [get_bd_pins pkg_fft_output_0/iq_13] [get_bd_pins ssrfft_16x4096_axis_0/biniq_13]
  connect_bd_net -net ssrfft_16x4096_axis_0_biniq_14 [get_bd_pins pkg_fft_output_0/iq_14] [get_bd_pins ssrfft_16x4096_axis_0/biniq_14]
  connect_bd_net -net ssrfft_16x4096_axis_0_biniq_15 [get_bd_pins pkg_fft_output_0/iq_15] [get_bd_pins ssrfft_16x4096_axis_0/biniq_15]
  connect_bd_net -net ssrfft_16x4096_axis_0_scale_out [get_bd_pins pkg_fft_output_0/scale_V] [get_bd_pins ssrfft_16x4096_axis_0/scale_out]
  connect_bd_net -net ssrfft_16x4096_noaxis_0_biniq_0 [get_bd_pins pkg_fft_output_0/iq_0] [get_bd_pins ssrfft_16x4096_axis_0/biniq_0]
  connect_bd_net -net ssrfft_16x4096_noaxis_0_biniq_valid [get_bd_pins pkg_fft_output_0/iq_0_ap_vld] [get_bd_pins pkg_fft_output_0/iq_10_ap_vld] [get_bd_pins pkg_fft_output_0/iq_11_ap_vld] [get_bd_pins pkg_fft_output_0/iq_12_ap_vld] [get_bd_pins pkg_fft_output_0/iq_13_ap_vld] [get_bd_pins pkg_fft_output_0/iq_14_ap_vld] [get_bd_pins pkg_fft_output_0/iq_15_ap_vld] [get_bd_pins pkg_fft_output_0/iq_1_ap_vld] [get_bd_pins pkg_fft_output_0/iq_2_ap_vld] [get_bd_pins pkg_fft_output_0/iq_3_ap_vld] [get_bd_pins pkg_fft_output_0/iq_4_ap_vld] [get_bd_pins pkg_fft_output_0/iq_5_ap_vld] [get_bd_pins pkg_fft_output_0/iq_6_ap_vld] [get_bd_pins pkg_fft_output_0/iq_7_ap_vld] [get_bd_pins pkg_fft_output_0/iq_8_ap_vld] [get_bd_pins pkg_fft_output_0/iq_9_ap_vld] [get_bd_pins pkg_fft_output_0/scale_V_ap_vld] [get_bd_pins ssrfft_16x4096_axis_0/biniq_valid]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins ssrfft_16x4096_axis_0/scale_in] [get_bd_pins xlconstant_0/dout]
  connect_bd_net -net zynq_ultra_ps_e_0_pl_clk0 [get_bd_pins aclk] [get_bd_pins pkg_fft_output_0/ap_clk] [get_bd_pins ssrfft_16x4096_axis_0/clk]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: reschan
proc create_hier_cell_reschan { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_reschan() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M00_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M01_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M01_AXIS1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M01_AXIS2

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 iq_stream

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_bin_to_res

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_resonator_dds


  # Create pins
  create_bd_pin -dir I -type clk S_AXI_clk
  create_bd_pin -dir I -type clk ap_clk
  create_bd_pin -dir I -type rst ap_rst_n
  create_bd_pin -dir I -type rst ap_rst_n_S_AXI_clk

  # Create instance: axis_broadcaster_1, and set properties
  set axis_broadcaster_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_broadcaster:1.1 axis_broadcaster_1 ]
  set_property -dict [ list \
   CONFIG.M00_TDATA_REMAP {tdata[255:0]} \
   CONFIG.M00_TUSER_REMAP {tuser[7:0]} \
   CONFIG.M01_TDATA_REMAP {tdata[255:0]} \
   CONFIG.M01_TUSER_REMAP {tuser[7:0]} \
 ] $axis_broadcaster_1

  # Create instance: axis_broadcaster_2, and set properties
  set axis_broadcaster_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_broadcaster:1.1 axis_broadcaster_2 ]
  set_property -dict [ list \
   CONFIG.M00_TDATA_REMAP {tdata[255:0]} \
   CONFIG.M00_TUSER_REMAP {tuser[7:0]} \
   CONFIG.M01_TDATA_REMAP {tdata[255:0]} \
   CONFIG.M01_TUSER_REMAP {tuser[7:0]} \
 ] $axis_broadcaster_2

  # Create instance: axis_broadcaster_4, and set properties
  set axis_broadcaster_4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_broadcaster:1.1 axis_broadcaster_4 ]
  set_property -dict [ list \
   CONFIG.M00_TDATA_REMAP {tdata[255:0]} \
   CONFIG.M00_TUSER_REMAP {tuser[7:0]} \
   CONFIG.M01_TDATA_REMAP {tdata[255:0]} \
   CONFIG.M01_TUSER_REMAP {tuser[7:0]} \
 ] $axis_broadcaster_4

  # Create instance: bin_to_res_0, and set properties
  set bin_to_res_0 [ create_bd_cell -type ip -vlnv MazinLab:mkidgen3:bin_to_res:1.0 bin_to_res_0 ]

  # Create instance: fir_compiler_0, and set properties
  set fir_compiler_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:fir_compiler:7.2 fir_compiler_0 ]
  set_property -dict [ list \
   CONFIG.BestPrecision {true} \
   CONFIG.Clock_Frequency {300.0} \
   CONFIG.CoefficientSource {COE_File} \
   CONFIG.Coefficient_File {../../../../../../../data/FCLowpass.coe} \
   CONFIG.Coefficient_Fractional_Bits {17} \
   CONFIG.Coefficient_Sets {1} \
   CONFIG.Coefficient_Sign {Signed} \
   CONFIG.Coefficient_Structure {Inferred} \
   CONFIG.Coefficient_Width {16} \
   CONFIG.ColumnConfig {5} \
   CONFIG.DATA_Has_TLAST {Packet_Framing} \
   CONFIG.DATA_TUSER_Width {8} \
   CONFIG.Data_Width {16} \
   CONFIG.Decimation_Rate {2} \
   CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} \
   CONFIG.Filter_Type {Decimation} \
   CONFIG.Interpolation_Rate {1} \
   CONFIG.M_DATA_Has_TUSER {User_Field} \
   CONFIG.Number_Channels {256} \
   CONFIG.Number_Paths {16} \
   CONFIG.Output_Rounding_Mode {Truncate_LSBs} \
   CONFIG.Output_Width {16} \
   CONFIG.Quantization {Quantize_Only} \
   CONFIG.RateSpecification {Input_Sample_Period} \
   CONFIG.S_DATA_Has_FIFO {false} \
   CONFIG.S_DATA_Has_TUSER {User_Field} \
   CONFIG.SamplePeriod {1} \
   CONFIG.Sample_Frequency {0.001} \
   CONFIG.Select_Pattern {All} \
   CONFIG.Zero_Pack_Factor {1} \
 ] $fir_compiler_0

  # Create instance: resonator_dds_0, and set properties
  set resonator_dds_0 [ create_bd_cell -type ip -vlnv MazinLab:mkidgen3:resonator_dds:1.0 resonator_dds_0 ]

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
 ] $xlconstant_0

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins M01_AXIS] [get_bd_intf_pins axis_broadcaster_1/M01_AXIS]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins s_axi_resonator_dds] [get_bd_intf_pins resonator_dds_0/s_axi_control]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins s_axi_bin_to_res] [get_bd_intf_pins bin_to_res_0/s_axi_control]
  connect_bd_intf_net -intf_net Conn4 [get_bd_intf_pins iq_stream] [get_bd_intf_pins bin_to_res_0/iq_stream]
  connect_bd_intf_net -intf_net Conn5 [get_bd_intf_pins M01_AXIS1] [get_bd_intf_pins axis_broadcaster_2/M01_AXIS]
  connect_bd_intf_net -intf_net Conn6 [get_bd_intf_pins M00_AXIS] [get_bd_intf_pins axis_broadcaster_4/M00_AXIS]
  connect_bd_intf_net -intf_net axis_broadcaster_1_M00_AXIS [get_bd_intf_pins axis_broadcaster_1/M00_AXIS] [get_bd_intf_pins resonator_dds_0/res_in]
  connect_bd_intf_net -intf_net axis_broadcaster_2_M00_AXIS [get_bd_intf_pins axis_broadcaster_2/M00_AXIS] [get_bd_intf_pins fir_compiler_0/S_AXIS_DATA]
  connect_bd_intf_net -intf_net axis_broadcaster_4_M01_AXIS [get_bd_intf_pins M01_AXIS2] [get_bd_intf_pins axis_broadcaster_4/M01_AXIS]
  connect_bd_intf_net -intf_net bin_to_res_0_res_stream [get_bd_intf_pins axis_broadcaster_1/S_AXIS] [get_bd_intf_pins bin_to_res_0/res_stream]
  connect_bd_intf_net -intf_net fir_compiler_0_M_AXIS_DATA [get_bd_intf_pins axis_broadcaster_4/S_AXIS] [get_bd_intf_pins fir_compiler_0/M_AXIS_DATA]
  connect_bd_intf_net -intf_net resonator_dds_0_res_out [get_bd_intf_pins axis_broadcaster_2/S_AXIS] [get_bd_intf_pins resonator_dds_0/res_out]

  # Create port connections
  connect_bd_net -net S_AXI_clk_0_1 [get_bd_pins S_AXI_clk] [get_bd_pins bin_to_res_0/S_AXI_clk] [get_bd_pins resonator_dds_0/s_axi_clk]
  connect_bd_net -net ap_clk_0_1 [get_bd_pins ap_clk] [get_bd_pins axis_broadcaster_1/aclk] [get_bd_pins axis_broadcaster_2/aclk] [get_bd_pins axis_broadcaster_4/aclk] [get_bd_pins bin_to_res_0/ap_clk] [get_bd_pins fir_compiler_0/aclk] [get_bd_pins resonator_dds_0/ap_clk]
  connect_bd_net -net ap_rst_n_0_1 [get_bd_pins ap_rst_n] [get_bd_pins axis_broadcaster_1/aresetn] [get_bd_pins axis_broadcaster_2/aresetn] [get_bd_pins axis_broadcaster_4/aresetn] [get_bd_pins bin_to_res_0/ap_rst_n] [get_bd_pins resonator_dds_0/ap_rst_n]
  connect_bd_net -net ap_rst_n_S_AXI_clk_1 [get_bd_pins ap_rst_n_S_AXI_clk] [get_bd_pins bin_to_res_0/ap_rst_n_S_AXI_clk] [get_bd_pins resonator_dds_0/ap_rst_n_s_axi_clk]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins resonator_dds_0/generate_tlast] [get_bd_pins xlconstant_0/dout]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: phasematch
proc create_hier_cell_phasematch { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_phasematch() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M00_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M01_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 phases


  # Create pins
  create_bd_pin -dir I -type clk aclk
  create_bd_pin -dir I -type rst ap_rst_n
  create_bd_pin -dir O -from 12 -to 0 dout

  # Create instance: axi_fifo_mm_s_0, and set properties
  set axi_fifo_mm_s_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_fifo_mm_s:4.2 axi_fifo_mm_s_0 ]
  set_property -dict [ list \
   CONFIG.C_AXIS_TDEST_WIDTH {3} \
   CONFIG.C_HAS_AXIS_TDEST {true} \
   CONFIG.C_HAS_AXIS_TKEEP {true} \
   CONFIG.C_TX_FIFO_DEPTH {1024} \
   CONFIG.C_TX_FIFO_PE_THRESHOLD {5} \
   CONFIG.C_TX_FIFO_PF_THRESHOLD {1019} \
   CONFIG.C_USE_RX_DATA {0} \
   CONFIG.C_USE_TX_CTRL {0} \
 ] $axi_fifo_mm_s_0

  # Create instance: axis_broadcaster_3, and set properties
  set axis_broadcaster_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_broadcaster:1.1 axis_broadcaster_3 ]
  set_property -dict [ list \
   CONFIG.M00_TDATA_REMAP {tdata[63:0]} \
   CONFIG.M00_TUSER_REMAP {tuser[35:0]} \
   CONFIG.M01_TDATA_REMAP {tdata[63:0]} \
   CONFIG.M01_TUSER_REMAP {tuser[35:0]} \
 ] $axis_broadcaster_3

  # Create instance: axis_combiner_0, and set properties
  set axis_combiner_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_combiner:1.1 axis_combiner_0 ]
  set_property -dict [ list \
   CONFIG.NUM_SI {4} \
 ] $axis_combiner_0

  # Create instance: axis_interconnect_0, and set properties
  set axis_interconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect:2.1 axis_interconnect_0 ]
  set_property -dict [ list \
   CONFIG.M00_FIFO_DEPTH {16} \
   CONFIG.M00_HAS_REGSLICE {1} \
   CONFIG.M01_FIFO_DEPTH {16} \
   CONFIG.M01_HAS_REGSLICE {1} \
   CONFIG.M02_FIFO_DEPTH {16} \
   CONFIG.M02_HAS_REGSLICE {1} \
   CONFIG.M03_FIFO_DEPTH {16} \
   CONFIG.M03_HAS_REGSLICE {1} \
   CONFIG.M04_FIFO_DEPTH {16} \
   CONFIG.M04_HAS_REGSLICE {1} \
   CONFIG.M05_FIFO_DEPTH {16} \
   CONFIG.M05_HAS_REGSLICE {1} \
   CONFIG.M06_FIFO_DEPTH {16} \
   CONFIG.M06_HAS_REGSLICE {1} \
   CONFIG.M07_FIFO_DEPTH {16} \
   CONFIG.M07_HAS_REGSLICE {1} \
   CONFIG.NUM_MI {4} \
   CONFIG.NUM_SI {1} \
   CONFIG.S00_HAS_REGSLICE {1} \
 ] $axis_interconnect_0

  # Create instance: lowpass_to_phase_0, and set properties
  set lowpass_to_phase_0 [ create_bd_cell -type ip -vlnv MazinLab:mkidgen3:lowpass_to_phase:1.0 lowpass_to_phase_0 ]

  # Create instance: matched_filter_512x0, and set properties
  set matched_filter_512x0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:fir_compiler:7.2 matched_filter_512x0 ]
  set_property -dict [ list \
   CONFIG.BestPrecision {false} \
   CONFIG.Clock_Frequency {300.0} \
   CONFIG.CoefficientSource {COE_File} \
   CONFIG.Coefficient_File {../../../../../../../data/30-tap-unity_512x.coe} \
   CONFIG.Coefficient_Fractional_Bits {15} \
   CONFIG.Coefficient_Reload {true} \
   CONFIG.Coefficient_Sets {512} \
   CONFIG.Coefficient_Sign {Signed} \
   CONFIG.Coefficient_Structure {Non_Symmetric} \
   CONFIG.Coefficient_Width {16} \
   CONFIG.ColumnConfig {30} \
   CONFIG.DATA_Has_TLAST {Vector_Framing} \
   CONFIG.DATA_TUSER_Width {1} \
   CONFIG.Data_Width {16} \
   CONFIG.DisplayReloadOrder {true} \
   CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} \
   CONFIG.Filter_Selection {1} \
   CONFIG.M_DATA_Has_TUSER {Chan_ID_Field} \
   CONFIG.Number_Channels {512} \
   CONFIG.Output_Rounding_Mode {Truncate_LSBs} \
   CONFIG.Output_Width {16} \
   CONFIG.Quantization {Quantize_Only} \
   CONFIG.RateSpecification {Input_Sample_Period} \
   CONFIG.S_CONFIG_Method {By_Channel} \
   CONFIG.S_DATA_Has_FIFO {false} \
   CONFIG.S_DATA_Has_TUSER {Not_Required} \
   CONFIG.SamplePeriod {1} \
   CONFIG.Sample_Frequency {0.001} \
   CONFIG.Select_Pattern {All} \
 ] $matched_filter_512x0

  # Create instance: matched_filter_512x1, and set properties
  set matched_filter_512x1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:fir_compiler:7.2 matched_filter_512x1 ]
  set_property -dict [ list \
   CONFIG.BestPrecision {false} \
   CONFIG.Clock_Frequency {300.0} \
   CONFIG.CoefficientSource {COE_File} \
   CONFIG.Coefficient_File {../../../../../../../data/30-tap-unity_512x.coe} \
   CONFIG.Coefficient_Fractional_Bits {15} \
   CONFIG.Coefficient_Reload {true} \
   CONFIG.Coefficient_Sets {512} \
   CONFIG.Coefficient_Sign {Signed} \
   CONFIG.Coefficient_Structure {Non_Symmetric} \
   CONFIG.Coefficient_Width {16} \
   CONFIG.ColumnConfig {30} \
   CONFIG.DATA_Has_TLAST {Vector_Framing} \
   CONFIG.DATA_TUSER_Width {1} \
   CONFIG.Data_Width {16} \
   CONFIG.DisplayReloadOrder {true} \
   CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} \
   CONFIG.Filter_Selection {1} \
   CONFIG.M_DATA_Has_TUSER {Chan_ID_Field} \
   CONFIG.Number_Channels {512} \
   CONFIG.Output_Rounding_Mode {Truncate_LSBs} \
   CONFIG.Output_Width {16} \
   CONFIG.Quantization {Quantize_Only} \
   CONFIG.RateSpecification {Input_Sample_Period} \
   CONFIG.S_CONFIG_Method {By_Channel} \
   CONFIG.S_DATA_Has_FIFO {false} \
   CONFIG.S_DATA_Has_TUSER {Not_Required} \
   CONFIG.SamplePeriod {1} \
   CONFIG.Sample_Frequency {0.001} \
   CONFIG.Select_Pattern {All} \
 ] $matched_filter_512x1

  # Create instance: matched_filter_512x2, and set properties
  set matched_filter_512x2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:fir_compiler:7.2 matched_filter_512x2 ]
  set_property -dict [ list \
   CONFIG.BestPrecision {false} \
   CONFIG.Clock_Frequency {300.0} \
   CONFIG.CoefficientSource {COE_File} \
   CONFIG.Coefficient_File {../../../../../../../data/30-tap-unity_512x.coe} \
   CONFIG.Coefficient_Fractional_Bits {15} \
   CONFIG.Coefficient_Reload {true} \
   CONFIG.Coefficient_Sets {512} \
   CONFIG.Coefficient_Sign {Signed} \
   CONFIG.Coefficient_Structure {Non_Symmetric} \
   CONFIG.Coefficient_Width {16} \
   CONFIG.ColumnConfig {30} \
   CONFIG.DATA_Has_TLAST {Vector_Framing} \
   CONFIG.DATA_TUSER_Width {1} \
   CONFIG.Data_Width {16} \
   CONFIG.DisplayReloadOrder {true} \
   CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} \
   CONFIG.Filter_Selection {1} \
   CONFIG.M_DATA_Has_TUSER {Not_Required} \
   CONFIG.Number_Channels {512} \
   CONFIG.Output_Rounding_Mode {Truncate_LSBs} \
   CONFIG.Output_Width {16} \
   CONFIG.Quantization {Quantize_Only} \
   CONFIG.RateSpecification {Input_Sample_Period} \
   CONFIG.S_CONFIG_Method {By_Channel} \
   CONFIG.S_DATA_Has_FIFO {false} \
   CONFIG.S_DATA_Has_TUSER {Not_Required} \
   CONFIG.SamplePeriod {1} \
   CONFIG.Sample_Frequency {0.001} \
   CONFIG.Select_Pattern {All} \
 ] $matched_filter_512x2

  # Create instance: matched_filter_512x3, and set properties
  set matched_filter_512x3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:fir_compiler:7.2 matched_filter_512x3 ]
  set_property -dict [ list \
   CONFIG.BestPrecision {false} \
   CONFIG.Clock_Frequency {300.0} \
   CONFIG.CoefficientSource {COE_File} \
   CONFIG.Coefficient_File {../../../../../../../data/30-tap-unity_512x.coe} \
   CONFIG.Coefficient_Fractional_Bits {15} \
   CONFIG.Coefficient_Reload {true} \
   CONFIG.Coefficient_Sets {512} \
   CONFIG.Coefficient_Sign {Signed} \
   CONFIG.Coefficient_Structure {Non_Symmetric} \
   CONFIG.Coefficient_Width {16} \
   CONFIG.ColumnConfig {30} \
   CONFIG.DATA_Has_TLAST {Vector_Framing} \
   CONFIG.DATA_TUSER_Width {1} \
   CONFIG.Data_Width {16} \
   CONFIG.DisplayReloadOrder {true} \
   CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} \
   CONFIG.Filter_Selection {1} \
   CONFIG.M_DATA_Has_TUSER {Not_Required} \
   CONFIG.Number_Channels {512} \
   CONFIG.Output_Rounding_Mode {Truncate_LSBs} \
   CONFIG.Output_Width {16} \
   CONFIG.Quantization {Quantize_Only} \
   CONFIG.RateSpecification {Input_Sample_Period} \
   CONFIG.S_CONFIG_Method {By_Channel} \
   CONFIG.S_DATA_Has_FIFO {false} \
   CONFIG.S_DATA_Has_TUSER {Not_Required} \
   CONFIG.SamplePeriod {1} \
   CONFIG.Sample_Frequency {0.001} \
   CONFIG.Select_Pattern {All} \
 ] $matched_filter_512x3

  # Create instance: phasematch_fir_cfg_0, and set properties
  set phasematch_fir_cfg_0 [ create_bd_cell -type ip -vlnv MazinLab:mkidgen3:phasematch_fir_cfg:1.0 phasematch_fir_cfg_0 ]

  # Create instance: phasematch_fir_cfg_1, and set properties
  set phasematch_fir_cfg_1 [ create_bd_cell -type ip -vlnv MazinLab:mkidgen3:phasematch_fir_cfg:1.0 phasematch_fir_cfg_1 ]

  # Create instance: phasematch_fir_cfg_2, and set properties
  set phasematch_fir_cfg_2 [ create_bd_cell -type ip -vlnv MazinLab:mkidgen3:phasematch_fir_cfg:1.0 phasematch_fir_cfg_2 ]

  # Create instance: phasematch_fir_cfg_3, and set properties
  set phasematch_fir_cfg_3 [ create_bd_cell -type ip -vlnv MazinLab:mkidgen3:phasematch_fir_cfg:1.0 phasematch_fir_cfg_3 ]

  # Create instance: xlconcat_0, and set properties
  set xlconcat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_0 ]
  set_property -dict [ list \
   CONFIG.NUM_PORTS {3} \
 ] $xlconcat_0

  # Create instance: xlconcat_1, and set properties
  set xlconcat_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_1 ]
  set_property -dict [ list \
   CONFIG.NUM_PORTS {6} \
 ] $xlconcat_1

  # Create instance: xlconcat_2, and set properties
  set xlconcat_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_2 ]
  set_property -dict [ list \
   CONFIG.NUM_PORTS {6} \
 ] $xlconcat_2

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins M00_AXIS] [get_bd_intf_pins axis_broadcaster_3/M00_AXIS]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins S_AXI] [get_bd_intf_pins axi_fifo_mm_s_0/S_AXI]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins phases] [get_bd_intf_pins lowpass_to_phase_0/phases]
  connect_bd_intf_net -intf_net S00_AXIS_1 [get_bd_intf_pins axi_fifo_mm_s_0/AXI_STR_TXD] [get_bd_intf_pins axis_interconnect_0/S00_AXIS]
  connect_bd_intf_net -intf_net S_AXIS_1 [get_bd_intf_pins S_AXIS] [get_bd_intf_pins lowpass_to_phase_0/instream]
  connect_bd_intf_net -intf_net axis_combiner_0_M_AXIS [get_bd_intf_pins axis_broadcaster_3/S_AXIS] [get_bd_intf_pins axis_combiner_0/M_AXIS]
  connect_bd_intf_net -intf_net axis_interconnect_0_M02_AXIS [get_bd_intf_pins axis_interconnect_0/M01_AXIS] [get_bd_intf_pins matched_filter_512x1/S_AXIS_RELOAD]
  connect_bd_intf_net -intf_net axis_interconnect_0_M02_AXIS1 [get_bd_intf_pins axis_interconnect_0/M02_AXIS] [get_bd_intf_pins matched_filter_512x2/S_AXIS_RELOAD]
  connect_bd_intf_net -intf_net axis_interconnect_0_M03_AXIS [get_bd_intf_pins axis_interconnect_0/M03_AXIS] [get_bd_intf_pins matched_filter_512x3/S_AXIS_RELOAD]
  connect_bd_intf_net -intf_net axis_switch_0_M00_AXIS [get_bd_intf_pins axis_interconnect_0/M00_AXIS] [get_bd_intf_pins matched_filter_512x0/S_AXIS_RELOAD]
  connect_bd_intf_net -intf_net lowpass_to_phase_0_phase_0 [get_bd_intf_pins lowpass_to_phase_0/phase_0] [get_bd_intf_pins matched_filter_512x0/S_AXIS_DATA]
  connect_bd_intf_net -intf_net lowpass_to_phase_0_phase_1 [get_bd_intf_pins lowpass_to_phase_0/phase_1] [get_bd_intf_pins matched_filter_512x1/S_AXIS_DATA]
  connect_bd_intf_net -intf_net lowpass_to_phase_0_phase_2 [get_bd_intf_pins lowpass_to_phase_0/phase_2] [get_bd_intf_pins matched_filter_512x2/S_AXIS_DATA]
  connect_bd_intf_net -intf_net lowpass_to_phase_0_phase_3 [get_bd_intf_pins lowpass_to_phase_0/phase_3] [get_bd_intf_pins matched_filter_512x3/S_AXIS_DATA]
  connect_bd_intf_net -intf_net matched_filter_512x0_M_AXIS_DATA [get_bd_intf_pins axis_combiner_0/S00_AXIS] [get_bd_intf_pins matched_filter_512x0/M_AXIS_DATA]
  connect_bd_intf_net -intf_net matched_filter_512x1_M_AXIS_DATA [get_bd_intf_pins axis_combiner_0/S01_AXIS] [get_bd_intf_pins matched_filter_512x1/M_AXIS_DATA]
  connect_bd_intf_net -intf_net matched_filter_512x2_M_AXIS_DATA [get_bd_intf_pins axis_combiner_0/S02_AXIS] [get_bd_intf_pins matched_filter_512x2/M_AXIS_DATA]
  connect_bd_intf_net -intf_net matched_filter_512x3_M_AXIS_DATA [get_bd_intf_pins axis_combiner_0/S03_AXIS] [get_bd_intf_pins matched_filter_512x3/M_AXIS_DATA]
  connect_bd_intf_net -intf_net phasematch_fir_cfg_0_config_r [get_bd_intf_pins matched_filter_512x0/S_AXIS_CONFIG] [get_bd_intf_pins phasematch_fir_cfg_0/config_r]
  connect_bd_intf_net -intf_net phasematch_fir_cfg_1_config_r [get_bd_intf_pins matched_filter_512x1/S_AXIS_CONFIG] [get_bd_intf_pins phasematch_fir_cfg_1/config_r]
  connect_bd_intf_net -intf_net phasematch_fir_cfg_2_config_r [get_bd_intf_pins matched_filter_512x2/S_AXIS_CONFIG] [get_bd_intf_pins phasematch_fir_cfg_2/config_r]
  connect_bd_intf_net -intf_net phasematch_fir_cfg_3_config_r [get_bd_intf_pins matched_filter_512x3/S_AXIS_CONFIG] [get_bd_intf_pins phasematch_fir_cfg_3/config_r]

  # Create port connections
  connect_bd_net -net Net [get_bd_pins aclk] [get_bd_pins axi_fifo_mm_s_0/s_axi_aclk] [get_bd_pins axis_broadcaster_3/aclk] [get_bd_pins axis_combiner_0/aclk] [get_bd_pins axis_interconnect_0/ACLK] [get_bd_pins axis_interconnect_0/M00_AXIS_ACLK] [get_bd_pins axis_interconnect_0/M01_AXIS_ACLK] [get_bd_pins axis_interconnect_0/M02_AXIS_ACLK] [get_bd_pins axis_interconnect_0/M03_AXIS_ACLK] [get_bd_pins axis_interconnect_0/S00_AXIS_ACLK] [get_bd_pins lowpass_to_phase_0/ap_clk] [get_bd_pins matched_filter_512x0/aclk] [get_bd_pins matched_filter_512x1/aclk] [get_bd_pins matched_filter_512x2/aclk] [get_bd_pins matched_filter_512x3/aclk] [get_bd_pins phasematch_fir_cfg_0/ap_clk] [get_bd_pins phasematch_fir_cfg_1/ap_clk] [get_bd_pins phasematch_fir_cfg_2/ap_clk] [get_bd_pins phasematch_fir_cfg_3/ap_clk]
  connect_bd_net -net Net3 [get_bd_pins phasematch_fir_cfg_0/ap_rst_n] [get_bd_pins phasematch_fir_cfg_1/ap_rst_n] [get_bd_pins phasematch_fir_cfg_2/ap_rst_n] [get_bd_pins phasematch_fir_cfg_3/ap_rst_n] [get_bd_pins xlconstant_0/dout]
  connect_bd_net -net S00_AXIS_ARESETN_1 [get_bd_pins axi_fifo_mm_s_0/mm2s_prmry_reset_out_n] [get_bd_pins axis_interconnect_0/S00_AXIS_ARESETN]
  connect_bd_net -net ap_rst_n_1 [get_bd_pins ap_rst_n] [get_bd_pins axi_fifo_mm_s_0/s_axi_aresetn] [get_bd_pins axis_broadcaster_3/aresetn] [get_bd_pins axis_combiner_0/aresetn] [get_bd_pins axis_interconnect_0/ARESETN] [get_bd_pins axis_interconnect_0/M00_AXIS_ARESETN] [get_bd_pins axis_interconnect_0/M01_AXIS_ARESETN] [get_bd_pins axis_interconnect_0/M02_AXIS_ARESETN] [get_bd_pins axis_interconnect_0/M03_AXIS_ARESETN] [get_bd_pins lowpass_to_phase_0/ap_rst_n]
  connect_bd_net -net axi_fifo_mm_s_0_interrupt [get_bd_pins axi_fifo_mm_s_0/interrupt] [get_bd_pins xlconcat_0/In2]
  connect_bd_net -net matched_filter_512x0_event_s_config_tlast_missing [get_bd_pins matched_filter_512x0/event_s_config_tlast_missing] [get_bd_pins xlconcat_1/In2]
  connect_bd_net -net matched_filter_512x0_event_s_config_tlast_unexpected [get_bd_pins matched_filter_512x0/event_s_config_tlast_unexpected] [get_bd_pins xlconcat_1/In3]
  connect_bd_net -net matched_filter_512x0_event_s_data_tlast_missing [get_bd_pins matched_filter_512x0/event_s_data_tlast_missing] [get_bd_pins xlconcat_1/In0]
  connect_bd_net -net matched_filter_512x0_event_s_data_tlast_unexpected [get_bd_pins matched_filter_512x0/event_s_data_tlast_unexpected] [get_bd_pins xlconcat_1/In1]
  connect_bd_net -net matched_filter_512x0_event_s_reload_tlast_missing [get_bd_pins matched_filter_512x0/event_s_reload_tlast_missing] [get_bd_pins xlconcat_1/In4]
  connect_bd_net -net matched_filter_512x0_event_s_reload_tlast_unexpected [get_bd_pins matched_filter_512x0/event_s_reload_tlast_unexpected] [get_bd_pins xlconcat_1/In5]
  connect_bd_net -net matched_filter_512x1_event_s_config_tlast_missing [get_bd_pins matched_filter_512x1/event_s_config_tlast_missing] [get_bd_pins xlconcat_2/In2]
  connect_bd_net -net matched_filter_512x1_event_s_config_tlast_unexpected [get_bd_pins matched_filter_512x1/event_s_config_tlast_unexpected] [get_bd_pins xlconcat_2/In3]
  connect_bd_net -net matched_filter_512x1_event_s_data_tlast_missing [get_bd_pins matched_filter_512x1/event_s_data_tlast_missing] [get_bd_pins xlconcat_2/In0]
  connect_bd_net -net matched_filter_512x1_event_s_data_tlast_unexpected [get_bd_pins matched_filter_512x1/event_s_data_tlast_unexpected] [get_bd_pins xlconcat_2/In1]
  connect_bd_net -net matched_filter_512x1_event_s_reload_tlast_missing [get_bd_pins matched_filter_512x1/event_s_reload_tlast_missing] [get_bd_pins xlconcat_2/In4]
  connect_bd_net -net matched_filter_512x1_event_s_reload_tlast_unexpected [get_bd_pins matched_filter_512x1/event_s_reload_tlast_unexpected] [get_bd_pins xlconcat_2/In5]
  connect_bd_net -net xlconcat_0_dout [get_bd_pins dout] [get_bd_pins xlconcat_0/dout]
  connect_bd_net -net xlconcat_1_dout [get_bd_pins xlconcat_0/In0] [get_bd_pins xlconcat_1/dout]
  connect_bd_net -net xlconcat_2_dout [get_bd_pins xlconcat_0/In1] [get_bd_pins xlconcat_2/dout]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: opfb
proc create_hier_cell_opfb { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_opfb() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 output_r


  # Create pins
  create_bd_pin -dir I -type clk aclk

  # Create instance: adc_to_opfb_0, and set properties
  set adc_to_opfb_0 [ create_bd_cell -type ip -vlnv MazinLab:mkidgen3:adc_to_opfb:1.1 adc_to_opfb_0 ]

  # Create instance: fft
  create_hier_cell_fft $hier_obj fft

  # Create instance: filters
  create_hier_cell_filters $hier_obj filters

  # Create instance: fir_to_fft_0, and set properties
  set fir_to_fft_0 [ create_bd_cell -type ip -vlnv MazinLab:mkidgen3:fir_to_fft:1.11 fir_to_fft_0 ]

  # Create instance: register_slice
  create_hier_cell_register_slice $hier_obj register_slice

  # Create instance: xlconstant_1, and set properties
  set xlconstant_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_1 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {1} \
   CONFIG.CONST_WIDTH {1} \
 ] $xlconstant_1

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins output_r] [get_bd_intf_pins fft/output_r]
  connect_bd_intf_net -intf_net S_AXIS11_1 [get_bd_intf_pins filters/M_AXIS_DATA11] [get_bd_intf_pins register_slice/S_AXIS11]
  connect_bd_intf_net -intf_net S_AXIS13_1 [get_bd_intf_pins filters/M_AXIS_DATA13] [get_bd_intf_pins register_slice/S_AXIS13]
  connect_bd_intf_net -intf_net S_AXIS15_1 [get_bd_intf_pins filters/M_AXIS_DATA15] [get_bd_intf_pins register_slice/S_AXIS15]
  connect_bd_intf_net -intf_net S_AXIS2_1 [get_bd_intf_pins filters/M_AXIS_DATA2] [get_bd_intf_pins register_slice/S_AXIS2]
  connect_bd_intf_net -intf_net S_AXIS5_1 [get_bd_intf_pins filters/M_AXIS_DATA5] [get_bd_intf_pins register_slice/S_AXIS5]
  connect_bd_intf_net -intf_net S_AXIS7_1 [get_bd_intf_pins filters/M_AXIS_DATA7] [get_bd_intf_pins register_slice/S_AXIS7]
  connect_bd_intf_net -intf_net S_AXIS9_1 [get_bd_intf_pins filters/M_AXIS_DATA9] [get_bd_intf_pins register_slice/S_AXIS9]
  connect_bd_intf_net -intf_net filters_M_AXIS_DATA1 [get_bd_intf_pins filters/M_AXIS_DATA1] [get_bd_intf_pins register_slice/S_AXIS1]
  connect_bd_intf_net -intf_net filters_M_AXIS_DATA3 [get_bd_intf_pins filters/M_AXIS_DATA3] [get_bd_intf_pins register_slice/S_AXIS3]
  connect_bd_intf_net -intf_net filters_M_AXIS_DATA4 [get_bd_intf_pins filters/M_AXIS_DATA4] [get_bd_intf_pins register_slice/S_AXIS4]
  connect_bd_intf_net -intf_net filters_M_AXIS_DATA6 [get_bd_intf_pins filters/M_AXIS_DATA6] [get_bd_intf_pins register_slice/S_AXIS6]
  connect_bd_intf_net -intf_net filters_M_AXIS_DATA8 [get_bd_intf_pins filters/M_AXIS_DATA8] [get_bd_intf_pins register_slice/S_AXIS8]
  connect_bd_intf_net -intf_net filters_M_AXIS_DATA10 [get_bd_intf_pins filters/M_AXIS_DATA10] [get_bd_intf_pins register_slice/S_AXIS10]
  connect_bd_intf_net -intf_net filters_M_AXIS_DATA12 [get_bd_intf_pins filters/M_AXIS_DATA12] [get_bd_intf_pins register_slice/S_AXIS12]
  connect_bd_intf_net -intf_net filters_M_AXIS_DATA14 [get_bd_intf_pins filters/M_AXIS_DATA14] [get_bd_intf_pins register_slice/S_AXIS14]
  connect_bd_intf_net -intf_net pfb_firs_M_AXIS_DATA [get_bd_intf_pins filters/M_AXIS_DATA] [get_bd_intf_pins register_slice/S_AXIS]

  # Create port connections
  connect_bd_net -net rst_ps8_0_99M_peripheral_aresetn [get_bd_pins adc_to_opfb_0/ap_rst_n] [get_bd_pins fft/ap_rst_n] [get_bd_pins filters/aresetn] [get_bd_pins fir_to_fft_0/ap_rst_n] [get_bd_pins register_slice/aresetn] [get_bd_pins xlconstant_1/dout]
  connect_bd_net -net zynq_ultra_ps_e_0_pl_clk0 [get_bd_pins aclk] [get_bd_pins adc_to_opfb_0/ap_clk] [get_bd_pins fft/aclk] [get_bd_pins filters/aclk] [get_bd_pins fir_to_fft_0/ap_clk] [get_bd_pins register_slice/aclk]

  # Restore current instance
  current_bd_instance $oldCurInst
}


# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports

  # Create ports

  # Create instance: opfb
  create_hier_cell_opfb [current_bd_instance .] opfb

  # Create instance: phasematch
  create_hier_cell_phasematch [current_bd_instance .] phasematch

  # Create instance: reschan
  create_hier_cell_reschan [current_bd_instance .] reschan

  # Create port connections

  # Create address segments


  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


common::send_gid_msg -ssname BD::TCL -id 2053 -severity "WARNING" "This Tcl script was generated from a block design that has not been validated. It is possible that design <$design_name> may result in errors during validation."

