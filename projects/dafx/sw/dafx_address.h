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
#ifndef DAFX_ADDRESS_H
#define DAFX_ADDRESS_H

  #define DAFX_HIGH_ADDRESS               0x0044
  #define DAFX_HARDWARE_VERSION_ADDR      0x0000
  #define DAFX_MIXER_OUTPUT_GAIN_ADDR     0x0004
  #define DAFX_MIXER_CHANNEL_GAIN_0_ADDR  0x0008
  #define DAFX_MIXER_CHANNEL_GAIN_1_ADDR  0x000C
  #define DAFX_MIXER_CHANNEL_GAIN_2_ADDR  0x0010
  #define DAFX_OSC0_WAVEFORM_SELECT_ADDR  0x0014
  #define DAFX_OSC0_FREQUENCY_ADDR        0x0018
  #define DAFX_OSC0_DUTY_CYCLE_ADDR       0x001C
  #define DAFX_CIR_MIN_ADC_AMPLITUDE_ADDR 0x0020
  #define DAFX_CIR_MAX_ADC_AMPLITUDE_ADDR 0x0024
  #define DAFX_CIR_MIN_DAC_AMPLITUDE_ADDR 0x0028
  #define DAFX_CIR_MAX_DAC_AMPLITUDE_ADDR 0x002C
  #define DAFX_CLEAR_ADC_AMPLITUDE_ADDR   0x0030
  #define DAFX_CLEAR_IRQ_0_ADDR           0x0034
  #define DAFX_CLEAR_IRQ_1_ADDR           0x0038
  #define DAFX_MIX_OUT_LEFT_ADDR          0x003C
  #define DAFX_MIX_OUT_RIGHT_ADDR         0x0040

#endif
