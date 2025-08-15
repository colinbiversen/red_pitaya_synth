# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "data_length_d" -parent ${Page_0}
  ipgui::add_param $IPINST -name "max_data_transfer_d" -parent ${Page_0}


}

proc update_PARAM_VALUE.data_length_d { PARAM_VALUE.data_length_d } {
	# Procedure called to update data_length_d when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.data_length_d { PARAM_VALUE.data_length_d } {
	# Procedure called to validate data_length_d
	return true
}

proc update_PARAM_VALUE.max_data_transfer_d { PARAM_VALUE.max_data_transfer_d } {
	# Procedure called to update max_data_transfer_d when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.max_data_transfer_d { PARAM_VALUE.max_data_transfer_d } {
	# Procedure called to validate max_data_transfer_d
	return true
}


proc update_MODELPARAM_VALUE.data_length_d { MODELPARAM_VALUE.data_length_d PARAM_VALUE.data_length_d } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.data_length_d}] ${MODELPARAM_VALUE.data_length_d}
}

proc update_MODELPARAM_VALUE.max_data_transfer_d { MODELPARAM_VALUE.max_data_transfer_d PARAM_VALUE.max_data_transfer_d } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.max_data_transfer_d}] ${MODELPARAM_VALUE.max_data_transfer_d}
}

