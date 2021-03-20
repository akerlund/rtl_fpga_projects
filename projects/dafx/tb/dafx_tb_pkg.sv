////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2021 Fredrik Åkerlund
// https://github.com/akerlund/VIP
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
//
// Description:
//
////////////////////////////////////////////////////////////////////////////////

package dafx_tb_pkg;

  `include "uvm_macros.svh"
  import uvm_pkg::*;

  import bool_pkg::*;
  import dafx_pkg::*;

  import clk_rst_types_pkg::*;
  import clk_rst_pkg::*;
  import vip_axi4_types_pkg::*;
  import vip_axi4_agent_pkg::*;
  import vip_axi4s_types_pkg::*;
  import vip_axi4s_agent_pkg::*;

  localparam int AXI4_ID_WIDTH_C   = 6;
  localparam int AXI4_ADDR_WIDTH_C = 20;
  localparam int AXI4_DATA_WIDTH_C = 128;
  localparam int AXI4_STRB_WIDTH_C = AXI4_DATA_WIDTH_C/8;

  // Configuration of the VIP (Memory)
  localparam vip_axi4_cfg_t VIP_MEM_CFG_C = '{
    VIP_AXI4_ID_WIDTH_P   : AXI4_ID_WIDTH_C,
    VIP_AXI4_ADDR_WIDTH_P : AXI4_ADDR_WIDTH_C,
    VIP_AXI4_DATA_WIDTH_P : AXI4_DATA_WIDTH_C,
    VIP_AXI4_STRB_WIDTH_P : AXI4_STRB_WIDTH_C,
    VIP_AXI4_USER_WIDTH_P : 0
  };

  // Configuration of the VIP (Registers)
  localparam vip_axi4_cfg_t VIP_REG_CFG_C = '{
    VIP_AXI4_ID_WIDTH_P   : 2,
    VIP_AXI4_ADDR_WIDTH_P : 16,
    VIP_AXI4_DATA_WIDTH_P : 64,
    VIP_AXI4_STRB_WIDTH_P : 8,
    VIP_AXI4_USER_WIDTH_P : 0
  };

  // Configuration of the VIP (Cirrus)
  localparam vip_axi4s_cfg_t VIP_CIR_CFG_C = '{
    VIP_AXI4S_TDATA_WIDTH_P : 32,
    VIP_AXI4S_TSTRB_WIDTH_P : 3,
    VIP_AXI4S_TKEEP_WIDTH_P : 0,
    VIP_AXI4S_TID_WIDTH_P   : 8,
    VIP_AXI4S_TDEST_WIDTH_P : 0,
    VIP_AXI4S_TUSER_WIDTH_P : 0
  };

  // Register model
  `include "dafx_reg.sv"
  `include "dafx_block.sv"
  `include "register_model.sv"
  `include "vip_axi4_adapter.sv"

  // Testbench
  //`include "dafx_scoreboard.sv"
  `include "dafx_virtual_sequencer.sv"
  `include "dafx_env.sv"


endpackage
