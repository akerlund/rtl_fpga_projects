////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2020 Fredrik Åkerlund
// https://github.com/akerlund/FPGA
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

import dafx_pkg::*;

`default_nettype none

module dafx_top #(
    parameter int MC_ID_WIDTH_P    = 6,
    parameter int MC_ADDR_WIDTH_P  = 32,
    parameter int MC_DATA_WIDTH_P  = 128,
    parameter int CFG_ID_WIDTH_P   = 16,
    parameter int CFG_ADDR_WIDTH_P = 16,
    parameter int CFG_DATA_WIDTH_P = 64,
    parameter int CFG_STRB_WIDTH_P = 64,
    parameter int AXI_ID_WIDTH_P   = 32,
    parameter int AXI_ADDR_WIDTH_P = 7,
    parameter int AXI_DATA_WIDTH_P = 32,
    parameter int AXI_STRB_WIDTH_P = AXI_DATA_WIDTH_P/8
  )(
    // Clock and reset
    input  wire                               clk,
    input  wire                               rst_n,

    // Cirrus CS5343 ADC/DAC
    output logic                              cs_tx_mclk,
    output logic                              cs_tx_lrck,
    output logic                              cs_tx_sclk,
    output logic                              cs_tx_sdout,
    output logic                              cs_rx_mclk,
    output logic                              cs_rx_lrck,
    output logic                              cs_rx_sclk,
    input  wire                               cs_rx_sdin,

    // IRQ
    output logic                              irq_0,
    output logic                              irq_1,

    // -------------------------------------------------------------------------
    // PL I/O
    // -------------------------------------------------------------------------

    // Arty Z7 LEDS
    output logic                              led_0,
    output logic                              led_1,
    output logic                              led_2,
    output logic                              led_3,

    // Arty Z7 buttons
    input  wire                               btn_0,
    input  wire                               btn_1,
    input  wire                               btn_2,
    input  wire                               btn_3,

    // Arty Z7 switches
    input  wire                               sw_0,
    input  wire                               sw_1,

    // -------------------------------------------------------------------------
    // PL register AXI4 ports
    // -------------------------------------------------------------------------

    // Write Address Channel
    input  wire      [CFG_ADDR_WIDTH_P-1 : 0] cfg_awaddr,
    input  wire                               cfg_awvalid,
    output logic                              cfg_awready,

    // Write Data Channel
    input  wire      [CFG_DATA_WIDTH_P-1 : 0] cfg_wdata,
    input  wire  [(CFG_DATA_WIDTH_P/8)-1 : 0] cfg_wstrb,
    input  wire                               cfg_wlast,
    input  wire                               cfg_wvalid,
    output logic                              cfg_wready,

    // Write Response Channel
    output logic                      [1 : 0] cfg_bresp,
    output logic                              cfg_bvalid,
    input  wire                               cfg_bready,

    // Read Address Channel
    input  wire      [CFG_ADDR_WIDTH_P-1 : 0] cfg_araddr,
    input  wire                       [7 : 0] cfg_arlen,
    input  wire                               cfg_arvalid,
    output logic                              cfg_arready,

    // Read Data Channel
    output logic     [CFG_DATA_WIDTH_P-1 : 0] cfg_rdata,
    output logic                      [1 : 0] cfg_rresp,
    output logic                              cfg_rlast,
    output logic                              cfg_rvalid,
    input  wire                               cfg_rready,

    // -------------------------------------------------------------------------
    // Memory Controller AXI4 ports
    // -------------------------------------------------------------------------

    // Write Address Channel
    output logic        [MC_ID_WIDTH_P-1 : 0] mc_awid,
    output logic      [MC_ADDR_WIDTH_P-1 : 0] mc_awaddr,
    output logic                      [7 : 0] mc_awlen,
    output logic                      [2 : 0] mc_awsize,
    output logic                      [1 : 0] mc_awburst,
    output logic                              mc_awlock,
    output logic                      [3 : 0] mc_awqos,
    output logic                              mc_awvalid,
    input  wire                               mc_awready,

    // Write Data Channel
    output logic      [MC_DATA_WIDTH_P-1 : 0] mc_wdata,
    output logic  [(MC_DATA_WIDTH_P/8)-1 : 0] mc_wstrb,
    output logic                              mc_wlast,
    output logic                              mc_wvalid,
    input  wire                               mc_wready,

    // Write Response Channel
    input  wire         [MC_ID_WIDTH_P-1 : 0] mc_bid,
    input  wire                       [1 : 0] mc_bresp,
    input  wire                               mc_bvalid,
    output logic                              mc_bready,

    // Read Address Channel
    output logic        [MC_ID_WIDTH_P-1 : 0] mc_arid,
    output logic      [MC_ADDR_WIDTH_P-1 : 0] mc_araddr,
    output logic                      [7 : 0] mc_arlen,
    output logic                      [2 : 0] mc_arsize,
    output logic                      [1 : 0] mc_arburst,
    output logic                              mc_arlock,
    output logic                      [3 : 0] mc_arqos,
    output logic                              mc_arvalid,
    input  wire                               mc_arready,

    // Read Data Channel
    input  wire         [MC_ID_WIDTH_P-1 : 0] mc_rid,
    input  wire                       [1 : 0] mc_rresp,
    input  wire       [MC_DATA_WIDTH_P-1 : 0] mc_rdata,
    input  wire                               mc_rlast,
    input  wire                               mc_rvalid,
    output logic                              mc_rready
  );

  logic clk_mclk;
  logic rst_mclk_n;

  logic btn_0_tgl;
  logic btn_1_tgl;
  logic btn_2_tgl;

  logic switch_0;
  logic switch_1;

  logic [AXI_DATA_WIDTH_P-1 : 0] led_3_counter;

  // I2S2 PMOD
  logic [23 : 0] cs_adc_data;
  logic          cs_adc_ready;
  logic          cs_adc_valid;
  logic          cs_adc_last;

  logic [23 : 0] cs_dac_data;
  logic          cs_dac_last;
  logic          cs_dac_valid;
  logic          cs_dac_ready;

  //----------------------------------------------------------------------------
  // Register
  //----------------------------------------------------------------------------

  axi4_reg_if  #(
    .AXI4_ID_WIDTH_P   ( CFG_ID_WIDTH_P   ),
    .AXI4_ADDR_WIDTH_P ( CFG_ADDR_WIDTH_P ),
    .AXI4_DATA_WIDTH_P ( CFG_DATA_WIDTH_P ),
    .AXI4_STRB_WIDTH_P ( CFG_STRB_WIDTH_P )
  ) dafx_cfg_if (clk, rst_n);

  // Write Address Channel
  assign dafx_cfg_if.awaddr  = cfg_awaddr;
  assign dafx_cfg_if.awvalid = cfg_awvalid;
  assign cfg_awready = dafx_cfg_if.awready;

  // Write Data Channel
  assign dafx_cfg_if.wdata   = cfg_wdata;
  assign dafx_cfg_if.wstrb   = cfg_wstrb;
  assign dafx_cfg_if.wlast   = cfg_wlast;
  assign dafx_cfg_if.wvalid  = cfg_wvalid;
  assign cfg_wready  = dafx_cfg_if.wready;

  // Write Response Channel
  assign cfg_bresp   = dafx_cfg_if.bresp;
  assign cfg_bvalid  = dafx_cfg_if.bvalid;
  assign dafx_cfg_if.bready  = cfg_bready;

  // Read Address Channel
  assign dafx_cfg_if.araddr  = cfg_araddr;
  assign dafx_cfg_if.arlen   = cfg_arlen;
  assign dafx_cfg_if.arvalid = cfg_arvalid;
  assign cfg_arready = dafx_cfg_if.arready;

  // Read Data Channel
  assign cfg_rdata   = dafx_cfg_if.rdata;
  assign cfg_rresp   = dafx_cfg_if.rresp;
  assign cfg_rlast   = dafx_cfg_if.rlast;
  assign cfg_rvalid  = dafx_cfg_if.rvalid;
  assign dafx_cfg_if.rready  = cfg_rready;

  //----------------------------------------------------------------------------
  // Memory Controller
  //----------------------------------------------------------------------------

  axi4_if #(
    .ID_WIDTH_P   ( MC_ID_WIDTH_P   ),
    .ADDR_WIDTH_P ( MC_ADDR_WIDTH_P ),
    .DATA_WIDTH_P ( MC_DATA_WIDTH_P )
  ) axi4_if0 ();

  // Write Address Channel
  assign mc_awaddr        = axi4_if0.awaddr;
  assign mc_awvalid       = axi4_if0.awvalid;
  assign axi4_if0.awready = mc_awready;

  // Write Data Channel
  assign mc_wdata         = axi4_if0.wdata;
  assign mc_wstrb         = axi4_if0.wstrb;
  assign mc_wlast         = axi4_if0.wlast;
  assign mc_wvalid        = axi4_if0.wvalid;
  assign axi4_if0.wready  = mc_wready;

  // Write Response Channel
  assign axi4_if0.bresp   = mc_bresp;
  assign axi4_if0.bvalid  = mc_bvalid;
  assign mc_bready        = axi4_if0.bready;

  // Read Address Channel
  assign mc_araddr        = axi4_if0.araddr;
  assign mc_arlen         = axi4_if0.arlen;
  assign mc_arvalid       = axi4_if0.arvalid;
  assign axi4_if0.arready = mc_arready;

  // Read Data Channel
  assign axi4_if0.rdata   = mc_rdata;
  assign axi4_if0.rresp   = mc_rresp;
  assign axi4_if0.rlast   = mc_rlast;
  assign axi4_if0.rvalid  = mc_rvalid;
  assign mc_rready        = axi4_if0.rready;




  // Clock 'clk_sys' (125MHz) with LED process
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      led_3         <= '0;
      led_3_counter <= '0;
    end else begin
      if (led_3_counter == SYS_CLK_FREQUENCY_C/2-1) begin
        led_3         <= ~led_3;
        led_3_counter <= 0;
      end else begin
        led_3_counter <= led_3_counter + 1;
      end
    end
  end

  // ---------------------------------------------------------------------------
  // PLL for the Cirrus ICs
  // ---------------------------------------------------------------------------
  car_cs5343 car_cs5343_i0 (
    .clk        ( clk        ), // input
    .rst_n      ( rst_n      ), // input
    .clk_mclk   ( clk_mclk   ), // output
    .rst_mclk_n ( rst_mclk_n )  // output
  );

  // ---------------------------------------------------------------------------
  // Cirrus CS5343 ADC, CS4344 DAC
  // ---------------------------------------------------------------------------
  cs5343_top cs5343_top_i0 (

    // Clock and reset
    .clk         ( clk          ), // input
    .rst_n       ( rst_n        ), // input
    .clk_mclk    ( clk_mclk     ), // input
    .rst_mclk_n  ( rst_mclk_n   ), // input

    // I/O Cirrus CS5343 (DAC)
    .cs_tx_mclk  ( cs_tx_mclk   ), // output
    .cs_tx_lrck  ( cs_tx_lrck   ), // output
    .cs_tx_sclk  ( cs_tx_sclk   ), // output
    .cs_tx_sdout ( cs_tx_sdout  ), // output

    // I/O Cirrus CS4344 (ADC)
    .cs_rx_mclk  ( cs_rx_mclk   ), // output
    .cs_rx_lrck  ( cs_rx_lrck   ), // output
    .cs_rx_sclk  ( cs_rx_sclk   ), // output
    .cs_rx_sdin  ( cs_rx_sdin   ), // input

    // AXI-S ADC
    .adc_data    ( cs_adc_data  ), // output
    .adc_valid   ( cs_adc_valid ), // output
    .adc_ready   ( cs_adc_ready ), // input
    .adc_last    ( cs_adc_last  ), // output

    // AXI-S DAC
    .dac_data    ( cs_dac_data  ), // input
    .dac_valid   ( cs_dac_valid ), // input
    .dac_ready   ( cs_dac_ready ), // output
    .dac_last    ( cs_dac_last  )  // input
  );

  // ---------------------------------------------------------------------------
  // Wrapper for mechanical buttons
  // ---------------------------------------------------------------------------
  arty_z7_buttons_top arty_z7_buttons_top_i0 (
    .clk       ( clk       ), // input
    .rst_n     ( rst_n     ), // input
    .btn_0     ( btn_0     ), // input
    .btn_1     ( btn_1     ), // input
    .btn_2     ( btn_2     ), // input
    .btn_3     (           ), // input
    .btn_0_tgl ( btn_0_tgl ), // output
    .btn_1_tgl ( btn_1_tgl ), // output
    .btn_2_tgl ( btn_2_tgl ), // output
    .btn_3_tgl (           )  // output
  );

  // ---------------------------------------------------------------------------
  // Synchronizing Switch 0
  // ---------------------------------------------------------------------------
  io_synchronizer io_synchronizer_i0 (
    .clk         ( clk      ),
    .rst_n       ( rst_n    ),
    .bit_ingress ( sw_0     ),
    .bit_egress  ( switch_0 )
  );

  // ---------------------------------------------------------------------------
  // Synchronizing Switch 1
  // ---------------------------------------------------------------------------
  io_synchronizer io_synchronizer_i1 (
    .clk         ( clk      ),
    .rst_n       ( rst_n    ),
    .bit_ingress ( sw_1     ),
    .bit_egress  ( switch_1 )
  );

  // ---------------------------------------------------------------------------
  // Core
  // ---------------------------------------------------------------------------
  dafx_core #(
    .MC_ID_WIDTH_P    ( MC_ID_WIDTH_P      ),
    .MC_ADDR_WIDTH_P  ( MC_ADDR_WIDTH_P    ),
    .MC_DATA_WIDTH_P  ( MC_DATA_WIDTH_P    ),
    .CFG_ID_WIDTH_P   ( CFG_ID_WIDTH_P     ),
    .CFG_ADDR_WIDTH_P ( CFG_ADDR_WIDTH_P   ),
    .CFG_DATA_WIDTH_P ( CFG_DATA_WIDTH_P   ),
    .AXI_ID_WIDTH_P   ( AXI_ID_WIDTH_P     ),
    .AXI_ADDR_WIDTH_P ( AXI_ADDR_WIDTH_P   ),
    .AXI_DATA_WIDTH_P ( AXI_DATA_WIDTH_P   )
  ) dafx_core_i0 (
    .clk              ( clk                ), // input
    .rst_n            ( rst_n              ), // input
    .clk_mclk         ( clk_mclk           ), // input
    .rst_mclk_n       ( rst_mclk_n         ), // input
    .dafx_cfg_if      ( dafx_cfg_if.slave  ), // interface
    .cs_adc_data      ( cs_adc_data        ), // input
    .cs_adc_valid     ( cs_adc_valid       ), // input
    .cs_adc_ready     ( cs_adc_ready       ), // output
    .cs_adc_last      ( cs_adc_last        ), // input
    .cs_dac_data      ( cs_dac_data        ), // output
    .cs_dac_valid     ( cs_dac_valid       ), // output
    .cs_dac_ready     ( cs_dac_ready       ), // input
    .cs_dac_last      ( cs_dac_last        ), // output
    .led_0            ( led_0              ), // output
    .led_1            ( led_1              ), // output
    .led_2            ( led_2              ), // output
    .btn_0            ( btn_0_tgl          ), // input
    .btn_1            ( btn_1_tgl          ), // input
    .btn_2            ( btn_2_tgl          ), // input
    .btn_3            ( '0                 ), // input
    .sw_0             ( switch_0           ), // input
    .sw_1             ( switch_1           ), // input
    .irq_0            ( irq_0              ), // output
    .irq_1            ( irq_1              )  // output
  );

endmodule

`default_nettype wire
