

##################################################################
# DESIGN PROCs
##################################################################


# Hierarchical cell: firs
proc create_hier_cell_firs { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_firs() - Empty argument(s)!"}
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

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS1


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

  # Create instance: axis_broadcaster_1, and set properties
  set axis_broadcaster_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_broadcaster:1.1 axis_broadcaster_1 ]
  set_property -dict [ list \
   CONFIG.HAS_TREADY {0} \
   CONFIG.M00_TDATA_REMAP {tdata[31:0]} \
   CONFIG.M01_TDATA_REMAP {tdata[63:32]} \
   CONFIG.M02_TDATA_REMAP {tdata[95:64]} \
   CONFIG.M03_TDATA_REMAP {tdata[127:96]} \
   CONFIG.M04_TDATA_REMAP {tdata[159:128]} \
   CONFIG.M05_TDATA_REMAP {tdata[191:160]} \
   CONFIG.M06_TDATA_REMAP {tdata[223:192]} \
   CONFIG.M07_TDATA_REMAP {tdata[255:224]} \
   CONFIG.M08_TDATA_REMAP {tdata[287:256]} \
   CONFIG.M09_TDATA_REMAP {tdata[319:288]} \
   CONFIG.M10_TDATA_REMAP {tdata[351:320]} \
   CONFIG.M11_TDATA_REMAP {tdata[383:352]} \
   CONFIG.M12_TDATA_REMAP {tdata[415:384]} \
   CONFIG.M13_TDATA_REMAP {tdata[447:416]} \
   CONFIG.M14_TDATA_REMAP {tdata[479:448]} \
   CONFIG.M15_TDATA_REMAP {tdata[511:480]} \
   CONFIG.M_TDATA_NUM_BYTES {4} \
   CONFIG.NUM_MI {16} \
   CONFIG.S_TDATA_NUM_BYTES {64} \
 ] $axis_broadcaster_1

  # Create instance: axis_combiner_0, and set properties
  set axis_combiner_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_combiner:1.1 axis_combiner_0 ]
  set_property -dict [ list \
   CONFIG.NUM_SI {16} \
 ] $axis_combiner_0

  # Create instance: axis_register_slice_0, and set properties
  set axis_register_slice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axis_register_slice_0 ]
  set_property -dict [ list \
   CONFIG.HAS_TREADY {0} \
 ] $axis_register_slice_0

  # Create instance: axis_register_slice_1, and set properties
  set axis_register_slice_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axis_register_slice_1 ]
  set_property -dict [ list \
   CONFIG.HAS_TREADY {0} \
 ] $axis_register_slice_1

  # Create instance: fir_compiler_0, and set properties
  set fir_compiler_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:fir_compiler:7.2 fir_compiler_0 ]
  set_property -dict [ list \
   CONFIG.BestPrecision {true} \
   CONFIG.Clock_Frequency {300.0} \
   CONFIG.CoefficientSource {COE_File} \
   CONFIG.Coefficient_Fanout {false} \
   CONFIG.Coefficient_File {../../../../../../../data/lane0.coe} \
   CONFIG.Coefficient_Fractional_Bits {26} \
   CONFIG.Coefficient_Sets {256} \
   CONFIG.Coefficient_Sign {Signed} \
   CONFIG.Coefficient_Structure {Inferred} \
   CONFIG.Coefficient_Width {16} \
   CONFIG.ColumnConfig {4} \
   CONFIG.Control_Broadcast_Fanout {false} \
   CONFIG.Control_Column_Fanout {false} \
   CONFIG.Control_LUT_Pipeline {false} \
   CONFIG.Control_Path_Fanout {false} \
   CONFIG.DATA_Has_TLAST {Vector_Framing} \
   CONFIG.Data_Fractional_Bits {15} \
   CONFIG.Data_Path_Broadcast {false} \
   CONFIG.Data_Path_Fanout {false} \
   CONFIG.Disable_Half_Band_Centre_Tap {false} \
   CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} \
   CONFIG.Filter_Selection {1} \
   CONFIG.M_DATA_Has_TUSER {Not_Required} \
   CONFIG.No_BRAM_Read_First_Mode {false} \
   CONFIG.No_SRL_Attributes {false} \
   CONFIG.Number_Channels {512} \
   CONFIG.Number_Paths {2} \
   CONFIG.Optimal_Column_Lengths {false} \
   CONFIG.Optimization_Goal {Area} \
   CONFIG.Optimization_List {None} \
   CONFIG.Optimization_Selection {None} \
   CONFIG.Other {false} \
   CONFIG.Output_Rounding_Mode {Truncate_LSBs} \
   CONFIG.Output_Width {16} \
   CONFIG.Pre_Adder_Pipeline {false} \
   CONFIG.Quantization {Quantize_Only} \
   CONFIG.RateSpecification {Input_Sample_Period} \
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
   CONFIG.Clock_Frequency {300.0} \
   CONFIG.CoefficientSource {COE_File} \
   CONFIG.Coefficient_Fanout {false} \
   CONFIG.Coefficient_File {../../../../../../../data/lane1.coe} \
   CONFIG.Coefficient_Fractional_Bits {26} \
   CONFIG.Coefficient_Sets {256} \
   CONFIG.Coefficient_Sign {Signed} \
   CONFIG.Coefficient_Structure {Inferred} \
   CONFIG.Coefficient_Width {16} \
   CONFIG.ColumnConfig {4} \
   CONFIG.Control_Broadcast_Fanout {false} \
   CONFIG.Control_Column_Fanout {false} \
   CONFIG.Control_LUT_Pipeline {false} \
   CONFIG.Control_Path_Fanout {false} \
   CONFIG.DATA_Has_TLAST {Vector_Framing} \
   CONFIG.Data_Fractional_Bits {15} \
   CONFIG.Data_Path_Broadcast {false} \
   CONFIG.Data_Path_Fanout {false} \
   CONFIG.Disable_Half_Band_Centre_Tap {false} \
   CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} \
   CONFIG.Filter_Selection {1} \
   CONFIG.M_DATA_Has_TUSER {Not_Required} \
   CONFIG.No_BRAM_Read_First_Mode {false} \
   CONFIG.No_SRL_Attributes {false} \
   CONFIG.Number_Channels {512} \
   CONFIG.Number_Paths {2} \
   CONFIG.Optimal_Column_Lengths {false} \
   CONFIG.Optimization_Goal {Area} \
   CONFIG.Optimization_List {None} \
   CONFIG.Optimization_Selection {None} \
   CONFIG.Other {false} \
   CONFIG.Output_Rounding_Mode {Truncate_LSBs} \
   CONFIG.Output_Width {16} \
   CONFIG.Pre_Adder_Pipeline {false} \
   CONFIG.Quantization {Quantize_Only} \
   CONFIG.RateSpecification {Input_Sample_Period} \
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
   CONFIG.Clock_Frequency {300.0} \
   CONFIG.CoefficientSource {COE_File} \
   CONFIG.Coefficient_Fanout {false} \
   CONFIG.Coefficient_File {../../../../../../../data/lane2.coe} \
   CONFIG.Coefficient_Fractional_Bits {26} \
   CONFIG.Coefficient_Sets {256} \
   CONFIG.Coefficient_Sign {Signed} \
   CONFIG.Coefficient_Structure {Inferred} \
   CONFIG.Coefficient_Width {16} \
   CONFIG.ColumnConfig {4} \
   CONFIG.Control_Broadcast_Fanout {false} \
   CONFIG.Control_Column_Fanout {false} \
   CONFIG.Control_LUT_Pipeline {false} \
   CONFIG.Control_Path_Fanout {false} \
   CONFIG.DATA_Has_TLAST {Vector_Framing} \
   CONFIG.Data_Fractional_Bits {15} \
   CONFIG.Data_Path_Broadcast {false} \
   CONFIG.Data_Path_Fanout {false} \
   CONFIG.Disable_Half_Band_Centre_Tap {false} \
   CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} \
   CONFIG.Filter_Selection {1} \
   CONFIG.M_DATA_Has_TUSER {Not_Required} \
   CONFIG.No_BRAM_Read_First_Mode {false} \
   CONFIG.No_SRL_Attributes {false} \
   CONFIG.Number_Channels {512} \
   CONFIG.Number_Paths {2} \
   CONFIG.Optimal_Column_Lengths {false} \
   CONFIG.Optimization_Goal {Area} \
   CONFIG.Optimization_List {None} \
   CONFIG.Optimization_Selection {None} \
   CONFIG.Other {false} \
   CONFIG.Output_Rounding_Mode {Truncate_LSBs} \
   CONFIG.Output_Width {16} \
   CONFIG.Pre_Adder_Pipeline {false} \
   CONFIG.Quantization {Quantize_Only} \
   CONFIG.RateSpecification {Input_Sample_Period} \
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
   CONFIG.Clock_Frequency {300.0} \
   CONFIG.CoefficientSource {COE_File} \
   CONFIG.Coefficient_Fanout {false} \
   CONFIG.Coefficient_File {../../../../../../../data/lane3.coe} \
   CONFIG.Coefficient_Fractional_Bits {26} \
   CONFIG.Coefficient_Sets {256} \
   CONFIG.Coefficient_Sign {Signed} \
   CONFIG.Coefficient_Structure {Inferred} \
   CONFIG.Coefficient_Width {16} \
   CONFIG.ColumnConfig {4} \
   CONFIG.Control_Broadcast_Fanout {false} \
   CONFIG.Control_Column_Fanout {false} \
   CONFIG.Control_LUT_Pipeline {false} \
   CONFIG.Control_Path_Fanout {false} \
   CONFIG.DATA_Has_TLAST {Vector_Framing} \
   CONFIG.Data_Fractional_Bits {15} \
   CONFIG.Data_Path_Broadcast {false} \
   CONFIG.Data_Path_Fanout {false} \
   CONFIG.Disable_Half_Band_Centre_Tap {false} \
   CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} \
   CONFIG.Filter_Selection {1} \
   CONFIG.M_DATA_Has_TUSER {Not_Required} \
   CONFIG.No_BRAM_Read_First_Mode {false} \
   CONFIG.No_SRL_Attributes {false} \
   CONFIG.Number_Channels {512} \
   CONFIG.Number_Paths {2} \
   CONFIG.Optimal_Column_Lengths {false} \
   CONFIG.Optimization_Goal {Area} \
   CONFIG.Optimization_List {None} \
   CONFIG.Optimization_Selection {None} \
   CONFIG.Other {false} \
   CONFIG.Output_Rounding_Mode {Truncate_LSBs} \
   CONFIG.Output_Width {16} \
   CONFIG.Pre_Adder_Pipeline {false} \
   CONFIG.Quantization {Quantize_Only} \
   CONFIG.RateSpecification {Input_Sample_Period} \
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
   CONFIG.Clock_Frequency {300.0} \
   CONFIG.CoefficientSource {COE_File} \
   CONFIG.Coefficient_Fanout {false} \
   CONFIG.Coefficient_File {../../../../../../../data/lane4.coe} \
   CONFIG.Coefficient_Fractional_Bits {26} \
   CONFIG.Coefficient_Sets {256} \
   CONFIG.Coefficient_Sign {Signed} \
   CONFIG.Coefficient_Structure {Inferred} \
   CONFIG.Coefficient_Width {16} \
   CONFIG.ColumnConfig {4} \
   CONFIG.Control_Broadcast_Fanout {false} \
   CONFIG.Control_Column_Fanout {false} \
   CONFIG.Control_LUT_Pipeline {false} \
   CONFIG.Control_Path_Fanout {false} \
   CONFIG.DATA_Has_TLAST {Vector_Framing} \
   CONFIG.Data_Fractional_Bits {15} \
   CONFIG.Data_Path_Broadcast {false} \
   CONFIG.Data_Path_Fanout {false} \
   CONFIG.Disable_Half_Band_Centre_Tap {false} \
   CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} \
   CONFIG.Filter_Selection {1} \
   CONFIG.M_DATA_Has_TUSER {Not_Required} \
   CONFIG.No_BRAM_Read_First_Mode {false} \
   CONFIG.No_SRL_Attributes {false} \
   CONFIG.Number_Channels {512} \
   CONFIG.Number_Paths {2} \
   CONFIG.Optimal_Column_Lengths {false} \
   CONFIG.Optimization_Goal {Area} \
   CONFIG.Optimization_List {None} \
   CONFIG.Optimization_Selection {None} \
   CONFIG.Other {false} \
   CONFIG.Output_Rounding_Mode {Truncate_LSBs} \
   CONFIG.Output_Width {16} \
   CONFIG.Pre_Adder_Pipeline {false} \
   CONFIG.Quantization {Quantize_Only} \
   CONFIG.RateSpecification {Input_Sample_Period} \
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
   CONFIG.Clock_Frequency {300.0} \
   CONFIG.CoefficientSource {COE_File} \
   CONFIG.Coefficient_Fanout {false} \
   CONFIG.Coefficient_File {../../../../../../../data/lane5.coe} \
   CONFIG.Coefficient_Fractional_Bits {26} \
   CONFIG.Coefficient_Sets {256} \
   CONFIG.Coefficient_Sign {Signed} \
   CONFIG.Coefficient_Structure {Inferred} \
   CONFIG.Coefficient_Width {16} \
   CONFIG.ColumnConfig {4} \
   CONFIG.Control_Broadcast_Fanout {false} \
   CONFIG.Control_Column_Fanout {false} \
   CONFIG.Control_LUT_Pipeline {false} \
   CONFIG.Control_Path_Fanout {false} \
   CONFIG.DATA_Has_TLAST {Vector_Framing} \
   CONFIG.Data_Fractional_Bits {15} \
   CONFIG.Data_Path_Broadcast {false} \
   CONFIG.Data_Path_Fanout {false} \
   CONFIG.Disable_Half_Band_Centre_Tap {false} \
   CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} \
   CONFIG.Filter_Selection {1} \
   CONFIG.M_DATA_Has_TUSER {Not_Required} \
   CONFIG.No_BRAM_Read_First_Mode {false} \
   CONFIG.No_SRL_Attributes {false} \
   CONFIG.Number_Channels {512} \
   CONFIG.Number_Paths {2} \
   CONFIG.Optimal_Column_Lengths {false} \
   CONFIG.Optimization_Goal {Area} \
   CONFIG.Optimization_List {None} \
   CONFIG.Optimization_Selection {None} \
   CONFIG.Other {false} \
   CONFIG.Output_Rounding_Mode {Truncate_LSBs} \
   CONFIG.Output_Width {16} \
   CONFIG.Pre_Adder_Pipeline {false} \
   CONFIG.Quantization {Quantize_Only} \
   CONFIG.RateSpecification {Input_Sample_Period} \
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
   CONFIG.Clock_Frequency {300.0} \
   CONFIG.CoefficientSource {COE_File} \
   CONFIG.Coefficient_Fanout {false} \
   CONFIG.Coefficient_File {../../../../../../../data/lane6.coe} \
   CONFIG.Coefficient_Fractional_Bits {26} \
   CONFIG.Coefficient_Sets {256} \
   CONFIG.Coefficient_Sign {Signed} \
   CONFIG.Coefficient_Structure {Inferred} \
   CONFIG.Coefficient_Width {16} \
   CONFIG.ColumnConfig {4} \
   CONFIG.Control_Broadcast_Fanout {false} \
   CONFIG.Control_Column_Fanout {false} \
   CONFIG.Control_LUT_Pipeline {false} \
   CONFIG.Control_Path_Fanout {false} \
   CONFIG.DATA_Has_TLAST {Vector_Framing} \
   CONFIG.Data_Fractional_Bits {15} \
   CONFIG.Data_Path_Broadcast {false} \
   CONFIG.Data_Path_Fanout {false} \
   CONFIG.Disable_Half_Band_Centre_Tap {false} \
   CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} \
   CONFIG.Filter_Selection {1} \
   CONFIG.M_DATA_Has_TUSER {Not_Required} \
   CONFIG.No_BRAM_Read_First_Mode {false} \
   CONFIG.No_SRL_Attributes {false} \
   CONFIG.Number_Channels {512} \
   CONFIG.Number_Paths {2} \
   CONFIG.Optimal_Column_Lengths {false} \
   CONFIG.Optimization_Goal {Area} \
   CONFIG.Optimization_List {None} \
   CONFIG.Optimization_Selection {None} \
   CONFIG.Other {false} \
   CONFIG.Output_Rounding_Mode {Truncate_LSBs} \
   CONFIG.Output_Width {16} \
   CONFIG.Pre_Adder_Pipeline {false} \
   CONFIG.Quantization {Quantize_Only} \
   CONFIG.RateSpecification {Input_Sample_Period} \
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
   CONFIG.Clock_Frequency {300.0} \
   CONFIG.CoefficientSource {COE_File} \
   CONFIG.Coefficient_Fanout {false} \
   CONFIG.Coefficient_File {../../../../../../../data/lane7.coe} \
   CONFIG.Coefficient_Fractional_Bits {26} \
   CONFIG.Coefficient_Sets {256} \
   CONFIG.Coefficient_Sign {Signed} \
   CONFIG.Coefficient_Structure {Inferred} \
   CONFIG.Coefficient_Width {16} \
   CONFIG.ColumnConfig {4} \
   CONFIG.Control_Broadcast_Fanout {false} \
   CONFIG.Control_Column_Fanout {false} \
   CONFIG.Control_LUT_Pipeline {false} \
   CONFIG.Control_Path_Fanout {false} \
   CONFIG.DATA_Has_TLAST {Vector_Framing} \
   CONFIG.Data_Fractional_Bits {15} \
   CONFIG.Data_Path_Broadcast {false} \
   CONFIG.Data_Path_Fanout {false} \
   CONFIG.Disable_Half_Band_Centre_Tap {false} \
   CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} \
   CONFIG.Filter_Selection {1} \
   CONFIG.M_DATA_Has_TUSER {Not_Required} \
   CONFIG.No_BRAM_Read_First_Mode {false} \
   CONFIG.No_SRL_Attributes {false} \
   CONFIG.Number_Channels {512} \
   CONFIG.Number_Paths {2} \
   CONFIG.Optimal_Column_Lengths {false} \
   CONFIG.Optimization_Goal {Area} \
   CONFIG.Optimization_List {None} \
   CONFIG.Optimization_Selection {None} \
   CONFIG.Other {false} \
   CONFIG.Output_Rounding_Mode {Truncate_LSBs} \
   CONFIG.Output_Width {16} \
   CONFIG.Pre_Adder_Pipeline {false} \
   CONFIG.Quantization {Quantize_Only} \
   CONFIG.RateSpecification {Input_Sample_Period} \
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
   CONFIG.Clock_Frequency {300.0} \
   CONFIG.CoefficientSource {COE_File} \
   CONFIG.Coefficient_Fanout {false} \
   CONFIG.Coefficient_File {../../../../../../../data/lane8.coe} \
   CONFIG.Coefficient_Fractional_Bits {26} \
   CONFIG.Coefficient_Sets {256} \
   CONFIG.Coefficient_Sign {Signed} \
   CONFIG.Coefficient_Structure {Inferred} \
   CONFIG.Coefficient_Width {16} \
   CONFIG.ColumnConfig {4} \
   CONFIG.Control_Broadcast_Fanout {false} \
   CONFIG.Control_Column_Fanout {false} \
   CONFIG.Control_LUT_Pipeline {false} \
   CONFIG.Control_Path_Fanout {false} \
   CONFIG.DATA_Has_TLAST {Vector_Framing} \
   CONFIG.Data_Fractional_Bits {15} \
   CONFIG.Data_Path_Broadcast {false} \
   CONFIG.Data_Path_Fanout {false} \
   CONFIG.Disable_Half_Band_Centre_Tap {false} \
   CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} \
   CONFIG.Filter_Selection {1} \
   CONFIG.M_DATA_Has_TUSER {Not_Required} \
   CONFIG.No_BRAM_Read_First_Mode {false} \
   CONFIG.No_SRL_Attributes {false} \
   CONFIG.Number_Channels {512} \
   CONFIG.Number_Paths {2} \
   CONFIG.Optimal_Column_Lengths {false} \
   CONFIG.Optimization_Goal {Area} \
   CONFIG.Optimization_List {None} \
   CONFIG.Optimization_Selection {None} \
   CONFIG.Other {false} \
   CONFIG.Output_Rounding_Mode {Truncate_LSBs} \
   CONFIG.Output_Width {16} \
   CONFIG.Pre_Adder_Pipeline {false} \
   CONFIG.Quantization {Quantize_Only} \
   CONFIG.RateSpecification {Input_Sample_Period} \
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
   CONFIG.Clock_Frequency {300.0} \
   CONFIG.CoefficientSource {COE_File} \
   CONFIG.Coefficient_Fanout {false} \
   CONFIG.Coefficient_File {../../../../../../../data/lane9.coe} \
   CONFIG.Coefficient_Fractional_Bits {26} \
   CONFIG.Coefficient_Sets {256} \
   CONFIG.Coefficient_Sign {Signed} \
   CONFIG.Coefficient_Structure {Inferred} \
   CONFIG.Coefficient_Width {16} \
   CONFIG.ColumnConfig {4} \
   CONFIG.Control_Broadcast_Fanout {false} \
   CONFIG.Control_Column_Fanout {false} \
   CONFIG.Control_LUT_Pipeline {false} \
   CONFIG.Control_Path_Fanout {false} \
   CONFIG.DATA_Has_TLAST {Vector_Framing} \
   CONFIG.Data_Fractional_Bits {15} \
   CONFIG.Data_Path_Broadcast {false} \
   CONFIG.Data_Path_Fanout {false} \
   CONFIG.Disable_Half_Band_Centre_Tap {false} \
   CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} \
   CONFIG.Filter_Selection {1} \
   CONFIG.M_DATA_Has_TUSER {Not_Required} \
   CONFIG.No_BRAM_Read_First_Mode {false} \
   CONFIG.No_SRL_Attributes {false} \
   CONFIG.Number_Channels {512} \
   CONFIG.Number_Paths {2} \
   CONFIG.Optimal_Column_Lengths {false} \
   CONFIG.Optimization_Goal {Area} \
   CONFIG.Optimization_List {None} \
   CONFIG.Optimization_Selection {None} \
   CONFIG.Other {false} \
   CONFIG.Output_Rounding_Mode {Truncate_LSBs} \
   CONFIG.Output_Width {16} \
   CONFIG.Pre_Adder_Pipeline {false} \
   CONFIG.Quantization {Quantize_Only} \
   CONFIG.RateSpecification {Input_Sample_Period} \
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
   CONFIG.Clock_Frequency {300.0} \
   CONFIG.CoefficientSource {COE_File} \
   CONFIG.Coefficient_Fanout {false} \
   CONFIG.Coefficient_File {../../../../../../../data/lane10.coe} \
   CONFIG.Coefficient_Fractional_Bits {26} \
   CONFIG.Coefficient_Sets {256} \
   CONFIG.Coefficient_Sign {Signed} \
   CONFIG.Coefficient_Structure {Inferred} \
   CONFIG.Coefficient_Width {16} \
   CONFIG.ColumnConfig {4} \
   CONFIG.Control_Broadcast_Fanout {false} \
   CONFIG.Control_Column_Fanout {false} \
   CONFIG.Control_LUT_Pipeline {false} \
   CONFIG.Control_Path_Fanout {false} \
   CONFIG.DATA_Has_TLAST {Vector_Framing} \
   CONFIG.Data_Fractional_Bits {15} \
   CONFIG.Data_Path_Broadcast {false} \
   CONFIG.Data_Path_Fanout {false} \
   CONFIG.Disable_Half_Band_Centre_Tap {false} \
   CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} \
   CONFIG.Filter_Selection {1} \
   CONFIG.M_DATA_Has_TUSER {Not_Required} \
   CONFIG.No_BRAM_Read_First_Mode {false} \
   CONFIG.No_SRL_Attributes {false} \
   CONFIG.Number_Channels {512} \
   CONFIG.Number_Paths {2} \
   CONFIG.Optimal_Column_Lengths {false} \
   CONFIG.Optimization_Goal {Area} \
   CONFIG.Optimization_List {None} \
   CONFIG.Optimization_Selection {None} \
   CONFIG.Other {false} \
   CONFIG.Output_Rounding_Mode {Truncate_LSBs} \
   CONFIG.Output_Width {16} \
   CONFIG.Pre_Adder_Pipeline {false} \
   CONFIG.Quantization {Quantize_Only} \
   CONFIG.RateSpecification {Input_Sample_Period} \
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
   CONFIG.Clock_Frequency {300.0} \
   CONFIG.CoefficientSource {COE_File} \
   CONFIG.Coefficient_Fanout {false} \
   CONFIG.Coefficient_File {../../../../../../../data/lane11.coe} \
   CONFIG.Coefficient_Fractional_Bits {26} \
   CONFIG.Coefficient_Sets {256} \
   CONFIG.Coefficient_Sign {Signed} \
   CONFIG.Coefficient_Structure {Inferred} \
   CONFIG.Coefficient_Width {16} \
   CONFIG.ColumnConfig {4} \
   CONFIG.Control_Broadcast_Fanout {false} \
   CONFIG.Control_Column_Fanout {false} \
   CONFIG.Control_LUT_Pipeline {false} \
   CONFIG.Control_Path_Fanout {false} \
   CONFIG.DATA_Has_TLAST {Vector_Framing} \
   CONFIG.Data_Fractional_Bits {15} \
   CONFIG.Data_Path_Broadcast {false} \
   CONFIG.Data_Path_Fanout {false} \
   CONFIG.Disable_Half_Band_Centre_Tap {false} \
   CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} \
   CONFIG.Filter_Selection {1} \
   CONFIG.M_DATA_Has_TUSER {Not_Required} \
   CONFIG.No_BRAM_Read_First_Mode {false} \
   CONFIG.No_SRL_Attributes {false} \
   CONFIG.Number_Channels {512} \
   CONFIG.Number_Paths {2} \
   CONFIG.Optimal_Column_Lengths {false} \
   CONFIG.Optimization_Goal {Area} \
   CONFIG.Optimization_List {None} \
   CONFIG.Optimization_Selection {None} \
   CONFIG.Other {false} \
   CONFIG.Output_Rounding_Mode {Truncate_LSBs} \
   CONFIG.Output_Width {16} \
   CONFIG.Pre_Adder_Pipeline {false} \
   CONFIG.Quantization {Quantize_Only} \
   CONFIG.RateSpecification {Input_Sample_Period} \
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
   CONFIG.Clock_Frequency {300.0} \
   CONFIG.CoefficientSource {COE_File} \
   CONFIG.Coefficient_Fanout {false} \
   CONFIG.Coefficient_File {../../../../../../../data/lane12.coe} \
   CONFIG.Coefficient_Fractional_Bits {26} \
   CONFIG.Coefficient_Sets {256} \
   CONFIG.Coefficient_Sign {Signed} \
   CONFIG.Coefficient_Structure {Inferred} \
   CONFIG.Coefficient_Width {16} \
   CONFIG.ColumnConfig {4} \
   CONFIG.Control_Broadcast_Fanout {false} \
   CONFIG.Control_Column_Fanout {false} \
   CONFIG.Control_LUT_Pipeline {false} \
   CONFIG.Control_Path_Fanout {false} \
   CONFIG.DATA_Has_TLAST {Vector_Framing} \
   CONFIG.Data_Fractional_Bits {15} \
   CONFIG.Data_Path_Broadcast {false} \
   CONFIG.Data_Path_Fanout {false} \
   CONFIG.Disable_Half_Band_Centre_Tap {false} \
   CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} \
   CONFIG.Filter_Selection {1} \
   CONFIG.M_DATA_Has_TUSER {Not_Required} \
   CONFIG.No_BRAM_Read_First_Mode {false} \
   CONFIG.No_SRL_Attributes {false} \
   CONFIG.Number_Channels {512} \
   CONFIG.Number_Paths {2} \
   CONFIG.Optimal_Column_Lengths {false} \
   CONFIG.Optimization_Goal {Area} \
   CONFIG.Optimization_List {None} \
   CONFIG.Optimization_Selection {None} \
   CONFIG.Other {false} \
   CONFIG.Output_Rounding_Mode {Truncate_LSBs} \
   CONFIG.Output_Width {16} \
   CONFIG.Pre_Adder_Pipeline {false} \
   CONFIG.Quantization {Quantize_Only} \
   CONFIG.RateSpecification {Input_Sample_Period} \
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
   CONFIG.Clock_Frequency {300.0} \
   CONFIG.CoefficientSource {COE_File} \
   CONFIG.Coefficient_Fanout {false} \
   CONFIG.Coefficient_File {../../../../../../../data/lane13.coe} \
   CONFIG.Coefficient_Fractional_Bits {26} \
   CONFIG.Coefficient_Sets {256} \
   CONFIG.Coefficient_Sign {Signed} \
   CONFIG.Coefficient_Structure {Inferred} \
   CONFIG.Coefficient_Width {16} \
   CONFIG.ColumnConfig {4} \
   CONFIG.Control_Broadcast_Fanout {false} \
   CONFIG.Control_Column_Fanout {false} \
   CONFIG.Control_LUT_Pipeline {false} \
   CONFIG.Control_Path_Fanout {false} \
   CONFIG.DATA_Has_TLAST {Vector_Framing} \
   CONFIG.Data_Fractional_Bits {15} \
   CONFIG.Data_Path_Broadcast {false} \
   CONFIG.Data_Path_Fanout {false} \
   CONFIG.Disable_Half_Band_Centre_Tap {false} \
   CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} \
   CONFIG.Filter_Selection {1} \
   CONFIG.M_DATA_Has_TUSER {Not_Required} \
   CONFIG.No_BRAM_Read_First_Mode {false} \
   CONFIG.No_SRL_Attributes {false} \
   CONFIG.Number_Channels {512} \
   CONFIG.Number_Paths {2} \
   CONFIG.Optimal_Column_Lengths {false} \
   CONFIG.Optimization_Goal {Area} \
   CONFIG.Optimization_List {None} \
   CONFIG.Optimization_Selection {None} \
   CONFIG.Other {false} \
   CONFIG.Output_Rounding_Mode {Truncate_LSBs} \
   CONFIG.Output_Width {16} \
   CONFIG.Pre_Adder_Pipeline {false} \
   CONFIG.Quantization {Quantize_Only} \
   CONFIG.RateSpecification {Input_Sample_Period} \
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
   CONFIG.Clock_Frequency {300.0} \
   CONFIG.CoefficientSource {COE_File} \
   CONFIG.Coefficient_Fanout {false} \
   CONFIG.Coefficient_File {../../../../../../../data/lane14.coe} \
   CONFIG.Coefficient_Fractional_Bits {26} \
   CONFIG.Coefficient_Sets {256} \
   CONFIG.Coefficient_Sign {Signed} \
   CONFIG.Coefficient_Structure {Inferred} \
   CONFIG.Coefficient_Width {16} \
   CONFIG.ColumnConfig {4} \
   CONFIG.Control_Broadcast_Fanout {false} \
   CONFIG.Control_Column_Fanout {false} \
   CONFIG.Control_LUT_Pipeline {false} \
   CONFIG.Control_Path_Fanout {false} \
   CONFIG.DATA_Has_TLAST {Vector_Framing} \
   CONFIG.Data_Fractional_Bits {15} \
   CONFIG.Data_Path_Broadcast {false} \
   CONFIG.Data_Path_Fanout {false} \
   CONFIG.Disable_Half_Band_Centre_Tap {false} \
   CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} \
   CONFIG.Filter_Selection {1} \
   CONFIG.M_DATA_Has_TUSER {Not_Required} \
   CONFIG.No_BRAM_Read_First_Mode {false} \
   CONFIG.No_SRL_Attributes {false} \
   CONFIG.Number_Channels {512} \
   CONFIG.Number_Paths {2} \
   CONFIG.Optimal_Column_Lengths {false} \
   CONFIG.Optimization_Goal {Area} \
   CONFIG.Optimization_List {None} \
   CONFIG.Optimization_Selection {None} \
   CONFIG.Other {false} \
   CONFIG.Output_Rounding_Mode {Truncate_LSBs} \
   CONFIG.Output_Width {16} \
   CONFIG.Pre_Adder_Pipeline {false} \
   CONFIG.Quantization {Quantize_Only} \
   CONFIG.RateSpecification {Input_Sample_Period} \
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
   CONFIG.Clock_Frequency {300.0} \
   CONFIG.CoefficientSource {COE_File} \
   CONFIG.Coefficient_Fanout {false} \
   CONFIG.Coefficient_File {../../../../../../../data/lane15.coe} \
   CONFIG.Coefficient_Fractional_Bits {26} \
   CONFIG.Coefficient_Sets {256} \
   CONFIG.Coefficient_Sign {Signed} \
   CONFIG.Coefficient_Structure {Inferred} \
   CONFIG.Coefficient_Width {16} \
   CONFIG.ColumnConfig {4} \
   CONFIG.Control_Broadcast_Fanout {false} \
   CONFIG.Control_Column_Fanout {false} \
   CONFIG.Control_LUT_Pipeline {false} \
   CONFIG.Control_Path_Fanout {false} \
   CONFIG.DATA_Has_TLAST {Vector_Framing} \
   CONFIG.Data_Fractional_Bits {15} \
   CONFIG.Data_Path_Broadcast {false} \
   CONFIG.Data_Path_Fanout {false} \
   CONFIG.Disable_Half_Band_Centre_Tap {false} \
   CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} \
   CONFIG.Filter_Selection {1} \
   CONFIG.M_DATA_Has_TUSER {Not_Required} \
   CONFIG.No_BRAM_Read_First_Mode {false} \
   CONFIG.No_SRL_Attributes {false} \
   CONFIG.Number_Channels {512} \
   CONFIG.Number_Paths {2} \
   CONFIG.Optimal_Column_Lengths {false} \
   CONFIG.Optimization_Goal {Area} \
   CONFIG.Optimization_List {None} \
   CONFIG.Optimization_Selection {None} \
   CONFIG.Other {false} \
   CONFIG.Output_Rounding_Mode {Truncate_LSBs} \
   CONFIG.Output_Width {16} \
   CONFIG.Pre_Adder_Pipeline {false} \
   CONFIG.Quantization {Quantize_Only} \
   CONFIG.RateSpecification {Input_Sample_Period} \
   CONFIG.S_CONFIG_Method {By_Channel} \
   CONFIG.S_DATA_Has_FIFO {false} \
   CONFIG.S_DATA_Has_TUSER {Not_Required} \
   CONFIG.SamplePeriod {1} \
   CONFIG.Sample_Frequency {0.001} \
   CONFIG.Select_Pattern {All} \
 ] $fir_compiler_15

  # Create instance: opfb_fir_cfg_1, and set properties
  set opfb_fir_cfg_1 [ create_bd_cell -type ip -vlnv mazinlab:mkidgen3:opfb_fir_cfg:1.31 opfb_fir_cfg_1 ]

  # Create interface connections
  connect_bd_intf_net -intf_net S_AXIS1_1 [get_bd_intf_pins S_AXIS1] [get_bd_intf_pins axis_register_slice_0/S_AXIS]
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
  connect_bd_intf_net -intf_net axis_broadcaster_1_M00_AXIS [get_bd_intf_pins axis_broadcaster_1/M00_AXIS] [get_bd_intf_pins fir_compiler_0/S_AXIS_DATA]
  connect_bd_intf_net -intf_net axis_broadcaster_1_M01_AXIS [get_bd_intf_pins axis_broadcaster_1/M01_AXIS] [get_bd_intf_pins fir_compiler_1/S_AXIS_DATA]
  connect_bd_intf_net -intf_net axis_broadcaster_1_M02_AXIS [get_bd_intf_pins axis_broadcaster_1/M02_AXIS] [get_bd_intf_pins fir_compiler_2/S_AXIS_DATA]
  connect_bd_intf_net -intf_net axis_broadcaster_1_M03_AXIS [get_bd_intf_pins axis_broadcaster_1/M03_AXIS] [get_bd_intf_pins fir_compiler_3/S_AXIS_DATA]
  connect_bd_intf_net -intf_net axis_broadcaster_1_M04_AXIS [get_bd_intf_pins axis_broadcaster_1/M04_AXIS] [get_bd_intf_pins fir_compiler_4/S_AXIS_DATA]
  connect_bd_intf_net -intf_net axis_broadcaster_1_M05_AXIS [get_bd_intf_pins axis_broadcaster_1/M05_AXIS] [get_bd_intf_pins fir_compiler_5/S_AXIS_DATA]
  connect_bd_intf_net -intf_net axis_broadcaster_1_M06_AXIS [get_bd_intf_pins axis_broadcaster_1/M06_AXIS] [get_bd_intf_pins fir_compiler_6/S_AXIS_DATA]
  connect_bd_intf_net -intf_net axis_broadcaster_1_M07_AXIS [get_bd_intf_pins axis_broadcaster_1/M07_AXIS] [get_bd_intf_pins fir_compiler_7/S_AXIS_DATA]
  connect_bd_intf_net -intf_net axis_broadcaster_1_M08_AXIS [get_bd_intf_pins axis_broadcaster_1/M08_AXIS] [get_bd_intf_pins fir_compiler_8/S_AXIS_DATA]
  connect_bd_intf_net -intf_net axis_broadcaster_1_M09_AXIS [get_bd_intf_pins axis_broadcaster_1/M09_AXIS] [get_bd_intf_pins fir_compiler_9/S_AXIS_DATA]
  connect_bd_intf_net -intf_net axis_broadcaster_1_M10_AXIS [get_bd_intf_pins axis_broadcaster_1/M10_AXIS] [get_bd_intf_pins fir_compiler_10/S_AXIS_DATA]
  connect_bd_intf_net -intf_net axis_broadcaster_1_M11_AXIS [get_bd_intf_pins axis_broadcaster_1/M11_AXIS] [get_bd_intf_pins fir_compiler_11/S_AXIS_DATA]
  connect_bd_intf_net -intf_net axis_broadcaster_1_M12_AXIS [get_bd_intf_pins axis_broadcaster_1/M12_AXIS] [get_bd_intf_pins fir_compiler_12/S_AXIS_DATA]
  connect_bd_intf_net -intf_net axis_broadcaster_1_M13_AXIS [get_bd_intf_pins axis_broadcaster_1/M13_AXIS] [get_bd_intf_pins fir_compiler_13/S_AXIS_DATA]
  connect_bd_intf_net -intf_net axis_broadcaster_1_M14_AXIS [get_bd_intf_pins axis_broadcaster_1/M14_AXIS] [get_bd_intf_pins fir_compiler_14/S_AXIS_DATA]
  connect_bd_intf_net -intf_net axis_broadcaster_1_M15_AXIS [get_bd_intf_pins axis_broadcaster_1/M15_AXIS] [get_bd_intf_pins fir_compiler_15/S_AXIS_DATA]
  connect_bd_intf_net -intf_net axis_combiner_0_M_AXIS [get_bd_intf_pins axis_combiner_0/M_AXIS] [get_bd_intf_pins axis_register_slice_1/S_AXIS]
  connect_bd_intf_net -intf_net axis_register_slice_0_M_AXIS [get_bd_intf_pins axis_broadcaster_1/S_AXIS] [get_bd_intf_pins axis_register_slice_0/M_AXIS]
  connect_bd_intf_net -intf_net axis_register_slice_1_M_AXIS [get_bd_intf_pins M_AXIS] [get_bd_intf_pins axis_register_slice_1/M_AXIS]
  connect_bd_intf_net -intf_net fir_compiler_0_M_AXIS_DATA [get_bd_intf_pins axis_combiner_0/S00_AXIS] [get_bd_intf_pins fir_compiler_0/M_AXIS_DATA]
  connect_bd_intf_net -intf_net fir_compiler_10_M_AXIS_DATA [get_bd_intf_pins axis_combiner_0/S10_AXIS] [get_bd_intf_pins fir_compiler_10/M_AXIS_DATA]
  connect_bd_intf_net -intf_net fir_compiler_11_M_AXIS_DATA [get_bd_intf_pins axis_combiner_0/S11_AXIS] [get_bd_intf_pins fir_compiler_11/M_AXIS_DATA]
  connect_bd_intf_net -intf_net fir_compiler_12_M_AXIS_DATA [get_bd_intf_pins axis_combiner_0/S12_AXIS] [get_bd_intf_pins fir_compiler_12/M_AXIS_DATA]
  connect_bd_intf_net -intf_net fir_compiler_13_M_AXIS_DATA [get_bd_intf_pins axis_combiner_0/S13_AXIS] [get_bd_intf_pins fir_compiler_13/M_AXIS_DATA]
  connect_bd_intf_net -intf_net fir_compiler_14_M_AXIS_DATA [get_bd_intf_pins axis_combiner_0/S14_AXIS] [get_bd_intf_pins fir_compiler_14/M_AXIS_DATA]
  connect_bd_intf_net -intf_net fir_compiler_15_M_AXIS_DATA [get_bd_intf_pins axis_combiner_0/S15_AXIS] [get_bd_intf_pins fir_compiler_15/M_AXIS_DATA]
  connect_bd_intf_net -intf_net fir_compiler_1_M_AXIS_DATA [get_bd_intf_pins axis_combiner_0/S01_AXIS] [get_bd_intf_pins fir_compiler_1/M_AXIS_DATA]
  connect_bd_intf_net -intf_net fir_compiler_2_M_AXIS_DATA [get_bd_intf_pins axis_combiner_0/S02_AXIS] [get_bd_intf_pins fir_compiler_2/M_AXIS_DATA]
  connect_bd_intf_net -intf_net fir_compiler_3_M_AXIS_DATA [get_bd_intf_pins axis_combiner_0/S03_AXIS] [get_bd_intf_pins fir_compiler_3/M_AXIS_DATA]
  connect_bd_intf_net -intf_net fir_compiler_4_M_AXIS_DATA [get_bd_intf_pins axis_combiner_0/S04_AXIS] [get_bd_intf_pins fir_compiler_4/M_AXIS_DATA]
  connect_bd_intf_net -intf_net fir_compiler_5_M_AXIS_DATA [get_bd_intf_pins axis_combiner_0/S05_AXIS] [get_bd_intf_pins fir_compiler_5/M_AXIS_DATA]
  connect_bd_intf_net -intf_net fir_compiler_6_M_AXIS_DATA [get_bd_intf_pins axis_combiner_0/S06_AXIS] [get_bd_intf_pins fir_compiler_6/M_AXIS_DATA]
  connect_bd_intf_net -intf_net fir_compiler_7_M_AXIS_DATA [get_bd_intf_pins axis_combiner_0/S07_AXIS] [get_bd_intf_pins fir_compiler_7/M_AXIS_DATA]
  connect_bd_intf_net -intf_net fir_compiler_8_M_AXIS_DATA [get_bd_intf_pins axis_combiner_0/S08_AXIS] [get_bd_intf_pins fir_compiler_8/M_AXIS_DATA]
  connect_bd_intf_net -intf_net fir_compiler_9_M_AXIS_DATA [get_bd_intf_pins axis_combiner_0/S09_AXIS] [get_bd_intf_pins fir_compiler_9/M_AXIS_DATA]
  connect_bd_intf_net -intf_net opfb_fir_cfg_1_config_r [get_bd_intf_pins axis_broadcaster_0/S_AXIS] [get_bd_intf_pins opfb_fir_cfg_1/config_r]

  # Create port connections
  connect_bd_net -net Net [get_bd_pins aresetn] [get_bd_pins axis_broadcaster_0/aresetn] [get_bd_pins axis_broadcaster_1/aresetn] [get_bd_pins axis_combiner_0/aresetn] [get_bd_pins axis_register_slice_0/aresetn] [get_bd_pins axis_register_slice_1/aresetn] [get_bd_pins opfb_fir_cfg_1/ap_rst_n]
  connect_bd_net -net Net1 [get_bd_pins aclk] [get_bd_pins axis_broadcaster_0/aclk] [get_bd_pins axis_broadcaster_1/aclk] [get_bd_pins axis_combiner_0/aclk] [get_bd_pins axis_register_slice_0/aclk] [get_bd_pins axis_register_slice_1/aclk] [get_bd_pins fir_compiler_0/aclk] [get_bd_pins fir_compiler_1/aclk] [get_bd_pins fir_compiler_10/aclk] [get_bd_pins fir_compiler_11/aclk] [get_bd_pins fir_compiler_12/aclk] [get_bd_pins fir_compiler_13/aclk] [get_bd_pins fir_compiler_14/aclk] [get_bd_pins fir_compiler_15/aclk] [get_bd_pins fir_compiler_2/aclk] [get_bd_pins fir_compiler_3/aclk] [get_bd_pins fir_compiler_4/aclk] [get_bd_pins fir_compiler_5/aclk] [get_bd_pins fir_compiler_6/aclk] [get_bd_pins fir_compiler_7/aclk] [get_bd_pins fir_compiler_8/aclk] [get_bd_pins fir_compiler_9/aclk] [get_bd_pins opfb_fir_cfg_1/ap_clk]

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
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 output_r


  # Create pins
  create_bd_pin -dir I -type rst ap_rst_n
  create_bd_pin -dir I -type clk clk_out1

  # Create instance: axis_broadcaster_0, and set properties
  set axis_broadcaster_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_broadcaster:1.1 axis_broadcaster_0 ]
  set_property -dict [ list \
   CONFIG.HAS_TREADY {0} \
   CONFIG.M00_TDATA_REMAP {tdata[31:0]} \
   CONFIG.M01_TDATA_REMAP {tdata[63:32]} \
   CONFIG.M02_TDATA_REMAP {tdata[95:64]} \
   CONFIG.M03_TDATA_REMAP {tdata[127:96]} \
   CONFIG.M04_TDATA_REMAP {tdata[159:128]} \
   CONFIG.M05_TDATA_REMAP {tdata[191:160]} \
   CONFIG.M06_TDATA_REMAP {tdata[223:192]} \
   CONFIG.M07_TDATA_REMAP {tdata[255:224]} \
   CONFIG.M08_TDATA_REMAP {tdata[287:256]} \
   CONFIG.M09_TDATA_REMAP {tdata[319:288]} \
   CONFIG.M10_TDATA_REMAP {tdata[351:320]} \
   CONFIG.M11_TDATA_REMAP {tdata[383:352]} \
   CONFIG.M12_TDATA_REMAP {tdata[415:384]} \
   CONFIG.M13_TDATA_REMAP {tdata[447:416]} \
   CONFIG.M14_TDATA_REMAP {tdata[479:448]} \
   CONFIG.M15_TDATA_REMAP {tdata[511:480]} \
   CONFIG.M_TDATA_NUM_BYTES {4} \
   CONFIG.NUM_MI {16} \
   CONFIG.S_TDATA_NUM_BYTES {64} \
 ] $axis_broadcaster_0

  # Create instance: axis_register_slice_0, and set properties
  set axis_register_slice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axis_register_slice_0 ]
  set_property -dict [ list \
   CONFIG.HAS_TREADY {0} \
 ] $axis_register_slice_0

  # Create instance: axis_register_slice_1, and set properties
  set axis_register_slice_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axis_register_slice_1 ]
  set_property -dict [ list \
   CONFIG.HAS_TREADY {0} \
 ] $axis_register_slice_1

  # Create instance: pkg_fft_output_1, and set properties
  set pkg_fft_output_1 [ create_bd_cell -type ip -vlnv mazinlab:mkidgen3:pkg_fft_output:0.3 pkg_fft_output_1 ]

  # Create instance: ssrfft_16x4096_axis_0, and set properties
  set ssrfft_16x4096_axis_0 [ create_bd_cell -type ip -vlnv MazinLab:mkidgen3:ssrfft_16x4096_axis:1.0 ssrfft_16x4096_axis_0 ]

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]

  # Create instance: xlconstant_1, and set properties
  set xlconstant_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_1 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
   CONFIG.CONST_WIDTH {12} \
 ] $xlconstant_1

  # Create interface connections
  connect_bd_intf_net -intf_net S_AXIS_1 [get_bd_intf_pins S_AXIS] [get_bd_intf_pins axis_register_slice_0/S_AXIS]
  connect_bd_intf_net -intf_net axis_broadcaster_0_M00_AXIS [get_bd_intf_pins axis_broadcaster_0/M00_AXIS] [get_bd_intf_pins ssrfft_16x4096_axis_0/iq_0]
  connect_bd_intf_net -intf_net axis_broadcaster_0_M01_AXIS [get_bd_intf_pins axis_broadcaster_0/M01_AXIS] [get_bd_intf_pins ssrfft_16x4096_axis_0/iq_1]
  connect_bd_intf_net -intf_net axis_broadcaster_0_M02_AXIS [get_bd_intf_pins axis_broadcaster_0/M02_AXIS] [get_bd_intf_pins ssrfft_16x4096_axis_0/iq_2]
  connect_bd_intf_net -intf_net axis_broadcaster_0_M03_AXIS [get_bd_intf_pins axis_broadcaster_0/M03_AXIS] [get_bd_intf_pins ssrfft_16x4096_axis_0/iq_3]
  connect_bd_intf_net -intf_net axis_broadcaster_0_M04_AXIS [get_bd_intf_pins axis_broadcaster_0/M04_AXIS] [get_bd_intf_pins ssrfft_16x4096_axis_0/iq_4]
  connect_bd_intf_net -intf_net axis_broadcaster_0_M05_AXIS [get_bd_intf_pins axis_broadcaster_0/M05_AXIS] [get_bd_intf_pins ssrfft_16x4096_axis_0/iq_5]
  connect_bd_intf_net -intf_net axis_broadcaster_0_M06_AXIS [get_bd_intf_pins axis_broadcaster_0/M06_AXIS] [get_bd_intf_pins ssrfft_16x4096_axis_0/iq_6]
  connect_bd_intf_net -intf_net axis_broadcaster_0_M07_AXIS [get_bd_intf_pins axis_broadcaster_0/M07_AXIS] [get_bd_intf_pins ssrfft_16x4096_axis_0/iq_7]
  connect_bd_intf_net -intf_net axis_broadcaster_0_M08_AXIS [get_bd_intf_pins axis_broadcaster_0/M08_AXIS] [get_bd_intf_pins ssrfft_16x4096_axis_0/iq_8]
  connect_bd_intf_net -intf_net axis_broadcaster_0_M09_AXIS [get_bd_intf_pins axis_broadcaster_0/M09_AXIS] [get_bd_intf_pins ssrfft_16x4096_axis_0/iq_9]
  connect_bd_intf_net -intf_net axis_broadcaster_0_M10_AXIS [get_bd_intf_pins axis_broadcaster_0/M10_AXIS] [get_bd_intf_pins ssrfft_16x4096_axis_0/iq_10]
  connect_bd_intf_net -intf_net axis_broadcaster_0_M11_AXIS [get_bd_intf_pins axis_broadcaster_0/M11_AXIS] [get_bd_intf_pins ssrfft_16x4096_axis_0/iq_11]
  connect_bd_intf_net -intf_net axis_broadcaster_0_M12_AXIS [get_bd_intf_pins axis_broadcaster_0/M12_AXIS] [get_bd_intf_pins ssrfft_16x4096_axis_0/iq_12]
  connect_bd_intf_net -intf_net axis_broadcaster_0_M13_AXIS [get_bd_intf_pins axis_broadcaster_0/M13_AXIS] [get_bd_intf_pins ssrfft_16x4096_axis_0/iq_13]
  connect_bd_intf_net -intf_net axis_broadcaster_0_M14_AXIS [get_bd_intf_pins axis_broadcaster_0/M14_AXIS] [get_bd_intf_pins ssrfft_16x4096_axis_0/iq_14]
  connect_bd_intf_net -intf_net axis_broadcaster_0_M15_AXIS [get_bd_intf_pins axis_broadcaster_0/M15_AXIS] [get_bd_intf_pins ssrfft_16x4096_axis_0/iq_15]
  connect_bd_intf_net -intf_net axis_register_slice_0_M_AXIS [get_bd_intf_pins axis_broadcaster_0/S_AXIS] [get_bd_intf_pins axis_register_slice_0/M_AXIS]
  connect_bd_intf_net -intf_net axis_register_slice_1_M_AXIS [get_bd_intf_pins output_r] [get_bd_intf_pins axis_register_slice_1/M_AXIS]
  connect_bd_intf_net -intf_net pkg_fft_output_1_output_r [get_bd_intf_pins axis_register_slice_1/S_AXIS] [get_bd_intf_pins pkg_fft_output_1/output_r]

  # Create port connections
  connect_bd_net -net Net [get_bd_pins ap_rst_n] [get_bd_pins axis_broadcaster_0/aresetn] [get_bd_pins axis_register_slice_0/aresetn] [get_bd_pins axis_register_slice_1/aresetn] [get_bd_pins pkg_fft_output_1/ap_rst_n]
  connect_bd_net -net Net2 [get_bd_pins clk_out1] [get_bd_pins axis_broadcaster_0/aclk] [get_bd_pins axis_register_slice_0/aclk] [get_bd_pins axis_register_slice_1/aclk] [get_bd_pins pkg_fft_output_1/ap_clk] [get_bd_pins ssrfft_16x4096_axis_0/clk]
  connect_bd_net -net ssrfft_16x4096_axis_0_biniq_0 [get_bd_pins pkg_fft_output_1/iq00] [get_bd_pins ssrfft_16x4096_axis_0/biniq_0]
  connect_bd_net -net ssrfft_16x4096_axis_0_biniq_1 [get_bd_pins pkg_fft_output_1/iq01] [get_bd_pins ssrfft_16x4096_axis_0/biniq_1]
  connect_bd_net -net ssrfft_16x4096_axis_0_biniq_2 [get_bd_pins pkg_fft_output_1/iq02] [get_bd_pins ssrfft_16x4096_axis_0/biniq_2]
  connect_bd_net -net ssrfft_16x4096_axis_0_biniq_3 [get_bd_pins pkg_fft_output_1/iq03] [get_bd_pins ssrfft_16x4096_axis_0/biniq_3]
  connect_bd_net -net ssrfft_16x4096_axis_0_biniq_4 [get_bd_pins pkg_fft_output_1/iq04] [get_bd_pins ssrfft_16x4096_axis_0/biniq_4]
  connect_bd_net -net ssrfft_16x4096_axis_0_biniq_5 [get_bd_pins pkg_fft_output_1/iq05] [get_bd_pins ssrfft_16x4096_axis_0/biniq_5]
  connect_bd_net -net ssrfft_16x4096_axis_0_biniq_6 [get_bd_pins pkg_fft_output_1/iq06] [get_bd_pins ssrfft_16x4096_axis_0/biniq_6]
  connect_bd_net -net ssrfft_16x4096_axis_0_biniq_7 [get_bd_pins pkg_fft_output_1/iq07] [get_bd_pins ssrfft_16x4096_axis_0/biniq_7]
  connect_bd_net -net ssrfft_16x4096_axis_0_biniq_8 [get_bd_pins pkg_fft_output_1/iq08] [get_bd_pins ssrfft_16x4096_axis_0/biniq_8]
  connect_bd_net -net ssrfft_16x4096_axis_0_biniq_9 [get_bd_pins pkg_fft_output_1/iq09] [get_bd_pins ssrfft_16x4096_axis_0/biniq_9]
  connect_bd_net -net ssrfft_16x4096_axis_0_biniq_10 [get_bd_pins pkg_fft_output_1/iq10] [get_bd_pins ssrfft_16x4096_axis_0/biniq_10]
  connect_bd_net -net ssrfft_16x4096_axis_0_biniq_11 [get_bd_pins pkg_fft_output_1/iq11] [get_bd_pins ssrfft_16x4096_axis_0/biniq_11]
  connect_bd_net -net ssrfft_16x4096_axis_0_biniq_12 [get_bd_pins pkg_fft_output_1/iq12] [get_bd_pins ssrfft_16x4096_axis_0/biniq_12]
  connect_bd_net -net ssrfft_16x4096_axis_0_biniq_13 [get_bd_pins pkg_fft_output_1/iq13] [get_bd_pins ssrfft_16x4096_axis_0/biniq_13]
  connect_bd_net -net ssrfft_16x4096_axis_0_biniq_14 [get_bd_pins pkg_fft_output_1/iq14] [get_bd_pins ssrfft_16x4096_axis_0/biniq_14]
  connect_bd_net -net ssrfft_16x4096_axis_0_biniq_15 [get_bd_pins pkg_fft_output_1/iq15] [get_bd_pins ssrfft_16x4096_axis_0/biniq_15]
  connect_bd_net -net ssrfft_16x4096_axis_0_biniq_valid [get_bd_pins pkg_fft_output_1/iq00_ap_vld] [get_bd_pins pkg_fft_output_1/iq01_ap_vld] [get_bd_pins pkg_fft_output_1/iq02_ap_vld] [get_bd_pins pkg_fft_output_1/iq03_ap_vld] [get_bd_pins pkg_fft_output_1/iq04_ap_vld] [get_bd_pins pkg_fft_output_1/iq05_ap_vld] [get_bd_pins pkg_fft_output_1/iq06_ap_vld] [get_bd_pins pkg_fft_output_1/iq07_ap_vld] [get_bd_pins pkg_fft_output_1/iq08_ap_vld] [get_bd_pins pkg_fft_output_1/iq09_ap_vld] [get_bd_pins pkg_fft_output_1/iq10_ap_vld] [get_bd_pins pkg_fft_output_1/iq11_ap_vld] [get_bd_pins pkg_fft_output_1/iq12_ap_vld] [get_bd_pins pkg_fft_output_1/iq13_ap_vld] [get_bd_pins pkg_fft_output_1/iq14_ap_vld] [get_bd_pins pkg_fft_output_1/iq15_ap_vld] [get_bd_pins pkg_fft_output_1/scale_ap_vld] [get_bd_pins ssrfft_16x4096_axis_0/biniq_valid]
  connect_bd_net -net ssrfft_16x4096_axis_0_scale_out [get_bd_pins pkg_fft_output_1/scale] [get_bd_pins ssrfft_16x4096_axis_0/scale_out]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins pkg_fft_output_1/output_r_TREADY] [get_bd_pins xlconstant_0/dout]
  connect_bd_net -net xlconstant_1_dout [get_bd_pins ssrfft_16x4096_axis_0/scale_in] [get_bd_pins xlconstant_1/dout]

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
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M01_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS_DATA

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 iq_stream

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_control

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_control1


  # Create pins
  create_bd_pin -dir I -type clk aclk
  create_bd_pin -dir I -type rst ap_rst_n

  # Create instance: axis_broadcaster_0, and set properties
  set axis_broadcaster_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_broadcaster:1.1 axis_broadcaster_0 ]
  set_property -dict [ list \
   CONFIG.HAS_TREADY {0} \
   CONFIG.M00_TDATA_REMAP {tdata[255:0]} \
   CONFIG.M00_TUSER_REMAP {tuser[7:0]} \
   CONFIG.M01_TDATA_REMAP {tdata[255:0]} \
   CONFIG.M01_TUSER_REMAP {tuser[7:0]} \
   CONFIG.M_TDATA_NUM_BYTES {32} \
   CONFIG.M_TUSER_WIDTH {8} \
   CONFIG.S_TDATA_NUM_BYTES {32} \
   CONFIG.S_TUSER_WIDTH {8} \
 ] $axis_broadcaster_0

  # Create instance: axis_broadcaster_1, and set properties
  set axis_broadcaster_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_broadcaster:1.1 axis_broadcaster_1 ]
  set_property -dict [ list \
   CONFIG.HAS_TREADY {0} \
   CONFIG.M00_TDATA_REMAP {tdata[255:0]} \
   CONFIG.M00_TUSER_REMAP {tuser[7:0]} \
   CONFIG.M01_TDATA_REMAP {tdata[255:0]} \
   CONFIG.M01_TUSER_REMAP {tuser[7:0]} \
   CONFIG.M_TDATA_NUM_BYTES {32} \
   CONFIG.M_TUSER_WIDTH {8} \
   CONFIG.S_TDATA_NUM_BYTES {32} \
   CONFIG.S_TUSER_WIDTH {8} \
 ] $axis_broadcaster_1

  # Create instance: axis_register_slice_0, and set properties
  set axis_register_slice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axis_register_slice_0 ]
  set_property -dict [ list \
   CONFIG.HAS_TREADY {0} \
 ] $axis_register_slice_0

  # Create instance: axis_register_slice_1, and set properties
  set axis_register_slice_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axis_register_slice_1 ]

  # Create instance: axis_register_slice_2, and set properties
  set axis_register_slice_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axis_register_slice_2 ]

  # Create instance: axis_register_slice_3, and set properties
  set axis_register_slice_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axis_register_slice_3 ]

  # Create instance: bin_to_res, and set properties
  set bin_to_res [ create_bd_cell -type ip -vlnv mazinlab:mkidgen3:bin_to_res:1.33 bin_to_res ]

  # Create instance: fir_compiler_0, and set properties
  set fir_compiler_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:fir_compiler:7.2 fir_compiler_0 ]
  set_property -dict [ list \
   CONFIG.BestPrecision {true} \
   CONFIG.Clock_Frequency {300.0} \
   CONFIG.CoefficientSource {COE_File} \
   CONFIG.Coefficient_File {../../../../../../../data/lowpass.coe} \
   CONFIG.Coefficient_Fractional_Bits {17} \
   CONFIG.Coefficient_Sets {1} \
   CONFIG.Coefficient_Sign {Signed} \
   CONFIG.Coefficient_Structure {Inferred} \
   CONFIG.Coefficient_Width {16} \
   CONFIG.ColumnConfig {5} \
   CONFIG.DATA_Has_TLAST {Vector_Framing} \
   CONFIG.DATA_TUSER_Width {8} \
   CONFIG.Data_Fractional_Bits {15} \
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

  # Create instance: resonator_ddc, and set properties
  set resonator_ddc [ create_bd_cell -type ip -vlnv mazinlab:mkidgen3:resonator_dds:1.33 resonator_ddc ]

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]

  # Create interface connections
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins M01_AXIS] [get_bd_intf_pins axis_broadcaster_0/M01_AXIS]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins s_axi_control] [get_bd_intf_pins resonator_ddc/s_axi_control]
  connect_bd_intf_net -intf_net Conn4 [get_bd_intf_pins s_axi_control1] [get_bd_intf_pins bin_to_res/s_axi_control]
  connect_bd_intf_net -intf_net axis_broadcaster_0_M00_AXIS [get_bd_intf_pins axis_broadcaster_0/M00_AXIS] [get_bd_intf_pins axis_register_slice_1/S_AXIS]
  connect_bd_intf_net -intf_net axis_broadcaster_1_M00_AXIS [get_bd_intf_pins axis_broadcaster_1/M00_AXIS] [get_bd_intf_pins axis_register_slice_2/S_AXIS]
  connect_bd_intf_net -intf_net axis_register_slice_0_M_AXIS [get_bd_intf_pins axis_register_slice_0/M_AXIS] [get_bd_intf_pins bin_to_res/iq_stream]
  connect_bd_intf_net -intf_net axis_register_slice_1_M_AXIS [get_bd_intf_pins axis_register_slice_1/M_AXIS] [get_bd_intf_pins resonator_ddc/res_in]
  connect_bd_intf_net -intf_net axis_register_slice_2_M_AXIS [get_bd_intf_pins axis_register_slice_2/M_AXIS] [get_bd_intf_pins fir_compiler_0/S_AXIS_DATA]
  connect_bd_intf_net -intf_net axis_register_slice_3_M_AXIS [get_bd_intf_pins M_AXIS_DATA] [get_bd_intf_pins axis_register_slice_3/M_AXIS]
  connect_bd_intf_net -intf_net bin_to_res_res_stream [get_bd_intf_pins axis_broadcaster_0/S_AXIS] [get_bd_intf_pins bin_to_res/res_stream]
  connect_bd_intf_net -intf_net fir_compiler_0_M_AXIS_DATA [get_bd_intf_pins axis_register_slice_3/S_AXIS] [get_bd_intf_pins fir_compiler_0/M_AXIS_DATA]
  connect_bd_intf_net -intf_net iq_stream_1 [get_bd_intf_pins iq_stream] [get_bd_intf_pins axis_register_slice_0/S_AXIS]
  connect_bd_intf_net -intf_net resonator_ddc_res_out [get_bd_intf_pins axis_broadcaster_1/S_AXIS] [get_bd_intf_pins resonator_ddc/res_out]

  # Create port connections
  connect_bd_net -net Net [get_bd_pins aclk] [get_bd_pins axis_broadcaster_0/aclk] [get_bd_pins axis_broadcaster_1/aclk] [get_bd_pins axis_register_slice_0/aclk] [get_bd_pins axis_register_slice_1/aclk] [get_bd_pins axis_register_slice_2/aclk] [get_bd_pins axis_register_slice_3/aclk] [get_bd_pins bin_to_res/ap_clk] [get_bd_pins fir_compiler_0/aclk] [get_bd_pins resonator_ddc/ap_clk]
  connect_bd_net -net ap_rst_n_1 [get_bd_pins ap_rst_n] [get_bd_pins axis_broadcaster_0/aresetn] [get_bd_pins axis_broadcaster_1/aresetn] [get_bd_pins axis_register_slice_0/aresetn] [get_bd_pins axis_register_slice_1/aresetn] [get_bd_pins axis_register_slice_2/aresetn] [get_bd_pins axis_register_slice_3/aresetn] [get_bd_pins bin_to_res/ap_rst_n] [get_bd_pins resonator_ddc/ap_rst_n]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins bin_to_res/res_stream_TREADY] [get_bd_pins resonator_ddc/res_out_TREADY] [get_bd_pins xlconstant_0/dout]

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
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 istream_V

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 output_r

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 qstream_V


  # Create pins
  create_bd_pin -dir I -type clk ap_clk
  create_bd_pin -dir I -type rst ap_rst_n

  # Create instance: adc_to_opfb_0, and set properties
  set adc_to_opfb_0 [ create_bd_cell -type ip -vlnv mazinlab:mkidgen3:adc_to_opfb:1.31 adc_to_opfb_0 ]

  # Create instance: fft
  create_hier_cell_fft $hier_obj fft

  # Create instance: fir_to_fft_1, and set properties
  set fir_to_fft_1 [ create_bd_cell -type ip -vlnv mazinlab:mkidgen3:fir_to_fft:1.31 fir_to_fft_1 ]

  # Create instance: firs
  create_hier_cell_firs $hier_obj firs

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]

  # Create interface connections
  connect_bd_intf_net -intf_net adc_to_opfb_1_lanes [get_bd_intf_pins adc_to_opfb_0/lanes] [get_bd_intf_pins firs/S_AXIS1]
  connect_bd_intf_net -intf_net fft_output_r [get_bd_intf_pins output_r] [get_bd_intf_pins fft/output_r]
  connect_bd_intf_net -intf_net fir_to_fft_1_output_r [get_bd_intf_pins fft/S_AXIS] [get_bd_intf_pins fir_to_fft_1/output_r]
  connect_bd_intf_net -intf_net firs_M_AXIS [get_bd_intf_pins fir_to_fft_1/input_r] [get_bd_intf_pins firs/M_AXIS]
  connect_bd_intf_net -intf_net istream_V_1 [get_bd_intf_pins istream_V] [get_bd_intf_pins adc_to_opfb_0/istream_V]
  connect_bd_intf_net -intf_net qstream_V_1 [get_bd_intf_pins qstream_V] [get_bd_intf_pins adc_to_opfb_0/qstream_V]

  # Create port connections
  connect_bd_net -net Net [get_bd_pins ap_rst_n] [get_bd_pins adc_to_opfb_0/ap_rst_n] [get_bd_pins fft/ap_rst_n] [get_bd_pins fir_to_fft_1/ap_rst_n] [get_bd_pins firs/aresetn]
  connect_bd_net -net Net1 [get_bd_pins ap_clk] [get_bd_pins adc_to_opfb_0/ap_clk] [get_bd_pins fft/clk_out1] [get_bd_pins fir_to_fft_1/ap_clk] [get_bd_pins firs/aclk]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins adc_to_opfb_0/lanes_TREADY] [get_bd_pins fir_to_fft_1/output_r_TREADY] [get_bd_pins xlconstant_0/dout]

  # Restore current instance
  current_bd_instance $oldCurInst
}

