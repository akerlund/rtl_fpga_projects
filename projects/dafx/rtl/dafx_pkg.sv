////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2021 Fredrik Åkerlund
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

package dafx_pkg;

  localparam int MC_ID_WIDTH_C    = 6;
  localparam int MC_ADDR_WIDTH_C  = 32;
  localparam int MC_DATA_WIDTH_C  = 128;

  localparam int CFG_ID_WIDTH_C   = 6;
  localparam int CFG_ADDR_WIDTH_C = 16;
  localparam int CFG_DATA_WIDTH_C = 64;
  localparam int CFG_STRB_WIDTH_C = 8;

  localparam int AXI_ID_WIDTH_C   = 32;
  localparam int AXI_ADDR_WIDTH_C = 7;
  localparam int AXI_DATA_WIDTH_C = 32;
  localparam int AXI_STRB_WIDTH_C = AXI_DATA_WIDTH_C/8;

  // Common
  localparam int            SYS_CLK_FREQUENCY_C   = 125000000;
  localparam logic [63 : 0] SR_HARDWARE_VERSION_C = 2012;
  localparam int            NR_OF_MASTERS_C       = 2;
  localparam int            AUDIO_WIDTH_C         = 24;
  localparam int            GAIN_WIDTH_C          = 24;
  localparam int            NR_OF_CHANNELS_C      = 3;

  // Sampling
  localparam int HOST_F_SAMPLING_C      = 10000;
  localparam int SAMPLING_IRQ_COUNTER_C = SYS_CLK_FREQUENCY_C / HOST_F_SAMPLING_C;

  // Oscillator
  localparam int PRIME_FREQUENCY_C    = 1000000;
  localparam int WAVE_WIDTH_C         = 24;
  localparam int DUTY_CYCLE_DIVIDER_C = 1000;
  localparam int N_BITS_C             = 32;
  localparam int Q_BITS_C             = 11;
  localparam int AXI_ID_C             = 32'hDEADBEA7;

endpackage
