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
`ifndef DAFX_ADDRESS_PKG
`define DAFX_ADDRESS_PKG

package dafx_address_pkg;

  localparam logic [31 : 0] DAFX_HIGH_ADDRESS               = 32'h003C;
  localparam logic [31 : 0] DAFX_HARDWARE_VERSION_ADDR      = 32'h0000;
  localparam logic [31 : 0] DAFX_MIXER_OUTPUT_GAIN_ADDR     = 32'h0004;
  localparam logic [31 : 0] DAFX_MIXER_CHANNEL_GAIN_0_ADDR  = 32'h0008;
  localparam logic [31 : 0] DAFX_MIXER_CHANNEL_GAIN_1_ADDR  = 32'h000C;
  localparam logic [31 : 0] DAFX_MIXER_CHANNEL_GAIN_2_ADDR  = 32'h0010;
  localparam logic [31 : 0] DAFX_OSC0_WAVEFORM_SELECT_ADDR  = 32'h0014;
  localparam logic [31 : 0] DAFX_OSC0_FREQUENCY_ADDR        = 32'h0018;
  localparam logic [31 : 0] DAFX_OSC0_DUTY_CYCLE_ADDR       = 32'h001C;
  localparam logic [31 : 0] DAFX_CIR_MIN_ADC_AMPLITUDE_ADDR = 32'h0020;
  localparam logic [31 : 0] DAFX_CIR_MAX_ADC_AMPLITUDE_ADDR = 32'h0024;
  localparam logic [31 : 0] DAFX_CIR_MIN_DAC_AMPLITUDE_ADDR = 32'h0028;
  localparam logic [31 : 0] DAFX_CIR_MAX_DAC_AMPLITUDE_ADDR = 32'h002C;
  localparam logic [31 : 0] DAFX_CLEAR_ADC_AMPLITUDE_ADDR   = 32'h0030;
  localparam logic [31 : 0] DAFX_CLEAR_IRQ_0_ADDR           = 32'h0034;
  localparam logic [31 : 0] DAFX_CLEAR_IRQ_1_ADDR           = 32'h0038;

endpackage

`endif
