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
#ifndef QHOST_DEFINES_H
#define QHOST_DEFINES_H

  #define LENGTH_8_BITS_C      0xAA
  #define LENGTH_16_BITS_C     0x55
  #define CRC_ENABLED_BIT_C    0x80
  #define STRING_C             0x50
  #define SAMPLE_MIXER_LEFT_C  0x51
  #define SAMPLE_MIXER_RIGHT_C 0x52

  #define CRC_C     CRC_ENABLED_BIT_C
  #define STR_C     STRING_C
  #define CRC_STR_C CRC_ENABLED_BIT_C | STRING_C

#endif
