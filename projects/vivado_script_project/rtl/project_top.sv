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

  localparam logic [AXI_DATA_WIDTH_P-1 : 0] SR_HARDWARE_VERSION_C = 2058;
  localparam int                            NR_OF_MASTERS_C       = 2;
  localparam int                            AUDIO_WIDTH_C         = 24;
  localparam int                            GAIN_WIDTH_C          = 24;
  localparam int                            NR_OF_CHANNELS_C      = 3;
  //localparam int                            Q_BITS_C              = 7;

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
  logic [AXI_DATA_WIDTH_P-1 : 0] cmd_irq_clear;

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

  logic clk_mclk;
  logic rst_mclk_n;

  // -------------------------------------------------------------------------
  // I2S2 PMOD
  // -------------------------------------------------------------------------

  logic [AUDIO_WIDTH_C-1 : 0] cs_adc_data;
  logic                       cs_adc_ready;
  logic                       cs_adc_valid;
  logic                       cs_adc_last;

  logic [AUDIO_WIDTH_C-1 : 0] cs_dac_data;
  logic                       cs_dac_last;
  logic                       cs_dac_valid;
  logic                       cs_dac_ready;

  logic [AUDIO_WIDTH_C-1 : 0] sr_cir_max_amplitude;
  logic [AUDIO_WIDTH_C-1 : 0] sr_cir_min_amplitude;
  logic                       cmd_cir_clear_max;

  // -------------------------------------------------------------------------
  // Mixer
  // -------------------------------------------------------------------------

  logic signed [NR_OF_CHANNELS_C-1 : 0] [AUDIO_WIDTH_C-1 : 0] mix_channel_data;
  logic                                                       mix_channel_valid;
  logic signed                          [AUDIO_WIDTH_C-1 : 0] mix_out_left;
  logic signed                          [AUDIO_WIDTH_C-1 : 0] mix_out_right;
  logic signed                          [AUDIO_WIDTH_C-1 : 0] mix_out_right_r0;
  logic                                                       mix_out_valid;
  logic                                                       mix_out_ready;
  logic                              [NR_OF_CHANNELS_C-1 : 0] sr_mix_channel_clip;
  logic                                                       sr_mix_out_clip;
  logic         [NR_OF_CHANNELS_C-1 : 0] [GAIN_WIDTH_C-1 : 0] cr_mix_channel_gain;
  logic                                  [GAIN_WIDTH_C-1 : 0] cr_mix_channel_gain_0;
  logic                                  [GAIN_WIDTH_C-1 : 0] cr_mix_channel_gain_1;

  logic                              [NR_OF_CHANNELS_C-1 : 0] cr_mix_channel_pan;
  logic                                  [GAIN_WIDTH_C-1 : 0] cr_mix_output_gain;

  logic                                                       clip_detected;
  logic                                              [31 : 0] clip_counter;

  assign cr_mix_channel_gain[0] = cr_mix_channel_gain_0;
  assign cr_mix_channel_gain[1] = cr_mix_channel_gain_1;


  // -------------------------------------------------------------------------
  // Oscillator
  // -------------------------------------------------------------------------


  localparam int SYS_CLK_FREQUENCY_C  = 125000000;
  localparam int PRIME_FREQUENCY_C    = 1000000;
  localparam int WAVE_WIDTH_C         = 24;
  localparam int DUTY_CYCLE_DIVIDER_C = 1000;
  localparam int N_BITS_C             = 32;
  localparam int Q_BITS_C             = 11;
  localparam int AXI_DATA_WIDTH_C     = 32;
  localparam int AXI_ID_WIDTH_C       = 32;
  localparam int AXI_ID_C             = 32'hDEADBEA7;

  logic signed [WAVE_WIDTH_C-1 : 0] osc_waveform;
  logic                     [1 : 0] cr_osc0_waveform_select;
  logic            [N_BITS_C-1 : 0] cr_osc0_frequency;
  logic            [N_BITS_C-1 : 0] cr_osc0_duty_cycle;


  assign mix_channel_data[2] = osc_waveform;

  // -------------------------------------------------------------------------
  // Mixer Clip LED
  // -------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin : mixer_clip_p0
    if (!rst_n) begin
      led_1         <= '0;
      clip_detected <= '0;
      clip_counter  <= '0;
    end
    else begin

      led_1 <= clip_counter[25]; // 2**25 = 67108864/2

      if ((|sr_mix_channel_clip) || sr_mix_out_clip) begin
        clip_detected <= '1;
      end

      if (clip_detected) begin
        if (clip_counter == 125000000 * 5) begin
          clip_detected <= '0;
          clip_counter  <= '0;
        end
        else begin
          clip_counter <= clip_counter + 1;
        end
      end

    end
  end


  // -------------------------------------------------------------------------
  // Mixer Ingress
  // -------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin : mixer_ingress_p0
    if (!rst_n) begin
      mix_channel_data[0]    <= '0;
      mix_channel_data[1]    <= '0;
      mix_channel_valid      <= '0;
      cr_mix_channel_pan[0]  <= '0;
      cr_mix_channel_pan[1]  <= '1;
      cs_adc_ready           <= '1;
      sr_cir_max_amplitude   <= '0;
      sr_cir_min_amplitude   <= {1'b1, {AUDIO_WIDTH_C{1'b0}}};
      led_2                  <= '0;
    end
    else begin

      mix_channel_valid <= '0;

      if (cs_adc_valid && !cs_adc_last) begin
        mix_channel_data[0] <= cs_adc_data;
      end

      if (cs_adc_valid && cs_adc_last) begin
        mix_channel_data[1] <= cs_adc_data;
        mix_channel_valid   <= '1;
      end

      if (cmd_cir_clear_max) begin
        led_2 <= ~led_2;
        sr_cir_max_amplitude <= '0;
      end
      else if (cs_adc_valid) begin
        if ($signed(cs_adc_data) > $signed(sr_cir_max_amplitude)) begin
          sr_cir_max_amplitude <= cs_adc_data;
        end
        if ($signed(cs_adc_data) < $signed(sr_cir_min_amplitude)) begin
          sr_cir_min_amplitude <= cs_adc_data;
        end
      end


    end
  end

  typedef enum {
    MIX_WAIT_VALID,
    MIX_SEND_FIRST,
    MIX_SEND_LAST
  } mix_egr_state_t;

  mix_egr_state_t mix_egr_state;

  // -------------------------------------------------------------------------
  // Mixer Egress
  // -------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin : mixer_egress_p0
    if (!rst_n) begin

      mix_egr_state      <= MIX_WAIT_VALID;
      mix_out_ready      <= '1;
      mix_out_right_r0   <= '0;
      cs_dac_data        <= '0;
      cs_dac_last        <= '0;
      cs_dac_valid       <= '0;
    end
    else begin

      case (mix_egr_state)

        MIX_WAIT_VALID: begin

          if (mix_out_valid) begin
            mix_egr_state    <= MIX_SEND_FIRST;
            mix_out_right_r0 <= mix_out_right;
            cs_dac_data      <= mix_out_left;
            cs_dac_last      <= '0;
            cs_dac_valid     <= '1;
          end
        end

        MIX_SEND_FIRST: begin

          if (cs_dac_ready) begin
            mix_egr_state <= MIX_SEND_LAST;
            cs_dac_data   <= mix_out_right_r0;
            cs_dac_last   <= '1;
          end

        end

        MIX_SEND_LAST: begin

          if (cs_dac_ready) begin
            mix_egr_state <= MIX_WAIT_VALID;
            cs_dac_valid  <= '0;
          end
        end

      endcase

    end
  end


  // -------------------------------------------------------------------------
  // IRQ 1
  // -------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin : axi_read_irq
    if (!rst_n) begin
      irq_1 <= '0;
    end
    else begin
      irq_1 <= '0;
      if (btn_0_tgl) begin
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
  // IRQ 1
  // -------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin : interrupt_p0

    if (!rst_n) begin

      irq_0         <= '0;
      irq_0_counter <= '0;

    end
    else begin

      irq_0 <= '0;

      if (cmd_irq_clear) begin
        irq_0_counter <= '0;
        irq_0         <= '0;
      end
      else if (irq_0_counter == 125000000-1) begin
        irq_0         <= '1;
        irq_0_counter <= '0;
      end
      else begin
        irq_0_counter <= irq_0_counter + 1;
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

  // -------------------------------------------------------------------------
  // Audio Mixer
  // -------------------------------------------------------------------------
  mixer #(
    .AUDIO_WIDTH_P       ( AUDIO_WIDTH_C       ),
    .GAIN_WIDTH_P        ( GAIN_WIDTH_C        ),
    .NR_OF_CHANNELS_P    ( NR_OF_CHANNELS_C    ),
    .Q_BITS_P            ( Q_BITS_C            )
  ) mixer_i0 (
    .clk                 ( clk                 ), // input
    .rst_n               ( rst_n               ), // input
    .channel_data        ( mix_channel_data    ), // input
    .channel_valid       ( mix_channel_valid   ), // input
    .out_left            ( mix_out_left        ), // output
    .out_right           ( mix_out_right       ), // output
    .out_valid           ( mix_out_valid       ), // input
    .out_ready           ( mix_out_ready       ), // input
    .sr_mix_channel_clip ( sr_mix_channel_clip ), // output
    .sr_mix_out_clip     ( sr_mix_out_clip     ), // output
    .cr_mix_channel_gain ( cr_mix_channel_gain ), // input
    .cr_mix_channel_pan  ( cr_mix_channel_pan  ), // input
    .cr_mix_output_gain  ( cr_mix_output_gain  )  // input
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
    .clk         ( clk          ), // input
    .rst_n       ( rst_n        ), // input
    .clk_mclk    ( clk_mclk     ), // output
    .rst_mclk_n  ( rst_mclk_n   ), // output

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
    .AXI_DATA_WIDTH_P        ( AXI_DATA_WIDTH_P        ),
    .AXI_ADDR_WIDTH_P        ( AXI_ADDR_WIDTH_P        ),
    .AUDIO_WIDTH_P           ( AUDIO_WIDTH_C           ),
    .GAIN_WIDTH_P            ( GAIN_WIDTH_C            ),
    .N_BITS_P                ( N_BITS_C                ),
    .Q_BITS_P                ( Q_BITS_C                )
  ) register_axi_slave_i0 (

    .clk                     ( clk                     ), // input
    .rst_n                   ( rst_n                   ), // input

    .awaddr                  ( cfg_awaddr              ), // input
    .awvalid                 ( cfg_awvalid             ), // input
    .awready                 ( cfg_awready             ), // output

    .wdata                   ( cfg_wdata               ), // input
    .wstrb                   ( cfg_wstrb               ), // input
    .wvalid                  ( cfg_wvalid              ), // input
    .wready                  ( cfg_wready              ), // output

    .bresp                   ( cfg_bresp               ), // output
    .bvalid                  ( cfg_bvalid              ), // output
    .bready                  ( cfg_bready              ), // input

    .araddr                  ( cfg_araddr              ), // input
    .arvalid                 ( cfg_arvalid             ), // input
    .arready                 ( cfg_arready             ), // output

    .rdata                   ( cfg_rdata               ), // output
    .rresp                   ( cfg_rresp               ), // output
    .rvalid                  ( cfg_rvalid              ), // output
    .rready                  ( cfg_rready              ), // input

    .sr_hardware_version     ( SR_HARDWARE_VERSION_C   ), // input
    .cmd_irq_clear           ( cmd_irq_clear           ), // output
    .cr_led_0                ( cr_led_0                ), // output
    .cr_mix_output_gain      ( cr_mix_output_gain      ), // output
    .cr_mix_channel_gain_0   ( cr_mix_channel_gain_0   ), // output
    .cr_mix_channel_gain_1   ( cr_mix_channel_gain_1   ), // output
    .sr_cir_max_amplitude    ( sr_cir_max_amplitude    ), // input
    .sr_cir_min_amplitude    ( sr_cir_min_amplitude    ), // input
    .cmd_cir_clear_max       ( cmd_cir_clear_max       ), // output
    .cr_osc0_waveform_select ( cr_osc0_waveform_select ), // output
    .cr_osc0_frequency       ( cr_osc0_frequency       ), // output
    .cr_osc0_duty_cycle      ( cr_osc0_duty_cycle      )  // output
  );


  // -------------------------------------------------------------------------
  // Oscillator
  // -------------------------------------------------------------------------
  oscillator_system #(
    .SYS_CLK_FREQUENCY_P  ( SYS_CLK_FREQUENCY_C     ),
    .PRIME_FREQUENCY_P    ( PRIME_FREQUENCY_C       ),
    .WAVE_WIDTH_P         ( WAVE_WIDTH_C            ),
    .DUTY_CYCLE_DIVIDER_P ( DUTY_CYCLE_DIVIDER_C    ),
    .N_BITS_P             ( N_BITS_C                ),
    .Q_BITS_P             ( Q_BITS_C                ),
    .AXI_DATA_WIDTH_P     ( AXI_DATA_WIDTH_C        ),
    .AXI_ID_WIDTH_P       ( AXI_ID_WIDTH_C          ),
    .AXI_ID_P             ( AXI_ID_C                )
  ) oscillator_system_i0 (
    .clk                  ( clk                     ), // input
    .rst_n                ( rst_n                   ), // input
    .waveform             ( osc_waveform            ), // output
    .cr_waveform_select   ( cr_osc0_waveform_select ), // input
    .cr_frequency         ( cr_osc0_frequency       ), // input
    .cr_duty_cycle        ( cr_osc0_duty_cycle      )  // input
  );

  // -------------------------------------------------------------------------
  // Recorder (and Playback)
  // -------------------------------------------------------------------------
/*
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
    .ing_tready            ( ),//vc_adc_ready      ), // output
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
*/

endmodule

`default_nettype wire
