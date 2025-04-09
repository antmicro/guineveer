#!/bin/bash
#
# Antmicro's vivado tcl generator
# author: pgielda@antmicro.com
#

# 1. Set important project information (adjust)
PROJECT_NAME="guineveer"
PART_NAME="xc7a100t"
DEFAULT_LANG="Verilog"
TOP_LEVEL="top"
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd ) # The full directory name of the script no matter where it is being called from
PROJECT_ROOT="$(realpath "${SCRIPT_DIR}")"
GUINEVEER_ROOT="$(realpath "${SCRIPT_DIR}/../..")"
CONFIG_DIR="$(realpath "${GUINEVEER_ROOT}/build/snapshots/default/")"

# 2. Save last project regeneration time
echo
echo "#"
echo -n "# script generated @ "
date
echo "#"
echo

# 3. Create a new project
echo "create_project ${PROJECT_NAME} ./${PROJECT_NAME} -part ${PART_NAME} -force"
echo "set_property target_language ${DEFAULT_LANG} [current_project]"

# 4. Include directories
echo "set_property include_dirs \"${INCLUDE_DIRS}\" [get_filesets sources_1]"

# 5. Import VHDL and Verilog filef
for f in $HDL_SOURCES
do
  if [ -f $f ];
  then
    echo "import_files -fileset sources_1 ${f}"
  fi
done

# Top-level wrapper
# TODO: Make this target-specific
echo "import_files -fileset sources_1 ${PROJECT_ROOT}/src/guineveer_arty100.sv"

# Manually import el2_mem_if because it's not loaded (all files from the el2_mem_if are imported though)
echo "import_files -fileset sources_1 ${RV_ROOT}/design/lib/el2_mem_if.sv"

# 6. Import constraints
for f in ${PROJECT_ROOT}/constrs/*.xdc
do
  if [ -f $f ];
  then
    echo "import_files -fileset constrs_1 ${f}"
  fi
done

# 7. Custom rules for the project, i.e. header imports (adjust)
echo "set_property is_global_include true [get_files -filter {NAME =~ *common_defines.vh}]"
echo "set_property is_global_include true  [get_files -filter {NAME =~ *el2_pdef.vh}]"
echo "set_property file_type SystemVerilog  [get_files -filter {NAME =~ *el2_pdef.vh}]"

echo "# Set specific Verilog files explicitly to SystemVerilog type"
echo "set_property file_type SystemVerilog [get_files dmi_jtag_to_core_sync.v]"
echo "set_property file_type SystemVerilog [get_files rvjtag_tap.v]"
echo "set_property file_type SystemVerilog [get_files dmi_mux.v]"

if [ -n "$HEX_FILE" ];
then
  echo "# Initialize memory with a provided file"
  echo "set_property verilog_define {GUINEVEER_MEMORY_FILE=\"$HEX_FILE\"} [current_fileset]"
  echo "if { ![file exists \"$HEX_FILE\"] } { error \"Could not find the provided memory file: '$HEX_FILE'\" }"
fi

echo "set_property top ${TOP_LEVEL} [current_fileset]"

echo
echo "launch_runs synth_1 -jobs $(nproc)"
echo "wait_on_run synth_1"

echo "launch_runs impl_1 -to_step write_bitstream -jobs $(nproc)"
echo "wait_on_run impl_1"
