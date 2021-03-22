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

import uvm_pkg::*;
import dafx_tb_pkg::*;
import dafx_tc_pkg::*;

module dafx_tb_top;

  // IF
  clk_rst_if                    clk_rst_vif0();
  clk_rst_if                    clk_rst_vif1();
  vip_axi4_if  #(VIP_MEM_CFG_C) mem_vif(clk_rst_vif0.clk, clk_rst_vif0.rst_n);
  vip_axi4_if  #(VIP_REG_CFG_C) reg_vif(clk_rst_vif0.clk, clk_rst_vif0.rst_n);
  vip_axi4s_if #(VIP_CIR_CFG_C) cir_vif(clk_rst_vif1.clk, clk_rst_vif0.rst_n);

  axi4_reg_if  #(
    .AXI4_ID_WIDTH_P   ( VIP_REG_CFG_C.VIP_AXI4_ID_WIDTH_P   ),
    .AXI4_ADDR_WIDTH_P ( VIP_REG_CFG_C.VIP_AXI4_ADDR_WIDTH_P ),
    .AXI4_DATA_WIDTH_P ( VIP_REG_CFG_C.VIP_AXI4_DATA_WIDTH_P ),
    .AXI4_STRB_WIDTH_P ( VIP_REG_CFG_C.VIP_AXI4_STRB_WIDTH_P )
  ) dafx_cfg_if (clk_rst_vif0.clk, clk_rst_vif0.rst_n);


  // Register slave
  assign dafx_cfg_if.awaddr  = reg_vif.awaddr;
  assign dafx_cfg_if.awvalid = reg_vif.awvalid;
  assign reg_vif.awready     = dafx_cfg_if.awready;
  assign dafx_cfg_if.wdata   = reg_vif.wdata;
  assign dafx_cfg_if.wstrb   = reg_vif.wstrb;
  assign dafx_cfg_if.wlast   = reg_vif.wlast;
  assign dafx_cfg_if.wvalid  = reg_vif.wvalid;
  assign reg_vif.wready      = dafx_cfg_if.wready;
  assign reg_vif.bresp       = dafx_cfg_if.bresp;
  assign reg_vif.bvalid      = dafx_cfg_if.bvalid;
  assign dafx_cfg_if.bready  = reg_vif.bready;
  assign dafx_cfg_if.araddr  = reg_vif.araddr;
  assign dafx_cfg_if.arlen   = reg_vif.arlen;
  assign dafx_cfg_if.arvalid = reg_vif.arvalid;
  assign reg_vif.arready     = dafx_cfg_if.arready;
  assign reg_vif.rdata       = dafx_cfg_if.rdata;
  assign reg_vif.rresp       = dafx_cfg_if.rresp;
  assign reg_vif.rlast       = dafx_cfg_if.rlast;
  assign reg_vif.rvalid      = dafx_cfg_if.rvalid;
  assign dafx_cfg_if.rready  = reg_vif.rready;


  initial begin
    uvm_config_db #(virtual clk_rst_if)::set(uvm_root::get(),                    "uvm_test_top.tb_env*",                "vif", clk_rst_vif0);
    uvm_config_db #(virtual clk_rst_if)::set(uvm_root::get(),                    "uvm_test_top.tb_env.clk_rst_agent0*", "vif", clk_rst_vif0);
    uvm_config_db #(virtual vip_axi4_if  #(VIP_MEM_CFG_C))::set(uvm_root::get(), "uvm_test_top.tb_env.mem_agent0*",     "vif", mem_vif);
    uvm_config_db #(virtual vip_axi4_if  #(VIP_REG_CFG_C))::set(uvm_root::get(), "uvm_test_top.tb_env.reg_agent0*",     "vif", reg_vif);
    uvm_config_db #(virtual vip_axi4s_if #(VIP_CIR_CFG_C))::set(uvm_root::get(), "uvm_test_top.tb_env.cir_agent0*",     "vif", cir_vif);
    run_test();
    $stop();
  end

  dafx_core #(
    .MC_ID_WIDTH_P    ( 6                  ),
    .MC_ADDR_WIDTH_P  ( 32                 ),
    .MC_DATA_WIDTH_P  ( 128                ),
    .CFG_ID_WIDTH_P   ( 16                 ),
    .CFG_ADDR_WIDTH_P ( 16                 ),
    .CFG_DATA_WIDTH_P ( 64                 ),
    .AXI_ID_WIDTH_P   ( 32                 ),
    .AXI_ADDR_WIDTH_P ( 7                  ),
    .AXI_DATA_WIDTH_P ( 32                 )
  ) dafx_core_i0 (

    // Clock and reset
    .clk              ( clk_rst_vif0.clk   ), // input
    .rst_n            ( clk_rst_vif0.rst_n ), // input
    .clk_mclk         ( clk_rst_vif1.clk   ), // input
    .rst_mclk_n       ( clk_rst_vif0.rst_n ), // input
    .dafx_cfg_if      ( dafx_cfg_if.slave  ), // interface

    .cs_adc_data      ( cir_vif.tdata      ), // input
    .cs_adc_valid     ( cir_vif.tvalid     ), // input
    .cs_adc_ready     ( cir_vif.tready     ), // output
    .cs_adc_last      ( cir_vif.tlast      ), // input
    .cs_dac_data      (                    ), // output
    .cs_dac_valid     (                    ), // output
    .cs_dac_ready     ( '1                 ), // input
    .cs_dac_last      (                    ), // output

    // Arty Z7 LEDS
    .led_0            (                    ), // output
    .led_1            (                    ), // output
    .led_2            (                    ), // output

    // Arty Z7 buttons
    .btn_0            ( '0                 ), // input
    .btn_1            ( '0                 ), // input
    .btn_2            ( '0                 ), // input
    .btn_3            ( '0                 ), // input

    // Arty Z7 switches
    .sw_0             ( '0                 ), // input
    .sw_1             ( '0                 ), // input

    // IRQ
    .irq_0            (                    ), // output
    .irq_1            (                    )  // output
  );

  initial begin
    $timeformat(-9, 0, "", 11);  // units, precision, suffix, min field width
    if ($test$plusargs("RECORD")) begin
      uvm_config_db #(uvm_verbosity)::set(null,"*", "recording_detail", UVM_FULL);
    end else begin
      uvm_config_db #(uvm_verbosity)::set(null,"*", "recording_detail", UVM_NONE);
    end
  end

endmodule
