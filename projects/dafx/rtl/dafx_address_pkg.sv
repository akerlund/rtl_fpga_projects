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

`ifndef DAFX_ADDRESS_PKG
`define DAFX_ADDRESS_PKG

package dafx_address_pkg;

  localparam logic [15 : 0] DAFX_HIGH_ADDRESS          = 16'h0088;
  localparam logic [15 : 0] HARDWARE_VERSION_ADDR      = 16'h0000;
  localparam logic [15 : 0] MIXER_OUTPUT_GAIN_ADDR     = 16'h0008;
  localparam logic [15 : 0] MIXER_CHANNEL_GAIN_0_ADDR  = 16'h0010;
  localparam logic [15 : 0] MIXER_CHANNEL_GAIN_1_ADDR  = 16'h0018;
  localparam logic [15 : 0] MIXER_CHANNEL_GAIN_2_ADDR  = 16'h0020;
  localparam logic [15 : 0] OSC0_WAVEFORM_SELECT_ADDR  = 16'h0028;
  localparam logic [15 : 0] OSC0_FREQUENCY_ADDR        = 16'h0030;
  localparam logic [15 : 0] OSC0_DUTY_CYCLE_ADDR       = 16'h0038;
  localparam logic [15 : 0] CIR_MIN_ADC_AMPLITUDE_ADDR = 16'h0040;
  localparam logic [15 : 0] CIR_MAX_ADC_AMPLITUDE_ADDR = 16'h0048;
  localparam logic [15 : 0] CIR_MIN_DAC_AMPLITUDE_ADDR = 16'h0050;
  localparam logic [15 : 0] CIR_MAX_DAC_AMPLITUDE_ADDR = 16'h0058;
  localparam logic [15 : 0] CLEAR_ADC_AMPLITUDE_ADDR   = 16'h0060;
  localparam logic [15 : 0] CLEAR_IRQ_0_ADDR           = 16'h0068;
  localparam logic [15 : 0] CLEAR_IRQ_1_ADDR           = 16'h0070;
  localparam logic [15 : 0] MIX_OUT_LEFT_ADDR          = 16'h0078;
  localparam logic [15 : 0] MIX_OUT_RIGHT_ADDR         = 16'h0080;

endpackage

`endif