## Hierarchical cell: resets
#proc create_hier_cell_resets { parentCell nameHier } {

#  variable script_folder

#  if { $parentCell eq "" || $nameHier eq "" } {
#     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_resets() - Empty argument(s)!"}
#     return
#  }

#  # Get object for parentCell
#  set parentObj [get_bd_cells $parentCell]
#  if { $parentObj == "" } {
#     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
#     return
#  }

#  # Make sure parentObj is hier blk
#  set parentType [get_property TYPE $parentObj]
#  if { $parentType ne "hier" } {
#     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
#     return
#  }

#  # Save current instance; Restore later
#  set oldCurInst [current_bd_instance .]

#  # Set parent object as current
#  current_bd_instance $parentObj

#  # Create cell and set as current instance
#  set hier_obj [create_bd_cell -type hier $nameHier]
#  current_bd_instance $hier_obj

#  # Create interface pins

#  # Create pins
#  create_bd_pin -dir I dcm_locked
#  create_bd_pin -dir I -type rst ext_reset_in
#  create_bd_pin -dir I -type rst ext_reset_in1
#  create_bd_pin -dir O -from 0 -to 0 -type rst peripheral_aresetn
#  create_bd_pin -dir O -from 0 -to 0 -type rst peripheral_aresetn1
#  create_bd_pin -dir O -from 0 -to 0 -type rst peripheral_aresetn2
#  create_bd_pin -dir O -from 0 -to 0 -type rst peripheral_aresetn3
#  create_bd_pin -dir O -from 0 -to 0 -type rst peripheral_aresetn4
#  create_bd_pin -dir I -type clk slowest_sync_clk
#  create_bd_pin -dir I -type clk slowest_sync_clk1
#  create_bd_pin -dir I -type clk slowest_sync_clk2
#  create_bd_pin -dir I -type clk slowest_sync_clk3

