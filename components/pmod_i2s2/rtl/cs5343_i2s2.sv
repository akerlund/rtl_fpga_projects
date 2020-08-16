////////////////////////////////////////////////////////////////////////////////
//
// Original author: Arthur Brown, Digilent, 03/23/2018 01:23:15 PM
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
// This is a System Verilog version of Arthur's original work.
// AXI-Stream I2S controller intended for use with Pmod I2S2. Generates clocks
// and select signals required to place each of the ICs on the Pmod I2S2 into
// slave mode. Data is 24-bit, left aligned, shifted one serial clock right from
// the LRCK boundaries. This module only supports 44.1KHz sample rate, and
// expects the frequency of axis_clk to be approx 22.591MHz. At the end of each
// I2S frame, a 2-word packet is made available on the AXIS master interface.
// Further packets will be discarded until the current packet is accepted by an
// AXIS slave. Whenever a 2-word packet is received on the AXIS slave interface,
// it is transmitted over the I2S interface on the next frame. Each packet
// consists of two 3-byte words, starting with left audio channel data, followed
// by right channel data.
//
////////////////////////////////////////////////////////////////////////////////

`default_nettype none

module i2s2_cs5343 (

    input  wire           clk_mclk, // Required to be approximately 22.591MHz
    input  wire           rst_n,

    output logic          tx_mclk,
    output logic          tx_lrck,
    output logic          tx_sclk,
    output logic          tx_sdout,

    output logic          rx_mclk,
    output logic          rx_lrck,
    output logic          rx_sclk,
    input  wire           rx_sdin,

    input  wire  [31 : 0] tx_axis_s_data,
    input  wire           tx_axis_s_valid,
    output logic          tx_axis_s_ready,
    input  wire           tx_axis_s_last,

    output logic [31 : 0] rx_axis_m_data,
    output logic          rx_axis_m_valid,
    input  wire           rx_axis_m_ready,
    output logic          rx_axis_m_last
  );

  localparam int eof_count_c = 9'd455;

  logic [8 : 0] count;

  logic mclk;
  logic sclk;
  logic lrck;


  // AXIS SLAVE CONTROLLER
  logic [31 : 0] tx_data_l;
  logic [31 : 0] tx_data_r;

  // I2S TRANSMIT SHIFT REGISTERS
  logic [23 : 0] tx_data_l_shift;
  logic [23 : 0] tx_data_r_shift;

  // SYNCHRONIZE DATA IN TO AXIS CLOCK DOMAIN
  logic  [2 : 0] din_sync_shift;

  // I2S RECEIVE SHIFT REGISTERS
  logic [23 : 0] rx_data_l_shift;
  logic [23 : 0] rx_data_r_shift;

  // AXIS MASTER CONTROLLER
  logic [31 : 0] rx_data_l;
  logic [31 : 0] rx_data_r;

  //
  assign rx_axis_m_data = (rx_axis_m_last == 1'b1) ? rx_data_r : rx_data_l;

  // Assign internal clock signals
  assign mclk = clk_mclk;
  assign sclk = count[2];
  assign lrck = count[8];


  // Assign ports
  assign tx_lrck = lrck;
  assign tx_sclk = sclk;
  assign tx_mclk = mclk;

  assign rx_lrck = lrck;
  assign rx_sclk = sclk;
  assign rx_mclk = mclk;

  //
  always_ff @(posedge clk_mclk or negedge rst_n) begin
    if (!rst_n) begin
      count <= '0;
    end
    else begin
      count <= count + 1;
    end
  end

  //
  always_ff @(posedge clk_mclk or negedge rst_n) begin
    if (!rst_n) begin
      tx_data_l_shift <= '0;
      tx_data_r_shift <= '0;
      tx_sdout        <= '0;
    end
    else begin

      if (count == 3'b000000111) begin
        tx_data_l_shift <= tx_data_l[23 : 0];
        tx_data_r_shift <= tx_data_r[23 : 0];
      end
      else if (count[2 : 0] == 3'b111 && count[7 : 3] >= 5'd1 && count[7 : 3] <= 5'd24) begin
        if (count[8] == 1'b1) begin
          tx_data_r_shift <= {tx_data_r_shift[22 : 0], 1'b0};
        end
        else begin
          tx_data_l_shift <= {tx_data_l_shift[22 : 0], 1'b0};
        end
      end

      if (count[7 : 3] <= 5'd24 && count[7 : 3] >= 4'd1) begin
        if (count[8] == 1'b1) begin
          tx_sdout = tx_data_r_shift[23];
        end
        else begin
          tx_sdout = tx_data_l_shift[23];
        end
      end
      else begin
        tx_sdout = 1'b0;
      end

    end
  end

  // Data in synchronization
  always_ff @(posedge clk_mclk or negedge rst_n) begin
    if (!rst_n) begin
      din_sync_shift <= '0;
    end
    else begin
      din_sync_shift <= {din_sync_shift[1 : 0], rx_sdin};
    end
  end

  // Receive registers
  always_ff @(posedge clk_mclk or negedge rst_n) begin
    if (!rst_n) begin
      rx_data_r_shift <= '0;
      rx_data_l_shift <= '0;
    end
    else begin
      if (count[2 : 0] == 3'b011 && count[7 : 3] <= 5'd24 && count[7 : 3] >= 5'd1) begin
        if (lrck == 1'b1) begin
          rx_data_r_shift  <= {rx_data_r_shift, din_sync_shift[2]};
        end
        else begin
          rx_data_l_shift <= {rx_data_l_shift, din_sync_shift[2]};
        end
      end
    end
  end

  always_ff @(posedge clk_mclk or negedge rst_n) begin
    if (!rst_n) begin
      rx_data_l <= '0;
      rx_data_r <= '0;
    end else if (count == eof_count_c && rx_axis_m_valid == 1'b0) begin
      rx_data_l <= {8'b0, rx_data_l_shift};
      rx_data_r <= {8'b0, rx_data_r_shift};
    end
  end

  always_ff @(posedge clk_mclk or negedge rst_n) begin
    if (!rst_n) begin
      rx_axis_m_valid <= '0;
    end
    else if (count == eof_count_c && rx_axis_m_valid == 1'b0) begin
      rx_axis_m_valid <= 1'b1;
    end
    else if (rx_axis_m_valid == 1'b1 && rx_axis_m_ready == 1'b1 && rx_axis_m_last == 1'b1) begin
      rx_axis_m_valid <= 1'b0;
    end
  end

  always_ff @(posedge clk_mclk or negedge rst_n) begin
    if (!rst_n) begin
        rx_axis_m_last <= '0;
    end
    else begin
      if (count == eof_count_c && rx_axis_m_valid == 1'b0) begin
        rx_axis_m_last <= 1'b0;
      end
      else if (rx_axis_m_valid == 1'b1 && rx_axis_m_ready == 1'b1) begin
        rx_axis_m_last <= ~rx_axis_m_last;
      end
    end
  end

  // AXI4-S slave controller
  always_ff @(posedge clk_mclk or negedge rst_n) begin
    if (!rst_n) begin
      tx_axis_s_ready <= '0;
    end
    else begin
      // End of packet, cannot accept data until current one has been transmitted
      if (tx_axis_s_ready == 1'b1 && tx_axis_s_valid == 1'b1 && tx_axis_s_last == 1'b1) begin
        tx_axis_s_ready <= 1'b0;
      end
      // Beginning of I2S frame, in order to avoid tearing, cannot accept data until frame complete
      else if (count == 9'b0) begin
        tx_axis_s_ready <= 1'b0;
      end
      // End of I2S frame, can accept data
      else if (count == eof_count_c) begin
        tx_axis_s_ready <= 1'b1;
      end
    end
  end


  always_ff @(posedge clk_mclk or negedge rst_n) begin
    if (!rst_n) begin
      tx_data_r <= '0;
      tx_data_l <= '0;
    end
    else begin
      if (tx_axis_s_valid == 1'b1 && tx_axis_s_ready == 1'b1) begin
        if (tx_axis_s_last == 1'b1) begin
          tx_data_r <= tx_axis_s_data;
        end
        else begin
          tx_data_l <= tx_axis_s_data;
        end
      end
    end
  end

endmodule

`default_nettype wire
