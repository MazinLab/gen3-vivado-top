
################################################################
# This is a generated script based on design: test_channelizer
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
set scripts_vivado_version 2019.2
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   catch {common::send_msg_id "BD_TCL-109" "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source test_channelizer_script.tcl

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
set design_name test_channelizer

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
      common::send_msg_id "BD_TCL-001" "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_msg_id "BD_TCL-002" "INFO" "Constructing design in IPI design <$cur_design>..."

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

   common::send_msg_id "BD_TCL-003" "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_msg_id "BD_TCL-004" "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_msg_id "BD_TCL-005" "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_msg_id "BD_TCL-114" "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
xilinx.com:ip:axi_dma:7.1\
xilinx.com:ip:axi_intc:4.1\
xilinx.com:ip:smartconnect:1.0\
xilinx.com:ip:axis_broadcaster:1.1\
xilinx.com:ip:axis_data_fifo:2.0\
xilinx.com:ip:proc_sys_reset:5.0\
xilinx.com:ip:system_ila:1.1\
xilinx.com:ip:xlconcat:2.1\
xilinx.com:ip:zynq_ultra_ps_e:3.3\
MazinLab:mkidgen3:adc_to_opfb:1.0\
xilinx.com:ip:axis_register_slice:1.1\
MazinLab:mkidgen3:fir_to_fft:1.10\
MazinLab:mkidgen3:pkg_fft_output:0.2\
MazinLab:mkidgen3:ssrfft_16x4096_axis:1.0\
xilinx.com:ip:xlconstant:1.1\
MazinLab:mkidgen3:bin_to_res:1.0\
xilinx.com:ip:fir_compiler:7.2\
MazinLab:mkidgen3:resonator_dds:1.0\
MazinLab:mkidgen3:opfb_fir_cfg:0.1\
"

   set list_ips_missing ""
   common::send_msg_id "BD_TCL-006" "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_msg_id "BD_TCL-115" "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

if { $bCheckIPsPassed != 1 } {
  common::send_msg_id "BD_TCL-1003" "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################


# Hierarchical cell: filters
proc create_hier_cell_filters { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_filters() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
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
   CONFIG.Coefficient_File {../../../../../../../data/lane0.coe} \
   CONFIG.Coefficient_Fractional_Bits {26} \
   CONFIG.Coefficient_Sets {256} \
   CONFIG.Coefficient_Sign {Signed} \
   CONFIG.Coefficient_Structure {Inferred} \
   CONFIG.Coefficient_Width {16} \
   CONFIG.ColumnConfig {8} \
   CONFIG.DATA_Has_TLAST {Vector_Framing} \
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
   CONFIG.Coefficient_File {../../../../../../../data/lane5.coe} \
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

# Hierarchical cell: reschan
proc create_hier_cell_reschan { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_reschan() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
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

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS_DATA

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 iq_stream

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:axis_rtl:1.0 res_stream

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_bin_to_res

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_resonator_dds


  # Create pins
  create_bd_pin -dir I -type clk S_AXI_clk
  create_bd_pin -dir I -type clk ap_clk
  create_bd_pin -dir I -type rst ap_rst_n
  create_bd_pin -dir I -type rst ap_rst_n_S_AXI_clk

  # Create instance: bin_to_res_0, and set properties
  set bin_to_res_0 [ create_bd_cell -type ip -vlnv MazinLab:mkidgen3:bin_to_res:1.0 bin_to_res_0 ]

  # Create instance: fir_compiler_0, and set properties
  set fir_compiler_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:fir_compiler:7.2 fir_compiler_0 ]
  set_property -dict [ list \
   CONFIG.BestPrecision {true} \
   CONFIG.Clock_Frequency {300.0} \
   CONFIG.CoefficientSource {COE_File} \
   CONFIG.Coefficient_File {../../../../../../../../gen3-reschan/data/FCLowpass.coe} \
   CONFIG.Coefficient_Fractional_Bits {17} \
   CONFIG.Coefficient_Sets {1} \
   CONFIG.Coefficient_Sign {Signed} \
   CONFIG.Coefficient_Structure {Inferred} \
   CONFIG.Coefficient_Width {16} \
   CONFIG.ColumnConfig {5} \
   CONFIG.DATA_Has_TLAST {Packet_Framing} \
   CONFIG.DATA_TUSER_Width {8} \
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
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins s_axi_resonator_dds] [get_bd_intf_pins resonator_dds_0/s_axi_control]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins s_axi_bin_to_res] [get_bd_intf_pins bin_to_res_0/s_axi_control]
  connect_bd_intf_net -intf_net Conn4 [get_bd_intf_pins iq_stream] [get_bd_intf_pins bin_to_res_0/iq_stream]
  connect_bd_intf_net -intf_net bin_to_res_0_res_stream [get_bd_intf_pins bin_to_res_0/res_stream] [get_bd_intf_pins resonator_dds_0/res_in]
  connect_bd_intf_net -intf_net [get_bd_intf_nets bin_to_res_0_res_stream] [get_bd_intf_pins res_stream] [get_bd_intf_pins resonator_dds_0/res_in]
  connect_bd_intf_net -intf_net fir_compiler_0_M_AXIS_DATA [get_bd_intf_pins M_AXIS_DATA] [get_bd_intf_pins fir_compiler_0/M_AXIS_DATA]
  connect_bd_intf_net -intf_net resonator_dds_0_res_out [get_bd_intf_pins fir_compiler_0/S_AXIS_DATA] [get_bd_intf_pins resonator_dds_0/res_out]
  connect_bd_intf_net -intf_net [get_bd_intf_nets resonator_dds_0_res_out] [get_bd_intf_pins S_AXIS_DATA] [get_bd_intf_pins fir_compiler_0/S_AXIS_DATA]

  # Create port connections
  connect_bd_net -net S_AXI_clk_0_1 [get_bd_pins S_AXI_clk] [get_bd_pins bin_to_res_0/S_AXI_clk] [get_bd_pins resonator_dds_0/s_axi_clk]
  connect_bd_net -net ap_clk_0_1 [get_bd_pins ap_clk] [get_bd_pins bin_to_res_0/ap_clk] [get_bd_pins fir_compiler_0/aclk] [get_bd_pins resonator_dds_0/ap_clk]
  connect_bd_net -net ap_rst_n_0_1 [get_bd_pins ap_rst_n] [get_bd_pins bin_to_res_0/ap_rst_n] [get_bd_pins resonator_dds_0/ap_rst_n]
  connect_bd_net -net ap_rst_n_S_AXI_clk_1 [get_bd_pins ap_rst_n_S_AXI_clk] [get_bd_pins bin_to_res_0/ap_rst_n_S_AXI_clk] [get_bd_pins resonator_dds_0/ap_rst_n_s_axi_clk]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins resonator_dds_0/generate_tlast] [get_bd_pins xlconstant_0/dout]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: opfb
proc create_hier_cell_opfb { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_opfb() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
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
  set adc_to_opfb_0 [ create_bd_cell -type ip -vlnv MazinLab:mkidgen3:adc_to_opfb:1.0 adc_to_opfb_0 ]

  # Create instance: axis_register_slice_1, and set properties
  set axis_register_slice_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axis_register_slice_1 ]

  # Create instance: axis_register_slice_2, and set properties
  set axis_register_slice_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axis_register_slice_2 ]

  # Create instance: axis_register_slice_3, and set properties
  set axis_register_slice_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axis_register_slice_3 ]

  # Create instance: axis_register_slice_4, and set properties
  set axis_register_slice_4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axis_register_slice_4 ]

  # Create instance: axis_register_slice_5, and set properties
  set axis_register_slice_5 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axis_register_slice_5 ]

  # Create instance: axis_register_slice_6, and set properties
  set axis_register_slice_6 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axis_register_slice_6 ]

  # Create instance: axis_register_slice_7, and set properties
  set axis_register_slice_7 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axis_register_slice_7 ]

  # Create instance: axis_register_slice_8, and set properties
  set axis_register_slice_8 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axis_register_slice_8 ]

  # Create instance: axis_register_slice_9, and set properties
  set axis_register_slice_9 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axis_register_slice_9 ]

  # Create instance: axis_register_slice_10, and set properties
  set axis_register_slice_10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axis_register_slice_10 ]

  # Create instance: axis_register_slice_11, and set properties
  set axis_register_slice_11 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axis_register_slice_11 ]

  # Create instance: axis_register_slice_12, and set properties
  set axis_register_slice_12 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axis_register_slice_12 ]

  # Create instance: axis_register_slice_13, and set properties
  set axis_register_slice_13 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axis_register_slice_13 ]

  # Create instance: axis_register_slice_14, and set properties
  set axis_register_slice_14 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axis_register_slice_14 ]

  # Create instance: axis_register_slice_15, and set properties
  set axis_register_slice_15 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axis_register_slice_15 ]

  # Create instance: axis_register_slice_16, and set properties
  set axis_register_slice_16 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axis_register_slice_16 ]

  # Create instance: axis_register_slice_17, and set properties
  set axis_register_slice_17 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axis_register_slice_17 ]

  # Create instance: axis_register_slice_18, and set properties
  set axis_register_slice_18 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axis_register_slice_18 ]

  # Create instance: filters
  create_hier_cell_filters $hier_obj filters

  # Create instance: fir_to_fft_0, and set properties
  set fir_to_fft_0 [ create_bd_cell -type ip -vlnv MazinLab:mkidgen3:fir_to_fft:1.10 fir_to_fft_0 ]

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

  # Create instance: xlconstant_1, and set properties
  set xlconstant_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_1 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {1} \
   CONFIG.CONST_WIDTH {1} \
 ] $xlconstant_1

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins output_r] [get_bd_intf_pins pkg_fft_output_0/output_r]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins S_AXIS] [get_bd_intf_pins axis_register_slice_1/S_AXIS]
  connect_bd_intf_net -intf_net S_AXIS_DATA10_1 [get_bd_intf_pins adc_to_opfb_0/lane_10] [get_bd_intf_pins filters/S_AXIS_DATA10]
  connect_bd_intf_net -intf_net S_AXIS_DATA12_1 [get_bd_intf_pins adc_to_opfb_0/lane_12] [get_bd_intf_pins filters/S_AXIS_DATA12]
  connect_bd_intf_net -intf_net S_AXIS_DATA14_1 [get_bd_intf_pins adc_to_opfb_0/lane_14] [get_bd_intf_pins filters/S_AXIS_DATA14]
  connect_bd_intf_net -intf_net S_AXIS_DATA1_1 [get_bd_intf_pins adc_to_opfb_0/lane_1] [get_bd_intf_pins filters/S_AXIS_DATA1]
  connect_bd_intf_net -intf_net S_AXIS_DATA4_1 [get_bd_intf_pins adc_to_opfb_0/lane_4] [get_bd_intf_pins filters/S_AXIS_DATA4]
  connect_bd_intf_net -intf_net S_AXIS_DATA6_1 [get_bd_intf_pins adc_to_opfb_0/lane_6] [get_bd_intf_pins filters/S_AXIS_DATA6]
  connect_bd_intf_net -intf_net S_AXIS_DATA8_1 [get_bd_intf_pins adc_to_opfb_0/lane_8] [get_bd_intf_pins filters/S_AXIS_DATA8]
  connect_bd_intf_net -intf_net S_AXIS_Q_1 [get_bd_intf_pins S_AXIS1] [get_bd_intf_pins axis_register_slice_2/S_AXIS]
  connect_bd_intf_net -intf_net adc_to_opfb_0_lane_2 [get_bd_intf_pins adc_to_opfb_0/lane_2] [get_bd_intf_pins filters/S_AXIS_DATA2]
  connect_bd_intf_net -intf_net adc_to_opfb_0_lane_3 [get_bd_intf_pins adc_to_opfb_0/lane_3] [get_bd_intf_pins filters/S_AXIS_DATA3]
  connect_bd_intf_net -intf_net adc_to_opfb_0_lane_5 [get_bd_intf_pins adc_to_opfb_0/lane_5] [get_bd_intf_pins filters/S_AXIS_DATA5]
  connect_bd_intf_net -intf_net adc_to_opfb_0_lane_7 [get_bd_intf_pins adc_to_opfb_0/lane_7] [get_bd_intf_pins filters/S_AXIS_DATA7]
  connect_bd_intf_net -intf_net adc_to_opfb_0_lane_9 [get_bd_intf_pins adc_to_opfb_0/lane_9] [get_bd_intf_pins filters/S_AXIS_DATA9]
  connect_bd_intf_net -intf_net adc_to_opfb_0_lane_11 [get_bd_intf_pins adc_to_opfb_0/lane_11] [get_bd_intf_pins filters/S_AXIS_DATA11]
  connect_bd_intf_net -intf_net adc_to_opfb_0_lane_13 [get_bd_intf_pins adc_to_opfb_0/lane_13] [get_bd_intf_pins filters/S_AXIS_DATA13]
  connect_bd_intf_net -intf_net adc_to_opfb_0_lane_15 [get_bd_intf_pins adc_to_opfb_0/lane_15] [get_bd_intf_pins filters/S_AXIS_DATA15]
  connect_bd_intf_net -intf_net adc_to_opfb_0_lane_data_0 [get_bd_intf_pins adc_to_opfb_0/lane_0] [get_bd_intf_pins filters/S_AXIS_DATA]
  connect_bd_intf_net -intf_net axis_register_slice_10_M_AXIS [get_bd_intf_pins axis_register_slice_10/M_AXIS] [get_bd_intf_pins fir_to_fft_0/input_10]
  connect_bd_intf_net -intf_net axis_register_slice_11_M_AXIS [get_bd_intf_pins axis_register_slice_11/M_AXIS] [get_bd_intf_pins fir_to_fft_0/input_11]
  connect_bd_intf_net -intf_net axis_register_slice_12_M_AXIS [get_bd_intf_pins axis_register_slice_12/M_AXIS] [get_bd_intf_pins fir_to_fft_0/input_12]
  connect_bd_intf_net -intf_net axis_register_slice_13_M_AXIS [get_bd_intf_pins axis_register_slice_13/M_AXIS] [get_bd_intf_pins fir_to_fft_0/input_13]
  connect_bd_intf_net -intf_net axis_register_slice_14_M_AXIS [get_bd_intf_pins axis_register_slice_14/M_AXIS] [get_bd_intf_pins fir_to_fft_0/input_14]
  connect_bd_intf_net -intf_net axis_register_slice_15_M_AXIS [get_bd_intf_pins axis_register_slice_15/M_AXIS] [get_bd_intf_pins fir_to_fft_0/input_15]
  connect_bd_intf_net -intf_net axis_register_slice_16_M_AXIS [get_bd_intf_pins axis_register_slice_16/M_AXIS] [get_bd_intf_pins fir_to_fft_0/input_1]
  connect_bd_intf_net -intf_net axis_register_slice_17_M_AXIS [get_bd_intf_pins axis_register_slice_17/M_AXIS] [get_bd_intf_pins fir_to_fft_0/input_2]
  connect_bd_intf_net -intf_net axis_register_slice_18_M_AXIS [get_bd_intf_pins axis_register_slice_18/M_AXIS] [get_bd_intf_pins fir_to_fft_0/input_3]
  connect_bd_intf_net -intf_net axis_register_slice_1_M_AXIS [get_bd_intf_pins adc_to_opfb_0/istream_data] [get_bd_intf_pins axis_register_slice_1/M_AXIS]
  connect_bd_intf_net -intf_net axis_register_slice_2_M_AXIS [get_bd_intf_pins adc_to_opfb_0/qstream_data] [get_bd_intf_pins axis_register_slice_2/M_AXIS]
  connect_bd_intf_net -intf_net axis_register_slice_3_M_AXIS [get_bd_intf_pins axis_register_slice_3/M_AXIS] [get_bd_intf_pins fir_to_fft_0/input_0]
  connect_bd_intf_net -intf_net axis_register_slice_4_M_AXIS [get_bd_intf_pins axis_register_slice_4/M_AXIS] [get_bd_intf_pins fir_to_fft_0/input_4]
  connect_bd_intf_net -intf_net axis_register_slice_5_M_AXIS [get_bd_intf_pins axis_register_slice_5/M_AXIS] [get_bd_intf_pins fir_to_fft_0/input_5]
  connect_bd_intf_net -intf_net axis_register_slice_6_M_AXIS [get_bd_intf_pins axis_register_slice_6/M_AXIS] [get_bd_intf_pins fir_to_fft_0/input_6]
  connect_bd_intf_net -intf_net axis_register_slice_7_M_AXIS [get_bd_intf_pins axis_register_slice_7/M_AXIS] [get_bd_intf_pins fir_to_fft_0/input_7]
  connect_bd_intf_net -intf_net axis_register_slice_8_M_AXIS [get_bd_intf_pins axis_register_slice_8/M_AXIS] [get_bd_intf_pins fir_to_fft_0/input_8]
  connect_bd_intf_net -intf_net axis_register_slice_9_M_AXIS [get_bd_intf_pins axis_register_slice_9/M_AXIS] [get_bd_intf_pins fir_to_fft_0/input_9]
  connect_bd_intf_net -intf_net fir_to_fft_0_output_0 [get_bd_intf_pins fir_to_fft_0/output_0] [get_bd_intf_pins ssrfft_16x4096_axis_0/iq_0]
  connect_bd_intf_net -intf_net fir_to_fft_0_output_1 [get_bd_intf_pins fir_to_fft_0/output_1] [get_bd_intf_pins ssrfft_16x4096_axis_0/iq_1]
  connect_bd_intf_net -intf_net fir_to_fft_0_output_2 [get_bd_intf_pins fir_to_fft_0/output_2] [get_bd_intf_pins ssrfft_16x4096_axis_0/iq_2]
  connect_bd_intf_net -intf_net fir_to_fft_0_output_3 [get_bd_intf_pins fir_to_fft_0/output_3] [get_bd_intf_pins ssrfft_16x4096_axis_0/iq_3]
  connect_bd_intf_net -intf_net fir_to_fft_0_output_4 [get_bd_intf_pins fir_to_fft_0/output_4] [get_bd_intf_pins ssrfft_16x4096_axis_0/iq_4]
  connect_bd_intf_net -intf_net fir_to_fft_0_output_5 [get_bd_intf_pins fir_to_fft_0/output_5] [get_bd_intf_pins ssrfft_16x4096_axis_0/iq_5]
  connect_bd_intf_net -intf_net fir_to_fft_0_output_6 [get_bd_intf_pins fir_to_fft_0/output_6] [get_bd_intf_pins ssrfft_16x4096_axis_0/iq_6]
  connect_bd_intf_net -intf_net fir_to_fft_0_output_7 [get_bd_intf_pins fir_to_fft_0/output_7] [get_bd_intf_pins ssrfft_16x4096_axis_0/iq_7]
  connect_bd_intf_net -intf_net fir_to_fft_0_output_8 [get_bd_intf_pins fir_to_fft_0/output_8] [get_bd_intf_pins ssrfft_16x4096_axis_0/iq_8]
  connect_bd_intf_net -intf_net fir_to_fft_0_output_9 [get_bd_intf_pins fir_to_fft_0/output_9] [get_bd_intf_pins ssrfft_16x4096_axis_0/iq_9]
  connect_bd_intf_net -intf_net fir_to_fft_0_output_10 [get_bd_intf_pins fir_to_fft_0/output_10] [get_bd_intf_pins ssrfft_16x4096_axis_0/iq_10]
  connect_bd_intf_net -intf_net fir_to_fft_0_output_11 [get_bd_intf_pins fir_to_fft_0/output_11] [get_bd_intf_pins ssrfft_16x4096_axis_0/iq_11]
  connect_bd_intf_net -intf_net fir_to_fft_0_output_12 [get_bd_intf_pins fir_to_fft_0/output_12] [get_bd_intf_pins ssrfft_16x4096_axis_0/iq_12]
  connect_bd_intf_net -intf_net fir_to_fft_0_output_13 [get_bd_intf_pins fir_to_fft_0/output_13] [get_bd_intf_pins ssrfft_16x4096_axis_0/iq_13]
  connect_bd_intf_net -intf_net fir_to_fft_0_output_14 [get_bd_intf_pins fir_to_fft_0/output_14] [get_bd_intf_pins ssrfft_16x4096_axis_0/iq_14]
  connect_bd_intf_net -intf_net fir_to_fft_0_output_15 [get_bd_intf_pins fir_to_fft_0/output_15] [get_bd_intf_pins ssrfft_16x4096_axis_0/iq_15]
  connect_bd_intf_net -intf_net pfb_firs_M_AXIS_DATA [get_bd_intf_pins axis_register_slice_3/S_AXIS] [get_bd_intf_pins filters/M_AXIS_DATA]
  connect_bd_intf_net -intf_net pfb_firs_M_AXIS_DATA1 [get_bd_intf_pins axis_register_slice_16/S_AXIS] [get_bd_intf_pins filters/M_AXIS_DATA1]
  connect_bd_intf_net -intf_net pfb_firs_M_AXIS_DATA2 [get_bd_intf_pins axis_register_slice_17/S_AXIS] [get_bd_intf_pins filters/M_AXIS_DATA2]
  connect_bd_intf_net -intf_net pfb_firs_M_AXIS_DATA3 [get_bd_intf_pins axis_register_slice_18/S_AXIS] [get_bd_intf_pins filters/M_AXIS_DATA3]
  connect_bd_intf_net -intf_net pfb_firs_M_AXIS_DATA4 [get_bd_intf_pins axis_register_slice_4/S_AXIS] [get_bd_intf_pins filters/M_AXIS_DATA4]
  connect_bd_intf_net -intf_net pfb_firs_M_AXIS_DATA5 [get_bd_intf_pins axis_register_slice_5/S_AXIS] [get_bd_intf_pins filters/M_AXIS_DATA5]
  connect_bd_intf_net -intf_net pfb_firs_M_AXIS_DATA6 [get_bd_intf_pins axis_register_slice_6/S_AXIS] [get_bd_intf_pins filters/M_AXIS_DATA6]
  connect_bd_intf_net -intf_net pfb_firs_M_AXIS_DATA7 [get_bd_intf_pins axis_register_slice_7/S_AXIS] [get_bd_intf_pins filters/M_AXIS_DATA7]
  connect_bd_intf_net -intf_net pfb_firs_M_AXIS_DATA8 [get_bd_intf_pins axis_register_slice_8/S_AXIS] [get_bd_intf_pins filters/M_AXIS_DATA8]
  connect_bd_intf_net -intf_net pfb_firs_M_AXIS_DATA9 [get_bd_intf_pins axis_register_slice_9/S_AXIS] [get_bd_intf_pins filters/M_AXIS_DATA9]
  connect_bd_intf_net -intf_net pfb_firs_M_AXIS_DATA10 [get_bd_intf_pins axis_register_slice_10/S_AXIS] [get_bd_intf_pins filters/M_AXIS_DATA10]
  connect_bd_intf_net -intf_net pfb_firs_M_AXIS_DATA11 [get_bd_intf_pins axis_register_slice_11/S_AXIS] [get_bd_intf_pins filters/M_AXIS_DATA11]
  connect_bd_intf_net -intf_net pfb_firs_M_AXIS_DATA12 [get_bd_intf_pins axis_register_slice_12/S_AXIS] [get_bd_intf_pins filters/M_AXIS_DATA12]
  connect_bd_intf_net -intf_net pfb_firs_M_AXIS_DATA13 [get_bd_intf_pins axis_register_slice_13/S_AXIS] [get_bd_intf_pins filters/M_AXIS_DATA13]
  connect_bd_intf_net -intf_net pfb_firs_M_AXIS_DATA14 [get_bd_intf_pins axis_register_slice_14/S_AXIS] [get_bd_intf_pins filters/M_AXIS_DATA14]
  connect_bd_intf_net -intf_net pfb_firs_M_AXIS_DATA15 [get_bd_intf_pins axis_register_slice_15/S_AXIS] [get_bd_intf_pins filters/M_AXIS_DATA15]

  # Create port connections
  connect_bd_net -net rst_ps8_0_99M_peripheral_aresetn [get_bd_pins adc_to_opfb_0/ap_rst_n] [get_bd_pins axis_register_slice_1/aresetn] [get_bd_pins axis_register_slice_10/aresetn] [get_bd_pins axis_register_slice_11/aresetn] [get_bd_pins axis_register_slice_12/aresetn] [get_bd_pins axis_register_slice_13/aresetn] [get_bd_pins axis_register_slice_14/aresetn] [get_bd_pins axis_register_slice_15/aresetn] [get_bd_pins axis_register_slice_16/aresetn] [get_bd_pins axis_register_slice_17/aresetn] [get_bd_pins axis_register_slice_18/aresetn] [get_bd_pins axis_register_slice_2/aresetn] [get_bd_pins axis_register_slice_3/aresetn] [get_bd_pins axis_register_slice_4/aresetn] [get_bd_pins axis_register_slice_5/aresetn] [get_bd_pins axis_register_slice_6/aresetn] [get_bd_pins axis_register_slice_7/aresetn] [get_bd_pins axis_register_slice_8/aresetn] [get_bd_pins axis_register_slice_9/aresetn] [get_bd_pins filters/aresetn] [get_bd_pins fir_to_fft_0/ap_rst_n] [get_bd_pins pkg_fft_output_0/ap_rst_n] [get_bd_pins xlconstant_1/dout]
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
  connect_bd_net -net zynq_ultra_ps_e_0_pl_clk0 [get_bd_pins aclk] [get_bd_pins adc_to_opfb_0/ap_clk] [get_bd_pins axis_register_slice_1/aclk] [get_bd_pins axis_register_slice_10/aclk] [get_bd_pins axis_register_slice_11/aclk] [get_bd_pins axis_register_slice_12/aclk] [get_bd_pins axis_register_slice_13/aclk] [get_bd_pins axis_register_slice_14/aclk] [get_bd_pins axis_register_slice_15/aclk] [get_bd_pins axis_register_slice_16/aclk] [get_bd_pins axis_register_slice_17/aclk] [get_bd_pins axis_register_slice_18/aclk] [get_bd_pins axis_register_slice_2/aclk] [get_bd_pins axis_register_slice_3/aclk] [get_bd_pins axis_register_slice_4/aclk] [get_bd_pins axis_register_slice_5/aclk] [get_bd_pins axis_register_slice_6/aclk] [get_bd_pins axis_register_slice_7/aclk] [get_bd_pins axis_register_slice_8/aclk] [get_bd_pins axis_register_slice_9/aclk] [get_bd_pins filters/aclk] [get_bd_pins fir_to_fft_0/ap_clk] [get_bd_pins pkg_fft_output_0/ap_clk] [get_bd_pins ssrfft_16x4096_axis_0/clk]

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
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports

  # Create ports

  # Create instance: axi_dma_0, and set properties
  set axi_dma_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 axi_dma_0 ]
  set_property -dict [ list \
   CONFIG.c_include_sg {0} \
   CONFIG.c_m_axi_mm2s_data_width {256} \
   CONFIG.c_m_axis_mm2s_tdata_width {256} \
   CONFIG.c_mm2s_burst_size {128} \
   CONFIG.c_s2mm_burst_size {128} \
   CONFIG.c_sg_include_stscntrl_strm {0} \
   CONFIG.c_sg_length_width {17} \
 ] $axi_dma_0

  # Create instance: axi_intc_0, and set properties
  set axi_intc_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc:4.1 axi_intc_0 ]

  # Create instance: axi_smc, and set properties
  set axi_smc [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 axi_smc ]
  set_property -dict [ list \
   CONFIG.NUM_SI {2} \
 ] $axi_smc

  # Create instance: axis_broadcaster_0, and set properties
  set axis_broadcaster_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_broadcaster:1.1 axis_broadcaster_0 ]
  set_property -dict [ list \
   CONFIG.M00_TDATA_REMAP {tdata[127:0]} \
   CONFIG.M01_TDATA_REMAP {tdata[255:128]} \
   CONFIG.M_TDATA_NUM_BYTES {16} \
   CONFIG.S_TDATA_NUM_BYTES {32} \
 ] $axis_broadcaster_0

  # Create instance: axis_data_fifo_0, and set properties
  set axis_data_fifo_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 axis_data_fifo_0 ]
  set_property -dict [ list \
   CONFIG.FIFO_DEPTH {2048} \
   CONFIG.FIFO_MODE {2} \
 ] $axis_data_fifo_0

  # Create instance: axis_data_fifo_1, and set properties
  set axis_data_fifo_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 axis_data_fifo_1 ]
  set_property -dict [ list \
   CONFIG.FIFO_DEPTH {2048} \
 ] $axis_data_fifo_1

  # Create instance: opfb
  create_hier_cell_opfb [current_bd_instance .] opfb

  # Create instance: ps8_0_axi_periph, and set properties
  set ps8_0_axi_periph [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 ps8_0_axi_periph ]
  set_property -dict [ list \
   CONFIG.NUM_MI {4} \
 ] $ps8_0_axi_periph

  # Create instance: reschan
  create_hier_cell_reschan [current_bd_instance .] reschan

  # Create instance: rst_ps8_0_99M, and set properties
  set rst_ps8_0_99M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_ps8_0_99M ]

  # Create instance: system_ila_0, and set properties
  set system_ila_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:system_ila:1.1 system_ila_0 ]
  set_property -dict [ list \
   CONFIG.C_BRAM_CNT {0.5} \
   CONFIG.C_DATA_DEPTH {2048} \
   CONFIG.C_INPUT_PIPE_STAGES {3} \
   CONFIG.C_MON_TYPE {MIX} \
   CONFIG.C_NUM_MONITOR_SLOTS {6} \
   CONFIG.C_NUM_OF_PROBES {1} \
   CONFIG.C_PROBE0_TYPE {0} \
   CONFIG.C_PROBE1_TYPE {0} \
   CONFIG.C_SLOT_0_APC_EN {0} \
   CONFIG.C_SLOT_0_AXI_AR_SEL_DATA {1} \
   CONFIG.C_SLOT_0_AXI_AR_SEL_TRIG {1} \
   CONFIG.C_SLOT_0_AXI_AW_SEL_DATA {1} \
   CONFIG.C_SLOT_0_AXI_AW_SEL_TRIG {1} \
   CONFIG.C_SLOT_0_AXI_B_SEL_DATA {1} \
   CONFIG.C_SLOT_0_AXI_B_SEL_TRIG {1} \
   CONFIG.C_SLOT_0_AXI_R_SEL_DATA {1} \
   CONFIG.C_SLOT_0_AXI_R_SEL_TRIG {1} \
   CONFIG.C_SLOT_0_AXI_W_SEL_DATA {1} \
   CONFIG.C_SLOT_0_AXI_W_SEL_TRIG {1} \
   CONFIG.C_SLOT_0_INTF_TYPE {xilinx.com:interface:aximm_rtl:1.0} \
   CONFIG.C_SLOT_1_APC_EN {0} \
   CONFIG.C_SLOT_1_AXI_DATA_SEL {1} \
   CONFIG.C_SLOT_1_AXI_TRIG_SEL {1} \
   CONFIG.C_SLOT_1_INTF_TYPE {xilinx.com:interface:axis_rtl:1.0} \
   CONFIG.C_SLOT_2_APC_EN {0} \
   CONFIG.C_SLOT_2_AXI_DATA_SEL {1} \
   CONFIG.C_SLOT_2_AXI_TRIG_SEL {1} \
   CONFIG.C_SLOT_2_INTF_TYPE {xilinx.com:interface:axis_rtl:1.0} \
   CONFIG.C_SLOT_3_APC_EN {0} \
   CONFIG.C_SLOT_3_AXI_DATA_SEL {1} \
   CONFIG.C_SLOT_3_AXI_TRIG_SEL {1} \
   CONFIG.C_SLOT_3_INTF_TYPE {xilinx.com:interface:axis_rtl:1.0} \
   CONFIG.C_SLOT_4_APC_EN {0} \
   CONFIG.C_SLOT_4_AXI_DATA_SEL {1} \
   CONFIG.C_SLOT_4_AXI_TRIG_SEL {1} \
   CONFIG.C_SLOT_4_INTF_TYPE {xilinx.com:interface:axis_rtl:1.0} \
   CONFIG.C_SLOT_5_APC_EN {0} \
   CONFIG.C_SLOT_5_AXI_DATA_SEL {1} \
   CONFIG.C_SLOT_5_AXI_TRIG_SEL {1} \
   CONFIG.C_SLOT_5_INTF_TYPE {xilinx.com:interface:axis_rtl:1.0} \
 ] $system_ila_0

  # Create instance: xlconcat_0, and set properties
  set xlconcat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_0 ]
  set_property -dict [ list \
   CONFIG.NUM_PORTS {2} \
 ] $xlconcat_0

  # Create instance: zynq_ultra_ps_e_0, and set properties
  set zynq_ultra_ps_e_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e:3.3 zynq_ultra_ps_e_0 ]
  set_property -dict [ list \
   CONFIG.CAN0_BOARD_INTERFACE {custom} \
   CONFIG.CAN1_BOARD_INTERFACE {custom} \
   CONFIG.CSU_BOARD_INTERFACE {custom} \
   CONFIG.DP_BOARD_INTERFACE {custom} \
   CONFIG.GEM0_BOARD_INTERFACE {custom} \
   CONFIG.GEM1_BOARD_INTERFACE {custom} \
   CONFIG.GEM2_BOARD_INTERFACE {custom} \
   CONFIG.GEM3_BOARD_INTERFACE {custom} \
   CONFIG.GPIO_BOARD_INTERFACE {custom} \
   CONFIG.IIC0_BOARD_INTERFACE {custom} \
   CONFIG.IIC1_BOARD_INTERFACE {custom} \
   CONFIG.NAND_BOARD_INTERFACE {custom} \
   CONFIG.PCIE_BOARD_INTERFACE {custom} \
   CONFIG.PJTAG_BOARD_INTERFACE {custom} \
   CONFIG.PMU_BOARD_INTERFACE {custom} \
   CONFIG.PSU_BANK_0_IO_STANDARD {LVCMOS18} \
   CONFIG.PSU_BANK_1_IO_STANDARD {LVCMOS18} \
   CONFIG.PSU_BANK_2_IO_STANDARD {LVCMOS18} \
   CONFIG.PSU_BANK_3_IO_STANDARD {LVCMOS33} \
   CONFIG.PSU_DDR_RAM_HIGHADDR {0xFFFFFFFF} \
   CONFIG.PSU_DDR_RAM_HIGHADDR_OFFSET {0x800000000} \
   CONFIG.PSU_DDR_RAM_LOWADDR_OFFSET {0x80000000} \
   CONFIG.PSU_DYNAMIC_DDR_CONFIG_EN {1} \
   CONFIG.PSU_IMPORT_BOARD_PRESET {} \
   CONFIG.PSU_MIO_0_DIRECTION {out} \
   CONFIG.PSU_MIO_0_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_0_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_0_POLARITY {Default} \
   CONFIG.PSU_MIO_0_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_0_SLEW {fast} \
   CONFIG.PSU_MIO_10_DIRECTION {inout} \
   CONFIG.PSU_MIO_10_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_10_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_10_POLARITY {Default} \
   CONFIG.PSU_MIO_10_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_10_SLEW {fast} \
   CONFIG.PSU_MIO_11_DIRECTION {inout} \
   CONFIG.PSU_MIO_11_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_11_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_11_POLARITY {Default} \
   CONFIG.PSU_MIO_11_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_11_SLEW {fast} \
   CONFIG.PSU_MIO_12_DIRECTION {out} \
   CONFIG.PSU_MIO_12_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_12_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_12_POLARITY {Default} \
   CONFIG.PSU_MIO_12_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_12_SLEW {fast} \
   CONFIG.PSU_MIO_13_DIRECTION {inout} \
   CONFIG.PSU_MIO_13_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_13_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_13_POLARITY {Default} \
   CONFIG.PSU_MIO_13_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_13_SLEW {fast} \
   CONFIG.PSU_MIO_14_DIRECTION {inout} \
   CONFIG.PSU_MIO_14_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_14_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_14_POLARITY {Default} \
   CONFIG.PSU_MIO_14_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_14_SLEW {fast} \
   CONFIG.PSU_MIO_15_DIRECTION {inout} \
   CONFIG.PSU_MIO_15_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_15_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_15_POLARITY {Default} \
   CONFIG.PSU_MIO_15_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_15_SLEW {fast} \
   CONFIG.PSU_MIO_16_DIRECTION {inout} \
   CONFIG.PSU_MIO_16_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_16_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_16_POLARITY {Default} \
   CONFIG.PSU_MIO_16_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_16_SLEW {fast} \
   CONFIG.PSU_MIO_17_DIRECTION {inout} \
   CONFIG.PSU_MIO_17_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_17_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_17_POLARITY {Default} \
   CONFIG.PSU_MIO_17_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_17_SLEW {fast} \
   CONFIG.PSU_MIO_18_DIRECTION {in} \
   CONFIG.PSU_MIO_18_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_18_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_18_POLARITY {Default} \
   CONFIG.PSU_MIO_18_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_18_SLEW {fast} \
   CONFIG.PSU_MIO_19_DIRECTION {out} \
   CONFIG.PSU_MIO_19_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_19_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_19_POLARITY {Default} \
   CONFIG.PSU_MIO_19_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_19_SLEW {fast} \
   CONFIG.PSU_MIO_1_DIRECTION {inout} \
   CONFIG.PSU_MIO_1_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_1_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_1_POLARITY {Default} \
   CONFIG.PSU_MIO_1_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_1_SLEW {fast} \
   CONFIG.PSU_MIO_20_DIRECTION {inout} \
   CONFIG.PSU_MIO_20_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_20_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_20_POLARITY {Default} \
   CONFIG.PSU_MIO_20_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_20_SLEW {fast} \
   CONFIG.PSU_MIO_21_DIRECTION {inout} \
   CONFIG.PSU_MIO_21_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_21_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_21_POLARITY {Default} \
   CONFIG.PSU_MIO_21_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_21_SLEW {fast} \
   CONFIG.PSU_MIO_22_DIRECTION {inout} \
   CONFIG.PSU_MIO_22_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_22_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_22_POLARITY {Default} \
   CONFIG.PSU_MIO_22_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_22_SLEW {fast} \
   CONFIG.PSU_MIO_23_DIRECTION {inout} \
   CONFIG.PSU_MIO_23_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_23_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_23_POLARITY {Default} \
   CONFIG.PSU_MIO_23_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_23_SLEW {fast} \
   CONFIG.PSU_MIO_24_DIRECTION {inout} \
   CONFIG.PSU_MIO_24_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_24_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_24_POLARITY {Default} \
   CONFIG.PSU_MIO_24_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_24_SLEW {fast} \
   CONFIG.PSU_MIO_25_DIRECTION {inout} \
   CONFIG.PSU_MIO_25_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_25_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_25_POLARITY {Default} \
   CONFIG.PSU_MIO_25_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_25_SLEW {fast} \
   CONFIG.PSU_MIO_26_DIRECTION {inout} \
   CONFIG.PSU_MIO_26_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_26_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_26_POLARITY {Default} \
   CONFIG.PSU_MIO_26_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_26_SLEW {fast} \
   CONFIG.PSU_MIO_27_DIRECTION {out} \
   CONFIG.PSU_MIO_27_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_27_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_27_POLARITY {Default} \
   CONFIG.PSU_MIO_27_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_27_SLEW {fast} \
   CONFIG.PSU_MIO_28_DIRECTION {in} \
   CONFIG.PSU_MIO_28_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_28_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_28_POLARITY {Default} \
   CONFIG.PSU_MIO_28_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_28_SLEW {fast} \
   CONFIG.PSU_MIO_29_DIRECTION {out} \
   CONFIG.PSU_MIO_29_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_29_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_29_POLARITY {Default} \
   CONFIG.PSU_MIO_29_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_29_SLEW {fast} \
   CONFIG.PSU_MIO_2_DIRECTION {inout} \
   CONFIG.PSU_MIO_2_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_2_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_2_POLARITY {Default} \
   CONFIG.PSU_MIO_2_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_2_SLEW {fast} \
   CONFIG.PSU_MIO_30_DIRECTION {in} \
   CONFIG.PSU_MIO_30_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_30_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_30_POLARITY {Default} \
   CONFIG.PSU_MIO_30_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_30_SLEW {fast} \
   CONFIG.PSU_MIO_31_DIRECTION {inout} \
   CONFIG.PSU_MIO_31_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_31_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_31_POLARITY {Default} \
   CONFIG.PSU_MIO_31_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_31_SLEW {fast} \
   CONFIG.PSU_MIO_32_DIRECTION {out} \
   CONFIG.PSU_MIO_32_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_32_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_32_POLARITY {Default} \
   CONFIG.PSU_MIO_32_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_32_SLEW {fast} \
   CONFIG.PSU_MIO_33_DIRECTION {out} \
   CONFIG.PSU_MIO_33_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_33_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_33_POLARITY {Default} \
   CONFIG.PSU_MIO_33_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_33_SLEW {fast} \
   CONFIG.PSU_MIO_34_DIRECTION {out} \
   CONFIG.PSU_MIO_34_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_34_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_34_POLARITY {Default} \
   CONFIG.PSU_MIO_34_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_34_SLEW {fast} \
   CONFIG.PSU_MIO_35_DIRECTION {out} \
   CONFIG.PSU_MIO_35_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_35_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_35_POLARITY {Default} \
   CONFIG.PSU_MIO_35_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_35_SLEW {fast} \
   CONFIG.PSU_MIO_36_DIRECTION {out} \
   CONFIG.PSU_MIO_36_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_36_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_36_POLARITY {Default} \
   CONFIG.PSU_MIO_36_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_36_SLEW {fast} \
   CONFIG.PSU_MIO_37_DIRECTION {out} \
   CONFIG.PSU_MIO_37_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_37_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_37_POLARITY {Default} \
   CONFIG.PSU_MIO_37_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_37_SLEW {fast} \
   CONFIG.PSU_MIO_38_DIRECTION {inout} \
   CONFIG.PSU_MIO_38_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_38_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_38_POLARITY {Default} \
   CONFIG.PSU_MIO_38_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_38_SLEW {fast} \
   CONFIG.PSU_MIO_39_DIRECTION {inout} \
   CONFIG.PSU_MIO_39_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_39_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_39_POLARITY {Default} \
   CONFIG.PSU_MIO_39_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_39_SLEW {fast} \
   CONFIG.PSU_MIO_3_DIRECTION {inout} \
   CONFIG.PSU_MIO_3_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_3_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_3_POLARITY {Default} \
   CONFIG.PSU_MIO_3_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_3_SLEW {fast} \
   CONFIG.PSU_MIO_40_DIRECTION {inout} \
   CONFIG.PSU_MIO_40_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_40_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_40_POLARITY {Default} \
   CONFIG.PSU_MIO_40_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_40_SLEW {fast} \
   CONFIG.PSU_MIO_41_DIRECTION {inout} \
   CONFIG.PSU_MIO_41_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_41_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_41_POLARITY {Default} \
   CONFIG.PSU_MIO_41_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_41_SLEW {fast} \
   CONFIG.PSU_MIO_42_DIRECTION {inout} \
   CONFIG.PSU_MIO_42_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_42_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_42_POLARITY {Default} \
   CONFIG.PSU_MIO_42_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_42_SLEW {fast} \
   CONFIG.PSU_MIO_43_DIRECTION {inout} \
   CONFIG.PSU_MIO_43_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_43_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_43_POLARITY {Default} \
   CONFIG.PSU_MIO_43_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_43_SLEW {fast} \
   CONFIG.PSU_MIO_44_DIRECTION {inout} \
   CONFIG.PSU_MIO_44_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_44_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_44_POLARITY {Default} \
   CONFIG.PSU_MIO_44_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_44_SLEW {fast} \
   CONFIG.PSU_MIO_45_DIRECTION {in} \
   CONFIG.PSU_MIO_45_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_45_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_45_POLARITY {Default} \
   CONFIG.PSU_MIO_45_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_45_SLEW {fast} \
   CONFIG.PSU_MIO_46_DIRECTION {inout} \
   CONFIG.PSU_MIO_46_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_46_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_46_POLARITY {Default} \
   CONFIG.PSU_MIO_46_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_46_SLEW {fast} \
   CONFIG.PSU_MIO_47_DIRECTION {inout} \
   CONFIG.PSU_MIO_47_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_47_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_47_POLARITY {Default} \
   CONFIG.PSU_MIO_47_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_47_SLEW {fast} \
   CONFIG.PSU_MIO_48_DIRECTION {inout} \
   CONFIG.PSU_MIO_48_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_48_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_48_POLARITY {Default} \
   CONFIG.PSU_MIO_48_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_48_SLEW {fast} \
   CONFIG.PSU_MIO_49_DIRECTION {inout} \
   CONFIG.PSU_MIO_49_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_49_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_49_POLARITY {Default} \
   CONFIG.PSU_MIO_49_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_49_SLEW {fast} \
   CONFIG.PSU_MIO_4_DIRECTION {inout} \
   CONFIG.PSU_MIO_4_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_4_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_4_POLARITY {Default} \
   CONFIG.PSU_MIO_4_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_4_SLEW {fast} \
   CONFIG.PSU_MIO_50_DIRECTION {inout} \
   CONFIG.PSU_MIO_50_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_50_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_50_POLARITY {Default} \
   CONFIG.PSU_MIO_50_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_50_SLEW {fast} \
   CONFIG.PSU_MIO_51_DIRECTION {out} \
   CONFIG.PSU_MIO_51_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_51_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_51_POLARITY {Default} \
   CONFIG.PSU_MIO_51_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_51_SLEW {fast} \
   CONFIG.PSU_MIO_52_DIRECTION {in} \
   CONFIG.PSU_MIO_52_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_52_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_52_POLARITY {Default} \
   CONFIG.PSU_MIO_52_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_52_SLEW {fast} \
   CONFIG.PSU_MIO_53_DIRECTION {in} \
   CONFIG.PSU_MIO_53_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_53_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_53_POLARITY {Default} \
   CONFIG.PSU_MIO_53_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_53_SLEW {fast} \
   CONFIG.PSU_MIO_54_DIRECTION {inout} \
   CONFIG.PSU_MIO_54_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_54_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_54_POLARITY {Default} \
   CONFIG.PSU_MIO_54_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_54_SLEW {fast} \
   CONFIG.PSU_MIO_55_DIRECTION {in} \
   CONFIG.PSU_MIO_55_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_55_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_55_POLARITY {Default} \
   CONFIG.PSU_MIO_55_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_55_SLEW {fast} \
   CONFIG.PSU_MIO_56_DIRECTION {inout} \
   CONFIG.PSU_MIO_56_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_56_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_56_POLARITY {Default} \
   CONFIG.PSU_MIO_56_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_56_SLEW {fast} \
   CONFIG.PSU_MIO_57_DIRECTION {inout} \
   CONFIG.PSU_MIO_57_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_57_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_57_POLARITY {Default} \
   CONFIG.PSU_MIO_57_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_57_SLEW {fast} \
   CONFIG.PSU_MIO_58_DIRECTION {out} \
   CONFIG.PSU_MIO_58_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_58_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_58_POLARITY {Default} \
   CONFIG.PSU_MIO_58_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_58_SLEW {fast} \
   CONFIG.PSU_MIO_59_DIRECTION {inout} \
   CONFIG.PSU_MIO_59_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_59_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_59_POLARITY {Default} \
   CONFIG.PSU_MIO_59_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_59_SLEW {fast} \
   CONFIG.PSU_MIO_5_DIRECTION {out} \
   CONFIG.PSU_MIO_5_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_5_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_5_POLARITY {Default} \
   CONFIG.PSU_MIO_5_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_5_SLEW {fast} \
   CONFIG.PSU_MIO_60_DIRECTION {inout} \
   CONFIG.PSU_MIO_60_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_60_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_60_POLARITY {Default} \
   CONFIG.PSU_MIO_60_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_60_SLEW {fast} \
   CONFIG.PSU_MIO_61_DIRECTION {inout} \
   CONFIG.PSU_MIO_61_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_61_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_61_POLARITY {Default} \
   CONFIG.PSU_MIO_61_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_61_SLEW {fast} \
   CONFIG.PSU_MIO_62_DIRECTION {inout} \
   CONFIG.PSU_MIO_62_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_62_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_62_POLARITY {Default} \
   CONFIG.PSU_MIO_62_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_62_SLEW {fast} \
   CONFIG.PSU_MIO_63_DIRECTION {inout} \
   CONFIG.PSU_MIO_63_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_63_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_63_POLARITY {Default} \
   CONFIG.PSU_MIO_63_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_63_SLEW {fast} \
   CONFIG.PSU_MIO_64_DIRECTION {out} \
   CONFIG.PSU_MIO_64_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_64_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_64_POLARITY {Default} \
   CONFIG.PSU_MIO_64_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_64_SLEW {fast} \
   CONFIG.PSU_MIO_65_DIRECTION {out} \
   CONFIG.PSU_MIO_65_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_65_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_65_POLARITY {Default} \
   CONFIG.PSU_MIO_65_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_65_SLEW {fast} \
   CONFIG.PSU_MIO_66_DIRECTION {out} \
   CONFIG.PSU_MIO_66_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_66_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_66_POLARITY {Default} \
   CONFIG.PSU_MIO_66_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_66_SLEW {fast} \
   CONFIG.PSU_MIO_67_DIRECTION {out} \
   CONFIG.PSU_MIO_67_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_67_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_67_POLARITY {Default} \
   CONFIG.PSU_MIO_67_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_67_SLEW {fast} \
   CONFIG.PSU_MIO_68_DIRECTION {out} \
   CONFIG.PSU_MIO_68_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_68_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_68_POLARITY {Default} \
   CONFIG.PSU_MIO_68_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_68_SLEW {fast} \
   CONFIG.PSU_MIO_69_DIRECTION {out} \
   CONFIG.PSU_MIO_69_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_69_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_69_POLARITY {Default} \
   CONFIG.PSU_MIO_69_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_69_SLEW {fast} \
   CONFIG.PSU_MIO_6_DIRECTION {out} \
   CONFIG.PSU_MIO_6_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_6_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_6_POLARITY {Default} \
   CONFIG.PSU_MIO_6_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_6_SLEW {fast} \
   CONFIG.PSU_MIO_70_DIRECTION {in} \
   CONFIG.PSU_MIO_70_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_70_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_70_POLARITY {Default} \
   CONFIG.PSU_MIO_70_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_70_SLEW {fast} \
   CONFIG.PSU_MIO_71_DIRECTION {in} \
   CONFIG.PSU_MIO_71_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_71_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_71_POLARITY {Default} \
   CONFIG.PSU_MIO_71_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_71_SLEW {fast} \
   CONFIG.PSU_MIO_72_DIRECTION {in} \
   CONFIG.PSU_MIO_72_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_72_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_72_POLARITY {Default} \
   CONFIG.PSU_MIO_72_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_72_SLEW {fast} \
   CONFIG.PSU_MIO_73_DIRECTION {in} \
   CONFIG.PSU_MIO_73_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_73_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_73_POLARITY {Default} \
   CONFIG.PSU_MIO_73_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_73_SLEW {fast} \
   CONFIG.PSU_MIO_74_DIRECTION {in} \
   CONFIG.PSU_MIO_74_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_74_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_74_POLARITY {Default} \
   CONFIG.PSU_MIO_74_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_74_SLEW {fast} \
   CONFIG.PSU_MIO_75_DIRECTION {in} \
   CONFIG.PSU_MIO_75_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_75_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_75_POLARITY {Default} \
   CONFIG.PSU_MIO_75_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_75_SLEW {fast} \
   CONFIG.PSU_MIO_76_DIRECTION {out} \
   CONFIG.PSU_MIO_76_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_76_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_76_POLARITY {Default} \
   CONFIG.PSU_MIO_76_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_76_SLEW {fast} \
   CONFIG.PSU_MIO_77_DIRECTION {inout} \
   CONFIG.PSU_MIO_77_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_77_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_77_POLARITY {Default} \
   CONFIG.PSU_MIO_77_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_77_SLEW {fast} \
   CONFIG.PSU_MIO_7_DIRECTION {out} \
   CONFIG.PSU_MIO_7_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_7_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_7_POLARITY {Default} \
   CONFIG.PSU_MIO_7_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_7_SLEW {fast} \
   CONFIG.PSU_MIO_8_DIRECTION {inout} \
   CONFIG.PSU_MIO_8_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_8_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_8_POLARITY {Default} \
   CONFIG.PSU_MIO_8_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_8_SLEW {fast} \
   CONFIG.PSU_MIO_9_DIRECTION {inout} \
   CONFIG.PSU_MIO_9_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_9_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_9_POLARITY {Default} \
   CONFIG.PSU_MIO_9_PULLUPDOWN {pullup} \
   CONFIG.PSU_MIO_9_SLEW {fast} \
   CONFIG.PSU_MIO_TREE_PERIPHERALS {Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Feedback Clk#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#GPIO0 MIO#I2C 0#I2C 0#I2C 1#I2C 1#UART 0#UART 0#GPIO0 MIO#GPIO0 MIO#GPIO0 MIO#GPIO0 MIO#GPIO0 MIO#GPIO0 MIO#GPIO1 MIO#DPAUX#DPAUX#DPAUX#DPAUX#GPIO1 MIO#PMU GPO 0#PMU GPO 1#PMU GPO 2#PMU GPO 3#PMU GPO 4#PMU GPO 5#GPIO1 MIO#SD 1#SD 1#SD 1#SD 1#GPIO1 MIO#GPIO1 MIO#SD 1#SD 1#SD 1#SD 1#SD 1#SD 1#SD 1#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#Gem 3#Gem 3#Gem 3#Gem 3#Gem 3#Gem 3#Gem 3#Gem 3#Gem 3#Gem 3#Gem 3#Gem 3#MDIO 3#MDIO 3} \
   CONFIG.PSU_MIO_TREE_SIGNALS {sclk_out#miso_mo1#mo2#mo3#mosi_mi0#n_ss_out#clk_for_lpbk#n_ss_out_upper#mo_upper[0]#mo_upper[1]#mo_upper[2]#mo_upper[3]#sclk_out_upper#gpio0[13]#scl_out#sda_out#scl_out#sda_out#rxd#txd#gpio0[20]#gpio0[21]#gpio0[22]#gpio0[23]#gpio0[24]#gpio0[25]#gpio1[26]#dp_aux_data_out#dp_hot_plug_detect#dp_aux_data_oe#dp_aux_data_in#gpio1[31]#gpo[0]#gpo[1]#gpo[2]#gpo[3]#gpo[4]#gpo[5]#gpio1[38]#sdio1_data_out[4]#sdio1_data_out[5]#sdio1_data_out[6]#sdio1_data_out[7]#gpio1[43]#gpio1[44]#sdio1_cd_n#sdio1_data_out[0]#sdio1_data_out[1]#sdio1_data_out[2]#sdio1_data_out[3]#sdio1_cmd_out#sdio1_clk_out#ulpi_clk_in#ulpi_dir#ulpi_tx_data[2]#ulpi_nxt#ulpi_tx_data[0]#ulpi_tx_data[1]#ulpi_stp#ulpi_tx_data[3]#ulpi_tx_data[4]#ulpi_tx_data[5]#ulpi_tx_data[6]#ulpi_tx_data[7]#rgmii_tx_clk#rgmii_txd[0]#rgmii_txd[1]#rgmii_txd[2]#rgmii_txd[3]#rgmii_tx_ctl#rgmii_rx_clk#rgmii_rxd[0]#rgmii_rxd[1]#rgmii_rxd[2]#rgmii_rxd[3]#rgmii_rx_ctl#gem3_mdc#gem3_mdio_out} \
   CONFIG.PSU_PERIPHERAL_BOARD_PRESET {} \
   CONFIG.PSU_SD0_INTERNAL_BUS_WIDTH {8} \
   CONFIG.PSU_SD1_INTERNAL_BUS_WIDTH {8} \
   CONFIG.PSU_SMC_CYCLE_T0 {NA} \
   CONFIG.PSU_SMC_CYCLE_T1 {NA} \
   CONFIG.PSU_SMC_CYCLE_T2 {NA} \
   CONFIG.PSU_SMC_CYCLE_T3 {NA} \
   CONFIG.PSU_SMC_CYCLE_T4 {NA} \
   CONFIG.PSU_SMC_CYCLE_T5 {NA} \
   CONFIG.PSU_SMC_CYCLE_T6 {NA} \
   CONFIG.PSU_USB3__DUAL_CLOCK_ENABLE {1} \
   CONFIG.PSU_VALUE_SILVERSION {3} \
   CONFIG.PSU__ACPU0__POWER__ON {1} \
   CONFIG.PSU__ACPU1__POWER__ON {1} \
   CONFIG.PSU__ACPU2__POWER__ON {1} \
   CONFIG.PSU__ACPU3__POWER__ON {1} \
   CONFIG.PSU__ACTUAL__IP {1} \
   CONFIG.PSU__ACT_DDR_FREQ_MHZ {1066.656006} \
   CONFIG.PSU__AFI0_COHERENCY {0} \
   CONFIG.PSU__AFI1_COHERENCY {0} \
   CONFIG.PSU__AUX_REF_CLK__FREQMHZ {33.333} \
   CONFIG.PSU__CAN0_LOOP_CAN1__ENABLE {0} \
   CONFIG.PSU__CAN0__GRP_CLK__ENABLE {0} \
   CONFIG.PSU__CAN0__PERIPHERAL__ENABLE {0} \
   CONFIG.PSU__CAN1__GRP_CLK__ENABLE {0} \
   CONFIG.PSU__CAN1__PERIPHERAL__ENABLE {0} \
   CONFIG.PSU__CRF_APB__ACPU_CTRL__ACT_FREQMHZ {1199.988037} \
   CONFIG.PSU__CRF_APB__ACPU_CTRL__DIVISOR0 {1} \
   CONFIG.PSU__CRF_APB__ACPU_CTRL__FREQMHZ {1200} \
   CONFIG.PSU__CRF_APB__ACPU_CTRL__SRCSEL {APLL} \
   CONFIG.PSU__CRF_APB__ACPU__FRAC_ENABLED {0} \
   CONFIG.PSU__CRF_APB__AFI0_REF_CTRL__ACT_FREQMHZ {667} \
   CONFIG.PSU__CRF_APB__AFI0_REF_CTRL__DIVISOR0 {2} \
   CONFIG.PSU__CRF_APB__AFI0_REF_CTRL__FREQMHZ {667} \
   CONFIG.PSU__CRF_APB__AFI0_REF_CTRL__SRCSEL {DPLL} \
   CONFIG.PSU__CRF_APB__AFI0_REF__ENABLE {0} \
   CONFIG.PSU__CRF_APB__AFI1_REF_CTRL__ACT_FREQMHZ {667} \
   CONFIG.PSU__CRF_APB__AFI1_REF_CTRL__DIVISOR0 {2} \
   CONFIG.PSU__CRF_APB__AFI1_REF_CTRL__FREQMHZ {667} \
   CONFIG.PSU__CRF_APB__AFI1_REF_CTRL__SRCSEL {DPLL} \
   CONFIG.PSU__CRF_APB__AFI1_REF__ENABLE {0} \
   CONFIG.PSU__CRF_APB__AFI2_REF_CTRL__ACT_FREQMHZ {667} \
   CONFIG.PSU__CRF_APB__AFI2_REF_CTRL__DIVISOR0 {2} \
   CONFIG.PSU__CRF_APB__AFI2_REF_CTRL__FREQMHZ {667} \
   CONFIG.PSU__CRF_APB__AFI2_REF_CTRL__SRCSEL {DPLL} \
   CONFIG.PSU__CRF_APB__AFI2_REF__ENABLE {0} \
   CONFIG.PSU__CRF_APB__AFI3_REF_CTRL__ACT_FREQMHZ {667} \
   CONFIG.PSU__CRF_APB__AFI3_REF_CTRL__DIVISOR0 {2} \
   CONFIG.PSU__CRF_APB__AFI3_REF_CTRL__FREQMHZ {667} \
   CONFIG.PSU__CRF_APB__AFI3_REF_CTRL__SRCSEL {DPLL} \
   CONFIG.PSU__CRF_APB__AFI3_REF__ENABLE {0} \
   CONFIG.PSU__CRF_APB__AFI4_REF_CTRL__ACT_FREQMHZ {667} \
   CONFIG.PSU__CRF_APB__AFI4_REF_CTRL__DIVISOR0 {2} \
   CONFIG.PSU__CRF_APB__AFI4_REF_CTRL__FREQMHZ {667} \
   CONFIG.PSU__CRF_APB__AFI4_REF_CTRL__SRCSEL {DPLL} \
   CONFIG.PSU__CRF_APB__AFI4_REF__ENABLE {0} \
   CONFIG.PSU__CRF_APB__AFI5_REF_CTRL__ACT_FREQMHZ {667} \
   CONFIG.PSU__CRF_APB__AFI5_REF_CTRL__DIVISOR0 {2} \
   CONFIG.PSU__CRF_APB__AFI5_REF_CTRL__FREQMHZ {667} \
   CONFIG.PSU__CRF_APB__AFI5_REF_CTRL__SRCSEL {DPLL} \
   CONFIG.PSU__CRF_APB__AFI5_REF__ENABLE {0} \
   CONFIG.PSU__CRF_APB__APLL_CTRL__DIV2 {1} \
   CONFIG.PSU__CRF_APB__APLL_CTRL__FBDIV {72} \
   CONFIG.PSU__CRF_APB__APLL_CTRL__FRACDATA {0.000000} \
   CONFIG.PSU__CRF_APB__APLL_CTRL__FRACFREQ {27.138} \
   CONFIG.PSU__CRF_APB__APLL_CTRL__SRCSEL {PSS_REF_CLK} \
   CONFIG.PSU__CRF_APB__APLL_FRAC_CFG__ENABLED {0} \
   CONFIG.PSU__CRF_APB__APLL_TO_LPD_CTRL__DIVISOR0 {3} \
   CONFIG.PSU__CRF_APB__APM_CTRL__ACT_FREQMHZ {1} \
   CONFIG.PSU__CRF_APB__APM_CTRL__DIVISOR0 {1} \
   CONFIG.PSU__CRF_APB__APM_CTRL__FREQMHZ {1} \
   CONFIG.PSU__CRF_APB__DBG_FPD_CTRL__ACT_FREQMHZ {249.997498} \
   CONFIG.PSU__CRF_APB__DBG_FPD_CTRL__DIVISOR0 {2} \
   CONFIG.PSU__CRF_APB__DBG_FPD_CTRL__FREQMHZ {250} \
   CONFIG.PSU__CRF_APB__DBG_FPD_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRF_APB__DBG_TRACE_CTRL__ACT_FREQMHZ {250} \
   CONFIG.PSU__CRF_APB__DBG_TRACE_CTRL__DIVISOR0 {5} \
   CONFIG.PSU__CRF_APB__DBG_TRACE_CTRL__FREQMHZ {250} \
   CONFIG.PSU__CRF_APB__DBG_TRACE_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRF_APB__DBG_TSTMP_CTRL__ACT_FREQMHZ {249.997498} \
   CONFIG.PSU__CRF_APB__DBG_TSTMP_CTRL__DIVISOR0 {2} \
   CONFIG.PSU__CRF_APB__DBG_TSTMP_CTRL__FREQMHZ {250} \
   CONFIG.PSU__CRF_APB__DBG_TSTMP_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRF_APB__DDR_CTRL__ACT_FREQMHZ {533.328003} \
   CONFIG.PSU__CRF_APB__DDR_CTRL__DIVISOR0 {2} \
   CONFIG.PSU__CRF_APB__DDR_CTRL__FREQMHZ {1067} \
   CONFIG.PSU__CRF_APB__DDR_CTRL__SRCSEL {DPLL} \
   CONFIG.PSU__CRF_APB__DPDMA_REF_CTRL__ACT_FREQMHZ {599.994019} \
   CONFIG.PSU__CRF_APB__DPDMA_REF_CTRL__DIVISOR0 {2} \
   CONFIG.PSU__CRF_APB__DPDMA_REF_CTRL__FREQMHZ {600} \
   CONFIG.PSU__CRF_APB__DPDMA_REF_CTRL__SRCSEL {APLL} \
   CONFIG.PSU__CRF_APB__DPLL_CTRL__DIV2 {1} \
   CONFIG.PSU__CRF_APB__DPLL_CTRL__FBDIV {64} \
   CONFIG.PSU__CRF_APB__DPLL_CTRL__FRACDATA {0.000000} \
   CONFIG.PSU__CRF_APB__DPLL_CTRL__FRACFREQ {27.138} \
   CONFIG.PSU__CRF_APB__DPLL_CTRL__SRCSEL {PSS_REF_CLK} \
   CONFIG.PSU__CRF_APB__DPLL_FRAC_CFG__ENABLED {0} \
   CONFIG.PSU__CRF_APB__DPLL_TO_LPD_CTRL__DIVISOR0 {2} \
   CONFIG.PSU__CRF_APB__DP_AUDIO_REF_CTRL__ACT_FREQMHZ {24.999750} \
   CONFIG.PSU__CRF_APB__DP_AUDIO_REF_CTRL__DIVISOR0 {15} \
   CONFIG.PSU__CRF_APB__DP_AUDIO_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRF_APB__DP_AUDIO_REF_CTRL__FREQMHZ {25} \
   CONFIG.PSU__CRF_APB__DP_AUDIO_REF_CTRL__SRCSEL {RPLL} \
   CONFIG.PSU__CRF_APB__DP_AUDIO__FRAC_ENABLED {0} \
   CONFIG.PSU__CRF_APB__DP_STC_REF_CTRL__ACT_FREQMHZ {26.785446} \
   CONFIG.PSU__CRF_APB__DP_STC_REF_CTRL__DIVISOR0 {14} \
   CONFIG.PSU__CRF_APB__DP_STC_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRF_APB__DP_STC_REF_CTRL__FREQMHZ {27} \
   CONFIG.PSU__CRF_APB__DP_STC_REF_CTRL__SRCSEL {RPLL} \
   CONFIG.PSU__CRF_APB__DP_VIDEO_REF_CTRL__ACT_FREQMHZ {299.997009} \
   CONFIG.PSU__CRF_APB__DP_VIDEO_REF_CTRL__DIVISOR0 {5} \
   CONFIG.PSU__CRF_APB__DP_VIDEO_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRF_APB__DP_VIDEO_REF_CTRL__FREQMHZ {300} \
   CONFIG.PSU__CRF_APB__DP_VIDEO_REF_CTRL__SRCSEL {VPLL} \
   CONFIG.PSU__CRF_APB__DP_VIDEO__FRAC_ENABLED {0} \
   CONFIG.PSU__CRF_APB__GDMA_REF_CTRL__ACT_FREQMHZ {599.994019} \
   CONFIG.PSU__CRF_APB__GDMA_REF_CTRL__DIVISOR0 {2} \
   CONFIG.PSU__CRF_APB__GDMA_REF_CTRL__FREQMHZ {600} \
   CONFIG.PSU__CRF_APB__GDMA_REF_CTRL__SRCSEL {APLL} \
   CONFIG.PSU__CRF_APB__GPU_REF_CTRL__ACT_FREQMHZ {0} \
   CONFIG.PSU__CRF_APB__GPU_REF_CTRL__DIVISOR0 {3} \
   CONFIG.PSU__CRF_APB__GPU_REF_CTRL__FREQMHZ {500} \
   CONFIG.PSU__CRF_APB__GPU_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRF_APB__GTGREF0_REF_CTRL__ACT_FREQMHZ {-1} \
   CONFIG.PSU__CRF_APB__GTGREF0_REF_CTRL__DIVISOR0 {-1} \
   CONFIG.PSU__CRF_APB__GTGREF0_REF_CTRL__FREQMHZ {-1} \
   CONFIG.PSU__CRF_APB__GTGREF0_REF_CTRL__SRCSEL {NA} \
   CONFIG.PSU__CRF_APB__GTGREF0__ENABLE {NA} \
   CONFIG.PSU__CRF_APB__PCIE_REF_CTRL__ACT_FREQMHZ {250} \
   CONFIG.PSU__CRF_APB__PCIE_REF_CTRL__DIVISOR0 {6} \
   CONFIG.PSU__CRF_APB__PCIE_REF_CTRL__FREQMHZ {250} \
   CONFIG.PSU__CRF_APB__PCIE_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRF_APB__SATA_REF_CTRL__ACT_FREQMHZ {249.997498} \
   CONFIG.PSU__CRF_APB__SATA_REF_CTRL__DIVISOR0 {2} \
   CONFIG.PSU__CRF_APB__SATA_REF_CTRL__FREQMHZ {250} \
   CONFIG.PSU__CRF_APB__SATA_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRF_APB__TOPSW_LSBUS_CTRL__ACT_FREQMHZ {99.999001} \
   CONFIG.PSU__CRF_APB__TOPSW_LSBUS_CTRL__DIVISOR0 {5} \
   CONFIG.PSU__CRF_APB__TOPSW_LSBUS_CTRL__FREQMHZ {100} \
   CONFIG.PSU__CRF_APB__TOPSW_LSBUS_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRF_APB__TOPSW_MAIN_CTRL__ACT_FREQMHZ {533.328003} \
   CONFIG.PSU__CRF_APB__TOPSW_MAIN_CTRL__DIVISOR0 {2} \
   CONFIG.PSU__CRF_APB__TOPSW_MAIN_CTRL__FREQMHZ {533.33} \
   CONFIG.PSU__CRF_APB__TOPSW_MAIN_CTRL__SRCSEL {DPLL} \
   CONFIG.PSU__CRF_APB__VPLL_CTRL__DIV2 {1} \
   CONFIG.PSU__CRF_APB__VPLL_CTRL__FBDIV {90} \
   CONFIG.PSU__CRF_APB__VPLL_CTRL__FRACDATA {0.000000} \
   CONFIG.PSU__CRF_APB__VPLL_CTRL__FRACFREQ {27.138} \
   CONFIG.PSU__CRF_APB__VPLL_CTRL__SRCSEL {PSS_REF_CLK} \
   CONFIG.PSU__CRF_APB__VPLL_FRAC_CFG__ENABLED {0} \
   CONFIG.PSU__CRF_APB__VPLL_TO_LPD_CTRL__DIVISOR0 {3} \
   CONFIG.PSU__CRL_APB__ADMA_REF_CTRL__ACT_FREQMHZ {499.994995} \
   CONFIG.PSU__CRL_APB__ADMA_REF_CTRL__DIVISOR0 {3} \
   CONFIG.PSU__CRL_APB__ADMA_REF_CTRL__FREQMHZ {500} \
   CONFIG.PSU__CRL_APB__ADMA_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__AFI6_REF_CTRL__ACT_FREQMHZ {500} \
   CONFIG.PSU__CRL_APB__AFI6_REF_CTRL__DIVISOR0 {3} \
   CONFIG.PSU__CRL_APB__AFI6_REF_CTRL__FREQMHZ {500} \
   CONFIG.PSU__CRL_APB__AFI6_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__AFI6__ENABLE {0} \
   CONFIG.PSU__CRL_APB__AMS_REF_CTRL__ACT_FREQMHZ {49.999500} \
   CONFIG.PSU__CRL_APB__AMS_REF_CTRL__DIVISOR0 {30} \
   CONFIG.PSU__CRL_APB__AMS_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__AMS_REF_CTRL__FREQMHZ {50} \
   CONFIG.PSU__CRL_APB__AMS_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__CAN0_REF_CTRL__ACT_FREQMHZ {100} \
   CONFIG.PSU__CRL_APB__CAN0_REF_CTRL__DIVISOR0 {15} \
   CONFIG.PSU__CRL_APB__CAN0_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__CAN0_REF_CTRL__FREQMHZ {100} \
   CONFIG.PSU__CRL_APB__CAN0_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__CAN1_REF_CTRL__ACT_FREQMHZ {100} \
   CONFIG.PSU__CRL_APB__CAN1_REF_CTRL__DIVISOR0 {15} \
   CONFIG.PSU__CRL_APB__CAN1_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__CAN1_REF_CTRL__FREQMHZ {100} \
   CONFIG.PSU__CRL_APB__CAN1_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__CPU_R5_CTRL__ACT_FREQMHZ {499.994995} \
   CONFIG.PSU__CRL_APB__CPU_R5_CTRL__DIVISOR0 {3} \
   CONFIG.PSU__CRL_APB__CPU_R5_CTRL__FREQMHZ {500} \
   CONFIG.PSU__CRL_APB__CPU_R5_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__CSU_PLL_CTRL__ACT_FREQMHZ {180} \
   CONFIG.PSU__CRL_APB__CSU_PLL_CTRL__DIVISOR0 {3} \
   CONFIG.PSU__CRL_APB__CSU_PLL_CTRL__FREQMHZ {180} \
   CONFIG.PSU__CRL_APB__CSU_PLL_CTRL__SRCSEL {SysOsc} \
   CONFIG.PSU__CRL_APB__DBG_LPD_CTRL__ACT_FREQMHZ {249.997498} \
   CONFIG.PSU__CRL_APB__DBG_LPD_CTRL__DIVISOR0 {6} \
   CONFIG.PSU__CRL_APB__DBG_LPD_CTRL__FREQMHZ {250} \
   CONFIG.PSU__CRL_APB__DBG_LPD_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__DEBUG_R5_ATCLK_CTRL__ACT_FREQMHZ {1000} \
   CONFIG.PSU__CRL_APB__DEBUG_R5_ATCLK_CTRL__DIVISOR0 {6} \
   CONFIG.PSU__CRL_APB__DEBUG_R5_ATCLK_CTRL__FREQMHZ {1000} \
   CONFIG.PSU__CRL_APB__DEBUG_R5_ATCLK_CTRL__SRCSEL {RPLL} \
   CONFIG.PSU__CRL_APB__DLL_REF_CTRL__ACT_FREQMHZ {1499.984985} \
   CONFIG.PSU__CRL_APB__DLL_REF_CTRL__FREQMHZ {1500} \
   CONFIG.PSU__CRL_APB__DLL_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__GEM0_REF_CTRL__ACT_FREQMHZ {125} \
   CONFIG.PSU__CRL_APB__GEM0_REF_CTRL__DIVISOR0 {12} \
   CONFIG.PSU__CRL_APB__GEM0_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__GEM0_REF_CTRL__FREQMHZ {125} \
   CONFIG.PSU__CRL_APB__GEM0_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__GEM1_REF_CTRL__ACT_FREQMHZ {125} \
   CONFIG.PSU__CRL_APB__GEM1_REF_CTRL__DIVISOR0 {12} \
   CONFIG.PSU__CRL_APB__GEM1_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__GEM1_REF_CTRL__FREQMHZ {125} \
   CONFIG.PSU__CRL_APB__GEM1_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__GEM2_REF_CTRL__ACT_FREQMHZ {125} \
   CONFIG.PSU__CRL_APB__GEM2_REF_CTRL__DIVISOR0 {12} \
   CONFIG.PSU__CRL_APB__GEM2_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__GEM2_REF_CTRL__FREQMHZ {125} \
   CONFIG.PSU__CRL_APB__GEM2_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__GEM3_REF_CTRL__ACT_FREQMHZ {124.998749} \
   CONFIG.PSU__CRL_APB__GEM3_REF_CTRL__DIVISOR0 {12} \
   CONFIG.PSU__CRL_APB__GEM3_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__GEM3_REF_CTRL__FREQMHZ {125} \
   CONFIG.PSU__CRL_APB__GEM3_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__GEM_TSU_REF_CTRL__ACT_FREQMHZ {249.997498} \
   CONFIG.PSU__CRL_APB__GEM_TSU_REF_CTRL__DIVISOR0 {6} \
   CONFIG.PSU__CRL_APB__GEM_TSU_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__GEM_TSU_REF_CTRL__FREQMHZ {250} \
   CONFIG.PSU__CRL_APB__GEM_TSU_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__I2C0_REF_CTRL__ACT_FREQMHZ {99.999001} \
   CONFIG.PSU__CRL_APB__I2C0_REF_CTRL__DIVISOR0 {15} \
   CONFIG.PSU__CRL_APB__I2C0_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__I2C0_REF_CTRL__FREQMHZ {100} \
   CONFIG.PSU__CRL_APB__I2C0_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__I2C1_REF_CTRL__ACT_FREQMHZ {99.999001} \
   CONFIG.PSU__CRL_APB__I2C1_REF_CTRL__DIVISOR0 {15} \
   CONFIG.PSU__CRL_APB__I2C1_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__I2C1_REF_CTRL__FREQMHZ {100} \
   CONFIG.PSU__CRL_APB__I2C1_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__IOPLL_CTRL__DIV2 {1} \
   CONFIG.PSU__CRL_APB__IOPLL_CTRL__FBDIV {90} \
   CONFIG.PSU__CRL_APB__IOPLL_CTRL__FRACDATA {0.000000} \
   CONFIG.PSU__CRL_APB__IOPLL_CTRL__FRACFREQ {27.138} \
   CONFIG.PSU__CRL_APB__IOPLL_CTRL__SRCSEL {PSS_REF_CLK} \
   CONFIG.PSU__CRL_APB__IOPLL_FRAC_CFG__ENABLED {0} \
   CONFIG.PSU__CRL_APB__IOPLL_TO_FPD_CTRL__DIVISOR0 {3} \
   CONFIG.PSU__CRL_APB__IOU_SWITCH_CTRL__ACT_FREQMHZ {249.997498} \
   CONFIG.PSU__CRL_APB__IOU_SWITCH_CTRL__DIVISOR0 {6} \
   CONFIG.PSU__CRL_APB__IOU_SWITCH_CTRL__FREQMHZ {250} \
   CONFIG.PSU__CRL_APB__IOU_SWITCH_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__LPD_LSBUS_CTRL__ACT_FREQMHZ {99.999001} \
   CONFIG.PSU__CRL_APB__LPD_LSBUS_CTRL__DIVISOR0 {15} \
   CONFIG.PSU__CRL_APB__LPD_LSBUS_CTRL__FREQMHZ {100} \
   CONFIG.PSU__CRL_APB__LPD_LSBUS_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__LPD_SWITCH_CTRL__ACT_FREQMHZ {499.994995} \
   CONFIG.PSU__CRL_APB__LPD_SWITCH_CTRL__DIVISOR0 {3} \
   CONFIG.PSU__CRL_APB__LPD_SWITCH_CTRL__FREQMHZ {500} \
   CONFIG.PSU__CRL_APB__LPD_SWITCH_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__NAND_REF_CTRL__ACT_FREQMHZ {100} \
   CONFIG.PSU__CRL_APB__NAND_REF_CTRL__DIVISOR0 {15} \
   CONFIG.PSU__CRL_APB__NAND_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__NAND_REF_CTRL__FREQMHZ {100} \
   CONFIG.PSU__CRL_APB__NAND_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__OCM_MAIN_CTRL__ACT_FREQMHZ {500} \
   CONFIG.PSU__CRL_APB__OCM_MAIN_CTRL__DIVISOR0 {3} \
   CONFIG.PSU__CRL_APB__OCM_MAIN_CTRL__FREQMHZ {500} \
   CONFIG.PSU__CRL_APB__OCM_MAIN_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__PCAP_CTRL__ACT_FREQMHZ {187.498123} \
   CONFIG.PSU__CRL_APB__PCAP_CTRL__DIVISOR0 {8} \
   CONFIG.PSU__CRL_APB__PCAP_CTRL__FREQMHZ {200} \
   CONFIG.PSU__CRL_APB__PCAP_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__PL0_REF_CTRL__ACT_FREQMHZ {99.999001} \
   CONFIG.PSU__CRL_APB__PL0_REF_CTRL__DIVISOR0 {15} \
   CONFIG.PSU__CRL_APB__PL0_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__PL0_REF_CTRL__FREQMHZ {100} \
   CONFIG.PSU__CRL_APB__PL0_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__PL1_REF_CTRL__ACT_FREQMHZ {100} \
   CONFIG.PSU__CRL_APB__PL1_REF_CTRL__DIVISOR0 {4} \
   CONFIG.PSU__CRL_APB__PL1_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__PL1_REF_CTRL__FREQMHZ {100} \
   CONFIG.PSU__CRL_APB__PL1_REF_CTRL__SRCSEL {RPLL} \
   CONFIG.PSU__CRL_APB__PL2_REF_CTRL__ACT_FREQMHZ {100} \
   CONFIG.PSU__CRL_APB__PL2_REF_CTRL__DIVISOR0 {4} \
   CONFIG.PSU__CRL_APB__PL2_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__PL2_REF_CTRL__FREQMHZ {100} \
   CONFIG.PSU__CRL_APB__PL2_REF_CTRL__SRCSEL {RPLL} \
   CONFIG.PSU__CRL_APB__PL3_REF_CTRL__ACT_FREQMHZ {100} \
   CONFIG.PSU__CRL_APB__PL3_REF_CTRL__DIVISOR0 {4} \
   CONFIG.PSU__CRL_APB__PL3_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__PL3_REF_CTRL__FREQMHZ {100} \
   CONFIG.PSU__CRL_APB__PL3_REF_CTRL__SRCSEL {RPLL} \
   CONFIG.PSU__CRL_APB__QSPI_REF_CTRL__ACT_FREQMHZ {124.998749} \
   CONFIG.PSU__CRL_APB__QSPI_REF_CTRL__DIVISOR0 {12} \
   CONFIG.PSU__CRL_APB__QSPI_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__QSPI_REF_CTRL__FREQMHZ {125} \
   CONFIG.PSU__CRL_APB__QSPI_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__RPLL_CTRL__DIV2 {1} \
   CONFIG.PSU__CRL_APB__RPLL_CTRL__FBDIV {45} \
   CONFIG.PSU__CRL_APB__RPLL_CTRL__FRACDATA {0.000000} \
   CONFIG.PSU__CRL_APB__RPLL_CTRL__FRACFREQ {27.138} \
   CONFIG.PSU__CRL_APB__RPLL_CTRL__SRCSEL {PSS_REF_CLK} \
   CONFIG.PSU__CRL_APB__RPLL_FRAC_CFG__ENABLED {0} \
   CONFIG.PSU__CRL_APB__RPLL_TO_FPD_CTRL__DIVISOR0 {2} \
   CONFIG.PSU__CRL_APB__SDIO0_REF_CTRL__ACT_FREQMHZ {200} \
   CONFIG.PSU__CRL_APB__SDIO0_REF_CTRL__DIVISOR0 {7} \
   CONFIG.PSU__CRL_APB__SDIO0_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__SDIO0_REF_CTRL__FREQMHZ {200} \
   CONFIG.PSU__CRL_APB__SDIO0_REF_CTRL__SRCSEL {RPLL} \
   CONFIG.PSU__CRL_APB__SDIO1_REF_CTRL__ACT_FREQMHZ {187.498123} \
   CONFIG.PSU__CRL_APB__SDIO1_REF_CTRL__DIVISOR0 {8} \
   CONFIG.PSU__CRL_APB__SDIO1_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__SDIO1_REF_CTRL__FREQMHZ {200} \
   CONFIG.PSU__CRL_APB__SDIO1_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__SPI0_REF_CTRL__ACT_FREQMHZ {214} \
   CONFIG.PSU__CRL_APB__SPI0_REF_CTRL__DIVISOR0 {7} \
   CONFIG.PSU__CRL_APB__SPI0_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__SPI0_REF_CTRL__FREQMHZ {200} \
   CONFIG.PSU__CRL_APB__SPI0_REF_CTRL__SRCSEL {RPLL} \
   CONFIG.PSU__CRL_APB__SPI1_REF_CTRL__ACT_FREQMHZ {214} \
   CONFIG.PSU__CRL_APB__SPI1_REF_CTRL__DIVISOR0 {7} \
   CONFIG.PSU__CRL_APB__SPI1_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__SPI1_REF_CTRL__FREQMHZ {200} \
   CONFIG.PSU__CRL_APB__SPI1_REF_CTRL__SRCSEL {RPLL} \
   CONFIG.PSU__CRL_APB__TIMESTAMP_REF_CTRL__ACT_FREQMHZ {99.999001} \
   CONFIG.PSU__CRL_APB__TIMESTAMP_REF_CTRL__DIVISOR0 {15} \
   CONFIG.PSU__CRL_APB__TIMESTAMP_REF_CTRL__FREQMHZ {100} \
   CONFIG.PSU__CRL_APB__TIMESTAMP_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__UART0_REF_CTRL__ACT_FREQMHZ {99.999001} \
   CONFIG.PSU__CRL_APB__UART0_REF_CTRL__DIVISOR0 {15} \
   CONFIG.PSU__CRL_APB__UART0_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__UART0_REF_CTRL__FREQMHZ {100} \
   CONFIG.PSU__CRL_APB__UART0_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__UART1_REF_CTRL__ACT_FREQMHZ {99.999001} \
   CONFIG.PSU__CRL_APB__UART1_REF_CTRL__DIVISOR0 {15} \
   CONFIG.PSU__CRL_APB__UART1_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__UART1_REF_CTRL__FREQMHZ {100} \
   CONFIG.PSU__CRL_APB__UART1_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__USB0_BUS_REF_CTRL__ACT_FREQMHZ {249.997498} \
   CONFIG.PSU__CRL_APB__USB0_BUS_REF_CTRL__DIVISOR0 {6} \
   CONFIG.PSU__CRL_APB__USB0_BUS_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__USB0_BUS_REF_CTRL__FREQMHZ {250} \
   CONFIG.PSU__CRL_APB__USB0_BUS_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__USB1_BUS_REF_CTRL__ACT_FREQMHZ {250} \
   CONFIG.PSU__CRL_APB__USB1_BUS_REF_CTRL__DIVISOR0 {6} \
   CONFIG.PSU__CRL_APB__USB1_BUS_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__USB1_BUS_REF_CTRL__FREQMHZ {250} \
   CONFIG.PSU__CRL_APB__USB1_BUS_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__USB3_DUAL_REF_CTRL__ACT_FREQMHZ {19.999800} \
   CONFIG.PSU__CRL_APB__USB3_DUAL_REF_CTRL__DIVISOR0 {25} \
   CONFIG.PSU__CRL_APB__USB3_DUAL_REF_CTRL__DIVISOR1 {3} \
   CONFIG.PSU__CRL_APB__USB3_DUAL_REF_CTRL__FREQMHZ {20} \
   CONFIG.PSU__CRL_APB__USB3_DUAL_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__USB3__ENABLE {1} \
   CONFIG.PSU__CSUPMU__PERIPHERAL__VALID {1} \
   CONFIG.PSU__CSU_COHERENCY {0} \
   CONFIG.PSU__CSU__CSU_TAMPER_0__ENABLE {0} \
   CONFIG.PSU__CSU__CSU_TAMPER_0__ERASE_BBRAM {0} \
   CONFIG.PSU__CSU__CSU_TAMPER_10__ENABLE {0} \
   CONFIG.PSU__CSU__CSU_TAMPER_10__ERASE_BBRAM {0} \
   CONFIG.PSU__CSU__CSU_TAMPER_11__ENABLE {0} \
   CONFIG.PSU__CSU__CSU_TAMPER_11__ERASE_BBRAM {0} \
   CONFIG.PSU__CSU__CSU_TAMPER_12__ENABLE {0} \
   CONFIG.PSU__CSU__CSU_TAMPER_12__ERASE_BBRAM {0} \
   CONFIG.PSU__CSU__CSU_TAMPER_1__ENABLE {0} \
   CONFIG.PSU__CSU__CSU_TAMPER_1__ERASE_BBRAM {0} \
   CONFIG.PSU__CSU__CSU_TAMPER_2__ENABLE {0} \
   CONFIG.PSU__CSU__CSU_TAMPER_2__ERASE_BBRAM {0} \
   CONFIG.PSU__CSU__CSU_TAMPER_3__ENABLE {0} \
   CONFIG.PSU__CSU__CSU_TAMPER_3__ERASE_BBRAM {0} \
   CONFIG.PSU__CSU__CSU_TAMPER_4__ENABLE {0} \
   CONFIG.PSU__CSU__CSU_TAMPER_4__ERASE_BBRAM {0} \
   CONFIG.PSU__CSU__CSU_TAMPER_5__ENABLE {0} \
   CONFIG.PSU__CSU__CSU_TAMPER_5__ERASE_BBRAM {0} \
   CONFIG.PSU__CSU__CSU_TAMPER_6__ENABLE {0} \
   CONFIG.PSU__CSU__CSU_TAMPER_6__ERASE_BBRAM {0} \
   CONFIG.PSU__CSU__CSU_TAMPER_7__ENABLE {0} \
   CONFIG.PSU__CSU__CSU_TAMPER_7__ERASE_BBRAM {0} \
   CONFIG.PSU__CSU__CSU_TAMPER_8__ENABLE {0} \
   CONFIG.PSU__CSU__CSU_TAMPER_8__ERASE_BBRAM {0} \
   CONFIG.PSU__CSU__CSU_TAMPER_9__ENABLE {0} \
   CONFIG.PSU__CSU__CSU_TAMPER_9__ERASE_BBRAM {0} \
   CONFIG.PSU__CSU__PERIPHERAL__ENABLE {0} \
   CONFIG.PSU__DDRC__ADDR_MIRROR {0} \
   CONFIG.PSU__DDRC__AL {0} \
   CONFIG.PSU__DDRC__BANK_ADDR_COUNT {2} \
   CONFIG.PSU__DDRC__BG_ADDR_COUNT {1} \
   CONFIG.PSU__DDRC__BRC_MAPPING {ROW_BANK_COL} \
   CONFIG.PSU__DDRC__BUS_WIDTH {64 Bit} \
   CONFIG.PSU__DDRC__CL {15} \
   CONFIG.PSU__DDRC__CLOCK_STOP_EN {0} \
   CONFIG.PSU__DDRC__COL_ADDR_COUNT {10} \
   CONFIG.PSU__DDRC__COMPONENTS {UDIMM} \
   CONFIG.PSU__DDRC__CWL {14} \
   CONFIG.PSU__DDRC__DDR3L_T_REF_RANGE {NA} \
   CONFIG.PSU__DDRC__DDR3_T_REF_RANGE {NA} \
   CONFIG.PSU__DDRC__DDR4_ADDR_MAPPING {0} \
   CONFIG.PSU__DDRC__DDR4_CAL_MODE_ENABLE {0} \
   CONFIG.PSU__DDRC__DDR4_CRC_CONTROL {0} \
   CONFIG.PSU__DDRC__DDR4_MAXPWR_SAVING_EN {0} \
   CONFIG.PSU__DDRC__DDR4_T_REF_MODE {0} \
   CONFIG.PSU__DDRC__DDR4_T_REF_RANGE {Normal (0-85)} \
   CONFIG.PSU__DDRC__DEEP_PWR_DOWN_EN {0} \
   CONFIG.PSU__DDRC__DEVICE_CAPACITY {8192 MBits} \
   CONFIG.PSU__DDRC__DIMM_ADDR_MIRROR {0} \
   CONFIG.PSU__DDRC__DM_DBI {DM_NO_DBI} \
   CONFIG.PSU__DDRC__DQMAP_0_3 {0} \
   CONFIG.PSU__DDRC__DQMAP_12_15 {0} \
   CONFIG.PSU__DDRC__DQMAP_16_19 {0} \
   CONFIG.PSU__DDRC__DQMAP_20_23 {0} \
   CONFIG.PSU__DDRC__DQMAP_24_27 {0} \
   CONFIG.PSU__DDRC__DQMAP_28_31 {0} \
   CONFIG.PSU__DDRC__DQMAP_32_35 {0} \
   CONFIG.PSU__DDRC__DQMAP_36_39 {0} \
   CONFIG.PSU__DDRC__DQMAP_40_43 {0} \
   CONFIG.PSU__DDRC__DQMAP_44_47 {0} \
   CONFIG.PSU__DDRC__DQMAP_48_51 {0} \
   CONFIG.PSU__DDRC__DQMAP_4_7 {0} \
   CONFIG.PSU__DDRC__DQMAP_52_55 {0} \
   CONFIG.PSU__DDRC__DQMAP_56_59 {0} \
   CONFIG.PSU__DDRC__DQMAP_60_63 {0} \
   CONFIG.PSU__DDRC__DQMAP_64_67 {0} \
   CONFIG.PSU__DDRC__DQMAP_68_71 {0} \
   CONFIG.PSU__DDRC__DQMAP_8_11 {0} \
   CONFIG.PSU__DDRC__DRAM_WIDTH {16 Bits} \
   CONFIG.PSU__DDRC__ECC {Disabled} \
   CONFIG.PSU__DDRC__ECC_SCRUB {0} \
   CONFIG.PSU__DDRC__ENABLE {1} \
   CONFIG.PSU__DDRC__ENABLE_2T_TIMING {0} \
   CONFIG.PSU__DDRC__ENABLE_DP_SWITCH {0} \
   CONFIG.PSU__DDRC__ENABLE_LP4_HAS_ECC_COMP {0} \
   CONFIG.PSU__DDRC__ENABLE_LP4_SLOWBOOT {0} \
   CONFIG.PSU__DDRC__EN_2ND_CLK {0} \
   CONFIG.PSU__DDRC__FGRM {1X} \
   CONFIG.PSU__DDRC__FREQ_MHZ {1} \
   CONFIG.PSU__DDRC__LPDDR3_DUALRANK_SDP {0} \
   CONFIG.PSU__DDRC__LPDDR3_T_REF_RANGE {NA} \
   CONFIG.PSU__DDRC__LPDDR4_T_REF_RANGE {NA} \
   CONFIG.PSU__DDRC__LP_ASR {manual normal} \
   CONFIG.PSU__DDRC__MEMORY_TYPE {DDR 4} \
   CONFIG.PSU__DDRC__PARITY_ENABLE {0} \
   CONFIG.PSU__DDRC__PER_BANK_REFRESH {0} \
   CONFIG.PSU__DDRC__PHY_DBI_MODE {0} \
   CONFIG.PSU__DDRC__PLL_BYPASS {0} \
   CONFIG.PSU__DDRC__PWR_DOWN_EN {0} \
   CONFIG.PSU__DDRC__RANK_ADDR_COUNT {0} \
   CONFIG.PSU__DDRC__RD_DQS_CENTER {0} \
   CONFIG.PSU__DDRC__ROW_ADDR_COUNT {16} \
   CONFIG.PSU__DDRC__SB_TARGET {15-15-15} \
   CONFIG.PSU__DDRC__SELF_REF_ABORT {0} \
   CONFIG.PSU__DDRC__SPEED_BIN {DDR4_2133P} \
   CONFIG.PSU__DDRC__STATIC_RD_MODE {0} \
   CONFIG.PSU__DDRC__TRAIN_DATA_EYE {1} \
   CONFIG.PSU__DDRC__TRAIN_READ_GATE {1} \
   CONFIG.PSU__DDRC__TRAIN_WRITE_LEVEL {1} \
   CONFIG.PSU__DDRC__T_FAW {30.0} \
   CONFIG.PSU__DDRC__T_RAS_MIN {33} \
   CONFIG.PSU__DDRC__T_RC {47.06} \
   CONFIG.PSU__DDRC__T_RCD {15} \
   CONFIG.PSU__DDRC__T_RP {15} \
   CONFIG.PSU__DDRC__VENDOR_PART {OTHERS} \
   CONFIG.PSU__DDRC__VIDEO_BUFFER_SIZE {0} \
   CONFIG.PSU__DDRC__VREF {1} \
   CONFIG.PSU__DDR_HIGH_ADDRESS_GUI_ENABLE {1} \
   CONFIG.PSU__DDR_QOS_ENABLE {0} \
   CONFIG.PSU__DDR_QOS_FIX_HP0_RDQOS {} \
   CONFIG.PSU__DDR_QOS_FIX_HP0_WRQOS {} \
   CONFIG.PSU__DDR_QOS_FIX_HP1_RDQOS {} \
   CONFIG.PSU__DDR_QOS_FIX_HP1_WRQOS {} \
   CONFIG.PSU__DDR_QOS_FIX_HP2_RDQOS {} \
   CONFIG.PSU__DDR_QOS_FIX_HP2_WRQOS {} \
   CONFIG.PSU__DDR_QOS_FIX_HP3_RDQOS {} \
   CONFIG.PSU__DDR_QOS_FIX_HP3_WRQOS {} \
   CONFIG.PSU__DDR_QOS_HP0_RDQOS {} \
   CONFIG.PSU__DDR_QOS_HP0_WRQOS {} \
   CONFIG.PSU__DDR_QOS_HP1_RDQOS {} \
   CONFIG.PSU__DDR_QOS_HP1_WRQOS {} \
   CONFIG.PSU__DDR_QOS_HP2_RDQOS {} \
   CONFIG.PSU__DDR_QOS_HP2_WRQOS {} \
   CONFIG.PSU__DDR_QOS_HP3_RDQOS {} \
   CONFIG.PSU__DDR_QOS_HP3_WRQOS {} \
   CONFIG.PSU__DDR_QOS_RD_HPR_THRSHLD {} \
   CONFIG.PSU__DDR_QOS_RD_LPR_THRSHLD {} \
   CONFIG.PSU__DDR_QOS_WR_THRSHLD {} \
   CONFIG.PSU__DDR_SW_REFRESH_ENABLED {1} \
   CONFIG.PSU__DDR__INTERFACE__FREQMHZ {533.500} \
   CONFIG.PSU__DEVICE_TYPE {RFSOC} \
   CONFIG.PSU__DISPLAYPORT__LANE0__ENABLE {1} \
   CONFIG.PSU__DISPLAYPORT__LANE0__IO {GT Lane1} \
   CONFIG.PSU__DISPLAYPORT__LANE1__ENABLE {1} \
   CONFIG.PSU__DISPLAYPORT__LANE1__IO {GT Lane0} \
   CONFIG.PSU__DISPLAYPORT__PERIPHERAL__ENABLE {1} \
   CONFIG.PSU__DLL__ISUSED {1} \
   CONFIG.PSU__DPAUX__PERIPHERAL__ENABLE {1} \
   CONFIG.PSU__DPAUX__PERIPHERAL__IO {MIO 27 .. 30} \
   CONFIG.PSU__DP__LANE_SEL {Dual Lower} \
   CONFIG.PSU__DP__REF_CLK_FREQ {27} \
   CONFIG.PSU__DP__REF_CLK_SEL {Ref Clk1} \
   CONFIG.PSU__ENABLE__DDR__REFRESH__SIGNALS {0} \
   CONFIG.PSU__ENET0__FIFO__ENABLE {0} \
   CONFIG.PSU__ENET0__GRP_MDIO__ENABLE {0} \
   CONFIG.PSU__ENET0__PERIPHERAL__ENABLE {0} \
   CONFIG.PSU__ENET0__PTP__ENABLE {0} \
   CONFIG.PSU__ENET0__TSU__ENABLE {0} \
   CONFIG.PSU__ENET1__FIFO__ENABLE {0} \
   CONFIG.PSU__ENET1__GRP_MDIO__ENABLE {0} \
   CONFIG.PSU__ENET1__PERIPHERAL__ENABLE {0} \
   CONFIG.PSU__ENET1__PTP__ENABLE {0} \
   CONFIG.PSU__ENET1__TSU__ENABLE {0} \
   CONFIG.PSU__ENET2__FIFO__ENABLE {0} \
   CONFIG.PSU__ENET2__GRP_MDIO__ENABLE {0} \
   CONFIG.PSU__ENET2__PERIPHERAL__ENABLE {0} \
   CONFIG.PSU__ENET2__PTP__ENABLE {0} \
   CONFIG.PSU__ENET2__TSU__ENABLE {0} \
   CONFIG.PSU__ENET3__FIFO__ENABLE {0} \
   CONFIG.PSU__ENET3__GRP_MDIO__ENABLE {1} \
   CONFIG.PSU__ENET3__GRP_MDIO__IO {MIO 76 .. 77} \
   CONFIG.PSU__ENET3__PERIPHERAL__ENABLE {1} \
   CONFIG.PSU__ENET3__PERIPHERAL__IO {MIO 64 .. 75} \
   CONFIG.PSU__ENET3__PTP__ENABLE {0} \
   CONFIG.PSU__ENET3__TSU__ENABLE {0} \
   CONFIG.PSU__EN_AXI_STATUS_PORTS {0} \
   CONFIG.PSU__EN_EMIO_TRACE {0} \
   CONFIG.PSU__EP__IP {0} \
   CONFIG.PSU__EXPAND__CORESIGHT {0} \
   CONFIG.PSU__EXPAND__FPD_SLAVES {0} \
   CONFIG.PSU__EXPAND__GIC {0} \
   CONFIG.PSU__EXPAND__LOWER_LPS_SLAVES {0} \
   CONFIG.PSU__EXPAND__UPPER_LPS_SLAVES {0} \
   CONFIG.PSU__FPDMASTERS_COHERENCY {0} \
   CONFIG.PSU__FPD_SLCR__WDT1__ACT_FREQMHZ {99.999001} \
   CONFIG.PSU__FPD_SLCR__WDT1__FREQMHZ {99.999001} \
   CONFIG.PSU__FPD_SLCR__WDT_CLK_SEL__SELECT {APB} \
   CONFIG.PSU__FPGA_PL0_ENABLE {1} \
   CONFIG.PSU__FPGA_PL1_ENABLE {0} \
   CONFIG.PSU__FPGA_PL2_ENABLE {0} \
   CONFIG.PSU__FPGA_PL3_ENABLE {0} \
   CONFIG.PSU__FP__POWER__ON {1} \
   CONFIG.PSU__FTM__CTI_IN_0 {0} \
   CONFIG.PSU__FTM__CTI_IN_1 {0} \
   CONFIG.PSU__FTM__CTI_IN_2 {0} \
   CONFIG.PSU__FTM__CTI_IN_3 {0} \
   CONFIG.PSU__FTM__CTI_OUT_0 {0} \
   CONFIG.PSU__FTM__CTI_OUT_1 {0} \
   CONFIG.PSU__FTM__CTI_OUT_2 {0} \
   CONFIG.PSU__FTM__CTI_OUT_3 {0} \
   CONFIG.PSU__FTM__GPI {0} \
   CONFIG.PSU__FTM__GPO {0} \
   CONFIG.PSU__GEM0_COHERENCY {0} \
   CONFIG.PSU__GEM0_ROUTE_THROUGH_FPD {0} \
   CONFIG.PSU__GEM1_COHERENCY {0} \
   CONFIG.PSU__GEM1_ROUTE_THROUGH_FPD {0} \
   CONFIG.PSU__GEM2_COHERENCY {0} \
   CONFIG.PSU__GEM2_ROUTE_THROUGH_FPD {0} \
   CONFIG.PSU__GEM3_COHERENCY {0} \
   CONFIG.PSU__GEM3_ROUTE_THROUGH_FPD {0} \
   CONFIG.PSU__GEM__TSU__ENABLE {0} \
   CONFIG.PSU__GEN_IPI_0__MASTER {APU} \
   CONFIG.PSU__GEN_IPI_10__MASTER {NONE} \
   CONFIG.PSU__GEN_IPI_1__MASTER {RPU0} \
   CONFIG.PSU__GEN_IPI_2__MASTER {RPU1} \
   CONFIG.PSU__GEN_IPI_3__MASTER {PMU} \
   CONFIG.PSU__GEN_IPI_4__MASTER {PMU} \
   CONFIG.PSU__GEN_IPI_5__MASTER {PMU} \
   CONFIG.PSU__GEN_IPI_6__MASTER {PMU} \
   CONFIG.PSU__GEN_IPI_7__MASTER {NONE} \
   CONFIG.PSU__GEN_IPI_8__MASTER {NONE} \
   CONFIG.PSU__GEN_IPI_9__MASTER {NONE} \
   CONFIG.PSU__GPIO0_MIO__IO {MIO 0 .. 25} \
   CONFIG.PSU__GPIO0_MIO__PERIPHERAL__ENABLE {1} \
   CONFIG.PSU__GPIO1_MIO__IO {MIO 26 .. 51} \
   CONFIG.PSU__GPIO1_MIO__PERIPHERAL__ENABLE {1} \
   CONFIG.PSU__GPIO2_MIO__PERIPHERAL__ENABLE {0} \
   CONFIG.PSU__GPIO_EMIO_WIDTH {1} \
   CONFIG.PSU__GPIO_EMIO__PERIPHERAL__ENABLE {0} \
   CONFIG.PSU__GPIO_EMIO__WIDTH {[94:0]} \
   CONFIG.PSU__GPU_PP0__POWER__ON {0} \
   CONFIG.PSU__GPU_PP1__POWER__ON {0} \
   CONFIG.PSU__GT_REF_CLK__FREQMHZ {33.333} \
   CONFIG.PSU__GT__LINK_SPEED {HBR} \
   CONFIG.PSU__GT__PRE_EMPH_LVL_4 {0} \
   CONFIG.PSU__GT__VLT_SWNG_LVL_4 {0} \
   CONFIG.PSU__HIGH_ADDRESS__ENABLE {1} \
   CONFIG.PSU__HPM0_FPD__NUM_READ_THREADS {4} \
   CONFIG.PSU__HPM0_FPD__NUM_WRITE_THREADS {4} \
   CONFIG.PSU__HPM0_LPD__NUM_READ_THREADS {4} \
   CONFIG.PSU__HPM0_LPD__NUM_WRITE_THREADS {4} \
   CONFIG.PSU__HPM1_FPD__NUM_READ_THREADS {4} \
   CONFIG.PSU__HPM1_FPD__NUM_WRITE_THREADS {4} \
   CONFIG.PSU__I2C0_LOOP_I2C1__ENABLE {0} \
   CONFIG.PSU__I2C0__GRP_INT__ENABLE {0} \
   CONFIG.PSU__I2C0__PERIPHERAL__ENABLE {1} \
   CONFIG.PSU__I2C0__PERIPHERAL__IO {MIO 14 .. 15} \
   CONFIG.PSU__I2C1__GRP_INT__ENABLE {0} \
   CONFIG.PSU__I2C1__PERIPHERAL__ENABLE {1} \
   CONFIG.PSU__I2C1__PERIPHERAL__IO {MIO 16 .. 17} \
   CONFIG.PSU__IOU_SLCR__IOU_TTC_APB_CLK__TTC0_SEL {APB} \
   CONFIG.PSU__IOU_SLCR__IOU_TTC_APB_CLK__TTC1_SEL {APB} \
   CONFIG.PSU__IOU_SLCR__IOU_TTC_APB_CLK__TTC2_SEL {APB} \
   CONFIG.PSU__IOU_SLCR__IOU_TTC_APB_CLK__TTC3_SEL {APB} \
   CONFIG.PSU__IOU_SLCR__TTC0__ACT_FREQMHZ {100.000000} \
   CONFIG.PSU__IOU_SLCR__TTC0__FREQMHZ {100.000000} \
   CONFIG.PSU__IOU_SLCR__TTC1__ACT_FREQMHZ {100.000000} \
   CONFIG.PSU__IOU_SLCR__TTC1__FREQMHZ {100.000000} \
   CONFIG.PSU__IOU_SLCR__TTC2__ACT_FREQMHZ {100.000000} \
   CONFIG.PSU__IOU_SLCR__TTC2__FREQMHZ {100.000000} \
   CONFIG.PSU__IOU_SLCR__TTC3__ACT_FREQMHZ {100.000000} \
   CONFIG.PSU__IOU_SLCR__TTC3__FREQMHZ {100.000000} \
   CONFIG.PSU__IOU_SLCR__WDT0__ACT_FREQMHZ {99.999001} \
   CONFIG.PSU__IOU_SLCR__WDT0__FREQMHZ {99.999001} \
   CONFIG.PSU__IOU_SLCR__WDT_CLK_SEL__SELECT {APB} \
   CONFIG.PSU__IRQ_P2F_ADMA_CHAN__INT {0} \
   CONFIG.PSU__IRQ_P2F_AIB_AXI__INT {0} \
   CONFIG.PSU__IRQ_P2F_AMS__INT {0} \
   CONFIG.PSU__IRQ_P2F_APM_FPD__INT {0} \
   CONFIG.PSU__IRQ_P2F_APU_COMM__INT {0} \
   CONFIG.PSU__IRQ_P2F_APU_CPUMNT__INT {0} \
   CONFIG.PSU__IRQ_P2F_APU_CTI__INT {0} \
   CONFIG.PSU__IRQ_P2F_APU_EXTERR__INT {0} \
   CONFIG.PSU__IRQ_P2F_APU_IPI__INT {0} \
   CONFIG.PSU__IRQ_P2F_APU_L2ERR__INT {0} \
   CONFIG.PSU__IRQ_P2F_APU_PMU__INT {0} \
   CONFIG.PSU__IRQ_P2F_APU_REGS__INT {0} \
   CONFIG.PSU__IRQ_P2F_ATB_LPD__INT {0} \
   CONFIG.PSU__IRQ_P2F_CAN0__INT {0} \
   CONFIG.PSU__IRQ_P2F_CAN1__INT {0} \
   CONFIG.PSU__IRQ_P2F_CLKMON__INT {0} \
   CONFIG.PSU__IRQ_P2F_CSUPMU_WDT__INT {0} \
   CONFIG.PSU__IRQ_P2F_CSU_DMA__INT {0} \
   CONFIG.PSU__IRQ_P2F_CSU__INT {0} \
   CONFIG.PSU__IRQ_P2F_DDR_SS__INT {0} \
   CONFIG.PSU__IRQ_P2F_DPDMA__INT {0} \
   CONFIG.PSU__IRQ_P2F_DPORT__INT {0} \
   CONFIG.PSU__IRQ_P2F_EFUSE__INT {0} \
   CONFIG.PSU__IRQ_P2F_ENT0_WAKEUP__INT {0} \
   CONFIG.PSU__IRQ_P2F_ENT0__INT {0} \
   CONFIG.PSU__IRQ_P2F_ENT1_WAKEUP__INT {0} \
   CONFIG.PSU__IRQ_P2F_ENT1__INT {0} \
   CONFIG.PSU__IRQ_P2F_ENT2_WAKEUP__INT {0} \
   CONFIG.PSU__IRQ_P2F_ENT2__INT {0} \
   CONFIG.PSU__IRQ_P2F_ENT3_WAKEUP__INT {0} \
   CONFIG.PSU__IRQ_P2F_ENT3__INT {0} \
   CONFIG.PSU__IRQ_P2F_FPD_APB__INT {0} \
   CONFIG.PSU__IRQ_P2F_FPD_ATB_ERR__INT {0} \
   CONFIG.PSU__IRQ_P2F_FP_WDT__INT {0} \
   CONFIG.PSU__IRQ_P2F_GDMA_CHAN__INT {0} \
   CONFIG.PSU__IRQ_P2F_GPIO__INT {0} \
   CONFIG.PSU__IRQ_P2F_GPU__INT {0} \
   CONFIG.PSU__IRQ_P2F_I2C0__INT {0} \
   CONFIG.PSU__IRQ_P2F_I2C1__INT {0} \
   CONFIG.PSU__IRQ_P2F_LPD_APB__INT {0} \
   CONFIG.PSU__IRQ_P2F_LPD_APM__INT {0} \
   CONFIG.PSU__IRQ_P2F_LP_WDT__INT {0} \
   CONFIG.PSU__IRQ_P2F_NAND__INT {0} \
   CONFIG.PSU__IRQ_P2F_OCM_ERR__INT {0} \
   CONFIG.PSU__IRQ_P2F_PCIE_DMA__INT {0} \
   CONFIG.PSU__IRQ_P2F_PCIE_LEGACY__INT {0} \
   CONFIG.PSU__IRQ_P2F_PCIE_MSC__INT {0} \
   CONFIG.PSU__IRQ_P2F_PCIE_MSI__INT {0} \
   CONFIG.PSU__IRQ_P2F_PL_IPI__INT {0} \
   CONFIG.PSU__IRQ_P2F_QSPI__INT {0} \
   CONFIG.PSU__IRQ_P2F_R5_CORE0_ECC_ERR__INT {0} \
   CONFIG.PSU__IRQ_P2F_R5_CORE1_ECC_ERR__INT {0} \
   CONFIG.PSU__IRQ_P2F_RPU_IPI__INT {0} \
   CONFIG.PSU__IRQ_P2F_RPU_PERMON__INT {0} \
   CONFIG.PSU__IRQ_P2F_RTC_ALARM__INT {0} \
   CONFIG.PSU__IRQ_P2F_RTC_SECONDS__INT {0} \
   CONFIG.PSU__IRQ_P2F_SATA__INT {0} \
   CONFIG.PSU__IRQ_P2F_SDIO0_WAKE__INT {0} \
   CONFIG.PSU__IRQ_P2F_SDIO0__INT {0} \
   CONFIG.PSU__IRQ_P2F_SDIO1_WAKE__INT {0} \
   CONFIG.PSU__IRQ_P2F_SDIO1__INT {0} \
   CONFIG.PSU__IRQ_P2F_SPI0__INT {0} \
   CONFIG.PSU__IRQ_P2F_SPI1__INT {0} \
   CONFIG.PSU__IRQ_P2F_TTC0__INT0 {0} \
   CONFIG.PSU__IRQ_P2F_TTC0__INT1 {0} \
   CONFIG.PSU__IRQ_P2F_TTC0__INT2 {0} \
   CONFIG.PSU__IRQ_P2F_TTC1__INT0 {0} \
   CONFIG.PSU__IRQ_P2F_TTC1__INT1 {0} \
   CONFIG.PSU__IRQ_P2F_TTC1__INT2 {0} \
   CONFIG.PSU__IRQ_P2F_TTC2__INT0 {0} \
   CONFIG.PSU__IRQ_P2F_TTC2__INT1 {0} \
   CONFIG.PSU__IRQ_P2F_TTC2__INT2 {0} \
   CONFIG.PSU__IRQ_P2F_TTC3__INT0 {0} \
   CONFIG.PSU__IRQ_P2F_TTC3__INT1 {0} \
   CONFIG.PSU__IRQ_P2F_TTC3__INT2 {0} \
   CONFIG.PSU__IRQ_P2F_UART0__INT {0} \
   CONFIG.PSU__IRQ_P2F_UART1__INT {0} \
   CONFIG.PSU__IRQ_P2F_USB3_ENDPOINT__INT0 {0} \
   CONFIG.PSU__IRQ_P2F_USB3_ENDPOINT__INT1 {0} \
   CONFIG.PSU__IRQ_P2F_USB3_OTG__INT0 {0} \
   CONFIG.PSU__IRQ_P2F_USB3_OTG__INT1 {0} \
   CONFIG.PSU__IRQ_P2F_USB3_PMU_WAKEUP__INT {0} \
   CONFIG.PSU__IRQ_P2F_XMPU_FPD__INT {0} \
   CONFIG.PSU__IRQ_P2F_XMPU_LPD__INT {0} \
   CONFIG.PSU__IRQ_P2F__INTF_FPD_SMMU__INT {0} \
   CONFIG.PSU__IRQ_P2F__INTF_PPD_CCI__INT {0} \
   CONFIG.PSU__L2_BANK0__POWER__ON {1} \
   CONFIG.PSU__LPDMA0_COHERENCY {0} \
   CONFIG.PSU__LPDMA1_COHERENCY {0} \
   CONFIG.PSU__LPDMA2_COHERENCY {0} \
   CONFIG.PSU__LPDMA3_COHERENCY {0} \
   CONFIG.PSU__LPDMA4_COHERENCY {0} \
   CONFIG.PSU__LPDMA5_COHERENCY {0} \
   CONFIG.PSU__LPDMA6_COHERENCY {0} \
   CONFIG.PSU__LPDMA7_COHERENCY {0} \
   CONFIG.PSU__LPD_SLCR__CSUPMU_WDT_CLK_SEL__SELECT {APB} \
   CONFIG.PSU__LPD_SLCR__CSUPMU__ACT_FREQMHZ {100.000000} \
   CONFIG.PSU__LPD_SLCR__CSUPMU__FREQMHZ {100.000000} \
   CONFIG.PSU__MAXIGP0__DATA_WIDTH {128} \
   CONFIG.PSU__MAXIGP1__DATA_WIDTH {128} \
   CONFIG.PSU__MAXIGP2__DATA_WIDTH {32} \
   CONFIG.PSU__M_AXI_GP0_SUPPORTS_NARROW_BURST {1} \
   CONFIG.PSU__M_AXI_GP1_SUPPORTS_NARROW_BURST {1} \
   CONFIG.PSU__M_AXI_GP2_SUPPORTS_NARROW_BURST {1} \
   CONFIG.PSU__NAND_COHERENCY {0} \
   CONFIG.PSU__NAND_ROUTE_THROUGH_FPD {0} \
   CONFIG.PSU__NAND__CHIP_ENABLE__ENABLE {0} \
   CONFIG.PSU__NAND__DATA_STROBE__ENABLE {0} \
   CONFIG.PSU__NAND__PERIPHERAL__ENABLE {0} \
   CONFIG.PSU__NAND__READY0_BUSY__ENABLE {0} \
   CONFIG.PSU__NAND__READY1_BUSY__ENABLE {0} \
   CONFIG.PSU__NAND__READY_BUSY__ENABLE {0} \
   CONFIG.PSU__NUM_FABRIC_RESETS {1} \
   CONFIG.PSU__OCM_BANK0__POWER__ON {1} \
   CONFIG.PSU__OCM_BANK1__POWER__ON {1} \
   CONFIG.PSU__OCM_BANK2__POWER__ON {1} \
   CONFIG.PSU__OCM_BANK3__POWER__ON {1} \
   CONFIG.PSU__OVERRIDE_HPX_QOS {0} \
   CONFIG.PSU__OVERRIDE__BASIC_CLOCK {0} \
   CONFIG.PSU__PCIE__ACS_VIOLAION {0} \
   CONFIG.PSU__PCIE__ACS_VIOLATION {0} \
   CONFIG.PSU__PCIE__AER_CAPABILITY {0} \
   CONFIG.PSU__PCIE__ATOMICOP_EGRESS_BLOCKED {0} \
   CONFIG.PSU__PCIE__BAR0_64BIT {0} \
   CONFIG.PSU__PCIE__BAR0_ENABLE {0} \
   CONFIG.PSU__PCIE__BAR0_PREFETCHABLE {0} \
   CONFIG.PSU__PCIE__BAR0_VAL {} \
   CONFIG.PSU__PCIE__BAR1_64BIT {0} \
   CONFIG.PSU__PCIE__BAR1_ENABLE {0} \
   CONFIG.PSU__PCIE__BAR1_PREFETCHABLE {0} \
   CONFIG.PSU__PCIE__BAR1_VAL {} \
   CONFIG.PSU__PCIE__BAR2_64BIT {0} \
   CONFIG.PSU__PCIE__BAR2_ENABLE {0} \
   CONFIG.PSU__PCIE__BAR2_PREFETCHABLE {0} \
   CONFIG.PSU__PCIE__BAR2_VAL {} \
   CONFIG.PSU__PCIE__BAR3_64BIT {0} \
   CONFIG.PSU__PCIE__BAR3_ENABLE {0} \
   CONFIG.PSU__PCIE__BAR3_PREFETCHABLE {0} \
   CONFIG.PSU__PCIE__BAR3_VAL {} \
   CONFIG.PSU__PCIE__BAR4_64BIT {0} \
   CONFIG.PSU__PCIE__BAR4_ENABLE {0} \
   CONFIG.PSU__PCIE__BAR4_PREFETCHABLE {0} \
   CONFIG.PSU__PCIE__BAR4_VAL {} \
   CONFIG.PSU__PCIE__BAR5_64BIT {0} \
   CONFIG.PSU__PCIE__BAR5_ENABLE {0} \
   CONFIG.PSU__PCIE__BAR5_PREFETCHABLE {0} \
   CONFIG.PSU__PCIE__BAR5_VAL {} \
   CONFIG.PSU__PCIE__CLASS_CODE_BASE {} \
   CONFIG.PSU__PCIE__CLASS_CODE_INTERFACE {} \
   CONFIG.PSU__PCIE__CLASS_CODE_SUB {} \
   CONFIG.PSU__PCIE__CLASS_CODE_VALUE {} \
   CONFIG.PSU__PCIE__COMPLETER_ABORT {0} \
   CONFIG.PSU__PCIE__COMPLTION_TIMEOUT {0} \
   CONFIG.PSU__PCIE__CORRECTABLE_INT_ERR {0} \
   CONFIG.PSU__PCIE__CRS_SW_VISIBILITY {0} \
   CONFIG.PSU__PCIE__DEVICE_ID {} \
   CONFIG.PSU__PCIE__ECRC_CHECK {0} \
   CONFIG.PSU__PCIE__ECRC_ERR {0} \
   CONFIG.PSU__PCIE__ECRC_GEN {0} \
   CONFIG.PSU__PCIE__EROM_ENABLE {0} \
   CONFIG.PSU__PCIE__EROM_VAL {} \
   CONFIG.PSU__PCIE__FLOW_CONTROL_ERR {0} \
   CONFIG.PSU__PCIE__FLOW_CONTROL_PROTOCOL_ERR {0} \
   CONFIG.PSU__PCIE__HEADER_LOG_OVERFLOW {0} \
   CONFIG.PSU__PCIE__INTX_GENERATION {0} \
   CONFIG.PSU__PCIE__LANE0__ENABLE {0} \
   CONFIG.PSU__PCIE__LANE1__ENABLE {0} \
   CONFIG.PSU__PCIE__LANE2__ENABLE {0} \
   CONFIG.PSU__PCIE__LANE3__ENABLE {0} \
   CONFIG.PSU__PCIE__MC_BLOCKED_TLP {0} \
   CONFIG.PSU__PCIE__MSIX_BAR_INDICATOR {} \
   CONFIG.PSU__PCIE__MSIX_CAPABILITY {0} \
   CONFIG.PSU__PCIE__MSIX_PBA_BAR_INDICATOR {} \
   CONFIG.PSU__PCIE__MSIX_PBA_OFFSET {0} \
   CONFIG.PSU__PCIE__MSIX_TABLE_OFFSET {0} \
   CONFIG.PSU__PCIE__MSIX_TABLE_SIZE {0} \
   CONFIG.PSU__PCIE__MSI_64BIT_ADDR_CAPABLE {0} \
   CONFIG.PSU__PCIE__MSI_CAPABILITY {0} \
   CONFIG.PSU__PCIE__MULTIHEADER {0} \
   CONFIG.PSU__PCIE__PERIPHERAL__ENABLE {0} \
   CONFIG.PSU__PCIE__PERIPHERAL__ENDPOINT_ENABLE {1} \
   CONFIG.PSU__PCIE__PERIPHERAL__ROOTPORT_ENABLE {0} \
   CONFIG.PSU__PCIE__PERM_ROOT_ERR_UPDATE {0} \
   CONFIG.PSU__PCIE__RECEIVER_ERR {0} \
   CONFIG.PSU__PCIE__RECEIVER_OVERFLOW {0} \
   CONFIG.PSU__PCIE__RESET__POLARITY {Active Low} \
   CONFIG.PSU__PCIE__REVISION_ID {} \
   CONFIG.PSU__PCIE__SUBSYSTEM_ID {} \
   CONFIG.PSU__PCIE__SUBSYSTEM_VENDOR_ID {} \
   CONFIG.PSU__PCIE__SURPRISE_DOWN {0} \
   CONFIG.PSU__PCIE__TLP_PREFIX_BLOCKED {0} \
   CONFIG.PSU__PCIE__UNCORRECTABL_INT_ERR {0} \
   CONFIG.PSU__PCIE__VENDOR_ID {} \
   CONFIG.PSU__PJTAG__PERIPHERAL__ENABLE {0} \
   CONFIG.PSU__PL_CLK0_BUF {TRUE} \
   CONFIG.PSU__PL_CLK1_BUF {FALSE} \
   CONFIG.PSU__PL_CLK2_BUF {FALSE} \
   CONFIG.PSU__PL_CLK3_BUF {FALSE} \
   CONFIG.PSU__PL__POWER__ON {1} \
   CONFIG.PSU__PMU_COHERENCY {0} \
   CONFIG.PSU__PMU__AIBACK__ENABLE {0} \
   CONFIG.PSU__PMU__EMIO_GPI__ENABLE {0} \
   CONFIG.PSU__PMU__EMIO_GPO__ENABLE {0} \
   CONFIG.PSU__PMU__GPI0__ENABLE {0} \
   CONFIG.PSU__PMU__GPI1__ENABLE {0} \
   CONFIG.PSU__PMU__GPI2__ENABLE {0} \
   CONFIG.PSU__PMU__GPI3__ENABLE {0} \
   CONFIG.PSU__PMU__GPI4__ENABLE {0} \
   CONFIG.PSU__PMU__GPI5__ENABLE {0} \
   CONFIG.PSU__PMU__GPO0__ENABLE {1} \
   CONFIG.PSU__PMU__GPO0__IO {MIO 32} \
   CONFIG.PSU__PMU__GPO1__ENABLE {1} \
   CONFIG.PSU__PMU__GPO1__IO {MIO 33} \
   CONFIG.PSU__PMU__GPO2__ENABLE {1} \
   CONFIG.PSU__PMU__GPO2__IO {MIO 34} \
   CONFIG.PSU__PMU__GPO2__POLARITY {low} \
   CONFIG.PSU__PMU__GPO3__ENABLE {1} \
   CONFIG.PSU__PMU__GPO3__IO {MIO 35} \
   CONFIG.PSU__PMU__GPO3__POLARITY {low} \
   CONFIG.PSU__PMU__GPO4__ENABLE {1} \
   CONFIG.PSU__PMU__GPO4__IO {MIO 36} \
   CONFIG.PSU__PMU__GPO4__POLARITY {low} \
   CONFIG.PSU__PMU__GPO5__ENABLE {1} \
   CONFIG.PSU__PMU__GPO5__IO {MIO 37} \
   CONFIG.PSU__PMU__GPO5__POLARITY {low} \
   CONFIG.PSU__PMU__PERIPHERAL__ENABLE {1} \
   CONFIG.PSU__PMU__PLERROR__ENABLE {0} \
   CONFIG.PSU__PRESET_APPLIED {1} \
   CONFIG.PSU__PROTECTION__DDR_SEGMENTS {NONE} \
   CONFIG.PSU__PROTECTION__DEBUG {0} \
   CONFIG.PSU__PROTECTION__ENABLE {0} \
   CONFIG.PSU__PROTECTION__FPD_SEGMENTS {SA:0xFD1A0000; SIZE:1280; UNIT:KB; RegionTZ:Secure; WrAllowed:Read/Write; subsystemId:PMU Firmware| SA:0xFD000000; SIZE:64; UNIT:KB; RegionTZ:Secure; WrAllowed:Read/Write; subsystemId:PMU Firmware| SA:0xFD010000; SIZE:64; UNIT:KB; RegionTZ:Secure; WrAllowed:Read/Write; subsystemId:PMU Firmware| SA:0xFD020000; SIZE:64; UNIT:KB; RegionTZ:Secure; WrAllowed:Read/Write; subsystemId:PMU Firmware| SA:0xFD030000; SIZE:64; UNIT:KB; RegionTZ:Secure; WrAllowed:Read/Write; subsystemId:PMU Firmware| SA:0xFD040000; SIZE:64; UNIT:KB; RegionTZ:Secure; WrAllowed:Read/Write; subsystemId:PMU Firmware| SA:0xFD050000; SIZE:64; UNIT:KB; RegionTZ:Secure; WrAllowed:Read/Write; subsystemId:PMU Firmware| SA:0xFD610000; SIZE:512; UNIT:KB; RegionTZ:Secure; WrAllowed:Read/Write; subsystemId:PMU Firmware| SA:0xFD5D0000; SIZE:64; UNIT:KB; RegionTZ:Secure; WrAllowed:Read/Write; subsystemId:PMU Firmware|SA:0xFD1A0000 ; SIZE:1280; UNIT:KB; RegionTZ:Secure ; WrAllowed:Read/Write; subsystemId:Secure Subsystem} \
   CONFIG.PSU__PROTECTION__LOCK_UNUSED_SEGMENTS {0} \
   CONFIG.PSU__PROTECTION__LPD_SEGMENTS {SA:0xFF980000; SIZE:64; UNIT:KB; RegionTZ:Secure; WrAllowed:Read/Write; subsystemId:PMU Firmware| SA:0xFF5E0000; SIZE:2560; UNIT:KB; RegionTZ:Secure; WrAllowed:Read/Write; subsystemId:PMU Firmware| SA:0xFFCC0000; SIZE:64; UNIT:KB; RegionTZ:Secure; WrAllowed:Read/Write; subsystemId:PMU Firmware| SA:0xFF180000; SIZE:768; UNIT:KB; RegionTZ:Secure; WrAllowed:Read/Write; subsystemId:PMU Firmware| SA:0xFF410000; SIZE:640; UNIT:KB; RegionTZ:Secure; WrAllowed:Read/Write; subsystemId:PMU Firmware| SA:0xFFA70000; SIZE:64; UNIT:KB; RegionTZ:Secure; WrAllowed:Read/Write; subsystemId:PMU Firmware| SA:0xFF9A0000; SIZE:64; UNIT:KB; RegionTZ:Secure; WrAllowed:Read/Write; subsystemId:PMU Firmware|SA:0xFF5E0000 ; SIZE:2560; UNIT:KB; RegionTZ:Secure ; WrAllowed:Read/Write; subsystemId:Secure Subsystem|SA:0xFFCC0000 ; SIZE:64; UNIT:KB; RegionTZ:Secure ; WrAllowed:Read/Write; subsystemId:Secure Subsystem|SA:0xFF180000 ; SIZE:768; UNIT:KB; RegionTZ:Secure ; WrAllowed:Read/Write; subsystemId:Secure Subsystem|SA:0xFF9A0000 ; SIZE:64; UNIT:KB; RegionTZ:Secure ; WrAllowed:Read/Write; subsystemId:Secure Subsystem} \
   CONFIG.PSU__PROTECTION__MASTERS {USB1:NonSecure;0|USB0:NonSecure;1|S_AXI_LPD:NA;0|S_AXI_HPC1_FPD:NA;0|S_AXI_HPC0_FPD:NA;0|S_AXI_HP3_FPD:NA;0|S_AXI_HP2_FPD:NA;0|S_AXI_HP1_FPD:NA;0|S_AXI_HP0_FPD:NA;1|S_AXI_ACP:NA;0|S_AXI_ACE:NA;0|SD1:NonSecure;1|SD0:NonSecure;0|SATA1:NonSecure;1|SATA0:NonSecure;1|RPU1:Secure;1|RPU0:Secure;1|QSPI:NonSecure;1|PMU:NA;1|PCIe:NonSecure;0|NAND:NonSecure;0|LDMA:NonSecure;1|GPU:NonSecure;1|GEM3:NonSecure;1|GEM2:NonSecure;0|GEM1:NonSecure;0|GEM0:NonSecure;0|FDMA:NonSecure;1|DP:NonSecure;1|DAP:NA;1|Coresight:NA;1|CSU:NA;1|APU:NA;1} \
   CONFIG.PSU__PROTECTION__MASTERS_TZ {GEM0:NonSecure|SD1:NonSecure|GEM2:NonSecure|GEM1:NonSecure|GEM3:NonSecure|PCIe:NonSecure|DP:NonSecure|NAND:NonSecure|GPU:NonSecure|USB1:NonSecure|USB0:NonSecure|LDMA:NonSecure|FDMA:NonSecure|QSPI:NonSecure|SD0:NonSecure} \
   CONFIG.PSU__PROTECTION__OCM_SEGMENTS {NONE} \
   CONFIG.PSU__PROTECTION__PRESUBSYSTEMS {NONE} \
   CONFIG.PSU__PROTECTION__SLAVES {LPD;USB3_1_XHCI;FE300000;FE3FFFFF;0|LPD;USB3_1;FF9E0000;FF9EFFFF;0|LPD;USB3_0_XHCI;FE200000;FE2FFFFF;1|LPD;USB3_0;FF9D0000;FF9DFFFF;1|LPD;UART1;FF010000;FF01FFFF;1|LPD;UART0;FF000000;FF00FFFF;1|LPD;TTC3;FF140000;FF14FFFF;1|LPD;TTC2;FF130000;FF13FFFF;1|LPD;TTC1;FF120000;FF12FFFF;1|LPD;TTC0;FF110000;FF11FFFF;1|FPD;SWDT1;FD4D0000;FD4DFFFF;1|LPD;SWDT0;FF150000;FF15FFFF;1|LPD;SPI1;FF050000;FF05FFFF;0|LPD;SPI0;FF040000;FF04FFFF;0|FPD;SMMU_REG;FD5F0000;FD5FFFFF;1|FPD;SMMU;FD800000;FDFFFFFF;1|FPD;SIOU;FD3D0000;FD3DFFFF;1|FPD;SERDES;FD400000;FD47FFFF;1|LPD;SD1;FF170000;FF17FFFF;1|LPD;SD0;FF160000;FF16FFFF;0|FPD;SATA;FD0C0000;FD0CFFFF;1|LPD;RTC;FFA60000;FFA6FFFF;1|LPD;RSA_CORE;FFCE0000;FFCEFFFF;1|LPD;RPU;FF9A0000;FF9AFFFF;1|LPD;R5_TCM_RAM_GLOBAL;FFE00000;FFE3FFFF;1|LPD;R5_1_Instruction_Cache;FFEC0000;FFECFFFF;1|LPD;R5_1_Data_Cache;FFED0000;FFEDFFFF;1|LPD;R5_1_BTCM_GLOBAL;FFEB0000;FFEBFFFF;1|LPD;R5_1_ATCM_GLOBAL;FFE90000;FFE9FFFF;1|LPD;R5_0_Instruction_Cache;FFE40000;FFE4FFFF;1|LPD;R5_0_Data_Cache;FFE50000;FFE5FFFF;1|LPD;R5_0_BTCM_GLOBAL;FFE20000;FFE2FFFF;1|LPD;R5_0_ATCM_GLOBAL;FFE00000;FFE0FFFF;1|LPD;QSPI_Linear_Address;C0000000;DFFFFFFF;1|LPD;QSPI;FF0F0000;FF0FFFFF;1|LPD;PMU_RAM;FFDC0000;FFDDFFFF;1|LPD;PMU_GLOBAL;FFD80000;FFDBFFFF;1|FPD;PCIE_MAIN;FD0E0000;FD0EFFFF;0|FPD;PCIE_LOW;E0000000;EFFFFFFF;0|FPD;PCIE_HIGH2;8000000000;BFFFFFFFFF;0|FPD;PCIE_HIGH1;600000000;7FFFFFFFF;0|FPD;PCIE_DMA;FD0F0000;FD0FFFFF;0|FPD;PCIE_ATTRIB;FD480000;FD48FFFF;0|LPD;OCM_XMPU_CFG;FFA70000;FFA7FFFF;1|LPD;OCM_SLCR;FF960000;FF96FFFF;1|OCM;OCM;FFFC0000;FFFFFFFF;1|LPD;NAND;FF100000;FF10FFFF;0|LPD;MBISTJTAG;FFCF0000;FFCFFFFF;1|LPD;LPD_XPPU_SINK;FF9C0000;FF9CFFFF;1|LPD;LPD_XPPU;FF980000;FF98FFFF;1|LPD;LPD_SLCR_SECURE;FF4B0000;FF4DFFFF;1|LPD;LPD_SLCR;FF410000;FF4AFFFF;1|LPD;LPD_GPV;FE100000;FE1FFFFF;1|LPD;LPD_DMA_7;FFAF0000;FFAFFFFF;1|LPD;LPD_DMA_6;FFAE0000;FFAEFFFF;1|LPD;LPD_DMA_5;FFAD0000;FFADFFFF;1|LPD;LPD_DMA_4;FFAC0000;FFACFFFF;1|LPD;LPD_DMA_3;FFAB0000;FFABFFFF;1|LPD;LPD_DMA_2;FFAA0000;FFAAFFFF;1|LPD;LPD_DMA_1;FFA90000;FFA9FFFF;1|LPD;LPD_DMA_0;FFA80000;FFA8FFFF;1|LPD;IPI_CTRL;FF380000;FF3FFFFF;1|LPD;IOU_SLCR;FF180000;FF23FFFF;1|LPD;IOU_SECURE_SLCR;FF240000;FF24FFFF;1|LPD;IOU_SCNTRS;FF260000;FF26FFFF;1|LPD;IOU_SCNTR;FF250000;FF25FFFF;1|LPD;IOU_GPV;FE000000;FE0FFFFF;1|LPD;I2C1;FF030000;FF03FFFF;1|LPD;I2C0;FF020000;FF02FFFF;1|FPD;GPU;FD4B0000;FD4BFFFF;0|LPD;GPIO;FF0A0000;FF0AFFFF;1|LPD;GEM3;FF0E0000;FF0EFFFF;1|LPD;GEM2;FF0D0000;FF0DFFFF;0|LPD;GEM1;FF0C0000;FF0CFFFF;0|LPD;GEM0;FF0B0000;FF0BFFFF;0|FPD;FPD_XMPU_SINK;FD4F0000;FD4FFFFF;1|FPD;FPD_XMPU_CFG;FD5D0000;FD5DFFFF;1|FPD;FPD_SLCR_SECURE;FD690000;FD6CFFFF;1|FPD;FPD_SLCR;FD610000;FD68FFFF;1|FPD;FPD_GPV;FD700000;FD7FFFFF;1|FPD;FPD_DMA_CH7;FD570000;FD57FFFF;1|FPD;FPD_DMA_CH6;FD560000;FD56FFFF;1|FPD;FPD_DMA_CH5;FD550000;FD55FFFF;1|FPD;FPD_DMA_CH4;FD540000;FD54FFFF;1|FPD;FPD_DMA_CH3;FD530000;FD53FFFF;1|FPD;FPD_DMA_CH2;FD520000;FD52FFFF;1|FPD;FPD_DMA_CH1;FD510000;FD51FFFF;1|FPD;FPD_DMA_CH0;FD500000;FD50FFFF;1|LPD;EFUSE;FFCC0000;FFCCFFFF;1|FPD;Display Port;FD4A0000;FD4AFFFF;1|FPD;DPDMA;FD4C0000;FD4CFFFF;1|FPD;DDR_XMPU5_CFG;FD050000;FD05FFFF;1|FPD;DDR_XMPU4_CFG;FD040000;FD04FFFF;1|FPD;DDR_XMPU3_CFG;FD030000;FD03FFFF;1|FPD;DDR_XMPU2_CFG;FD020000;FD02FFFF;1|FPD;DDR_XMPU1_CFG;FD010000;FD01FFFF;1|FPD;DDR_XMPU0_CFG;FD000000;FD00FFFF;1|FPD;DDR_QOS_CTRL;FD090000;FD09FFFF;1|FPD;DDR_PHY;FD080000;FD08FFFF;1|DDR;DDR_LOW;0;7FFFFFFF;1|DDR;DDR_HIGH;800000000;87FFFFFFF;1|FPD;DDDR_CTRL;FD070000;FD070FFF;1|LPD;Coresight;FE800000;FEFFFFFF;1|LPD;CSU_DMA;FFC80000;FFC9FFFF;1|LPD;CSU;FFCA0000;FFCAFFFF;0|LPD;CRL_APB;FF5E0000;FF85FFFF;1|FPD;CRF_APB;FD1A0000;FD2DFFFF;1|FPD;CCI_REG;FD5E0000;FD5EFFFF;1|FPD;CCI_GPV;FD6E0000;FD6EFFFF;1|LPD;CAN1;FF070000;FF07FFFF;0|LPD;CAN0;FF060000;FF06FFFF;0|FPD;APU;FD5C0000;FD5CFFFF;1|LPD;APM_INTC_IOU;FFA20000;FFA2FFFF;1|LPD;APM_FPD_LPD;FFA30000;FFA3FFFF;1|FPD;APM_5;FD490000;FD49FFFF;1|FPD;APM_0;FD0B0000;FD0BFFFF;1|LPD;APM2;FFA10000;FFA1FFFF;1|LPD;APM1;FFA00000;FFA0FFFF;1|LPD;AMS;FFA50000;FFA5FFFF;1|FPD;AFI_5;FD3B0000;FD3BFFFF;1|FPD;AFI_4;FD3A0000;FD3AFFFF;1|FPD;AFI_3;FD390000;FD39FFFF;1|FPD;AFI_2;FD380000;FD38FFFF;1|FPD;AFI_1;FD370000;FD37FFFF;1|FPD;AFI_0;FD360000;FD36FFFF;1|LPD;AFIFM6;FF9B0000;FF9BFFFF;1|FPD;ACPU_GIC;F9010000;F907FFFF;1} \
   CONFIG.PSU__PROTECTION__SUBSYSTEMS {PMU Firmware:PMU|Secure Subsystem:} \
   CONFIG.PSU__PSS_ALT_REF_CLK__ENABLE {0} \
   CONFIG.PSU__PSS_ALT_REF_CLK__FREQMHZ {33.333} \
   CONFIG.PSU__PSS_REF_CLK__FREQMHZ {33.333} \
   CONFIG.PSU__QSPI_COHERENCY {0} \
   CONFIG.PSU__QSPI_ROUTE_THROUGH_FPD {0} \
   CONFIG.PSU__QSPI__GRP_FBCLK__ENABLE {1} \
   CONFIG.PSU__QSPI__GRP_FBCLK__IO {MIO 6} \
   CONFIG.PSU__QSPI__PERIPHERAL__DATA_MODE {x4} \
   CONFIG.PSU__QSPI__PERIPHERAL__ENABLE {1} \
   CONFIG.PSU__QSPI__PERIPHERAL__IO {MIO 0 .. 12} \
   CONFIG.PSU__QSPI__PERIPHERAL__MODE {Dual Parallel} \
   CONFIG.PSU__REPORT__DBGLOG {0} \
   CONFIG.PSU__RPU_COHERENCY {0} \
   CONFIG.PSU__RPU__POWER__ON {1} \
   CONFIG.PSU__SATA__LANE0__ENABLE {0} \
   CONFIG.PSU__SATA__LANE1__ENABLE {1} \
   CONFIG.PSU__SATA__LANE1__IO {GT Lane3} \
   CONFIG.PSU__SATA__PERIPHERAL__ENABLE {1} \
   CONFIG.PSU__SATA__REF_CLK_FREQ {125} \
   CONFIG.PSU__SATA__REF_CLK_SEL {Ref Clk3} \
   CONFIG.PSU__SAXIGP0__DATA_WIDTH {128} \
   CONFIG.PSU__SAXIGP1__DATA_WIDTH {128} \
   CONFIG.PSU__SAXIGP2__DATA_WIDTH {128} \
   CONFIG.PSU__SAXIGP3__DATA_WIDTH {128} \
   CONFIG.PSU__SAXIGP4__DATA_WIDTH {128} \
   CONFIG.PSU__SAXIGP5__DATA_WIDTH {128} \
   CONFIG.PSU__SAXIGP6__DATA_WIDTH {128} \
   CONFIG.PSU__SD0_COHERENCY {0} \
   CONFIG.PSU__SD0_ROUTE_THROUGH_FPD {0} \
   CONFIG.PSU__SD0__GRP_CD__ENABLE {0} \
   CONFIG.PSU__SD0__GRP_POW__ENABLE {0} \
   CONFIG.PSU__SD0__GRP_WP__ENABLE {0} \
   CONFIG.PSU__SD0__PERIPHERAL__ENABLE {0} \
   CONFIG.PSU__SD0__RESET__ENABLE {0} \
   CONFIG.PSU__SD1_COHERENCY {0} \
   CONFIG.PSU__SD1_ROUTE_THROUGH_FPD {0} \
   CONFIG.PSU__SD1__DATA_TRANSFER_MODE {8Bit} \
   CONFIG.PSU__SD1__GRP_CD__ENABLE {1} \
   CONFIG.PSU__SD1__GRP_CD__IO {MIO 45} \
   CONFIG.PSU__SD1__GRP_POW__ENABLE {0} \
   CONFIG.PSU__SD1__GRP_WP__ENABLE {0} \
   CONFIG.PSU__SD1__PERIPHERAL__ENABLE {1} \
   CONFIG.PSU__SD1__PERIPHERAL__IO {MIO 39 .. 51} \
   CONFIG.PSU__SD1__RESET__ENABLE {0} \
   CONFIG.PSU__SD1__SLOT_TYPE {SD 3.0} \
   CONFIG.PSU__SPI0_LOOP_SPI1__ENABLE {0} \
   CONFIG.PSU__SPI0__GRP_SS0__ENABLE {0} \
   CONFIG.PSU__SPI0__GRP_SS1__ENABLE {0} \
   CONFIG.PSU__SPI0__GRP_SS2__ENABLE {0} \
   CONFIG.PSU__SPI0__PERIPHERAL__ENABLE {0} \
   CONFIG.PSU__SPI1__GRP_SS0__ENABLE {0} \
   CONFIG.PSU__SPI1__GRP_SS1__ENABLE {0} \
   CONFIG.PSU__SPI1__GRP_SS2__ENABLE {0} \
   CONFIG.PSU__SPI1__PERIPHERAL__ENABLE {0} \
   CONFIG.PSU__SWDT0__CLOCK__ENABLE {0} \
   CONFIG.PSU__SWDT0__PERIPHERAL__ENABLE {1} \
   CONFIG.PSU__SWDT0__PERIPHERAL__IO {NA} \
   CONFIG.PSU__SWDT0__RESET__ENABLE {0} \
   CONFIG.PSU__SWDT1__CLOCK__ENABLE {0} \
   CONFIG.PSU__SWDT1__PERIPHERAL__ENABLE {1} \
   CONFIG.PSU__SWDT1__PERIPHERAL__IO {NA} \
   CONFIG.PSU__SWDT1__RESET__ENABLE {0} \
   CONFIG.PSU__TCM0A__POWER__ON {1} \
   CONFIG.PSU__TCM0B__POWER__ON {1} \
   CONFIG.PSU__TCM1A__POWER__ON {1} \
   CONFIG.PSU__TCM1B__POWER__ON {1} \
   CONFIG.PSU__TESTSCAN__PERIPHERAL__ENABLE {0} \
   CONFIG.PSU__TRACE_PIPELINE_WIDTH {8} \
   CONFIG.PSU__TRACE__INTERNAL_WIDTH {32} \
   CONFIG.PSU__TRACE__PERIPHERAL__ENABLE {0} \
   CONFIG.PSU__TRISTATE__INVERTED {1} \
   CONFIG.PSU__TSU__BUFG_PORT_PAIR {0} \
   CONFIG.PSU__TTC0__CLOCK__ENABLE {0} \
   CONFIG.PSU__TTC0__PERIPHERAL__ENABLE {1} \
   CONFIG.PSU__TTC0__PERIPHERAL__IO {NA} \
   CONFIG.PSU__TTC0__WAVEOUT__ENABLE {0} \
   CONFIG.PSU__TTC1__CLOCK__ENABLE {0} \
   CONFIG.PSU__TTC1__PERIPHERAL__ENABLE {1} \
   CONFIG.PSU__TTC1__PERIPHERAL__IO {NA} \
   CONFIG.PSU__TTC1__WAVEOUT__ENABLE {0} \
   CONFIG.PSU__TTC2__CLOCK__ENABLE {0} \
   CONFIG.PSU__TTC2__PERIPHERAL__ENABLE {1} \
   CONFIG.PSU__TTC2__PERIPHERAL__IO {NA} \
   CONFIG.PSU__TTC2__WAVEOUT__ENABLE {0} \
   CONFIG.PSU__TTC3__CLOCK__ENABLE {0} \
   CONFIG.PSU__TTC3__PERIPHERAL__ENABLE {1} \
   CONFIG.PSU__TTC3__PERIPHERAL__IO {NA} \
   CONFIG.PSU__TTC3__WAVEOUT__ENABLE {0} \
   CONFIG.PSU__UART0_LOOP_UART1__ENABLE {0} \
   CONFIG.PSU__UART0__BAUD_RATE {115200} \
   CONFIG.PSU__UART0__MODEM__ENABLE {0} \
   CONFIG.PSU__UART0__PERIPHERAL__ENABLE {1} \
   CONFIG.PSU__UART0__PERIPHERAL__IO {MIO 18 .. 19} \
   CONFIG.PSU__UART1__BAUD_RATE {115200} \
   CONFIG.PSU__UART1__MODEM__ENABLE {0} \
   CONFIG.PSU__UART1__PERIPHERAL__ENABLE {1} \
   CONFIG.PSU__UART1__PERIPHERAL__IO {EMIO} \
   CONFIG.PSU__USB0_COHERENCY {0} \
   CONFIG.PSU__USB0__PERIPHERAL__ENABLE {1} \
   CONFIG.PSU__USB0__PERIPHERAL__IO {MIO 52 .. 63} \
   CONFIG.PSU__USB0__REF_CLK_FREQ {26} \
   CONFIG.PSU__USB0__REF_CLK_SEL {Ref Clk2} \
   CONFIG.PSU__USB0__RESET__ENABLE {0} \
   CONFIG.PSU__USB1_COHERENCY {0} \
   CONFIG.PSU__USB1__PERIPHERAL__ENABLE {0} \
   CONFIG.PSU__USB1__RESET__ENABLE {0} \
   CONFIG.PSU__USB2_0__EMIO__ENABLE {0} \
   CONFIG.PSU__USB2_1__EMIO__ENABLE {0} \
   CONFIG.PSU__USB3_0__EMIO__ENABLE {0} \
   CONFIG.PSU__USB3_0__PERIPHERAL__ENABLE {1} \
   CONFIG.PSU__USB3_0__PERIPHERAL__IO {GT Lane2} \
   CONFIG.PSU__USB3_1__EMIO__ENABLE {0} \
   CONFIG.PSU__USB3_1__PERIPHERAL__ENABLE {0} \
   CONFIG.PSU__USB__RESET__MODE {Boot Pin} \
   CONFIG.PSU__USB__RESET__POLARITY {Active Low} \
   CONFIG.PSU__USE_DIFF_RW_CLK_GP0 {0} \
   CONFIG.PSU__USE_DIFF_RW_CLK_GP1 {0} \
   CONFIG.PSU__USE_DIFF_RW_CLK_GP2 {0} \
   CONFIG.PSU__USE_DIFF_RW_CLK_GP3 {0} \
   CONFIG.PSU__USE_DIFF_RW_CLK_GP4 {0} \
   CONFIG.PSU__USE_DIFF_RW_CLK_GP5 {0} \
   CONFIG.PSU__USE_DIFF_RW_CLK_GP6 {0} \
   CONFIG.PSU__USE__ADMA {0} \
   CONFIG.PSU__USE__APU_LEGACY_INTERRUPT {0} \
   CONFIG.PSU__USE__AUDIO {0} \
   CONFIG.PSU__USE__CLK {0} \
   CONFIG.PSU__USE__CLK0 {0} \
   CONFIG.PSU__USE__CLK1 {0} \
   CONFIG.PSU__USE__CLK2 {0} \
   CONFIG.PSU__USE__CLK3 {0} \
   CONFIG.PSU__USE__CROSS_TRIGGER {0} \
   CONFIG.PSU__USE__DDR_INTF_REQUESTED {0} \
   CONFIG.PSU__USE__DEBUG__TEST {0} \
   CONFIG.PSU__USE__EVENT_RPU {0} \
   CONFIG.PSU__USE__FABRIC__RST {1} \
   CONFIG.PSU__USE__FTM {0} \
   CONFIG.PSU__USE__GDMA {0} \
   CONFIG.PSU__USE__IRQ {0} \
   CONFIG.PSU__USE__IRQ0 {1} \
   CONFIG.PSU__USE__IRQ1 {0} \
   CONFIG.PSU__USE__M_AXI_GP0 {1} \
   CONFIG.PSU__USE__M_AXI_GP1 {0} \
   CONFIG.PSU__USE__M_AXI_GP2 {0} \
   CONFIG.PSU__USE__PROC_EVENT_BUS {0} \
   CONFIG.PSU__USE__RPU_LEGACY_INTERRUPT {0} \
   CONFIG.PSU__USE__RST0 {0} \
   CONFIG.PSU__USE__RST1 {0} \
   CONFIG.PSU__USE__RST2 {0} \
   CONFIG.PSU__USE__RST3 {0} \
   CONFIG.PSU__USE__RTC {0} \
   CONFIG.PSU__USE__STM {0} \
   CONFIG.PSU__USE__S_AXI_ACE {0} \
   CONFIG.PSU__USE__S_AXI_ACP {0} \
   CONFIG.PSU__USE__S_AXI_GP0 {0} \
   CONFIG.PSU__USE__S_AXI_GP1 {0} \
   CONFIG.PSU__USE__S_AXI_GP2 {1} \
   CONFIG.PSU__USE__S_AXI_GP3 {0} \
   CONFIG.PSU__USE__S_AXI_GP4 {0} \
   CONFIG.PSU__USE__S_AXI_GP5 {0} \
   CONFIG.PSU__USE__S_AXI_GP6 {0} \
   CONFIG.PSU__USE__USB3_0_HUB {0} \
   CONFIG.PSU__USE__USB3_1_HUB {0} \
   CONFIG.PSU__USE__VIDEO {0} \
   CONFIG.PSU__VIDEO_REF_CLK__ENABLE {0} \
   CONFIG.PSU__VIDEO_REF_CLK__FREQMHZ {33.333} \
   CONFIG.QSPI_BOARD_INTERFACE {custom} \
   CONFIG.SATA_BOARD_INTERFACE {custom} \
   CONFIG.SD0_BOARD_INTERFACE {custom} \
   CONFIG.SD1_BOARD_INTERFACE {custom} \
   CONFIG.SPI0_BOARD_INTERFACE {custom} \
   CONFIG.SPI1_BOARD_INTERFACE {custom} \
   CONFIG.SUBPRESET1 {Custom} \
   CONFIG.SUBPRESET2 {Custom} \
   CONFIG.SWDT0_BOARD_INTERFACE {custom} \
   CONFIG.SWDT1_BOARD_INTERFACE {custom} \
   CONFIG.TRACE_BOARD_INTERFACE {custom} \
   CONFIG.TTC0_BOARD_INTERFACE {custom} \
   CONFIG.TTC1_BOARD_INTERFACE {custom} \
   CONFIG.TTC2_BOARD_INTERFACE {custom} \
   CONFIG.TTC3_BOARD_INTERFACE {custom} \
   CONFIG.UART0_BOARD_INTERFACE {custom} \
   CONFIG.UART1_BOARD_INTERFACE {custom} \
   CONFIG.USB0_BOARD_INTERFACE {custom} \
   CONFIG.USB1_BOARD_INTERFACE {custom} \
 ] $zynq_ultra_ps_e_0

  # Create interface connections
connect_bd_intf_net -intf_net Conn [get_bd_intf_pins reschan/res_stream] [get_bd_intf_pins system_ila_0/SLOT_3_AXIS]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_intf_nets Conn]
connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins reschan/S_AXIS_DATA] [get_bd_intf_pins system_ila_0/SLOT_4_AXIS]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_intf_nets Conn1]
  connect_bd_intf_net -intf_net axi_dma_0_M_AXIS_MM2S [get_bd_intf_pins axi_dma_0/M_AXIS_MM2S] [get_bd_intf_pins axis_data_fifo_0/S_AXIS]
  connect_bd_intf_net -intf_net axi_dma_0_M_AXI_MM2S [get_bd_intf_pins axi_dma_0/M_AXI_MM2S] [get_bd_intf_pins axi_smc/S00_AXI]
