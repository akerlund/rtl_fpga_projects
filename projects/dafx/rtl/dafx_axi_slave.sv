////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2020 Fredrik Åkerlund
// https://github.com/akerlund/PYRG
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
    parameter int AUDIO_WIDTH_C = -1,
    parameter int AXI_ADDR_WIDTH_P = -1,
    parameter int AXI_DATA_WIDTH_P = -1,
    parameter int GAIN_WIDTH_C = -1,
    parameter int N_BITS_C = -1,
    parameter int Q_BITS_C = -1
  )(
    axi4_reg_if.slave cif,
    input  wire                     [63 : 0] sr_hardware_version,
    output logic        [GAIN_WIDTH_C-1 : 0] cr_mix_output_gain,
    output logic [3 : 0][GAIN_WIDTH_C-1 : 0] cr_mix_channel_gain,
    output logic                     [1 : 0] cr_osc0_waveform_select,
    output logic            [N_BITS_C-1 : 0] cr_osc0_frequency,
    output logic            [N_BITS_C-1 : 0] cr_osc0_duty_cycle,
    output logic                             cr_cpu_led0,
    output logic                             cr_cpu_led1,
    input  wire        [AUDIO_WIDTH_C-1 : 0] sr_cir_min_adc_amplitude,
    input  wire        [AUDIO_WIDTH_C-1 : 0] sr_cir_max_adc_amplitude,
    input  wire        [AUDIO_WIDTH_C-1 : 0] sr_cir_min_dac_amplitude,
    input  wire        [AUDIO_WIDTH_C-1 : 0] sr_cir_max_dac_amplitude,
    output logic                             cmd_clear_adc_amplitude,
    output logic                             cmd_clear_irq_0,
    output logic                             cmd_clear_irq_1,
    input  wire        [AUDIO_WIDTH_C-1 : 0] sr_mix_out_left,
    input  wire        [AUDIO_WIDTH_C-1 : 0] sr_mix_out_right
  );

  // Response codes
  localparam logic [1 : 0] AXI_RESP_OK_C     = 2'b00;
  localparam logic [1 : 0] AXI_RESP_EXOK_C   = 2'b01;
  localparam logic [1 : 0] AXI_RESP_SLVERR_C = 2'b10;
  localparam logic [1 : 0] AXI_RESP_DECERR_C = 2'b11;

  // ---------------------------------------------------------------------------
  // Internal signals
  // ---------------------------------------------------------------------------

  typedef enum {
    WAIT_MST_AWVALID_E,
    WAIT_FOR_BREADY_E,
    WAIT_MST_WLAST_E
  } write_state_t;

  write_state_t write_state;

  logic [AXI_ADDR_WIDTH_P-1 : 0] awaddr_r0;

  typedef enum {
    WAIT_MST_ARVALID_E,
    WAIT_SLV_RLAST_E
  } read_state_t;

  read_state_t read_state;

  logic [AXI_ADDR_WIDTH_P-1 : 0] araddr_r0;
  logic                  [7 : 0] arlen_c0;
  logic                  [7 : 0] arlen_r0;
  logic [AXI_DATA_WIDTH_P-1 : 0] rdata_c0;
  logic                  [1 : 0] rresp_c0;





  // ---------------------------------------------------------------------------
  // Write processes
  // ---------------------------------------------------------------------------
  always_ff @(posedge cif.clk or negedge cif.rst_n) begin
    if (!cif.rst_n) begin

      write_state <= WAIT_MST_AWVALID_E;
      awaddr_r0   <= '0;
      cif.awready <= '0;
      cif.wready  <= '0;
      cif.bid     <= '0;
      cif.bvalid  <= '0;
      cif.bresp   <= '0;
      cr_mix_output_gain      <= 1<<Q_BITS_C;
      cr_mix_channel_gain[0]  <= 1<<Q_BITS_C;
      cr_mix_channel_gain[1]  <= 1<<Q_BITS_C;
      cr_mix_channel_gain[2]  <= 1<<Q_BITS_C;
      cr_mix_channel_gain[3]  <= 1<<Q_BITS_C;
      cr_osc0_waveform_select <= 0;
      cr_osc0_frequency       <= 500<<Q_BITS_C;
      cr_osc0_duty_cycle      <= 500;
      cr_cpu_led0             <= 0;
      cr_cpu_led1             <= 0;
      cmd_clear_irq_0         <= 0;
      cmd_clear_irq_1         <= 0;

    end
    else begin

      cmd_clear_adc_amplitude <= '0;
      cmd_clear_irq_0         <= '0;
      cmd_clear_irq_1         <= '0;



      case (write_state)

        default: begin
          write_state <= WAIT_MST_AWVALID_E;
        end

        WAIT_MST_AWVALID_E: begin

          cif.awready <= '1;

          if (cif.awvalid && cif.awready) begin
            write_state <= WAIT_MST_WLAST_E;
            cif.awready <= '0;
            cif.bid     <= cif.awid;
            awaddr_r0   <= cif.awaddr;
            cif.wready  <= '1;
          end

        end


        WAIT_FOR_BREADY_E: begin

          if (cif.bvalid && cif.bready) begin
            write_state <= WAIT_MST_AWVALID_E;
            cif.awready <= '1;
            cif.bvalid  <= '0;
            cif.bresp   <= '0;
          end

        end


        WAIT_MST_WLAST_E: begin

          if (cif.wlast && cif.wvalid) begin
            write_state <= WAIT_FOR_BREADY_E;
            cif.bvalid  <= '1;
            cif.wready  <= '0;
          end


          if (cif.wvalid) begin

            awaddr_r0 <= awaddr_r0 + (AXI_DATA_WIDTH_P/8);

            case (awaddr_r0)

              MIXER_OUTPUT_GAIN_ADDR: begin
                cr_mix_output_gain <= cif.wdata[GAIN_WIDTH_C-1 : 0];
              end

              MIXER_CHANNEL_GAIN_0_ADDR: begin
                cr_mix_channel_gain[0] <= cif.wdata[GAIN_WIDTH_C-1 : 0];
              end

              MIXER_CHANNEL_GAIN_1_ADDR: begin
                cr_mix_channel_gain[1] <= cif.wdata[GAIN_WIDTH_C-1 : 0];
              end

              MIXER_CHANNEL_GAIN_2_ADDR: begin
                cr_mix_channel_gain[2] <= cif.wdata[GAIN_WIDTH_C-1 : 0];
              end

              MIXER_CHANNEL_GAIN_3_ADDR: begin
                cr_mix_channel_gain[3] <= cif.wdata[GAIN_WIDTH_C-1 : 0];
              end

              OSC0_WAVEFORM_SELECT_ADDR: begin
                cr_osc0_waveform_select <= cif.wdata[1 : 0];
              end

              OSC0_FREQUENCY_ADDR: begin
                cr_osc0_frequency <= cif.wdata[N_BITS_C-1 : 0];
              end

              OSC0_DUTY_CYCLE_ADDR: begin
                cr_osc0_duty_cycle <= cif.wdata[N_BITS_C-1 : 0];
              end

              CPU_LED_ADDR: begin
                cr_cpu_led0 <= cif.wdata[0];
                cr_cpu_led1 <= cif.wdata[1];
              end

              CLEAR_ADC_AMPLITUDE_ADDR: begin
                cmd_clear_adc_amplitude <= cif.wdata[0];
              end

              CLEAR_IRQ_0_ADDR: begin
                cmd_clear_irq_0 <= cif.wdata[0];
              end

              CLEAR_IRQ_1_ADDR: begin
                cmd_clear_irq_1 <= cif.wdata[0];
              end


              default: begin
                cif.bresp <= AXI_RESP_SLVERR_C;
              end

            endcase


          end
        end
      endcase
    end
  end

  // ---------------------------------------------------------------------------
  // Read process
  // ---------------------------------------------------------------------------

  assign cif.rlast = cif.rvalid && arlen_r0 == '0;



  always_comb begin
    arlen_c0 = arlen_r0;

    case (read_state)
      WAIT_MST_ARVALID_E: begin
        if (cif.arvalid && cif.arready) begin
          arlen_c0 = cif.arlen;
        end
      end

      WAIT_SLV_RLAST_E: begin
        if (cif.rready && cif.rvalid) begin
          if (arlen_r0 != '0) begin
            arlen_c0 = arlen_r0 - 1;
          end
        end
      end
    endcase
  end


  // FSM
  always_ff @(posedge cif.clk or negedge cif.rst_n) begin
    if (!cif.rst_n) begin

      read_state  <= WAIT_MST_ARVALID_E;
      cif.arready <= '0;
      araddr_r0   <= '0;
      arlen_r0    <= '0;
      cif.rid     <= '0;
      cif.rdata   <= '0;
      cif.rresp   <= '0;
      cif.rvalid  <= '0;

    end
    else begin


      arlen_r0 <= arlen_c0;

      case (read_state)

        default: begin
          read_state <= WAIT_MST_ARVALID_E;
        end

        WAIT_MST_ARVALID_E: begin

          cif.arready <= '1;

          if (cif.arvalid && cif.arready) begin
            read_state  <= WAIT_SLV_RLAST_E;
            araddr_r0   <= cif.araddr;
            cif.rid     <= cif.arid;
            cif.arready <= '0;


          end

        end

        WAIT_SLV_RLAST_E: begin

          cif.rvalid <= '1;
          cif.rdata  <= rdata_c0;
          cif.rresp  <= rresp_c0;

          if (cif.rready && cif.rvalid) begin
            araddr_r0 <= araddr_r0 + (AXI_DATA_WIDTH_P/8);
          end

          if (cif.rvalid && cif.rready && cif.rlast) begin
            read_state  <= WAIT_MST_ARVALID_E;
            cif.arready <= '1;
            cif.rvalid  <= '0;
          end



        end
      endcase
    end
  end



  always_comb begin

    rdata_c0 = '0;
    rresp_c0 = '0;


    case (araddr_r0)

      HARDWARE_VERSION_ADDR: begin
        rdata_c0[63 : 0] = sr_hardware_version;
      end

      MIXER_OUTPUT_GAIN_ADDR: begin
        rdata_c0[GAIN_WIDTH_C-1 : 0] = cr_mix_output_gain;
      end

      MIXER_CHANNEL_GAIN_0_ADDR: begin
        rdata_c0[GAIN_WIDTH_C-1 : 0] = cr_mix_channel_gain[0];
      end

      MIXER_CHANNEL_GAIN_1_ADDR: begin
        rdata_c0[GAIN_WIDTH_C-1 : 0] = cr_mix_channel_gain[1];
      end

      MIXER_CHANNEL_GAIN_2_ADDR: begin
        rdata_c0[GAIN_WIDTH_C-1 : 0] = cr_mix_channel_gain[2];
      end

      MIXER_CHANNEL_GAIN_3_ADDR: begin
        rdata_c0[GAIN_WIDTH_C-1 : 0] = cr_mix_channel_gain[3];
      end

      OSC0_WAVEFORM_SELECT_ADDR: begin
        rdata_c0[1 : 0] = cr_osc0_waveform_select;
      end

      OSC0_FREQUENCY_ADDR: begin
        rdata_c0[N_BITS_C-1 : 0] = cr_osc0_frequency;
      end

      OSC0_DUTY_CYCLE_ADDR: begin
        rdata_c0[N_BITS_C-1 : 0] = cr_osc0_duty_cycle;
      end

      CPU_LED_ADDR: begin
        rdata_c0[0] = cr_cpu_led0;
        rdata_c0[1] = cr_cpu_led1;
      end

      CIR_MIN_ADC_AMPLITUDE_ADDR: begin
        rdata_c0[AUDIO_WIDTH_C-1 : 0] = sr_cir_min_adc_amplitude;
      end

      CIR_MAX_ADC_AMPLITUDE_ADDR: begin
        rdata_c0[AUDIO_WIDTH_C-1 : 0] = sr_cir_max_adc_amplitude;
      end

      CIR_MIN_DAC_AMPLITUDE_ADDR: begin
        rdata_c0[AUDIO_WIDTH_C-1 : 0] = sr_cir_min_dac_amplitude;
      end

      CIR_MAX_DAC_AMPLITUDE_ADDR: begin
        rdata_c0[AUDIO_WIDTH_C-1 : 0] = sr_cir_max_dac_amplitude;
      end

      MIX_OUT_LEFT_ADDR: begin
        rdata_c0[AUDIO_WIDTH_C-1 : 0] = sr_mix_out_left;
      end

      MIX_OUT_RIGHT_ADDR: begin
        rdata_c0[AUDIO_WIDTH_C-1 : 0] = sr_mix_out_right;
      end


      default: begin
        rresp_c0 = AXI_RESP_SLVERR_C;
        rdata_c0 = '0;
      end

    endcase
  end

  // Read Clear retiming
  always_ff @(posedge cif.clk or negedge cif.rst_n) begin
    if (!cif.rst_n) begin

    end
    else begin

    end
  end

endmodule