#  # Create instance: rst_clk_wiz_0_512M, and set properties
#  set rst_clk_wiz_0_512M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_clk_wiz_0_512M ]

#  # Create instance: rst_ddr4_0_333M, and set properties
#  set rst_ddr4_0_333M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_ddr4_0_333M ]

#  # Create instance: rst_ps8_0_99M, and set properties
#  set rst_ps8_0_99M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_ps8_0_99M ]

#  # Create instance: rst_usp_rf_data_converter_0_256M, and set properties
#  set rst_usp_rf_data_converter_0_256M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_usp_rf_data_converter_0_256M ]

#  # Create instance: xlconstant_0, and set properties
#  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]

#  # Create port connections
#  connect_bd_net -net ap_clk_1 [get_bd_pins slowest_sync_clk1] [get_bd_pins rst_clk_wiz_0_512M/slowest_sync_clk]
#  connect_bd_net -net capture_c0_ddr4_ui_clk [get_bd_pins slowest_sync_clk] [get_bd_pins rst_ddr4_0_333M/slowest_sync_clk]
#  connect_bd_net -net capture_c0_ddr4_ui_clk_sync_rst [get_bd_pins ext_reset_in] [get_bd_pins rst_ddr4_0_333M/ext_reset_in]
#  connect_bd_net -net clk_wiz_0_locked [get_bd_pins dcm_locked] [get_bd_pins rst_clk_wiz_0_512M/dcm_locked] [get_bd_pins rst_ps8_0_99M/dcm_locked]
#  connect_bd_net -net rst_clk_wiz_0_512M_peripheral_aresetn [get_bd_pins peripheral_aresetn4] [get_bd_pins rst_clk_wiz_0_512M/peripheral_aresetn]
#  connect_bd_net -net rst_ddr4_0_333M_peripheral_aresetn [get_bd_pins peripheral_aresetn] [get_bd_pins rst_ddr4_0_333M/peripheral_aresetn]
#  connect_bd_net -net rst_ps8_0_99M_peripheral_aresetn [get_bd_pins peripheral_aresetn2] [get_bd_pins rst_ps8_0_99M/peripheral_aresetn]
#  connect_bd_net -net rst_usp_rf_data_converter_0_256M_peripheral_aresetn [get_bd_pins peripheral_aresetn3] [get_bd_pins rst_usp_rf_data_converter_0_256M/peripheral_aresetn]
#  connect_bd_net -net usp_rf_data_converter_0_clk_dac1 [get_bd_pins slowest_sync_clk3] [get_bd_pins rst_usp_rf_data_converter_0_256M/slowest_sync_clk]
#  connect_bd_net -net xlconstant_0_dout [get_bd_pins peripheral_aresetn1] [get_bd_pins xlconstant_0/dout]
#  connect_bd_net -net zynq_ultra_ps_e_0_pl_clk0 [get_bd_pins slowest_sync_clk2] [get_bd_pins rst_ps8_0_99M/slowest_sync_clk]
#  connect_bd_net -net zynq_ultra_ps_e_0_pl_resetn0 [get_bd_pins ext_reset_in1] [get_bd_pins rst_clk_wiz_0_512M/ext_reset_in] [get_bd_pins rst_ps8_0_99M/ext_reset_in] [get_bd_pins rst_usp_rf_data_converter_0_256M/ext_reset_in]