connect_bd_intf_net -intf_net [get_bd_intf_nets axi_dma_0_M_AXI_MM2S] [get_bd_intf_pins axi_dma_0/M_AXI_MM2S] [get_bd_intf_pins system_ila_0/SLOT_0_AXI]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_intf_nets axi_dma_0_M_AXI_MM2S]
  connect_bd_intf_net -intf_net axi_dma_0_M_AXI_S2MM [get_bd_intf_pins axi_dma_0/M_AXI_S2MM] [get_bd_intf_pins axi_smc/S01_AXI]
  connect_bd_intf_net -intf_net axi_smc_M00_AXI [get_bd_intf_pins axi_smc/M00_AXI] [get_bd_intf_pins zynq_ultra_ps_e_0/S_AXI_HP0_FPD]
  connect_bd_intf_net -intf_net axis_broadcaster_0_M00_AXIS [get_bd_intf_pins axis_broadcaster_0/M00_AXIS] [get_bd_intf_pins opfb/S_AXIS]
  connect_bd_intf_net -intf_net axis_broadcaster_0_M01_AXIS [get_bd_intf_pins axis_broadcaster_0/M01_AXIS] [get_bd_intf_pins opfb/S_AXIS1]
  connect_bd_intf_net -intf_net axis_data_fifo_0_M_AXIS [get_bd_intf_pins axis_broadcaster_0/S_AXIS] [get_bd_intf_pins axis_data_fifo_0/M_AXIS]
