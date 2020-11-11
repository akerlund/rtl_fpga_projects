#!/bin/bash

# Specify the top files
rtl_top=project_top
uvm_top=""

# ------------------------------------------------------------------------------
# Source submodules
# ------------------------------------------------------------------------------

git_root="$(git rev-parse --show-toplevel)/submodules/rtl_common_design" # The submodules use this variable
git_sub_root="$(git rev-parse --show-toplevel)"                          # We use this, because the former name is now taken

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

# Printing out the files
eval "arr=($rtl_files)"

echo "the files:"
for index in "${!arr[@]}"; do
  if [[ ! ${arr[index]} =~ \#.* ]] && [[ ! ${arr[index]} =~ ^$ ]]; then # We do not include empty lines
    echo "$index ${arr[index]}"
    submodule_files+="${arr[index]} "
  fi
done

# Restoring the git root
git_root="$(git rev-parse --show-toplevel)"
source $git_root/components/arty_z7_buttons/rtl/rtl_files.lst
source $git_root/components/cs5343/rtl/rtl_files.lst

# Source the module's file lists
source ./rtl/rtl_files.lst

# Parameter override
parameters+=(" ")
