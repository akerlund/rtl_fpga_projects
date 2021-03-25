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

module dafx_core #(
    parameter int MC_ID_WIDTH_P    = 6,
    parameter int MC_ADDR_WIDTH_P  = 32,
    parameter int MC_DATA_WIDTH_P  = 128,
    parameter int MC_STRB_WIDTH_P  = MC_DATA_WIDTH_P/8,
    parameter int CFG_ID_WIDTH_P   = 16,
    parameter int CFG_ADDR_WIDTH_P = 16,
    parameter int CFG_DATA_WIDTH_P = 64,
    parameter int CFG_STRB_WIDTH_P = CFG_DATA_WIDTH_P/8,
    parameter int AXI_ID_WIDTH_P   = 32,
    parameter int AXI_ADDR_WIDTH_P = 7,
    parameter int AXI_DATA_WIDTH_P = 32,
    parameter int AXI_STRB_WIDTH_P = AXI_DATA_WIDTH_P/8
  )(

    // Clock and reset
    input  wire                                   clk,
    input  wire                                   rst_n,
    input  wire                                   clk_mclk,
    input  wire                                   rst_mclk_n,
    axi4_reg_if.slave                             dafx_cfg_if,

    // Cirrus CS5343 ADC/DAC
    input  wire                          [23 : 0] cs_adc_data,
    input  wire                                   cs_adc_valid,
    output logic                                  cs_adc_ready,
    input  wire                                   cs_adc_last,
    output logic                         [23 : 0] cs_dac_data,
    output logic                                  cs_dac_valid,
    input  wire                                   cs_dac_ready,
    output logic                                  cs_dac_last,

    // ---------------------------------------------------------------------------
    // PL I/O
    // ---------------------------------------------------------------------------

    // Arty Z7 LEDS
    output logic                                  led_0,
    output logic                                  led_1,
    output logic                                  led_2,

    // Arty Z7 buttons
    input  wire                                   btn_0,
    input  wire                                   btn_1,
    input  wire                                   btn_2,
    input  wire                                   btn_3,

    // Arty Z7 switches
    input  wire                                   sw_0,
    input  wire                                   sw_1,

    output logic                                  irq_0,
    output logic                                  irq_1
  );

  axi4_if #(
    .ID_WIDTH_P   ( MC_ID_WIDTH_P   ),
    .ADDR_WIDTH_P ( MC_ADDR_WIDTH_P ),
    .DATA_WIDTH_P ( MC_DATA_WIDTH_P )
  ) axi4_if0 ();

  logic                          cmd_clear_irq_0;
  logic [AXI_DATA_WIDTH_P-1 : 0] irq_0_counter;
  logic [AXI_DATA_WIDTH_P-1 : 0] irq_1_counter;
  logic [AXI_DATA_WIDTH_P-1 : 0] led_2_counter;

  // Mixer
  logic                                                       fs_strobe;
  logic signed [NR_OF_CHANNELS_C-1 : 0] [AUDIO_WIDTH_C-1 : 0] mix_channel_data;
  logic                                                       cmd_cir_clear_max;
  logic         [NR_OF_CHANNELS_C-1 : 0] [GAIN_WIDTH_C-1 : 0] cr_mix_channel_gain;
  logic                                  [GAIN_WIDTH_C-1 : 0] cr_mix_channel_gain_0;
  logic                                  [GAIN_WIDTH_C-1 : 0] cr_mix_channel_gain_1;
  logic                                  [GAIN_WIDTH_C-1 : 0] cr_mix_channel_gain_2;
  logic                              [NR_OF_CHANNELS_C-1 : 0] cr_mix_channel_pan;
  logic                                  [GAIN_WIDTH_C-1 : 0] cr_mix_output_gain;
  logic                                                       sr_mix_out_clip;
  logic                              [NR_OF_CHANNELS_C-1 : 0] sr_mix_channel_clip;
  logic                                 [AUDIO_WIDTH_C-1 : 0] sr_mix_max_dac_amplitude;
  logic                                 [AUDIO_WIDTH_C-1 : 0] sr_mix_min_dac_amplitude;

  // Oscillator
  logic signed [WAVE_WIDTH_C-1 : 0] osc_waveform;
  logic                     [1 : 0] cr_osc0_waveform_select;
  logic            [N_BITS_C-1 : 0] cr_osc0_frequency;
  logic            [N_BITS_C-1 : 0] cr_osc0_duty_cycle;

  // Mixer assignments
  assign fs_strobe              = cs_adc_valid && cs_adc_ready && cs_adc_last;
  assign mix_channel_data[2]    = osc_waveform;
  assign cr_mix_channel_gain[0] = cr_mix_channel_gain_0;
  assign cr_mix_channel_gain[1] = cr_mix_channel_gain_1;
  assign cr_mix_channel_gain[2] = cr_mix_channel_gain_2;

  // ADC to mixer channels
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      mix_channel_data[0] <= '0;
      mix_channel_data[1] <= '0;
      cr_mix_channel_pan  <= '0;

      cr_mix_channel_pan[0] <= '0;
      cr_mix_channel_pan[1] <= '0;
      cr_mix_channel_pan[2] <= '1;

      cs_adc_ready <= '0;
    end
    else begin
      cs_adc_ready <= '1;

      if (cs_adc_valid && cs_adc_ready && !cs_adc_last) begin
        mix_channel_data[0] <= cs_adc_data;
      end

      if (cs_adc_valid && cs_adc_ready && cs_adc_last) begin
        mix_channel_data[1] <= cs_adc_data;
      end
    end
  end

  // IRQ 0
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      irq_0         <= '0;
      irq_0_counter <= '0;
    end else begin
      irq_0 <= '0;
      if (irq_0_counter == 125000000/10-1) begin
        irq_0         <= '1;
        irq_0_counter <= '0;
      end
      else begin
        irq_0_counter <= irq_0_counter + 1;
      end
    end
  end


  // IRQ 1
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      irq_1         <= '0;
      irq_1_counter <= '0;
    end else begin
      irq_1 <= '0;
      if (irq_1_counter == SAMPLING_IRQ_COUNTER_C-1) begin
        irq_1         <= '1;
        irq_1_counter <= '0;
      end else begin
        irq_1_counter <= irq_1_counter + 1;
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Audio Mixer
  // ---------------------------------------------------------------------------
  mixer_top #(
    .AUDIO_WIDTH_P             ( AUDIO_WIDTH_C            ),
    .GAIN_WIDTH_P              ( GAIN_WIDTH_C             ),
    .NR_OF_CHANNELS_P          ( NR_OF_CHANNELS_C         ),
    .Q_BITS_P                  ( Q_BITS_C                 )
  ) mixer_top_i0 (
    .clk                       ( clk                      ), // input
    .rst_n                     ( rst_n                    ), // input
    .clip_led                  (                          ), // output
    .fs_strobe                 ( fs_strobe                ), // input
    .dac_data                  ( cs_dac_data              ), // output
    .dac_valid                 ( cs_dac_valid             ), // output
    .dac_ready                 ( cs_dac_ready             ), // input
    .dac_last                  ( cs_dac_last              ), // output
    .channel_data              ( mix_channel_data         ), // input
    .cmd_mix_clear_dac_min_max ( '0                       ), // input
    .cr_mix_channel_gain       ( cr_mix_channel_gain      ), // input
    .cr_mix_channel_pan        ( cr_mix_channel_pan       ), // input
    .cr_mix_output_gain        ( cr_mix_output_gain       ), // input
    .sr_mix_out_clip           ( sr_mix_out_clip          ), // output
    .sr_mix_channel_clip       ( sr_mix_channel_clip      ), // output
    .sr_mix_max_dac_amplitude  ( sr_mix_max_dac_amplitude ), // output
    .sr_mix_min_dac_amplitude  ( sr_mix_min_dac_amplitude )  // output
  );

  // ---------------------------------------------------------------------------
  // AXI4 Slave with PL registers
  // ---------------------------------------------------------------------------
  dafx_axi_slave #(
    .AXI_DATA_WIDTH_P         ( AXI_DATA_WIDTH_P          ),
    .AXI_ADDR_WIDTH_P         ( AXI_ADDR_WIDTH_P          ),
    .AUDIO_WIDTH_C            ( AUDIO_WIDTH_C             ),
    .GAIN_WIDTH_C             ( GAIN_WIDTH_C              ),
    .N_BITS_C                 ( N_BITS_C                  ),
    .Q_BITS_C                 ( Q_BITS_C                  )
  ) dafx_axi_slave_i0 (
    .cif                      ( dafx_cfg_if               ), // modport
    .sr_hardware_version      ( SR_HARDWARE_VERSION_C     ), // input
    .cr_mix_output_gain       ( cr_mix_output_gain        ), // output
    .cr_mix_channel_gain_0    ( cr_mix_channel_gain_0     ), // output
    .cr_mix_channel_gain_1    ( cr_mix_channel_gain_1     ), // output
    .cr_mix_channel_gain_2    ( cr_mix_channel_gain_2     ), // output
    .cr_osc0_waveform_select  ( cr_osc0_waveform_select   ), // output
    .cr_osc0_frequency        ( cr_osc0_frequency         ), // output
    .cr_osc0_duty_cycle       ( cr_osc0_duty_cycle        ), // output
    .sr_cir_min_adc_amplitude ( '0                        ), // input
    .sr_cir_max_adc_amplitude ( '0                        ), // input
    .sr_cir_min_dac_amplitude ( -sr_mix_min_dac_amplitude ), // input
    .sr_cir_max_dac_amplitude ( sr_mix_max_dac_amplitude  ), // input
    .cmd_clear_adc_amplitude  ( cmd_cir_clear_max         ), // output
    .cmd_clear_irq_0          ( cmd_clear_irq_0           ), // output
    .cmd_clear_irq_1          (                           ), // output
    .sr_mix_out_left          ( '0                        ), // input
    .sr_mix_out_right         ( '0                        )  // input
  );

  // ---------------------------------------------------------------------------
  // Oscillator
  // ---------------------------------------------------------------------------
  oscillator_system #(
    .SYS_CLK_FREQUENCY_P  ( SYS_CLK_FREQUENCY_C     ),
    .PRIME_FREQUENCY_P    ( PRIME_FREQUENCY_C       ),
    .WAVE_WIDTH_P         ( WAVE_WIDTH_C            ),
    .DUTY_CYCLE_DIVIDER_P ( DUTY_CYCLE_DIVIDER_C    ),
    .N_BITS_P             ( N_BITS_C                ),
    .Q_BITS_P             ( Q_BITS_C                ),
    .AXI_DATA_WIDTH_P     ( N_BITS_C                ),
    .AXI_ID_WIDTH_P       ( 5                       ),
    .AXI_ID_P             ( 0                       )
  ) oscillator_system_i0 (
    .clk                  ( clk                     ), // input
    .rst_n                ( rst_n                   ), // input
    .waveform             ( osc_waveform            ), // output
    .cr_waveform_select   ( cr_osc0_waveform_select ), // input
    .cr_frequency         ( cr_osc0_frequency       ), // input
    .cr_duty_cycle        ( cr_osc0_duty_cycle      )  // input
  );

endmodule

`default_nettype wire
