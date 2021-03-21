////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2020 Fredrik Åkerlund
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
    parameter int CFG_ADDR_WIDTH_P = 16,
    parameter int CFG_DATA_WIDTH_P = 64,
    parameter int AXI_ID_WIDTH_P   = 32,
    parameter int AXI_ADDR_WIDTH_P = 7,
    parameter int AXI_DATA_WIDTH_P = 32,
    parameter int AXI_STRB_WIDTH_P = AXI_DATA_WIDTH_P/8
  )(
    // Clock and reset
    input  wire                                   clk,
    input  wire                                   rst_n,

    // ---------------------------------------------------------------------------
    // PL I/O
    // ---------------------------------------------------------------------------

    // Arty Z7 LEDS
    output logic                                  led_0,
    output logic                                  led_1,
    output logic                                  led_2,
    output logic                                  led_3,

    // Arty Z7 buttons
    input  wire                                   btn_0,
    input  wire                                   btn_1,
    input  wire                                   btn_2,
    input  wire                                   btn_3,

    // Arty Z7 switches
    input  wire                                   sw_0,
    input  wire                                   sw_1,

    output logic                                  irq_0,
    output logic                                  irq_1,

    // ---------------------------------------------------------------------------
    // PL register AXI4 ports
    // ---------------------------------------------------------------------------

    // Write Address Channel
    input  wire          [CFG_ADDR_WIDTH_P-1 : 0] cfg_awaddr,
    input  wire                                   cfg_awvalid,
    output logic                                  cfg_awready,

    // Write Data Channel
    input  wire          [CFG_DATA_WIDTH_P-1 : 0] cfg_wdata,
    input  wire      [(CFG_DATA_WIDTH_P/8)-1 : 0] cfg_wstrb,
    input  wire                                   cfg_wlast,
    input  wire                                   cfg_wvalid,
    output logic                                  cfg_wready,

    // Write Response Channel
    output logic                          [1 : 0] cfg_bresp,
    output logic                                  cfg_bvalid,
    input  wire                                   cfg_bready,

    // Read Address Channel
    input  wire          [CFG_ADDR_WIDTH_P-1 : 0] cfg_araddr,
    input  wire                           [7 : 0] cfg_arlen,
    input  wire                                   cfg_arvalid,
    output logic                                  cfg_arready,

    // Read Data Channel
    output logic         [CFG_DATA_WIDTH_P-1 : 0] cfg_rdata,
    output logic                          [1 : 0] cfg_rresp,
    output logic                                  cfg_rlast,
    output logic                                  cfg_rvalid,
    input  wire                                   cfg_rready,

    // ---------------------------------------------------------------------------
    // Memory Controller AXI4 ports
    // ---------------------------------------------------------------------------

    // Write Address Channel
    output logic            [MC_ID_WIDTH_P-1 : 0] mc_awid,
    output logic          [MC_ADDR_WIDTH_P-1 : 0] mc_awaddr,
    output logic                          [7 : 0] mc_awlen,
    output logic                          [2 : 0] mc_awsize,
    output logic                          [1 : 0] mc_awburst,
    output logic                                  mc_awlock,
    output logic                          [3 : 0] mc_awqos,
    output logic                                  mc_awvalid,
    input  wire                                   mc_awready,

    // Write Data Channel
    output logic          [MC_DATA_WIDTH_P-1 : 0] mc_wdata,
    output logic      [(MC_DATA_WIDTH_P/8)-1 : 0] mc_wstrb,
    output logic                                  mc_wlast,
    output logic                                  mc_wvalid,
    input  wire                                   mc_wready,

    // Write Response Channel
    input  wire             [MC_ID_WIDTH_P-1 : 0] mc_bid,
    input  wire                           [1 : 0] mc_bresp,
    input  wire                                   mc_bvalid,
    output logic                                  mc_bready,

    // Read Address Channel
    output logic            [MC_ID_WIDTH_P-1 : 0] mc_arid,
    output logic          [MC_ADDR_WIDTH_P-1 : 0] mc_araddr,
    output logic                          [7 : 0] mc_arlen,
    output logic                          [2 : 0] mc_arsize,
    output logic                          [1 : 0] mc_arburst,
    output logic                                  mc_arlock,
    output logic                          [3 : 0] mc_arqos,
    output logic                                  mc_arvalid,
    input  wire                                   mc_arready,

    // Read Data Channel
    input  wire             [MC_ID_WIDTH_P-1 : 0] mc_rid,
    input  wire                           [1 : 0] mc_rresp,
    input  wire           [MC_DATA_WIDTH_P-1 : 0] mc_rdata,
    input  wire                                   mc_rlast,
    input  wire                                   mc_rvalid,
    output logic                                  mc_rready,

    // Cirrus CS5343 ADC/DAC
    output logic                                  cs_tx_mclk,
    output logic                                  cs_tx_lrck,
    output logic                                  cs_tx_sclk,
    output logic                                  cs_tx_sdout,
    output logic                                  cs_rx_mclk,
    output logic                                  cs_rx_lrck,
    output logic                                  cs_rx_sclk,
    input  wire                                   cs_rx_sdin
  );

  logic clk_mclk;
  logic rst_mclk_n;

  logic btn_0_tgl;
  logic btn_1_tgl;
  logic btn_2_tgl;

  logic switch_0;
  logic switch_1;

  // I2S2 PMOD
  logic [23 : 0] cs_adc_data;
  logic          cs_adc_ready;
  logic          cs_adc_valid;
  logic          cs_adc_last;

  logic [23 : 0] cs_dac_data;
  logic          cs_dac_last;
  logic          cs_dac_valid;
  logic          cs_dac_ready;

  // -------------------------------------------------------------------------
  // PLL for the Cirrus ICs
  // -------------------------------------------------------------------------
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
    .MC_ID_WIDTH_P    ( 6                  ),
    .MC_ADDR_WIDTH_P  ( 32                 ),
    .MC_DATA_WIDTH_P  ( 128                ),
    .CFG_ADDR_WIDTH_P ( 16                 ),
    .CFG_DATA_WIDTH_P ( 64                 ),
    .AXI_ID_WIDTH_P   ( 32                 ),
    .AXI_ADDR_WIDTH_P ( 7                  ),
    .AXI_DATA_WIDTH_P ( 32                 ),
    .AXI_STRB_WIDTH_P ( AXI_DATA_WIDTH_P/8 )
  ) dafx_core_i0 (
    .clk              ( clk                ), // input
    .rst_n            ( rst_n              ), // input
    .clk_mclk         ( clk_mclk           ), // input
    .rst_mclk_n       ( rst_mclk_n         ), // input
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
    .led_3            ( led_3              ), // output
    .btn_0            ( btn_0_tgl          ), // input
    .btn_1            ( btn_1_tgl          ), // input
    .btn_2            ( btn_2_tgl          ), // input
    .btn_3            ( '0                 ), // input
    .sw_0             ( switch_0           ), // input
    .sw_1             ( switch_1           ), // input
    .irq_0            ( irq_0              ), // output
    .irq_1            ( irq_1              ), // output
    .cfg_awaddr       ( cfg_awaddr         ), // input
    .cfg_awvalid      ( cfg_awvalid        ), // input
    .cfg_awready      ( cfg_awready        ), // output
    .cfg_wdata        ( cfg_wdata          ), // input
    .cfg_wstrb        ( cfg_wstrb          ), // input
    .cfg_wlast        ( cfg_wlast          ), // input
    .cfg_wvalid       ( cfg_wvalid         ), // input
    .cfg_wready       ( cfg_wready         ), // output
    .cfg_bresp        ( cfg_bresp          ), // output
    .cfg_bvalid       ( cfg_bvalid         ), // output
    .cfg_bready       ( cfg_bready         ), // input
    .cfg_araddr       ( cfg_araddr         ), // input
    .cfg_arlen        ( cfg_arlen          ), // input
    .cfg_arvalid      ( cfg_arvalid        ), // input
    .cfg_arready      ( cfg_arready        ), // output
    .cfg_rdata        ( cfg_rdata          ), // output
    .cfg_rresp        ( cfg_rresp          ), // output
    .cfg_rlast        ( cfg_rlast          ), // output
    .cfg_rvalid       ( cfg_rvalid         ), // output
    .cfg_rready       ( cfg_rready         ), // input
    .mc_awid          ( mc_awid            ), // output
    .mc_awaddr        ( mc_awaddr          ), // output
    .mc_awlen         ( mc_awlen           ), // output
    .mc_awsize        ( mc_awsize          ), // output
    .mc_awburst       ( mc_awburst         ), // output
    .mc_awlock        ( mc_awlock          ), // output
    .mc_awqos         ( mc_awqos           ), // output
    .mc_awvalid       ( mc_awvalid         ), // output
    .mc_awready       ( mc_awready         ), // input
    .mc_wdata         ( mc_wdata           ), // output
    .mc_wstrb         ( mc_wstrb           ), // output
    .mc_wlast         ( mc_wlast           ), // output
    .mc_wvalid        ( mc_wvalid          ), // output
    .mc_wready        ( mc_wready          ), // input
    .mc_bid           ( mc_bid             ), // input
    .mc_bresp         ( mc_bresp           ), // input
    .mc_bvalid        ( mc_bvalid          ), // input
    .mc_bready        ( mc_bready          ), // output
    .mc_arid          ( mc_arid            ), // output
    .mc_araddr        ( mc_araddr          ), // output
    .mc_arlen         ( mc_arlen           ), // output
    .mc_arsize        ( mc_arsize          ), // output
    .mc_arburst       ( mc_arburst         ), // output
    .mc_arlock        ( mc_arlock          ), // output
    .mc_arqos         ( mc_arqos           ), // output
    .mc_arvalid       ( mc_arvalid         ), // output
    .mc_arready       ( mc_arready         ), // input
    .mc_rid           ( mc_rid             ), // input
    .mc_rresp         ( mc_rresp           ), // input
    .mc_rdata         ( mc_rdata           ), // input
    .mc_rlast         ( mc_rlast           ), // input
    .mc_rvalid        ( mc_rvalid          ), // input
    .mc_rready        ( mc_rready          )  // output
  );

endmodule

`default_nettype wire
