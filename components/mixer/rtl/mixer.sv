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

module mixer #(
    parameter int AUDIO_WIDTH_P    = -1,
    parameter int GAIN_WIDTH_P     = -1,
    parameter int NR_OF_CHANNELS_P = -1,
    parameter int Q_BITS_P         = -1
  )(
    // Clock and reset
    input  wire                                                       clk,
    input  wire                                                       rst_n,

    // Ingress
    input  wire signed [NR_OF_CHANNELS_P-1 : 0] [AUDIO_WIDTH_P-1 : 0] channel_data,
    input  wire                              [NR_OF_CHANNELS_P-1 : 0] channel_valid,

    // Egress
    output logic signed                         [AUDIO_WIDTH_P-1 : 0] mixed_data,
    output logic                                                      mixed_valid,
    input  wire                                                       mixed_ready,

    // Configuration
    input  wire         [NR_OF_CHANNELS_P-1 : 0] [GAIN_WIDTH_P-1 : 0] cr_channel_gain,
    input  wire                                  [GAIN_WIDTH_P-1 : 0] cr_output_gain
  );

  logic signed [NR_OF_CHANNELS_P-1 : 0] [AUDIO_WIDTH_P-1 : 0] channel_products;
  logic signed                          [AUDIO_WIDTH_P-1 : 0] mixed_data_r0;

  // Input stage
  always_ff @(posedge clk or negedge rst_n) begin : channel_input_p0
    if (!rst_n) begin
      channel_products <= '0;
    end
    else begin
      for (int i = 0; i < NR_OF_CHANNELS_P; i++) begin
        if (channel_valid[i]) begin
          channel_products[i] <= $signed(channel_data[i]) * cr_output_gain[i];
        end
      end
    end
  end

  // Output stage
  always_ff @(posedge clk or negedge rst_n) begin : mixer_output_p0
    if (!rst_n) begin
      mixed_valid   <= '0;
      mixed_data    <= '0;
      mixed_data_r0 <= '0;
    end
    else begin

      for (int i = 0; i < NR_OF_CHANNELS_P; i++) begin
        mixed_data_r0 <= mixed_data + (channel_products[i] >> Q_BITS_P);
      end

      if (mixed_ready && !mixed_valid) begin
        mixed_data  <= (mixed_data_r0 * cr_output_gain) >> Q_BITS_P;
        mixed_valid <= '1;
      end
      else if (mixed_valid) begin
        mixed_valid <= '0;
      end

    end
  end

endmodule

`default_nettype wire
