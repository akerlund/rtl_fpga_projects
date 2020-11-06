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

`default_nettype none

module project_top #(
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
    input  wire          [AXI_ADDR_WIDTH_P-1 : 0] cfg_awaddr,
    input  wire                           [2 : 0] cfg_awprot,
    input  wire                                   cfg_awvalid,
    output logic                                  cfg_awready,

    // Write Data Channel
    input  wire          [AXI_DATA_WIDTH_P-1 : 0] cfg_wdata,
    input  wire      [(AXI_DATA_WIDTH_P/8)-1 : 0] cfg_wstrb,
    input  wire                                   cfg_wvalid,
    output logic                                  cfg_wready,

    // Write Response Channel
    output logic                          [1 : 0] cfg_bresp,
    output logic                                  cfg_bvalid,
    input  wire                                   cfg_bready,

    // Read Address Channel
    input  wire          [AXI_ADDR_WIDTH_P-1 : 0] cfg_araddr,
    input  wire                           [2 : 0] cfg_arprot,
    input  wire                                   cfg_arvalid,
    output logic                                  cfg_arready,

    // Read Data Channel
    output logic         [AXI_DATA_WIDTH_P-1 : 0] cfg_rdata,
    output logic                          [1 : 0] cfg_rresp,
    output logic                                  cfg_rvalid,
    input  wire                                   cfg_rready,

    // -------------------------------------------------------------------------
    // Memory Controller AXI4 ports
    // -------------------------------------------------------------------------

    // Write Address Channel
    output logic           [AXI_ID_WIDTH_P-1 : 0] mc_awid,
    output logic         [AXI_ADDR_WIDTH_P-1 : 0] mc_awaddr,
    output logic                          [7 : 0] mc_awlen,
    output logic                          [2 : 0] mc_awsize,
    output logic                          [1 : 0] mc_awburst,
    output logic                                  mc_awlock,
    output logic                          [3 : 0] mc_awqos,
    output logic                                  mc_awvalid,
    input  wire                                   mc_awready,

    // Write Data Channel
    output logic         [AXI_DATA_WIDTH_P-1 : 0] mc_wdata,
    output logic     [(AXI_DATA_WIDTH_P/8)-1 : 0] mc_wstrb,
    output logic                                  mc_wlast,
    output logic                                  mc_wvalid,
    input  wire                                   mc_wready,

    // Write Response Channel
    input  wire            [AXI_ID_WIDTH_P-1 : 0] mc_bid,
    input  wire                           [1 : 0] mc_bresp,
    input  wire                                   mc_bvalid,
    output logic                                  mc_bready,

    // Read Address Channel
    output logic           [AXI_ID_WIDTH_P-1 : 0] mc_arid,
    output logic         [AXI_ADDR_WIDTH_P-1 : 0] mc_araddr,
    output logic                          [7 : 0] mc_arlen,
    output logic                          [2 : 0] mc_arsize,
    output logic                          [1 : 0] mc_arburst,
    output logic                                  mc_arlock,
    output logic                          [3 : 0] mc_arqos,
    output logic                                  mc_arvalid,
    input  wire                                   mc_arready,

    // Read Data Channel
    input  wire            [AXI_ID_WIDTH_P-1 : 0] mc_rid,
    input  wire                           [1 : 0] mc_rresp,
    input  wire          [AXI_DATA_WIDTH_P-1 : 0] mc_rdata,
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

  localparam logic [AXI_DATA_WIDTH_P-1 : 0] SR_HARDWARE_VERSION_C = 1811;
  localparam int                            NR_OF_MASTERS_C       = 2;
  localparam int                            AUDIO_WIDTH_C         = 24;
  localparam int                            GAIN_WIDTH_C          = 32;
  localparam int                            NR_OF_CHANNELS_C      = 1;
  localparam int                            Q_BITS_C              = 8;


  typedef enum {
    AW_WAIT_FOR_CMD_E,
    AW_WAIT_FOR_HS_E,
    W_WAIT_FOR_HS_E
  } write_state_t;

  typedef enum {
    AR_WAIT_FOR_CMD_E,
    AR_WAIT_FOR_HS_E,
    R_WAIT_FOR_HS_E
  } read_state_t;

  // -------------------------------------------------------------------------
  // IRQ
  // -------------------------------------------------------------------------
  logic [AXI_DATA_WIDTH_P-1 : 0] irq_0_counter;

  // -------------------------------------------------------------------------
  // Toggling LED
  // -------------------------------------------------------------------------
  logic [AXI_DATA_WIDTH_P-1 : 0] led_3_counter;
  logic [AXI_DATA_WIDTH_P-1 : 0] led_2_counter;

  // -------------------------------------------------------------------------
  // Buttons
  // -------------------------------------------------------------------------
  logic btn_0_tgl;
  logic btn_1_tgl;
  logic btn_2_tgl;

  // -------------------------------------------------------------------------
  // Switches
  // -------------------------------------------------------------------------
  logic switch_0;
  logic switch_1;

  // -------------------------------------------------------------------------
  // AXI4 registers
  // -------------------------------------------------------------------------
  logic [AXI_DATA_WIDTH_P-1 : 0] cr_led_0;
  logic [AXI_DATA_WIDTH_P-1 : 0] sr_led_counter;
  logic [AXI_DATA_WIDTH_P-1 : 0] sr_mc_axi4_rdata;
  logic [AXI_DATA_WIDTH_P-1 : 0] cr_axi_address;
  logic [AXI_DATA_WIDTH_P-1 : 0] cr_wdata;
  logic [AXI_DATA_WIDTH_P-1 : 0] cmd_irq_clear;
  logic [AXI_DATA_WIDTH_P-1 : 0] cmd_mc_axi4_write;
  logic [AXI_DATA_WIDTH_P-1 : 0] cmd_mc_axi4_read;
  logic [AXI_DATA_WIDTH_P-1 : 0] sr_rdata;

  // -------------------------------------------------------------------------
  // AXI4 Write Arbiter
  // -------------------------------------------------------------------------

  // Write Address Channel
  logic [0 : NR_OF_MASTERS_C-1]   [AXI_ID_WIDTH_P-1 : 0] mst_awid;
  logic [0 : NR_OF_MASTERS_C-1] [AXI_ADDR_WIDTH_P-1 : 0] mst_awaddr;
  logic [0 : NR_OF_MASTERS_C-1]                  [7 : 0] mst_awlen;
  logic [0 : NR_OF_MASTERS_C-1]                          mst_awvalid;
  logic [0 : NR_OF_MASTERS_C-1]                          mst_awready;

  // Write Data Channel
  logic [0 : NR_OF_MASTERS_C-1] [AXI_DATA_WIDTH_P-1 : 0] mst_wdata;
  logic [0 : NR_OF_MASTERS_C-1] [AXI_STRB_WIDTH_P-1 : 0] mst_wstrb;
  logic [0 : NR_OF_MASTERS_C-1]                          mst_wlast;
  logic [0 : NR_OF_MASTERS_C-1]                          mst_wvalid;
  logic [0 : NR_OF_MASTERS_C-1]                          mst_wready;

  // -------------------------------------------------------------------------
  // AXI4 Read Arbiter
  // -------------------------------------------------------------------------

  // Read Address Channel
  logic [0 : NR_OF_MASTERS_C-1]   [AXI_ID_WIDTH_P-1 : 0] mst_arid;
  logic [0 : NR_OF_MASTERS_C-1] [AXI_ADDR_WIDTH_P-1 : 0] mst_araddr;
  logic [0 : NR_OF_MASTERS_C-1]                  [7 : 0] mst_arlen;
  logic [0 : NR_OF_MASTERS_C-1]                          mst_arvalid;
  logic [0 : NR_OF_MASTERS_C-1]                          mst_arready;

  // Read Data Channel
  logic                           [AXI_ID_WIDTH_P-1 : 0] mst_rid;
  logic                         [AXI_DATA_WIDTH_P-1 : 0] mst_rdata;
  logic                                                  mst_rlast;
  logic [0 : NR_OF_MASTERS_C-1]                          mst_rvalid;
  logic [0 : NR_OF_MASTERS_C-1]                          mst_rready;

  // -------------------------------------------------------------------------
  // Cirrus clock and reset
  // -------------------------------------------------------------------------

  logic          clk_mclk;
  logic          rst_mclk_n;

  // -------------------------------------------------------------------------
  // I2S2 PMOD
  // -------------------------------------------------------------------------

  logic [AUDIO_WIDTH_C-1 : 0] cs_dac_data_mux;
  logic                       cs_dac_last_mux;
  logic                       cs_dac_valid_mux;
  logic                       cs_dac_ready;

  logic [AUDIO_WIDTH_C-1 : 0] cs_dac_data0;
  logic                       cs_dac_last0;
  logic                       cs_dac_valid0;
  logic [AUDIO_WIDTH_C-1 : 0] cs_adc_data;
  logic                       cs_adc_ready;
  logic                       cs_adc_valid;
  logic                       cs_adc_last;

  // -------------------------------------------------------------------------
  // Mixer
  // -------------------------------------------------------------------------

  logic signed [NR_OF_CHANNELS_P-1 : 0] [AUDIO_WIDTH_P-1 : 0] channel_data;
  logic                              [NR_OF_CHANNELS_P-1 : 0] channel_valid;
  logic signed                          [AUDIO_WIDTH_P-1 : 0] mixed_data;
  logic                                                       mixed_valid;
  logic                                                       mixed_ready;
  logic         [NR_OF_CHANNELS_P-1 : 0] [GAIN_WIDTH_P-1 : 0] cr_channel_gain;
  logic                                  [GAIN_WIDTH_P-1 : 0] cr_output_gain;

  // -------------------------------------------------------------------------
  // Volume Controller
  // -------------------------------------------------------------------------

  // Volume controller volume input
  logic  [3 : 0] vc_volume;

  // Volume controller ingress (ADC)
  logic [AUDIO_WIDTH_C-1 : 0] vc_adc_data;
  logic                       vc_adc_valid;
  logic                       vc_adc_last;
  logic                       vc_adc_ready;

  // Volume controller egress (DAC)
  logic [AUDIO_WIDTH_C-1 : 0] vc_dac_data;
  logic                       vc_dac_valid;
  logic                       vc_dac_last;
  logic                       vc_dac_ready;

  // -------------------------------------------------------------------------
  // IRQ of AXI Read Channel
  // -------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin : axi_read_irq
    if (!rst_n) begin
      irq_1 <= '0;
    end
    else begin
      irq_1 <= '0;
      if (mc_rvalid && mc_rready && mc_rlast) begin
        irq_1 <= '1;
      end
    end
  end


  // -------------------------------------------------------------------------
  // SW controlling LEDs
  // -------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin : led_toggle_p0
    if (!rst_n) begin
      led_0 <= '0;
    end
    else begin
      led_0 <= cr_led_0[0];
    end
  end


  // -------------------------------------------------------------------------
  // Interrupt 'irq_0'
  // -------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin : interrupt_p0

    if (!rst_n) begin

      irq_0         <= '0;
      irq_0_counter <= '0;
      led_1         <= '0;

    end
    else begin

      irq_0         <= '0;

      if (cmd_irq_clear) begin
        irq_0_counter <= '0;
        irq_0         <= '0;
        led_1         <= '0;
      end
      else if (irq_0_counter == 125000000-1) begin
        irq_0         <= '1;
        led_1         <= ~led_1;
        irq_0_counter <= '0;
      end
      else begin
        irq_0_counter <= irq_0_counter + 1;
      end

    end
  end


  // -------------------------------------------------------------------------
  // Clock 'clk_mclk' (22.58MHz) with LED process
  // -------------------------------------------------------------------------
  always_ff @(posedge clk_mclk or negedge rst_mclk_n) begin : led_blink_p1

    if (!rst_mclk_n) begin

      led_2         <= '0;
      led_2_counter <= '0;

    end
    else begin

      if (led_2_counter == 11290000-1) begin
        led_2         <= ~led_2;
        led_2_counter <= 0;
      end
      else begin
        led_2_counter <= led_2_counter + 1;
      end

    end
  end


  // -------------------------------------------------------------------------
  // Clock 'clk_sys' (125MHz) with LED process
  // -------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin : led_blink_p0

    if (!rst_n) begin

      led_3         <= '0;
      led_3_counter <= '0;

    end
    else begin

      if (led_3_counter == 62500000-1) begin
        led_3         <= ~led_3;
        led_3_counter <= 0;
      end
      else begin
        led_3_counter <= led_3_counter + 1;
      end

    end
  end

  mixer #(
    .AUDIO_WIDTH_P    ( AUDIO_WIDTH_P    ),
    .GAIN_WIDTH_P     ( GAIN_WIDTH_P     ),
    .NR_OF_CHANNELS_P ( NR_OF_CHANNELS_P ),
    .Q_BITS_P         ( Q_BITS_P         )
  ) mixer_i0 (
    .clk              ( clk              ), // input
    .rst_n            ( rst_n            ), // input
    .channel_data     ( channel_data     ), // input
    .channel_valid    ( channel_valid    ), // input
    .mixed_data       ( mixed_data       ), // output
    .mixed_valid      ( mixed_valid      ), // output
    .mixed_ready      ( mixed_ready      ), // input
    .cr_channel_gain  ( cr_channel_gain  ), // input
    .cr_output_gain   ( cr_output_gain   )  // input
  );

  recorder #(
    .AXI_ID_P              ( 420                   ),
    .AXI_ID_WIDTH_P        ( AXI_ID_WIDTH_P        ),
    .AXI_ADDR_WIDTH_P      ( AXI_ADDR_WIDTH_P      ),
    .AXI_DATA_WIDTH_P      ( AXI_DATA_WIDTH_P      ),
    .AXI_STRB_WIDTH_P      ( AXI_STRB_WIDTH_P      ),
    .RECORD_BIT_WIDTH_P    ( RECORD_BIT_WIDTH_P    ),
    .MEMORY_BASE_ADDRESS_P ( MEMORY_BASE_ADDRESS_P ),
    .MEMORY_HIGH_ADDRESS_P ( MEMORY_HIGH_ADDRESS_P )
  ) recorder_i0 (
    .clk                   ( clk                   ), // input
    .rst_n                 ( rst_n                 ), // input
    .ing_tdata             ( vc_adc_data           ), // input
    .ing_tvalid            ( vc_adc_valid          ), // input
    .ing_tready            ( /*vc_adc_ready*/      ), // output
    .egr_tdata             ( vc_dac_data           ), // output
    .egr_tvalid            ( vc_dac_valid          ), // output
    .egr_tready            ( vc_dac_ready          ), // input
    .cr_recording_enabled  (                       ), // output
    .cr_playback_enabled   (                       ), // output
    .awid                  (                       ), // output
    .awaddr                (                       ), // output
    .awlen                 (                       ), // output
    .awvalid               (                       ), // output
    .awready               (                       ), // input
    .wdata                 (                       ), // output
    .wstrb                 (                       ), // output
    .wlast                 (                       ), // output
    .wvalid                (                       ), // output
    .wready                (                       ), // input
    .arid                  (                       ), // output
    .araddr                (                       ), // output
    .arlen                 (                       ), // output
    .arvalid               (                       ), // output
    .arready               (                       ), // input
    .rid                   (                       ), // input
    .rdata                 (                       ), // input
    .rlast                 (                       ), // input
    .rvalid                (                       ), // input
    .rready                (                       )  // output
  );


  // -------------------------------------------------------------------------
  // AXI4 Write Arbiter
  // -------------------------------------------------------------------------
  axi4_write_arbiter #(

    .AXI_ID_WIDTH_P   ( AXI_ID_WIDTH_P   ),
    .AXI_ADDR_WIDTH_P ( AXI_ADDR_WIDTH_P ),
    .AXI_DATA_WIDTH_P ( AXI_DATA_WIDTH_P ),
    .AXI_STRB_WIDTH_P ( AXI_STRB_WIDTH_P ),
    .NR_OF_MASTERS_P  ( NR_OF_MASTERS_C  )

  ) axi4_write_arbiter_i0 (

    // Clock and reset
    .clk              ( clk              ),
    .rst_n            ( rst_n            ),

    // -------------------------------------------------------------------------
    // AXI4 Masters
    // -------------------------------------------------------------------------

    // Write Address Channel
    .mst_awid         ( mst_awid         ), // input
    .mst_awaddr       ( mst_awaddr       ), // input
    .mst_awlen        ( mst_awlen        ), // input
    .mst_awvalid      ( mst_awvalid      ), // input
    .mst_awready      ( mst_awready      ), // output

    // Write Data Channel
    .mst_wdata        ( mst_wdata        ), // input
    .mst_wstrb        ( mst_wstrb        ), // input
    .mst_wlast        ( mst_wlast        ), // input
    .mst_wvalid       ( mst_wvalid       ), // input
    .mst_wready       ( mst_wready       ), // output

    // -------------------------------------------------------------------------
    // AXI4 Slave
    // -------------------------------------------------------------------------

    // Write Address Channel
    .slv_awid         ( mc_awid          ), // output
    .slv_awaddr       ( mc_awaddr        ), // output
    .slv_awlen        ( mc_awlen         ), // output
    .slv_awsize       ( mc_awsize        ), // output
    .slv_awburst      ( mc_awburst       ), // output
    //slv_awlock
    .slv_awlock       (                  ), // output
    .slv_awcache      (                  ), // output
    .slv_awprot       (                  ), // output
    .slv_awqos        ( mc_awqos         ), // output
    .slv_awvalid      ( mc_awvalid       ), // output
    .slv_awready      ( mc_awready       ), // input

    // Write Data Channel
    .slv_wdata        ( mc_wdata         ), // output
    .slv_wstrb        ( mc_wstrb         ), // output
    .slv_wlast        ( mc_wlast         ), // output
    .slv_wvalid       ( mc_wvalid        ), // output
    .slv_wready       ( mc_wready        ), // input

    // Write Response Channel
    .slv_bid          ( mc_bid           ), // input
    .slv_bresp        ( mc_bresp         ), // input
    .slv_bvalid       ( mc_bvalid        ), // input
    .slv_bready       ( mc_bready        )  // output
  );


  // -------------------------------------------------------------------------
  // AXI4 Read Arbiter
  // -------------------------------------------------------------------------
  axi4_read_arbiter #(

    .AXI_ID_WIDTH_P   ( AXI_ID_WIDTH_P   ),
    .AXI_ADDR_WIDTH_P ( AXI_ADDR_WIDTH_P ),
    .AXI_DATA_WIDTH_P ( AXI_DATA_WIDTH_P ),
    .NR_OF_MASTERS_P  ( NR_OF_MASTERS_C  )

  ) axi4_read_arbiter_i0 (

    // Clock and reset
    .clk              ( clk              ), // input
    .rst_n            ( rst_n            ), // input

    // -------------------------------------------------------------------------
    // AXI4 Masters
    // -------------------------------------------------------------------------

    // Read Address Channel
    .mst_arid         ( mst_arid         ), // input
    .mst_araddr       ( mst_araddr       ), // input
    .mst_arlen        ( mst_arlen        ), // input
    .mst_arvalid      ( mst_arvalid      ), // input
    .mst_arready      ( mst_arready      ), // output

    // Read Data Channel
    .mst_rid          ( mst_rid          ), // output
    .mst_rdata        ( mst_rdata        ), // output
    .mst_rlast        ( mst_rlast        ), // output
    .mst_rvalid       ( mst_rvalid       ), // output
    .mst_rready       ( mst_rready       ), // input

    // -------------------------------------------------------------------------
    // AXI4 Slave
    // -------------------------------------------------------------------------

    // Read Address Channel
    .slv_arid         ( mc_arid          ), // output
    .slv_araddr       ( mc_araddr        ), // output
    .slv_arlen        ( mc_arlen         ), // output
    .slv_arsize       ( mc_arsize        ), // output
    .slv_arburst      ( mc_arburst       ), // output
    .slv_arlock       ( mc_arlock        ), // output
    .slv_arcache      (                  ), // output
    .slv_arprot       (                  ), // output
    .slv_arqos        ( mc_arqos         ), // output
    .slv_arvalid      ( mc_arvalid       ), // output
    .slv_arready      ( mc_arready       ), // input

    // Read Data Channel
    .slv_rid          ( mc_rid           ), // input
    .slv_rresp        ( mc_rresp         ), // input
    .slv_rdata        ( mc_rdata         ), // input
    .slv_rlast        ( mc_rlast         ), // input
    .slv_rvalid       ( mc_rvalid        ), // input
    .slv_rready       ( mc_rready        )  // output
  );


  // -------------------------------------------------------------------------
  // Cirrus CS5343 ADC, CS4344 DAC
  // -------------------------------------------------------------------------
  cs5343_top cs5343_top_i0 (

    // Clock and reset
    .clk         ( clk              ), // input
    .rst_n       ( rst_mclk_n       ), // input

    // I/O Cirrus CS5343 (DAC)
    .cs_tx_mclk  ( cs_tx_mclk       ), // output
    .cs_tx_lrck  ( cs_tx_lrck       ), // output
    .cs_tx_sclk  ( cs_tx_sclk       ), // output
    .cs_tx_sdout ( cs_tx_sdout      ), // output

    // I/O Cirrus CS4344 (ADC)
    .cs_rx_mclk  ( cs_rx_mclk       ), // output
    .cs_rx_lrck  ( cs_rx_lrck       ), // output
    .cs_rx_sclk  ( cs_rx_sclk       ), // output
    .cs_rx_sdin  ( cs_rx_sdin       ), // input

    // AXI-S ADC
    .adc_data    ( cs_adc_data      ), // output
    .adc_valid   ( cs_adc_valid     ), // output
    .adc_ready   ( cs_adc_ready     ), // input
    .adc_last    ( cs_adc_last      ), // output

    // AXI-S DAC
    .dac_data    ( cs_dac_data_mux  ), // input
    .dac_valid   ( cs_dac_valid_mux ), // input
    .dac_ready   ( cs_dac_ready     ), // output
    .dac_last    ( cs_dac_last_mux  )  // input
  );

  // -------------------------------------------------------------------------
  // Wrapper for mechanical buttons
  // -------------------------------------------------------------------------
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

  // -------------------------------------------------------------------------
  // Synchronizing Switch 0
  // -------------------------------------------------------------------------
  io_synchronizer io_synchronizer_i0 (
    .clk         ( clk      ),
    .rst_n       ( rst_n    ),
    .bit_ingress ( sw_0     ),
    .bit_egress  ( switch_0 )
  );


  // -------------------------------------------------------------------------
  // Synchronizing Switch 1
  // -------------------------------------------------------------------------
  io_synchronizer io_synchronizer_i1 (
    .clk         ( clk      ),
    .rst_n       ( rst_n    ),
    .bit_ingress ( sw_1     ),
    .bit_egress  ( switch_1 )
  );


  // -------------------------------------------------------------------------
  // AXI4 Slave with PL registers
  // -------------------------------------------------------------------------
  register_axi_slave #(
    .AXI_DATA_WIDTH_P    ( AXI_DATA_WIDTH_P      ),
    .AXI_ADDR_WIDTH_P    ( AXI_ADDR_WIDTH_P      )
  ) register_axi_slave_i0 (

    .clk                 ( clk                   ), // input
    .rst_n               ( rst_n                 ), // input

    .awaddr              ( cfg_awaddr            ), // input
    .awvalid             ( cfg_awvalid           ), // input
    .awready             ( cfg_awready           ), // output

    .wdata               ( cfg_wdata             ), // input
    .wstrb               ( cfg_wstrb             ), // input
    .wvalid              ( cfg_wvalid            ), // input
    .wready              ( cfg_wready            ), // output

    .bresp               ( cfg_bresp             ), // output
    .bvalid              ( cfg_bvalid            ), // output
    .bready              ( cfg_bready            ), // input

    .araddr              ( cfg_araddr            ), // input
    .arvalid             ( cfg_arvalid           ), // input
    .arready             ( cfg_arready           ), // output

    .rdata               ( cfg_rdata             ), // output
    .rresp               ( cfg_rresp             ), // output
    .rvalid              ( cfg_rvalid            ), // output
    .rready              ( cfg_rready            ), // input

    .sr_hardware_version ( SR_HARDWARE_VERSION_C ), // input
    .cmd_irq_clear       ( cmd_irq_clear         ), // output
    .sr_mc_axi4_rdata    ( '0                    ), // input

    .cr_led_0            ( cr_led_0              ), // output
    .cr_axi_address      ( cr_axi_address        ), // output
    .cr_wdata            ( cr_wdata              ), // output

    .cmd_mc_axi4_write   ( cmd_mc_axi4_write     ), // output
    .cmd_mc_axi4_read    ( cmd_mc_axi4_read      ), // output

    .sr_led_counter      ( sr_led_counter        ), // input
    .sr_rdata            ( sr_rdata              )  // input
  );

endmodule

`default_nettype wire
