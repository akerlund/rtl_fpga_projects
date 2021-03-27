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
#ifndef BASE_ADDRESSES_H
#define BASE_ADDRESSES_H

  // Physical Address of the FPGA's AXI Configuration Bus
  #define CFG_BASE_ADDR_C  0x000000000

  // Base Addresses of the Slaves
  #define DAFX_BASE_ADDRESS_C  0x000000

  // Physical Addresses for Users
  #define DAFX_PHYSICAL_ADDRESS_C (CFG_BASE_ADDR_C + DAFX_BASE_ADDRESS_C)

#endif