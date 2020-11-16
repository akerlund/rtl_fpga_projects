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

import dafx_address_pkg::*;

module dafx_axi_slave #(
    parameter int AUDIO_WIDTH_P = -1,
    parameter int AXI_ADDR_WIDTH_P = -1,
    parameter int AXI_DATA_WIDTH_P = -1,
    parameter int GAIN_WIDTH_P = -1,
    parameter int N_BITS_P = -1
  )(

    // ---------------------------------------------------------------------------
    // AXI ports
    // ---------------------------------------------------------------------------

    // Clock and reset
    input  wire                               clk,
    input  wire                               rst_n,

    // Write Address Channel
    input  wire      [AXI_ADDR_WIDTH_P-1 : 0] awaddr,
    input  wire                               awvalid,
    output logic                              awready,

    // Write Data Channel
    input  wire      [AXI_DATA_WIDTH_P-1 : 0] wdata,
    input  wire  [(AXI_DATA_WIDTH_P/8)-1 : 0] wstrb,
    input  wire                               wvalid,
    output logic                              wready,

    // Write Response Channel
    output logic                      [1 : 0] bresp,
    output logic                              bvalid,
    input  wire                               bready,

    // Read Address Channel
    input  wire      [AXI_ADDR_WIDTH_P-1 : 0] araddr,
    input  wire                               arvalid,
    output logic                              arready,

    // Read Data Channel
    output logic     [AXI_DATA_WIDTH_P-1 : 0] rdata,
    output logic                      [1 : 0] rresp,
    output logic                              rvalid,
    input  wire                               rready,

    // ---------------------------------------------------------------------------
    // Register Ports
    // ---------------------------------------------------------------------------
    input  wire  [AXI_DATA_WIDTH_P-1 : 0] sr_hardware_version,
    output logic     [GAIN_WIDTH_P-1 : 0] cr_mix_output_gain,
    output logic     [GAIN_WIDTH_P-1 : 0] cr_mix_channel_gain_0,
    output logic     [GAIN_WIDTH_P-1 : 0] cr_mix_channel_gain_1,
    output logic     [GAIN_WIDTH_P-1 : 0] cr_mix_channel_gain_2,
    output logic                  [1 : 0] cr_osc0_waveform_select,
    output logic         [N_BITS_P-1 : 0] cr_osc0_frequency,
    output logic         [N_BITS_P-1 : 0] cr_osc0_duty_cycle,
    input  wire     [AUDIO_WIDTH_P-1 : 0] sr_cir_min_adc_amplitude,
    input  wire     [AUDIO_WIDTH_P-1 : 0] sr_cir_max_adc_amplitude,
    input  wire     [AUDIO_WIDTH_P-1 : 0] sr_cir_min_dac_amplitude,
    input  wire     [AUDIO_WIDTH_P-1 : 0] sr_cir_max_dac_amplitude,
    output logic                          cmd_clear_adc_amplitude,
    output logic                          cmd_clear_irq_0,
    output logic                          cmd_clear_irq_1
  );

  // ---------------------------------------------------------------------------
  // Internal signals
  // ---------------------------------------------------------------------------

  logic                          aw_enable;
  logic [AXI_ADDR_WIDTH_P-1 : 0] awaddr_d0;
  logic                          write_enable;
  logic                          read_enable;
  logic [AXI_ADDR_WIDTH_P-1 : 0] araddr_d0;
  logic [AXI_DATA_WIDTH_P-1 : 0] rdata_d0;


  // ---------------------------------------------------------------------------
  // Internal assignments
  // ---------------------------------------------------------------------------

  assign write_enable = wready  && wvalid  && awready && awvalid;
  assign read_enable  = arready && arvalid && !rvalid;

  // ---------------------------------------------------------------------------
  // Write Address Channel
  // Generate "awready" and internal address write enable
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      awaddr_d0 <= '0;
      awready   <= '0;
      aw_enable <= '1;
    end
    else begin

      // awready
      if (!awready && awvalid && wvalid && aw_enable) begin
        awready   <= '1;
        aw_enable <= '0;
      end
      else if (bready && bvalid) begin
        aw_enable <= '1;
        awready   <= '0;
      end
      else begin
        awready   <= '0;
      end

      // awaddr
      if (!awready && awvalid && wvalid && aw_enable) begin
        awaddr_d0 <= awaddr;
      end

    end
  end


  // ---------------------------------------------------------------------------
  // Write Data Channel
  // Generate "wready"
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wready <= '0;
    end
    else begin

      if (!wready && wvalid && awvalid && aw_enable) begin
        wready <= '1;
      end
      else begin
        wready <= '0;
      end

    end
  end


  // ---------------------------------------------------------------------------
  // Register writes
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin

      cr_mix_output_gain      <= 1;
      cr_mix_channel_gain_0   <= 1;
      cr_mix_channel_gain_1   <= 1;
      cr_mix_channel_gain_2   <= 1;
      cr_osc0_waveform_select <= 0;
      cr_osc0_frequency       <= 500;
      cr_osc0_duty_cycle      <= 500;
      cmd_clear_irq_0         <= 0;
      cmd_clear_irq_1         <= 0;

    end
    else begin

      cmd_clear_adc_amplitude <= '0;
      cmd_clear_irq_0         <= '0;
      cmd_clear_irq_1         <= '0;

      if (write_enable) begin

        case (awaddr_d0)

          DAFX_MIXER_OUTPUT_GAIN_ADDR: begin
            cr_mix_output_gain <= wdata[GAIN_WIDTH_P-1 : 0];
          end

          DAFX_MIXER_CHANNEL_GAIN_0_ADDR: begin
            cr_mix_channel_gain_0 <= wdata[GAIN_WIDTH_P-1 : 0];
          end

          DAFX_MIXER_CHANNEL_GAIN_1_ADDR: begin
            cr_mix_channel_gain_1 <= wdata[GAIN_WIDTH_P-1 : 0];
          end

          DAFX_MIXER_CHANNEL_GAIN_2_ADDR: begin
            cr_mix_channel_gain_2 <= wdata[GAIN_WIDTH_P-1 : 0];
          end

          DAFX_OSC0_WAVEFORM_SELECT_ADDR: begin
            cr_osc0_waveform_select <= wdata[1 : 0];
          end

          DAFX_OSC0_FREQUENCY_ADDR: begin
            cr_osc0_frequency <= wdata[N_BITS_P-1 : 0];
          end

          DAFX_OSC0_DUTY_CYCLE_ADDR: begin
            cr_osc0_duty_cycle <= wdata[N_BITS_P-1 : 0];
          end

          DAFX_CLEAR_ADC_AMPLITUDE_ADDR: begin
            cmd_clear_adc_amplitude <= wdata[0];
          end

          DAFX_CLEAR_IRQ_0_ADDR: begin
            cmd_clear_irq_0 <= wdata[0];
          end

          DAFX_CLEAR_IRQ_1_ADDR: begin
            cmd_clear_irq_1 <= wdata[0];
          end


          default : begin

          end

        endcase
      end
    end
  end


  // ---------------------------------------------------------------------------
  // Write Response Channel
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      bvalid <= '0;
      bresp  <= '0;
    end
    else begin

      if (awready && awvalid && !bvalid && wready && wvalid) begin
        bvalid <= '1;
        bresp  <= '0;
      end
      else begin
        if (bready && bvalid) begin
          bvalid <= '0;
        end
      end
    end
  end


  // ---------------------------------------------------------------------------
  // Read Address Channel
  // Generate "arready"
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      arready   <= '0;
      araddr_d0 <= '0;
    end
    else begin

      if (!arready && arvalid) begin
        arready   <= '1;
        araddr_d0 <= araddr;
      end
      else begin
        arready <= '0;
      end

    end
  end


  // ---------------------------------------------------------------------------
  // Read Data Channel
  // Generate "rvalid"
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rdata  <= 0;
      rresp  <= 0;
      rvalid <= 0;
    end
    else begin

      if (read_enable) begin
        rdata <= rdata_d0;
      end

      if (arready && arvalid && !rvalid) begin
        rvalid <= '1;
        rresp  <= '0;
      end
      else if (rvalid && rready) begin
        rvalid <= '0;
      end

    end
  end


  // ---------------------------------------------------------------------------
  // Register reads
  // ---------------------------------------------------------------------------
  always_comb begin

    rdata_d0 <= '0;

    // Address decoding for reading registers
    case (araddr_d0)

      DAFX_HARDWARE_VERSION_ADDR: begin
        rdata_d0[AXI_DATA_WIDTH_P-1 : 0] <= sr_hardware_version;
      end

      DAFX_MIXER_OUTPUT_GAIN_ADDR: begin
        rdata_d0[GAIN_WIDTH_P-1 : 0] <= cr_mix_output_gain;
      end

      DAFX_MIXER_CHANNEL_GAIN_0_ADDR: begin
        rdata_d0[GAIN_WIDTH_P-1 : 0] <= cr_mix_channel_gain_0;
      end

      DAFX_MIXER_CHANNEL_GAIN_1_ADDR: begin
        rdata_d0[GAIN_WIDTH_P-1 : 0] <= cr_mix_channel_gain_1;
      end

      DAFX_MIXER_CHANNEL_GAIN_2_ADDR: begin
        rdata_d0[GAIN_WIDTH_P-1 : 0] <= cr_mix_channel_gain_2;
      end

      DAFX_OSC0_WAVEFORM_SELECT_ADDR: begin
        rdata_d0[1 : 0] <= cr_osc0_waveform_select;
      end

      DAFX_OSC0_FREQUENCY_ADDR: begin
        rdata_d0[N_BITS_P-1 : 0] <= cr_osc0_frequency;
      end

      DAFX_OSC0_DUTY_CYCLE_ADDR: begin
        rdata_d0[N_BITS_P-1 : 0] <= cr_osc0_duty_cycle;
      end

      DAFX_CIR_MIN_ADC_AMPLITUDE_ADDR: begin
        rdata_d0[AUDIO_WIDTH_P-1 : 0] <= sr_cir_min_adc_amplitude;
      end

      DAFX_CIR_MAX_ADC_AMPLITUDE_ADDR: begin
        rdata_d0[AUDIO_WIDTH_P-1 : 0] <= sr_cir_max_adc_amplitude;
      end

      DAFX_CIR_MIN_DAC_AMPLITUDE_ADDR: begin
        rdata_d0[AUDIO_WIDTH_P-1 : 0] <= sr_cir_min_dac_amplitude;
      end

      DAFX_CIR_MAX_DAC_AMPLITUDE_ADDR: begin
        rdata_d0[AUDIO_WIDTH_P-1 : 0] <= sr_cir_max_dac_amplitude;
      end


      default : rdata_d0 = 32'hBAADFACE;

    endcase
  end

endmodule