#  # Restore current instance
#  current_bd_instance $oldCurInst
#}

# Hierarchical cell: photon_pipe
proc create_hier_cell_photon_pipe { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_photon_pipe() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M01_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS_DATA

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 istream_V

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 qstream_V

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_control

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_control1


  # Create pins
  create_bd_pin -dir I -type clk aclk
  create_bd_pin -dir I -type rst ap_rst_n

  # Create instance: axis_register_slice_0, and set properties
  set axis_register_slice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axis_register_slice_0 ]
  set_property -dict [ list \
   CONFIG.HAS_TREADY {0} \
 ] $axis_register_slice_0

  # Create instance: axis_register_slice_1, and set properties
  set axis_register_slice_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axis_register_slice_1 ]

  # Create instance: axis_register_slice_2, and set properties
  set axis_register_slice_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axis_register_slice_2 ]

  # Create instance: opfb
  create_hier_cell_opfb $hier_obj opfb

  # Create instance: reschan
  create_hier_cell_reschan $hier_obj reschan

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins M01_AXIS] [get_bd_intf_pins reschan/M01_AXIS]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins s_axi_control] [get_bd_intf_pins reschan/s_axi_control]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins s_axi_control1] [get_bd_intf_pins reschan/s_axi_control1]
  connect_bd_intf_net -intf_net axis_register_slice_0_M_AXIS [get_bd_intf_pins axis_register_slice_0/M_AXIS] [get_bd_intf_pins reschan/iq_stream]
  connect_bd_intf_net -intf_net axis_register_slice_2_M_AXIS [get_bd_intf_pins axis_register_slice_2/M_AXIS] [get_bd_intf_pins opfb/istream_V]
  connect_bd_intf_net -intf_net istream_V_1 [get_bd_intf_pins istream_V] [get_bd_intf_pins axis_register_slice_2/S_AXIS]
  connect_bd_intf_net -intf_net opfb_output_r [get_bd_intf_pins axis_register_slice_0/S_AXIS] [get_bd_intf_pins opfb/output_r]
  connect_bd_intf_net -intf_net qstream_V_1 [get_bd_intf_pins axis_register_slice_1/M_AXIS] [get_bd_intf_pins opfb/qstream_V]
  connect_bd_intf_net -intf_net qstream_V_2 [get_bd_intf_pins qstream_V] [get_bd_intf_pins axis_register_slice_1/S_AXIS]
  connect_bd_intf_net -intf_net reschan_M_AXIS_DATA [get_bd_intf_pins M_AXIS_DATA] [get_bd_intf_pins reschan/M_AXIS_DATA]

  # Create port connections
  connect_bd_net -net ap_clk_1 [get_bd_pins aclk] [get_bd_pins axis_register_slice_0/aclk] [get_bd_pins axis_register_slice_1/aclk] [get_bd_pins axis_register_slice_2/aclk] [get_bd_pins opfb/ap_clk] [get_bd_pins reschan/aclk]
  connect_bd_net -net ap_rst_n_1 [get_bd_pins ap_rst_n] [get_bd_pins axis_register_slice_0/aresetn] [get_bd_pins axis_register_slice_1/aresetn] [get_bd_pins axis_register_slice_2/aresetn] [get_bd_pins opfb/ap_rst_n] [get_bd_pins reschan/ap_rst_n]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: capture
