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

#ifndef CFG_ADDR_MAP_H
#define CFG_ADDR_MAP_H

// AXI addresses to the FPGA
#define FPGA_BASEADDR           0x43C00000

#define LED_0_ADDR              0  // 0
#define IRQ_CLEAR_ADDR          4  // 1
#define MIX_OUTPUT_GAIN         8  // 2
#define MIX_CHANNEL_GAIN_0      12 // 3
#define MIX_CHANNEL_GAIN_1      16 // 4
#define CIR_CLEAR_MAX           20 // 5
#define CIR_MAX_AMPLITUDE       24 // 6
#define CIR_MIN_AMPLITUDE       28 // 7
#define CR_OSC0_WAVEFORM_SELECT 32 // 8
#define CR_OSC0_FREQUENCY       36 // 9
#define CR_OSC0_DUTY_CYCLE      40 // 10



#endif
