////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2020 Fredrik Åkerlund
// https://github.com/akerlund/PYRG
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

  #define DAFX_HIGH_ADDRESS          DAFX_PHYSICAL_ADDRESS_C + 0x0098
  #define HARDWARE_VERSION_ADDR      DAFX_PHYSICAL_ADDRESS_C + 0x0000
  #define MIXER_OUTPUT_GAIN_ADDR     DAFX_PHYSICAL_ADDRESS_C + 0x0008
  #define MIXER_CHANNEL_GAIN_0_ADDR  DAFX_PHYSICAL_ADDRESS_C + 0x0010
  #define MIXER_CHANNEL_GAIN_1_ADDR  DAFX_PHYSICAL_ADDRESS_C + 0x0018
  #define MIXER_CHANNEL_GAIN_2_ADDR  DAFX_PHYSICAL_ADDRESS_C + 0x0020
  #define MIXER_CHANNEL_GAIN_3_ADDR  DAFX_PHYSICAL_ADDRESS_C + 0x0028
  #define OSC0_WAVEFORM_SELECT_ADDR  DAFX_PHYSICAL_ADDRESS_C + 0x0030
  #define OSC0_FREQUENCY_ADDR        DAFX_PHYSICAL_ADDRESS_C + 0x0038
  #define OSC0_DUTY_CYCLE_ADDR       DAFX_PHYSICAL_ADDRESS_C + 0x0040
  #define CPU_LED_ADDR               DAFX_PHYSICAL_ADDRESS_C + 0x0048
  #define CIR_MIN_ADC_AMPLITUDE_ADDR DAFX_PHYSICAL_ADDRESS_C + 0x0050
  #define CIR_MAX_ADC_AMPLITUDE_ADDR DAFX_PHYSICAL_ADDRESS_C + 0x0058
  #define CIR_MIN_DAC_AMPLITUDE_ADDR DAFX_PHYSICAL_ADDRESS_C + 0x0060
  #define CIR_MAX_DAC_AMPLITUDE_ADDR DAFX_PHYSICAL_ADDRESS_C + 0x0068
  #define CLEAR_ADC_AMPLITUDE_ADDR   DAFX_PHYSICAL_ADDRESS_C + 0x0070
  #define CLEAR_IRQ_0_ADDR           DAFX_PHYSICAL_ADDRESS_C + 0x0078
  #define CLEAR_IRQ_1_ADDR           DAFX_PHYSICAL_ADDRESS_C + 0x0080
  #define MIX_OUT_LEFT_ADDR          DAFX_PHYSICAL_ADDRESS_C + 0x0088
  #define MIX_OUT_RIGHT_ADDR         DAFX_PHYSICAL_ADDRESS_C + 0x0090

#endif
