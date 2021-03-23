#!/bin/bash

# Specify the top files
rtl_top="dafx_top"
uvm_top="dafx_tb_top"

# ------------------------------------------------------------------------------
# Source submodules
# ------------------------------------------------------------------------------

git_sub_root="$(git rev-parse --show-toplevel)"

git_root="$(git rev-parse --show-toplevel)/submodules/rtl_common_design"
source $git_sub_root/submodules/rtl_common_design/modules/synchronizers/io/rtl/rtl_files.lst
source $git_sub_root/submodules/rtl_common_design/modules/synchronizers/reset/rtl/rtl_files.lst
source $git_sub_root/submodules/rtl_common_design/modules/synchronizers/cdc_bit_sync/rtl/rtl_files.lst
source $git_sub_root/submodules/rtl_common_design/modules/synchronizers/cdc_vector_sync/rtl/rtl_files.lst
source $git_sub_root/submodules/rtl_common_design/modules/mechanics/button/rtl/rtl_files.lst
source $git_sub_root/submodules/rtl_common_design/modules/axi4_read_arbiter/rtl/rtl_files.lst
source $git_sub_root/submodules/rtl_common_design/modules/axi4_write_arbiter/rtl/rtl_files.lst
source $git_sub_root/submodules/rtl_common_design/modules/memory/reg/rtl/rtl_files.lst
source $git_sub_root/submodules/rtl_common_design/modules/fifo/synchronous_fifo/rtl/rtl_files.lst
source $git_sub_root/submodules/rtl_common_design/modules/math/multiplication/rtl/rtl_files.lst
source $git_sub_root/submodules/rtl_common_design/modules/mixer/rtl/rtl_files.lst
source $git_sub_root/submodules/rtl_common_design/modules/math/cordic/rtl/rtl_files.lst
source $git_sub_root/submodules/rtl_common_design/modules/math/division/long_division/rtl/rtl_files.lst
source $git_sub_root/submodules/rtl_common_design/modules/clock_enablers/clock_enable/rtl/rtl_files.lst
source $git_sub_root/submodules/rtl_common_design/modules/clock_enablers/clock_enable_scaler/rtl/rtl_files.lst
source $git_sub_root/submodules/rtl_common_design/modules/clock_enablers/delay_enable/rtl/rtl_files.lst
source $git_sub_root/submodules/rtl_common_design/modules/clock_enablers/frequency_enable/rtl/rtl_files.lst
source $git_sub_root/submodules/rtl_common_design/modules/oscillator/rtl/rtl_files.lst
source $git_sub_root/submodules/rtl_common_design/modules/interfaces/axi4/rtl/files.lst

git_root="$(git rev-parse --show-toplevel)/submodules/VIP"
source $git_sub_root/submodules/VIP/bool/files.lst
source $git_sub_root/submodules/VIP/vip_fixed_point/files.lst
source $git_sub_root/submodules/VIP/vip_axi4_agent/files.lst
source $git_sub_root/submodules/VIP/vip_axi4s_agent/files.lst
source $git_sub_root/submodules/VIP/vip_clk_rst_agent/files.lst
source $git_sub_root/submodules/VIP/report_server/files.lst

git_root="$(git rev-parse --show-toplevel)/submodules/PYRG"
source $git_sub_root/submodules/PYRG/rtl/files.lst

# Printing out the files
eval "arr=($rtl_files)"

echo "the files:"
for index in "${!arr[@]}"; do
  if [[ ! ${arr[index]} =~ \#.* ]] && [[ ! ${arr[index]} =~ ^$ ]]; then # We do not include empty lines
    echo "$index ${arr[index]}"
    submodule_files+="${arr[index]} "
  fi
done

# ------------------------------------------------------------------------------
# Source modules
# ------------------------------------------------------------------------------

# Restoring the git root
git_root="$(git rev-parse --show-toplevel)"
source $git_root/components/arty_z7_buttons/rtl/rtl_files.lst
source $git_root/components/cs5343/rtl/rtl_files.lst

# Source the module's file lists
source ./rtl/files.lst
source ./tb/files.lst

# Parameter override
parameters+=(" ")