proc create_hier_cell_capture { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_capture() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S02_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 ddr4_sdram_075

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 default_sysclk1_300mhz

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 istream_V

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 qstream_V

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 resstream

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 resstream1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_control

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_control1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_control2


  # Create pins
  create_bd_pin -dir I -type clk ap_clk
  create_bd_pin -dir I -type rst ap_rst_n
  create_bd_pin -dir I -type rst c0_ddr4_aresetn
  create_bd_pin -dir O -type clk c0_ddr4_ui_clk
  create_bd_pin -dir O -type rst c0_ddr4_ui_clk_sync_rst
  create_bd_pin -dir I -type rst reset

  # Create instance: adc_capture_0, and set properties
  set adc_capture_0 [ create_bd_cell -type ip -vlnv mazinlab:mkidgen3:adc_capture:1.33 adc_capture_0 ]

  # Create instance: axi_smc, and set properties
  set axi_smc [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 axi_smc ]
  set_property -dict [ list \
   CONFIG.HAS_ARESETN {0} \
   CONFIG.NUM_CLKS {2} \
   CONFIG.NUM_SI {4} \
 ] $axi_smc

  # Create instance: axis_register_slice_0, and set properties
  set axis_register_slice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axis_register_slice_0 ]

  # Create instance: axis_register_slice_1, and set properties
  set axis_register_slice_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axis_register_slice_1 ]

  # Create instance: axis_register_slice_2, and set properties
  set axis_register_slice_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axis_register_slice_2 ]

  # Create instance: axis_register_slice_3, and set properties
  set axis_register_slice_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axis_register_slice_3 ]

  # Create instance: ddr4_0, and set properties
  set ddr4_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ddr4:2.2 ddr4_0 ]
