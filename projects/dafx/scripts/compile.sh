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
source ./sw/files.lst

# ------------------------------------------------------------------------------
# Parameter override
# ------------------------------------------------------------------------------
parameters+=(" ")

# ------------------------------------------------------------------------------
# FPGA
# ------------------------------------------------------------------------------
VITIS_DIR="/opt/Xilinx/Vitis/2020.1"
JTAG_NAME="{jtag_cable_name =~ \"Digilent Arty Z7 003017A6FCE4A\" && level==0 && jtag_device_ctx==\"jsn-Arty Z7-003017A6FCE4A-23727093-0\"}"
PLATFORM_NAME="the_platform"
APP_NAME="dafx"
DOMAIN_NAME="domain_ps7_cortexa9_0"
PROCESSOR="ps7_cortexa9_0"

XSA_FILE="$git_root/projects/dafx/rundir/vivado/dafx/bd_design_0_wrapper.xsa"
BIT_FILE="$git_root/projects/dafx/rundir/vivado/dafx/dafx.runs/impl_1/bd_design_0_wrapper.bit"
FSBL_FILE="$git_root/projects/dafx/rundir/xsct/the_platform/export/the_platform/sw/the_platform/boot/fsbl.elf"
APP_ELF_FILE="$git_root/projects/dafx/rundir/xsct/dafx/Debug/dafx.elf"