connect_bd_intf_net -intf_net [get_bd_intf_nets axis_data_fifo_0_M_AXIS] [get_bd_intf_pins axis_data_fifo_0/M_AXIS] [get_bd_intf_pins system_ila_0/SLOT_1_AXIS]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_intf_nets axis_data_fifo_0_M_AXIS]
  connect_bd_intf_net -intf_net axis_data_fifo_1_M_AXIS [get_bd_intf_pins axi_dma_0/S_AXIS_S2MM] [get_bd_intf_pins axis_data_fifo_1/M_AXIS]
  connect_bd_intf_net -intf_net gen3_opfb_100MHz_0_M_AXIS_IQBINS [get_bd_intf_pins opfb/output_r] [get_bd_intf_pins reschan/iq_stream]
connect_bd_intf_net -intf_net [get_bd_intf_nets gen3_opfb_100MHz_0_M_AXIS_IQBINS] [get_bd_intf_pins reschan/iq_stream] [get_bd_intf_pins system_ila_0/SLOT_2_AXIS]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_intf_nets gen3_opfb_100MHz_0_M_AXIS_IQBINS]
  connect_bd_intf_net -intf_net ps8_0_axi_periph_M00_AXI [get_bd_intf_pins axi_dma_0/S_AXI_LITE] [get_bd_intf_pins ps8_0_axi_periph/M00_AXI]
  connect_bd_intf_net -intf_net ps8_0_axi_periph_M01_AXI [get_bd_intf_pins axi_intc_0/s_axi] [get_bd_intf_pins ps8_0_axi_periph/M01_AXI]
  connect_bd_intf_net -intf_net ps8_0_axi_periph_M02_AXI [get_bd_intf_pins ps8_0_axi_periph/M02_AXI] [get_bd_intf_pins reschan/s_axi_bin_to_res]
  connect_bd_intf_net -intf_net ps8_0_axi_periph_M03_AXI [get_bd_intf_pins ps8_0_axi_periph/M03_AXI] [get_bd_intf_pins reschan/s_axi_resonator_dds]
  connect_bd_intf_net -intf_net reschan_M_AXIS_DATA_0 [get_bd_intf_pins axis_data_fifo_1/S_AXIS] [get_bd_intf_pins reschan/M_AXIS_DATA]