#  set_property -dict [ list \
#   CONFIG.ADDN_UI_CLKOUT1_FREQ_HZ {None} \
#   CONFIG.C0.BANK_GROUP_WIDTH {1} \
#   CONFIG.C0.DDR4_AxiAddressWidth {32} \
#   CONFIG.C0.DDR4_AxiArbitrationScheme {WRITE_PRIORITY_REG} \
#   CONFIG.C0.DDR4_AxiDataWidth {512} \
#   CONFIG.C0.DDR4_CLKFBOUT_MULT {10} \
#   CONFIG.C0.DDR4_CLKOUT0_DIVIDE {3} \
#   CONFIG.C0.DDR4_CasLatency {19} \
#   CONFIG.C0.DDR4_DIVCLK_DIVIDE {3} \
#   CONFIG.C0.DDR4_DataWidth {64} \
#   CONFIG.C0.DDR4_InputClockPeriod {3334} \
#   CONFIG.C0.DDR4_MemoryPart {MT40A512M16LY-075} \
#   CONFIG.C0_CLOCK_BOARD_INTERFACE {default_sysclk1_300mhz} \
#   CONFIG.C0_DDR4_BOARD_INTERFACE {ddr4_sdram_075} \
#   CONFIG.RESET_BOARD_INTERFACE {Custom} \
# ] $ddr4_0

  # Create instance: iq_capture_0, and set properties
  set iq_capture_0 [ create_bd_cell -type ip -vlnv mazinlab:mkidgen3:iq_capture:1.33 iq_capture_0 ]

  # Create instance: iq_capture_1, and set properties
  set iq_capture_1 [ create_bd_cell -type ip -vlnv mazinlab:mkidgen3:iq_capture:1.33 iq_capture_1 ]

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
 ] $xlconstant_0

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins ddr4_sdram_075] [get_bd_intf_pins ddr4_0/C0_DDR4]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins default_sysclk1_300mhz] [get_bd_intf_pins ddr4_0/C0_SYS_CLK]
  connect_bd_intf_net -intf_net S02_AXI_1 [get_bd_intf_pins S02_AXI] [get_bd_intf_pins axi_smc/S03_AXI]
  connect_bd_intf_net -intf_net adc_capture_0_m_axi_gmem [get_bd_intf_pins adc_capture_0/m_axi_gmem] [get_bd_intf_pins axi_smc/S00_AXI]
  connect_bd_intf_net -intf_net axi_smc_M00_AXI [get_bd_intf_pins axi_smc/M00_AXI] [get_bd_intf_pins ddr4_0/C0_DDR4_S_AXI]
  connect_bd_intf_net -intf_net axis_register_slice_0_M_AXIS [get_bd_intf_pins adc_capture_0/istream_V] [get_bd_intf_pins axis_register_slice_0/M_AXIS]
  connect_bd_intf_net -intf_net axis_register_slice_1_M_AXIS [get_bd_intf_pins adc_capture_0/qstream_V] [get_bd_intf_pins axis_register_slice_1/M_AXIS]
  connect_bd_intf_net -intf_net axis_register_slice_2_M_AXIS [get_bd_intf_pins axis_register_slice_2/M_AXIS] [get_bd_intf_pins iq_capture_0/resstream]
  connect_bd_intf_net -intf_net axis_register_slice_3_M_AXIS [get_bd_intf_pins axis_register_slice_3/M_AXIS] [get_bd_intf_pins iq_capture_1/resstream]
  connect_bd_intf_net -intf_net iq_capture_0_m_axi_gmem [get_bd_intf_pins axi_smc/S01_AXI] [get_bd_intf_pins iq_capture_0/m_axi_gmem]
  connect_bd_intf_net -intf_net iq_capture_1_m_axi_gmem [get_bd_intf_pins axi_smc/S02_AXI] [get_bd_intf_pins iq_capture_1/m_axi_gmem]
  connect_bd_intf_net -intf_net istream_V_1 [get_bd_intf_pins istream_V] [get_bd_intf_pins axis_register_slice_0/S_AXIS]
  connect_bd_intf_net -intf_net qstream_V_1 [get_bd_intf_pins qstream_V] [get_bd_intf_pins axis_register_slice_1/S_AXIS]
  connect_bd_intf_net -intf_net resstream1_1 [get_bd_intf_pins resstream1] [get_bd_intf_pins axis_register_slice_3/S_AXIS]
  connect_bd_intf_net -intf_net resstream_1 [get_bd_intf_pins resstream] [get_bd_intf_pins axis_register_slice_2/S_AXIS]
  connect_bd_intf_net -intf_net s_axi_control1_1 [get_bd_intf_pins s_axi_control1] [get_bd_intf_pins iq_capture_0/s_axi_control]
  connect_bd_intf_net -intf_net s_axi_control2_1 [get_bd_intf_pins s_axi_control2] [get_bd_intf_pins iq_capture_1/s_axi_control]
  connect_bd_intf_net -intf_net s_axi_control_1 [get_bd_intf_pins s_axi_control] [get_bd_intf_pins adc_capture_0/s_axi_control]

  # Create port connections
  connect_bd_net -net Net [get_bd_pins ap_clk] [get_bd_pins adc_capture_0/ap_clk] [get_bd_pins axi_smc/aclk] [get_bd_pins axis_register_slice_0/aclk] [get_bd_pins axis_register_slice_1/aclk] [get_bd_pins axis_register_slice_2/aclk] [get_bd_pins axis_register_slice_3/aclk] [get_bd_pins iq_capture_0/ap_clk] [get_bd_pins iq_capture_1/ap_clk]
  connect_bd_net -net ap_rst_n_1 [get_bd_pins ap_rst_n] [get_bd_pins adc_capture_0/ap_rst_n] [get_bd_pins axis_register_slice_0/aresetn] [get_bd_pins axis_register_slice_1/aresetn] [get_bd_pins axis_register_slice_2/aresetn] [get_bd_pins axis_register_slice_3/aresetn] [get_bd_pins iq_capture_0/ap_rst_n] [get_bd_pins iq_capture_1/ap_rst_n]
  connect_bd_net -net c0_ddr4_aresetn_1 [get_bd_pins c0_ddr4_aresetn] [get_bd_pins ddr4_0/c0_ddr4_aresetn]
  connect_bd_net -net ddr4_0_c0_ddr4_ui_clk [get_bd_pins c0_ddr4_ui_clk] [get_bd_pins axi_smc/aclk1] [get_bd_pins ddr4_0/c0_ddr4_ui_clk]
  connect_bd_net -net ddr4_0_c0_ddr4_ui_clk_sync_rst [get_bd_pins c0_ddr4_ui_clk_sync_rst] [get_bd_pins ddr4_0/c0_ddr4_ui_clk_sync_rst]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins ddr4_0/sys_rst] [get_bd_pins xlconstant_0/dout]

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
#  set adc1_clk [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 adc1_clk ]
#  set_property -dict [ list \
#   CONFIG.FREQ_HZ {409600000.0} \
#   ] $adc1_clk

