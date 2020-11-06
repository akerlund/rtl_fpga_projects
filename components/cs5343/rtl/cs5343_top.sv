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

module cs5343_top (

  input  wire           clk,
  input  wire           rst_n,

  output logic          cs_tx_mclk,
  output logic          cs_tx_lrck,
  output logic          cs_tx_sclk,
  output logic          cs_tx_sdout,

  output logic          cs_rx_mclk,
  output logic          cs_rx_lrck,
  output logic          cs_rx_sclk,
  input  wire           cs_rx_sdin,

  output logic [23 : 0] adc_data,
  output logic          adc_valid,
  input  wire           adc_ready,
  output logic          adc_last,

  input  wire  [23 : 0] dac_data,
  input  wire           dac_valid,
  output logic          dac_ready,
  input  wire           dac_last
);

  logic clk_mclk;
  logic rst_mclk_n;

  logic [23 : 0] mclk_dac_data;
  logic          mclk_dac_valid;
  logic          mclk_dac_ready;
  logic          mclk_dac_last;

  logic [23 : 0] mclk_adc_data;
  logic          mclk_adc_valid;
  logic          mclk_adc_ready;
  logic          mclk_adc_last;


  // -------------------------------------------------------------------------
  // PLL for the Cirrus ICs
  // -------------------------------------------------------------------------
  car_cs5343 car_cs5343_i0 (
    .clk        ( clk        ), // input
    .rst_n      ( rst_n      ), // input
    .clk_mclk   ( clk_mclk   ), // output
    .rst_mclk_n ( rst_mclk_n )  // output
  );

  // -------------------------------------------------------------------------
  // Cirrus CS5343 ADC, CS4344 DAC
  // -------------------------------------------------------------------------
  cs5343_i2s2 cs5343_i2s2_i0 (

    // Clock and reset
    .clk_mclk        ( clk_mclk       ), // input
    .rst_n           ( rst_mclk_n     ), // input

    // I/O Cirrus CS5343 (DAC)
    .tx_mclk         ( cs_tx_mclk     ), // output
    .tx_lrck         ( cs_tx_lrck     ), // output
    .tx_sclk         ( cs_tx_sclk     ), // output
    .tx_sdout        ( cs_tx_sdout    ), // output

    // I/O Cirrus CS4344 (ADC)
    .rx_mclk         ( cs_rx_mclk     ), // output
    .rx_lrck         ( cs_rx_lrck     ), // output
    .rx_sclk         ( cs_rx_sclk     ), // output
    .rx_sdin         ( cs_rx_sdin     ), // input

    // AXI-S ADC
    .rx_axis_m_data  ( mclk_adc_data  ), // output
    .rx_axis_m_valid ( mclk_adc_valid ), // output
    .rx_axis_m_ready ( mclk_adc_ready ), // input
    .rx_axis_m_last  ( mclk_adc_last  ), // output

    // AXI-S DAC
    .tx_axis_s_data  ( mclk_dac_data  ), // input
    .tx_axis_s_valid ( mclk_dac_valid ), // input
    .tx_axis_s_ready ( mclk_dac_ready ), // output
    .tx_axis_s_last  ( mclk_dac_last  )  // input
  );


  // -------------------------------------------------------------------------
  // CDC: Cirrus ADC to System clock
  // -------------------------------------------------------------------------
  cdc_vector_sync #(
    .DATA_WIDTH_P ( 25                             )
  ) cdc_vector_sync_i0 (

    // Clock and reset (Source)
    .clk_src      ( clk_mclk                       ), // input
    .rst_src_n    ( rst_mclk_n                     ), // input

    // Clock and reset (Destination)
    .clk_dst      ( clk                            ), // input
    .rst_dst_n    ( rst_n                          ), // input

    // Data (Source)
    .ing_vector   ( {mclk_adc_last, mclk_adc_data} ), // input
    .ing_valid    ( mclk_adc_valid                 ), // input
    .ing_ready    ( mclk_adc_ready                 ), // output

    // Data (Destination)
    .egr_vector   ( {cs_adc_last, cs_adc_data}      ), // output
    .egr_valid    ( cs_adc_valid                    ), // output
    .egr_ready    ( cs_adc_ready                    )  // input
  );


  // -------------------------------------------------------------------------
  // CDC: System clock to Cirrus DAC
  // -------------------------------------------------------------------------
  cdc_vector_sync #(
    .DATA_WIDTH_P ( 25                             )
  ) cdc_vector_sync_i1 (

    // Clock and reset (Source)
    .clk_src      ( clk                            ), // input
    .rst_src_n    ( rst_n                          ), // input

    // Clock and reset (Destination)
    .clk_dst      ( clk_mclk                       ), // input
    .rst_dst_n    ( rst_mclk_n                     ), // input

    // Data (Source)
    .ing_vector   ( {dac_last, dac_data}           ), // input
    .ing_valid    ( dac_valid                      ), // input
    .ing_ready    ( dac_ready                      ), // output

    // Data (Destination)
    .egr_vector   ( {mclk_dac_last, mclk_dac_data} ), // output
    .egr_valid    ( mclk_dac_valid                 ), // output
    .egr_ready    ( mclk_dac_ready                 )  // input
  );


endmodule

`default_nettype wire