connect_bd_intf_net -intf_net [get_bd_intf_nets reschan_M_AXIS_DATA_0] [get_bd_intf_pins reschan/M_AXIS_DATA] [get_bd_intf_pins system_ila_0/SLOT_5_AXIS]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_intf_nets reschan_M_AXIS_DATA_0]
  connect_bd_intf_net -intf_net zynq_ultra_ps_e_0_M_AXI_HPM0_FPD [get_bd_intf_pins ps8_0_axi_periph/S00_AXI] [get_bd_intf_pins zynq_ultra_ps_e_0/M_AXI_HPM0_FPD]

  # Create port connections
  connect_bd_net -net axi_dma_0_mm2s_introut [get_bd_pins axi_dma_0/mm2s_introut] [get_bd_pins system_ila_0/probe0] [get_bd_pins xlconcat_0/In0]
  connect_bd_net -net axi_dma_0_s2mm_introut [get_bd_pins axi_dma_0/s2mm_introut] [get_bd_pins xlconcat_0/In1]
  connect_bd_net -net axi_intc_0_irq [get_bd_pins axi_intc_0/irq] [get_bd_pins zynq_ultra_ps_e_0/pl_ps_irq0]
  connect_bd_net -net rst_ps8_0_99M_peripheral_aresetn [get_bd_pins axi_dma_0/axi_resetn] [get_bd_pins axi_intc_0/s_axi_aresetn] [get_bd_pins axi_smc/aresetn] [get_bd_pins axis_broadcaster_0/aresetn] [get_bd_pins axis_data_fifo_0/s_axis_aresetn] [get_bd_pins axis_data_fifo_1/s_axis_aresetn] [get_bd_pins ps8_0_axi_periph/ARESETN] [get_bd_pins ps8_0_axi_periph/M00_ARESETN] [get_bd_pins ps8_0_axi_periph/M01_ARESETN] [get_bd_pins ps8_0_axi_periph/M02_ARESETN] [get_bd_pins ps8_0_axi_periph/M03_ARESETN] [get_bd_pins ps8_0_axi_periph/S00_ARESETN] [get_bd_pins reschan/ap_rst_n] [get_bd_pins reschan/ap_rst_n_S_AXI_clk] [get_bd_pins rst_ps8_0_99M/peripheral_aresetn] [get_bd_pins system_ila_0/resetn]
  connect_bd_net -net xlconcat_0_dout [get_bd_pins axi_intc_0/intr] [get_bd_pins xlconcat_0/dout]
  connect_bd_net -net zynq_ultra_ps_e_0_pl_clk0 [get_bd_pins axi_dma_0/m_axi_mm2s_aclk] [get_bd_pins axi_dma_0/m_axi_s2mm_aclk] [get_bd_pins axi_dma_0/s_axi_lite_aclk] [get_bd_pins axi_intc_0/s_axi_aclk] [get_bd_pins axi_smc/aclk] [get_bd_pins axis_broadcaster_0/aclk] [get_bd_pins axis_data_fifo_0/s_axis_aclk] [get_bd_pins axis_data_fifo_1/s_axis_aclk] [get_bd_pins opfb/aclk] [get_bd_pins ps8_0_axi_periph/ACLK] [get_bd_pins ps8_0_axi_periph/M00_ACLK] [get_bd_pins ps8_0_axi_periph/M01_ACLK] [get_bd_pins ps8_0_axi_periph/M02_ACLK] [get_bd_pins ps8_0_axi_periph/M03_ACLK] [get_bd_pins ps8_0_axi_periph/S00_ACLK] [get_bd_pins reschan/S_AXI_clk] [get_bd_pins reschan/ap_clk] [get_bd_pins rst_ps8_0_99M/slowest_sync_clk] [get_bd_pins system_ila_0/clk] [get_bd_pins zynq_ultra_ps_e_0/maxihpm0_fpd_aclk] [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins zynq_ultra_ps_e_0/saxihp0_fpd_aclk]
  connect_bd_net -net zynq_ultra_ps_e_0_pl_resetn0 [get_bd_pins rst_ps8_0_99M/ext_reset_in] [get_bd_pins zynq_ultra_ps_e_0/pl_resetn0]

  # Create address segments
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces axi_dma_0/Data_MM2S] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_DDR_LOW] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces axi_dma_0/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_DDR_LOW] -force
  assign_bd_address -offset 0xFF000000 -range 0x01000000 -target_address_space [get_bd_addr_spaces axi_dma_0/Data_MM2S] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_LPS_OCM] -force
  assign_bd_address -offset 0xFF000000 -range 0x01000000 -target_address_space [get_bd_addr_spaces axi_dma_0/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_LPS_OCM] -force
  assign_bd_address -offset 0xC0000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces axi_dma_0/Data_MM2S] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_QSPI] -force
  assign_bd_address -offset 0xC0000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces axi_dma_0/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_QSPI] -force
  assign_bd_address -offset 0xA0000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs axi_dma_0/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0xA0010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs axi_intc_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xA0020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs reschan/bin_to_res_0/s_axi_control/Reg] -force
  assign_bd_address -offset 0xA0030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs reschan/resonator_dds_0/s_axi_control/Reg] -force

  # Exclude Address Segments
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces axi_dma_0/Data_MM2S] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_DDR_HIGH]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces axi_dma_0/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_DDR_HIGH]


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""

