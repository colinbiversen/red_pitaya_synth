# ==================================================================================================
# make_project.tcl
#
# Simple script for creating a Vivado project from the project/ folder 
# Based on Pavel Demin's red-pitaya-notes-master/ git project
#
# Make sure the script is executed from redpitaya_synth/ folder

set project_name "red_pitaya_synth"

source projects/$project_name/block_design.tcl