#  set dac1_clk [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 dac1_clk ]
#  set_property -dict [ list \
#   CONFIG.FREQ_HZ {409600000.0} \
#   ] $dac1_clk

#  set ddr4_sdram_075 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 ddr4_sdram_075 ]

#  set default_sysclk1_300mhz [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 default_sysclk1_300mhz ]
#  set_property -dict [ list \
#   CONFIG.FREQ_HZ {300000000} \
#   ] $default_sysclk1_300mhz

#  set sysref_in [ create_bd_intf_port -mode Slave -vlnv xilinx.com:display_usp_rf_data_converter:diff_pins_rtl:1.0 sysref_in ]

#  set vin1_01 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 vin1_01 ]

#  set vin1_23 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 vin1_23 ]

#  set vout10 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 vout10 ]

#  set vout11 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 vout11 ]


  # Create ports
  set reset [ create_bd_port -dir I -type rst reset ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $reset

  # Create instance: axi_interconnect_0, and set properties
  set axi_interconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0 ]
  set_property -dict [ list \
   CONFIG.ENABLE_ADVANCED_OPTIONS {1} \
   CONFIG.M00_HAS_REGSLICE {4} \
   CONFIG.M01_HAS_REGSLICE {4} \
   CONFIG.M02_HAS_REGSLICE {4} \
   CONFIG.M03_HAS_REGSLICE {4} \
   CONFIG.M04_HAS_REGSLICE {4} \
   CONFIG.NUM_MI {5} \
   CONFIG.S00_HAS_DATA_FIFO {1} \
   CONFIG.S00_HAS_REGSLICE {4} \
 ] $axi_interconnect_0

  # Create instance: axi_protocol_convert_0, and set properties
  set axi_protocol_convert_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_protocol_converter:2.1 axi_protocol_convert_0 ]
  set_property -dict [ list \
   CONFIG.MI_PROTOCOL {AXI4LITE} \
 ] $axi_protocol_convert_0

  # Create instance: axis_broadcaster_0, and set properties
  set axis_broadcaster_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_broadcaster:1.1 axis_broadcaster_0 ]
  set_property -dict [ list \
   CONFIG.HAS_TREADY {0} \
   CONFIG.M00_TDATA_REMAP {tdata[127:0]} \
   CONFIG.M01_TDATA_REMAP {tdata[127:0]} \
   CONFIG.M_TDATA_NUM_BYTES {16} \
   CONFIG.S_TDATA_NUM_BYTES {16} \
 ] $axis_broadcaster_0

  # Create instance: axis_broadcaster_1, and set properties
  set axis_broadcaster_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_broadcaster:1.1 axis_broadcaster_1 ]
  set_property -dict [ list \
   CONFIG.HAS_TREADY {0} \
   CONFIG.M00_TDATA_REMAP {tdata[127:0]} \
   CONFIG.M01_TDATA_REMAP {tdata[127:0]} \
   CONFIG.M_TDATA_NUM_BYTES {16} \
   CONFIG.S_TDATA_NUM_BYTES {16} \
 ] $axis_broadcaster_1

#  # Create instance: capture
#  create_hier_cell_capture [current_bd_instance .] capture

  # Create instance: clk_wiz_0, and set properties
  set clk_wiz_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_0 ]
  set_property -dict [ list \
   CONFIG.CLKIN1_JITTER_PS {93} \
   CONFIG.CLKIN1_UI_JITTER {93} \
   CONFIG.CLKIN2_JITTER_PS {100.000} \
   CONFIG.CLKIN2_UI_JITTER {100.000} \
   CONFIG.CLKOUT1_DRIVES {BUFG} \
   CONFIG.CLKOUT1_JITTER {70.189} \
   CONFIG.CLKOUT1_PHASE_ERROR {72.706} \
   CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {512} \
   CONFIG.CLKOUT2_DRIVES {BUFG} \
   CONFIG.CLKOUT2_JITTER {90.045} \
   CONFIG.CLKOUT2_PHASE_ERROR {72.706} \
   CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {128} \
   CONFIG.CLKOUT2_USED {false} \
   CONFIG.FEEDBACK_SOURCE {FDBK_AUTO} \
   CONFIG.JITTER_OPTIONS {PS} \
   CONFIG.JITTER_SEL {Min_O_Jitter} \
   CONFIG.MMCM_BANDWIDTH {HIGH} \
   CONFIG.MMCM_CLKFBOUT_MULT_F {12.000} \
   CONFIG.MMCM_CLKOUT0_DIVIDE_F {3.000} \
   CONFIG.MMCM_CLKOUT1_DIVIDE {1} \
   CONFIG.MMCM_DIVCLK_DIVIDE {1} \
   CONFIG.MMCM_REF_JITTER1 {0.012} \
   CONFIG.MMCM_REF_JITTER2 {0.010} \
   CONFIG.NUM_OUT_CLKS {1} \
   CONFIG.OPTIMIZE_CLOCKING_STRUCTURE_EN {true} \
   CONFIG.PRIM_SOURCE {No_buffer} \
   CONFIG.RESET_PORT {reset} \
   CONFIG.RESET_TYPE {ACTIVE_HIGH} \
   CONFIG.USE_RESET {false} \
 ] $clk_wiz_0

  # Create instance: dac_table_axim_0, and set properties
  set dac_table_axim_0 [ create_bd_cell -type ip -vlnv mazinlab:mkidgen3:dac_table_axim:1.31 dac_table_axim_0 ]
  set_property -dict [ list \
   CONFIG.C_M_AXI_GMEM_DATA_WIDTH {128} \
 ] $dac_table_axim_0

  # Create instance: photon_pipe
  create_hier_cell_photon_pipe [current_bd_instance .] photon_pipe

  # Create instance: ps8_0_axi_periph, and set properties
  set ps8_0_axi_periph [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 ps8_0_axi_periph ]
  set_property -dict [ list \
   CONFIG.ENABLE_ADVANCED_OPTIONS {1} \
   CONFIG.M00_HAS_REGSLICE {4} \
   CONFIG.M01_HAS_REGSLICE {0} \
   CONFIG.M02_HAS_REGSLICE {0} \
   CONFIG.M03_HAS_REGSLICE {4} \
   CONFIG.M04_HAS_REGSLICE {4} \
   CONFIG.M05_HAS_REGSLICE {4} \
   CONFIG.M06_HAS_REGSLICE {4} \
   CONFIG.NUM_MI {3} \
 ] $ps8_0_axi_periph

  # Create instance: resets
#  create_hier_cell_resets [current_bd_instance .] resets

#  # Create instance: usp_rf_data_converter_0, and set properties
#  set usp_rf_data_converter_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:usp_rf_data_converter:2.5 usp_rf_data_converter_0 ]
#  set_property -dict [ list \
#   CONFIG.ADC0_Enable {0} \
#   CONFIG.ADC0_Fabric_Freq {0.0} \
#   CONFIG.ADC1_Enable {1} \
#   CONFIG.ADC1_Fabric_Freq {512.000} \
#   CONFIG.ADC1_Outclk_Freq {128.000} \
#   CONFIG.ADC1_PLL_Enable {true} \
#   CONFIG.ADC1_Refclk_Freq {409.600} \
#   CONFIG.ADC1_Sampling_Rate {4.096} \
#   CONFIG.ADC_Decimation_Mode00 {0} \
#   CONFIG.ADC_Decimation_Mode01 {0} \
#   CONFIG.ADC_Decimation_Mode10 {1} \
#   CONFIG.ADC_Decimation_Mode11 {1} \
#   CONFIG.ADC_Decimation_Mode12 {1} \
#   CONFIG.ADC_Decimation_Mode13 {1} \
#   CONFIG.ADC_Mixer_Type00 {3} \
#   CONFIG.ADC_Mixer_Type01 {3} \
#   CONFIG.ADC_Mixer_Type10 {0} \
#   CONFIG.ADC_Mixer_Type11 {0} \
#   CONFIG.ADC_Mixer_Type12 {0} \
#   CONFIG.ADC_Mixer_Type13 {0} \
#   CONFIG.ADC_RESERVED_1_00 {false} \
#   CONFIG.ADC_RESERVED_1_02 {false} \
#   CONFIG.ADC_RESERVED_1_10 {false} \
#   CONFIG.ADC_RESERVED_1_12 {false} \
#   CONFIG.ADC_Slice00_Enable {false} \
#   CONFIG.ADC_Slice01_Enable {false} \
#   CONFIG.ADC_Slice10_Enable {true} \
#   CONFIG.ADC_Slice11_Enable {true} \
#   CONFIG.ADC_Slice12_Enable {true} \
#   CONFIG.ADC_Slice13_Enable {true} \
#   CONFIG.Axiclk_Freq {128} \
#   CONFIG.DAC0_Enable {0} \
#   CONFIG.DAC0_Fabric_Freq {0.0} \
#   CONFIG.DAC1_Enable {1} \
#   CONFIG.DAC1_Fabric_Freq {256.000} \
#   CONFIG.DAC1_Outclk_Freq {256.000} \
#   CONFIG.DAC1_PLL_Enable {true} \
#   CONFIG.DAC1_Refclk_Freq {409.600} \
#   CONFIG.DAC1_Sampling_Rate {4.096} \
#   CONFIG.DAC_Interpolation_Mode00 {0} \
#   CONFIG.DAC_Interpolation_Mode02 {0} \
#   CONFIG.DAC_Interpolation_Mode10 {1} \
#   CONFIG.DAC_Interpolation_Mode11 {1} \
#   CONFIG.DAC_Mixer_Type00 {3} \
#   CONFIG.DAC_Mixer_Type02 {3} \
#   CONFIG.DAC_Mixer_Type10 {0} \
#   CONFIG.DAC_Mixer_Type11 {0} \
#   CONFIG.DAC_RESERVED_1_00 {false} \
#   CONFIG.DAC_RESERVED_1_01 {false} \
#   CONFIG.DAC_RESERVED_1_02 {false} \
#   CONFIG.DAC_RESERVED_1_03 {false} \
#   CONFIG.DAC_RESERVED_1_10 {false} \
#   CONFIG.DAC_RESERVED_1_11 {false} \
#   CONFIG.DAC_RESERVED_1_12 {false} \
#   CONFIG.DAC_RESERVED_1_13 {false} \
#   CONFIG.DAC_Slice00_Enable {false} \
#   CONFIG.DAC_Slice02_Enable {false} \
#   CONFIG.DAC_Slice10_Enable {true} \
#   CONFIG.DAC_Slice11_Enable {true} \
# ] $usp_rf_data_converter_0
 

