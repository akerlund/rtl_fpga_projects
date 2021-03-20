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
  clk_rst_if                    clk_rst_vif();
  vip_axi4_if  #(VIP_MEM_CFG_C) mem_vif(clk_rst_vif.clk, clk_rst_vif.rst_n);
  vip_axi4_if  #(VIP_REG_CFG_C) reg_vif(clk_rst_vif.clk, clk_rst_vif.rst_n);
  vip_axi4s_if #(VIP_CIR_CFG_C) cir_vif(clk_rst_vif.clk, clk_rst_vif.rst_n);

  axi4_reg_if  #(
    .AXI4_ID_WIDTH_P   ( VIP_REG_CFG_C.VIP_AXI4_ID_WIDTH_P   ),
    .AXI4_ADDR_WIDTH_P ( VIP_REG_CFG_C.VIP_AXI4_ADDR_WIDTH_P ),
    .AXI4_DATA_WIDTH_P ( VIP_REG_CFG_C.VIP_AXI4_DATA_WIDTH_P ),
    .AXI4_STRB_WIDTH_P ( VIP_REG_CFG_C.VIP_AXI4_STRB_WIDTH_P )
  ) cfg_vif (clk_rst_vif.clk, clk_rst_vif.rst_n);

  //----------------------------------------------------------------------------
  // Register
  //----------------------------------------------------------------------------

  // Write Address Channel
  assign cfg_vif.awaddr  = reg_vif.awaddr;
  assign cfg_vif.awvalid = reg_vif.awvalid;
  assign reg_vif.awready = cfg_vif.awready;

  // Write Data Channel
  assign cfg_vif.wdata   = reg_vif.wdata;
  assign cfg_vif.wstrb   = reg_vif.wstrb;
  assign cfg_vif.wlast   = reg_vif.wlast;
  assign cfg_vif.wvalid  = reg_vif.wvalid;
  assign reg_vif.wready  = cfg_vif.wready;

  // Write Response Channel
  assign reg_vif.bresp   = cfg_vif.bresp;
  assign reg_vif.bvalid  = cfg_vif.bvalid;
  assign cfg_vif.bready  = reg_vif.bready;

  // Read Address Channel
  assign cfg_vif.araddr  = reg_vif.araddr;
  assign cfg_vif.arlen   = reg_vif.arlen;
  assign cfg_vif.arvalid = reg_vif.arvalid;
  assign reg_vif.arready = cfg_vif.arready;

  // Read Data Channel
  assign reg_vif.rdata   = cfg_vif.rdata;
  assign reg_vif.rresp   = cfg_vif.rresp;
  assign reg_vif.rlast   = cfg_vif.rlast;
  assign reg_vif.rvalid  = cfg_vif.rvalid;
  assign cfg_vif.rready  = reg_vif.rready;


  initial begin
    uvm_config_db #(virtual clk_rst_if)::set(uvm_root::get(),                   "uvm_test_top.tb_env*",                "vif", clk_rst_vif);
    uvm_config_db #(virtual clk_rst_if)::set(uvm_root::get(),                   "uvm_test_top.tb_env.clk_rst_agent0*", "vif", clk_rst_vif);
    uvm_config_db #(virtual vip_axi4_if #(VIP_MEM_CFG_C))::set(uvm_root::get(), "uvm_test_top.tb_env.mem_agent0*",     "vif", mem_vif);
    uvm_config_db #(virtual vip_axi4_if #(VIP_REG_CFG_C))::set(uvm_root::get(), "uvm_test_top.tb_env.reg_agent0*",     "vif", reg_vif);
    run_test();
    $stop();
  end

  dafx_core
  //#(
  //  .AXI_ID_WIDTH_P   ( 32                 ),
  //  .AXI_ADDR_WIDTH_P ( 7                  ),
  //  .AXI_DATA_WIDTH_P ( 32                 ),
  //  .AXI_STRB_WIDTH_P ( AXI_DATA_WIDTH_P/8 )
  //)
  dafx_core_i0 (

    // Clock and reset
    .clk         ( clk_rst_vif.clk   ), // input
    .rst_n       ( clk_rst_vif.rst_n ), // input

    // Arty Z7 LEDS
    .led_0       ( led_0             ), // output
    .led_1       ( led_1             ), // output
    .led_2       ( led_2             ), // output
    .led_3       ( led_3             ), // output

    // Arty Z7 buttons
    .btn_0       ( btn_0             ), // input
    .btn_1       ( btn_1             ), // input
    .btn_2       ( btn_2             ), // input
    .btn_3       ( btn_3             ), // input

    // Arty Z7 switches
    .sw_0        ( sw_0              ), // input
    .sw_1        ( sw_1              ), // input

    // IRQ
    .irq_0       ( irq_0             ), // output
    .irq_1       ( irq_1             ), // output

    // Write Address Channel
    .cfg_awaddr  ( cfg_vif.awaddr    ), // input
    .cfg_awvalid ( cfg_vif.awvalid   ), // input
    .cfg_awready ( cfg_vif.awready   ), // output

    // Write Data Channel
    .cfg_wdata   ( cfg_vif.wdata     ), // input
    .cfg_wstrb   ( cfg_vif.wstrb     ), // input
    .cfg_wlast   ( cfg_vif.wlast     ), // input
    .cfg_wvalid  ( cfg_vif.wvalid    ), // input
    .cfg_wready  ( cfg_vif.wready    ), // output

    // Write Response Channel
    .cfg_bresp   ( cfg_vif.bresp     ), // output
    .cfg_bvalid  ( cfg_vif.bvalid    ), // output
    .cfg_bready  ( cfg_vif.bready    ), // input

    // Read Address Channel
    .cfg_araddr  ( cfg_vif.araddr    ), // input
    .cfg_arlen   ( cfg_vif.arlen     ), // input
    .cfg_arvalid ( cfg_vif.arvalid   ), // input
    .cfg_arready ( cfg_vif.arready   ), // output

    // Read Data Channel
    .cfg_rdata   ( cfg_vif.rdata     ), // output
    .cfg_rresp   ( cfg_vif.rresp     ), // output
    .cfg_rlast   ( cfg_vif.rlast     ), // output
    .cfg_rvalid  ( cfg_vif.rvalid    ), // output
    .cfg_rready  ( cfg_vif.rready    ), // input

    // Write Address Channel
    .mc_awid     ( mem_vif.awid      ), // output
    .mc_awaddr   ( mem_vif.awaddr    ), // output
    .mc_awlen    ( mem_vif.awlen     ), // output
    .mc_awsize   ( mem_vif.awsize    ), // output
    .mc_awburst  ( mem_vif.awburst   ), // output
    .mc_awlock   ( mem_vif.awlock    ), // output
    .mc_awqos    ( mem_vif.awqos     ), // output
    .mc_awvalid  ( mem_vif.awvalid   ), // output
    .mc_awready  ( mem_vif.awready   ), // input

    // Write Data Channel
    .mc_wdata    ( mem_vif.wdata     ), // output
    .mc_wstrb    ( mem_vif.wstrb     ), // output
    .mc_wlast    ( mem_vif.wlast     ), // output
    .mc_wvalid   ( mem_vif.wvalid    ), // output
    .mc_wready   ( mem_vif.wready    ), // input

    // Write Response Channel
    .mc_bid      ( mem_vif.bid       ), // input
    .mc_bresp    ( mem_vif.bresp     ), // input
    .mc_bvalid   ( mem_vif.bvalid    ), // input
    .mc_bready   ( mem_vif.bready    ), // output

    // Read Address Channel
    .mc_arid     ( mem_vif.arid      ), // output
    .mc_araddr   ( mem_vif.araddr    ), // output
    .mc_arlen    ( mem_vif.arlen     ), // output
    .mc_arsize   ( mem_vif.arsize    ), // output
    .mc_arburst  ( mem_vif.arburst   ), // output
    .mc_arlock   ( mem_vif.arlock    ), // output
    .mc_arqos    ( mem_vif.arqos     ), // output
    .mc_arvalid  ( mem_vif.arvalid   ), // output
    .mc_arready  ( mem_vif.arready   ), // input

    // Read Data Channel
    .mc_rid      ( mem_vif.rid       ), // input
    .mc_rresp    ( mem_vif.rresp     ), // input
    .mc_rdata    ( mem_vif.rdata     ), // input
    .mc_rlast    ( mem_vif.rlast     ), // input
    .mc_rvalid   ( mem_vif.rvalid    ), // input
    .mc_rready   ( mem_vif.rready    ), // output

    // Cirrus CS5343 ADC/DAC
    .cs_tx_mclk  ( cs_tx_mclk        ), // output
    .cs_tx_lrck  ( cs_tx_lrck        ), // output
    .cs_tx_sclk  ( cs_tx_sclk        ), // output
    .cs_tx_sdout ( cs_tx_sdout       ), // output
    .cs_rx_mclk  ( cs_rx_mclk        ), // output
    .cs_rx_lrck  ( cs_rx_lrck        ), // output
    .cs_rx_sclk  ( cs_rx_sclk        ), // output
    .cs_rx_sdin  ( cs_rx_sdin        )  // input
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
