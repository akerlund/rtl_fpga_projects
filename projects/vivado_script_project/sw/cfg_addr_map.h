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

#ifndef CFG_ADDR_MAP_H
#define CFG_ADDR_MAP_H

// AXI addresses to the FPGA
#define FPGA_BASEADDR          0x43C00000
#define CR_LED_0_ADDR          0
#define CR_AXI_ADDRESS_ADDR    4
#define CR_WDATA_ADDR          8
#define CMD_MC_AXI4_WRITE_ADDR 12
#define CMD_MC_AXI4_READ_ADDR  16
#define SR_LED_COUNTER_ADDR    20
#define SR_MC_AXI4_RDATA_ADDR  24
#define SR_HW_VERSION_ADDR     28

#endif