#  # Create instance: zynq_ultra_ps_e_0, and set properties
#  set zynq_ultra_ps_e_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e:3.3 zynq_ultra_ps_e_0 ]

  # Create interface connections
  connect_bd_intf_net -intf_net adc1_clk_1 [get_bd_intf_ports adc1_clk] [get_bd_intf_pins usp_rf_data_converter_0/adc1_clk]
#  connect_bd_intf_net -intf_net axi_interconnect_0_M02_AXI [get_bd_intf_pins axi_interconnect_0/M02_AXI] [get_bd_intf_pins capture/s_axi_control]
#  connect_bd_intf_net -intf_net axi_interconnect_0_M04_AXI [get_bd_intf_pins axi_interconnect_0/M04_AXI] [get_bd_intf_pins capture/s_axi_control2]
  connect_bd_intf_net -intf_net axi_protocol_convert_0_M_AXI [get_bd_intf_pins axi_protocol_convert_0/M_AXI] [get_bd_intf_pins ps8_0_axi_periph/S00_AXI]
  connect_bd_intf_net -intf_net axis_broadcaster_0_M00_AXIS [get_bd_intf_pins axis_broadcaster_0/M00_AXIS] [get_bd_intf_pins photon_pipe/istream_V]
#  connect_bd_intf_net -intf_net axis_broadcaster_0_M01_AXIS [get_bd_intf_pins axis_broadcaster_0/M01_AXIS] [get_bd_intf_pins capture/istream_V]
  connect_bd_intf_net -intf_net axis_broadcaster_1_M00_AXIS [get_bd_intf_pins axis_broadcaster_1/M00_AXIS] [get_bd_intf_pins photon_pipe/qstream_V]
#  connect_bd_intf_net -intf_net axis_broadcaster_1_M01_AXIS [get_bd_intf_pins axis_broadcaster_1/M01_AXIS] [get_bd_intf_pins capture/qstream_V]
#  connect_bd_intf_net -intf_net capture_ddr4_sdram_075 [get_bd_intf_ports ddr4_sdram_075] [get_bd_intf_pins capture/ddr4_sdram_075]
  connect_bd_intf_net -intf_net dac1_clk_1 [get_bd_intf_ports dac1_clk] [get_bd_intf_pins usp_rf_data_converter_0/dac1_clk]
  connect_bd_intf_net -intf_net dac_table_axim_0_iout [get_bd_intf_pins dac_table_axim_0/iout] [get_bd_intf_pins usp_rf_data_converter_0/s10_axis]
  connect_bd_intf_net -intf_net dac_table_axim_0_m_axi_control [get_bd_intf_pins dac_table_axim_0/m_axi_gmem] [get_bd_intf_pins zynq_ultra_ps_e_0/S_AXI_HP0_FPD]
  connect_bd_intf_net -intf_net dac_table_axim_0_qout [get_bd_intf_pins dac_table_axim_0/qout] [get_bd_intf_pins usp_rf_data_converter_0/s11_axis]
#  connect_bd_intf_net -intf_net default_sysclk1_300mhz_1 [get_bd_intf_ports default_sysclk1_300mhz] [get_bd_intf_pins capture/default_sysclk1_300mhz]
#  connect_bd_intf_net -intf_net photon_pipe_M01_AXIS [get_bd_intf_pins capture/resstream1] [get_bd_intf_pins photon_pipe/M01_AXIS]
  connect_bd_intf_net -intf_net ps8_0_axi_periph_M00_AXI [get_bd_intf_pins dac_table_axim_0/s_axi_control] [get_bd_intf_pins ps8_0_axi_periph/M00_AXI]
  connect_bd_intf_net -intf_net ps8_0_axi_periph_M01_AXI [get_bd_intf_pins ps8_0_axi_periph/M01_AXI] [get_bd_intf_pins usp_rf_data_converter_0/s_axi]
  connect_bd_intf_net -intf_net ps8_0_axi_periph_M02_AXI [get_bd_intf_pins axi_interconnect_0/S00_AXI] [get_bd_intf_pins ps8_0_axi_periph/M02_AXI]
#  connect_bd_intf_net -intf_net resstream_1 [get_bd_intf_pins capture/resstream] [get_bd_intf_pins photon_pipe/M_AXIS_DATA]
#  connect_bd_intf_net -intf_net s_axi_control1_1 [get_bd_intf_pins axi_interconnect_0/M03_AXI] [get_bd_intf_pins capture/s_axi_control1]
  connect_bd_intf_net -intf_net s_axi_control1_2 [get_bd_intf_pins axi_interconnect_0/M01_AXI] [get_bd_intf_pins photon_pipe/s_axi_control1]
  connect_bd_intf_net -intf_net s_axi_control_1 [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_pins photon_pipe/s_axi_control]
  connect_bd_intf_net -intf_net sysref_in_1 [get_bd_intf_ports sysref_in] [get_bd_intf_pins usp_rf_data_converter_0/sysref_in]
  connect_bd_intf_net -intf_net usp_rf_data_converter_0_m10_axis [get_bd_intf_pins axis_broadcaster_0/S_AXIS] [get_bd_intf_pins usp_rf_data_converter_0/m10_axis]
  connect_bd_intf_net -intf_net usp_rf_data_converter_0_m12_axis [get_bd_intf_pins axis_broadcaster_1/S_AXIS] [get_bd_intf_pins usp_rf_data_converter_0/m12_axis]
#  connect_bd_intf_net -intf_net usp_rf_data_converter_0_vout10 [get_bd_intf_ports vout10] [get_bd_intf_pins usp_rf_data_converter_0/vout10]
#  connect_bd_intf_net -intf_net usp_rf_data_converter_0_vout11 [get_bd_intf_ports vout11] [get_bd_intf_pins usp_rf_data_converter_0/vout11]
#  connect_bd_intf_net -intf_net vin1_01_1 [get_bd_intf_ports vin1_01] [get_bd_intf_pins usp_rf_data_converter_0/vin1_01]
#  connect_bd_intf_net -intf_net vin1_23_1 [get_bd_intf_ports vin1_23] [get_bd_intf_pins usp_rf_data_converter_0/vin1_23]
  connect_bd_intf_net -intf_net zynq_ultra_ps_e_0_M_AXI_HPM0_FPD [get_bd_intf_pins axi_protocol_convert_0/S_AXI] [get_bd_intf_pins zynq_ultra_ps_e_0/M_AXI_HPM0_FPD]
#  connect_bd_intf_net -intf_net zynq_ultra_ps_e_0_M_AXI_HPM1_FPD [get_bd_intf_pins capture/S02_AXI] [get_bd_intf_pins zynq_ultra_ps_e_0/M_AXI_HPM1_FPD]

  # Create port connections
#  connect_bd_net -net M02_ARESETN_1 [get_bd_pins axi_interconnect_0/S00_ARESETN] [get_bd_pins axi_protocol_convert_0/aresetn] [get_bd_pins ps8_0_axi_periph/ARESETN] [get_bd_pins ps8_0_axi_periph/M01_ARESETN] [get_bd_pins ps8_0_axi_periph/M02_ARESETN] [get_bd_pins ps8_0_axi_periph/S00_ARESETN] [get_bd_pins resets/peripheral_aresetn2] [get_bd_pins usp_rf_data_converter_0/s_axi_aresetn]
#  connect_bd_net -net ap_clk_1 [get_bd_pins axi_interconnect_0/ACLK] [get_bd_pins axi_interconnect_0/M00_ACLK] [get_bd_pins axi_interconnect_0/M01_ACLK] [get_bd_pins axi_interconnect_0/M02_ACLK] [get_bd_pins axi_interconnect_0/M03_ACLK] [get_bd_pins axi_interconnect_0/M04_ACLK] [get_bd_pins axis_broadcaster_0/aclk] [get_bd_pins axis_broadcaster_1/aclk] [get_bd_pins capture/ap_clk] [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins photon_pipe/aclk] [get_bd_pins resets/slowest_sync_clk1] [get_bd_pins usp_rf_data_converter_0/m1_axis_aclk]
#  connect_bd_net -net capture_c0_ddr4_ui_clk [get_bd_pins capture/c0_ddr4_ui_clk] [get_bd_pins resets/slowest_sync_clk] [get_bd_pins zynq_ultra_ps_e_0/maxihpm1_fpd_aclk]
#  connect_bd_net -net capture_c0_ddr4_ui_clk_sync_rst [get_bd_pins capture/c0_ddr4_ui_clk_sync_rst] [get_bd_pins resets/ext_reset_in]
#  connect_bd_net -net clk_wiz_0_locked [get_bd_pins clk_wiz_0/locked] [get_bd_pins resets/dcm_locked]
#  connect_bd_net -net reset_1 [get_bd_ports reset] [get_bd_pins capture/reset]
#  connect_bd_net -net resets_peripheral_aresetn4 [get_bd_pins axi_interconnect_0/ARESETN] [get_bd_pins resets/peripheral_aresetn4] [get_bd_pins usp_rf_data_converter_0/m1_axis_aresetn]
#  connect_bd_net -net rst_clk_wiz_0_512M_peripheral_aresetn [get_bd_pins axi_interconnect_0/M00_ARESETN] [get_bd_pins axi_interconnect_0/M01_ARESETN] [get_bd_pins axi_interconnect_0/M02_ARESETN] [get_bd_pins axi_interconnect_0/M03_ARESETN] [get_bd_pins axi_interconnect_0/M04_ARESETN] [get_bd_pins axis_broadcaster_0/aresetn] [get_bd_pins axis_broadcaster_1/aresetn] [get_bd_pins capture/ap_rst_n] [get_bd_pins photon_pipe/ap_rst_n] [get_bd_pins resets/peripheral_aresetn1]
#  connect_bd_net -net rst_ddr4_0_333M_peripheral_aresetn [get_bd_pins capture/c0_ddr4_aresetn] [get_bd_pins resets/peripheral_aresetn]
#  connect_bd_net -net rst_usp_rf_data_converter_0_256M_peripheral_aresetn [get_bd_pins dac_table_axim_0/ap_rst_n] [get_bd_pins ps8_0_axi_periph/M00_ARESETN] [get_bd_pins resets/peripheral_aresetn3] [get_bd_pins usp_rf_data_converter_0/s1_axis_aresetn]
#  connect_bd_net -net usp_rf_data_converter_0_clk_adc2 [get_bd_pins axi_interconnect_0/S00_ACLK] [get_bd_pins axi_protocol_convert_0/aclk] [get_bd_pins clk_wiz_0/clk_in1] [get_bd_pins ps8_0_axi_periph/ACLK] [get_bd_pins ps8_0_axi_periph/M01_ACLK] [get_bd_pins ps8_0_axi_periph/M02_ACLK] [get_bd_pins ps8_0_axi_periph/S00_ACLK] [get_bd_pins resets/slowest_sync_clk2] [get_bd_pins usp_rf_data_converter_0/clk_adc1] [get_bd_pins usp_rf_data_converter_0/s_axi_aclk] [get_bd_pins zynq_ultra_ps_e_0/maxihpm0_fpd_aclk]
#  connect_bd_net -net usp_rf_data_converter_0_clk_dac1 [get_bd_pins dac_table_axim_0/ap_clk] [get_bd_pins ps8_0_axi_periph/M00_ACLK] [get_bd_pins resets/slowest_sync_clk3] [get_bd_pins usp_rf_data_converter_0/clk_dac1] [get_bd_pins usp_rf_data_converter_0/s1_axis_aclk] [get_bd_pins zynq_ultra_ps_e_0/saxihp0_fpd_aclk]
#  connect_bd_net -net zynq_ultra_ps_e_0_pl_resetn0 [get_bd_pins resets/ext_reset_in1] [get_bd_pins zynq_ultra_ps_e_0/pl_resetn0]

#  # Create address segments
#  assign_bd_address -offset 0x000800000000 -range 0x000800000000 -target_address_space [get_bd_addr_spaces dac_table_axim_0/Data_m_axi_gmem] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_DDR_HIGH] -force
#  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces dac_table_axim_0/Data_m_axi_gmem] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_DDR_LOW] -force
#  assign_bd_address -offset 0xC0000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces dac_table_axim_0/Data_m_axi_gmem] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_QSPI] -force
#  assign_bd_address -offset 0xA0000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs capture/adc_capture_0/s_axi_control/Reg] -force
#  assign_bd_address -offset 0xA0040000 -range 0x00010000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs photon_pipe/reschan/bin_to_res/s_axi_control/Reg] -force
#  assign_bd_address -offset 0xA0030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs dac_table_axim_0/s_axi_control/Reg] -force
#  assign_bd_address -offset 0x000500000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs capture/ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
#  assign_bd_address -offset 0xA0010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs capture/iq_capture_0/s_axi_control/Reg] -force
#  assign_bd_address -offset 0xA0020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs capture/iq_capture_1/s_axi_control/Reg] -force
#  assign_bd_address -offset 0xA0050000 -range 0x00010000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs photon_pipe/reschan/resonator_ddc/s_axi_control/Reg] -force
#  assign_bd_address -offset 0xA0080000 -range 0x00040000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs usp_rf_data_converter_0/s_axi/Reg] -force
#  assign_bd_address -offset 0x000500000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces capture/adc_capture_0/Data_m_axi_gmem] [get_bd_addr_segs capture/ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
#  assign_bd_address -offset 0x000500000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces capture/iq_capture_0/Data_m_axi_gmem] [get_bd_addr_segs capture/ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
#  assign_bd_address -offset 0x000500000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces capture/iq_capture_1/Data_m_axi_gmem] [get_bd_addr_segs capture/ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force

#  # Exclude Address Segments
#  exclude_bd_addr_seg -offset 0xFF000000 -range 0x01000000 -target_address_space [get_bd_addr_spaces dac_table_axim_0/Data_m_axi_gmem] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_LPS_OCM]


  # Restore current instance
  current_bd_instance $oldCurInst

#  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

#create_root_design ""

