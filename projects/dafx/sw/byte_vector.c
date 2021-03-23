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

#include "byte_vector.h"
#include <math.h>
#include <stdbool.h>

void vector_append_int16(uint8_t* vector, int16_t number, int32_t *index) {
  vector[(*index)++] = number >> 8;
  vector[(*index)++] = number;
}

void vector_append_uint16(uint8_t* vector, uint16_t number, int32_t *index) {
  vector[(*index)++] = number >> 8;
  vector[(*index)++] = number;
}

void vector_append_int32(uint8_t* vector, int32_t number, int32_t *index) {
  vector[(*index)++] = number >> 24;
  vector[(*index)++] = number >> 16;
  vector[(*index)++] = number >> 8;
  vector[(*index)++] = number;
}

void vector_append_uint32(uint8_t* vector, uint32_t number, int32_t *index) {
  vector[(*index)++] = number >> 24;
  vector[(*index)++] = number >> 16;
  vector[(*index)++] = number >> 8;
  vector[(*index)++] = number;
}

void vector_append_float16(uint8_t* vector, float number, float scale, int32_t *index) {
  vector_append_int16(vector, (int16_t)(number * scale), index);
}

void vector_append_float32(uint8_t* vector, float number, float scale, int32_t *index) {
  vector_append_int32(vector, (int32_t)(number * scale), index);
}

void vector_append_float32_auto(uint8_t* vector, float number, int32_t *index) {
  int      e       = 0;
  float    sig     = frexpf(number, &e);
  float    sig_abs = fabsf(sig);
  uint32_t sig_i   = 0;

  if (sig_abs >= 0.5) {
    sig_i = (uint32_t)((sig_abs - 0.5f) * 2.0f * 8388608.0f);
    e += 126;
  }

  uint32_t res = ((e & 0xFF) << 23) | (sig_i & 0x7FFFFF);
  if (sig < 0) {
    res |= 1U << 31;
  }

  vector_append_uint32(vector, res, index);
}

int16_t vector_get_int16(const uint8_t *vector, int32_t *index) {
  int16_t _int16 = ((uint16_t) vector[*index]) << 8 |
                   ((uint16_t) vector[*index + 1]);
  *index += 2;
  return _int16;
}

uint16_t vector_get_uint16(const uint8_t *vector, int32_t *index) {
  uint16_t _uint16 = ((uint16_t) vector[*index]) << 8 |
                     ((uint16_t) vector[*index + 1]);
  *index += 2;
  return _uint16;
}

int32_t vector_get_int32(const uint8_t *vector, int32_t *index) {
  int32_t _int32 = ((uint32_t) vector[*index])     << 24 |
                   ((uint32_t) vector[*index + 1]) << 16 |
                   ((uint32_t) vector[*index + 2]) << 8  |
                   ((uint32_t) vector[*index + 3]);
  *index += 4;
  return _int32;
}

uint32_t vector_get_uint32(const uint8_t *vector, int32_t *index) {
  uint32_t _uint32 = ((uint32_t) vector[*index])     << 24 |
                     ((uint32_t) vector[*index + 1]) << 16 |
                     ((uint32_t) vector[*index + 2]) << 8  |
                     ((uint32_t) vector[*index + 3]);
  *index += 4;
  return _uint32;
}

float vector_get_float16(const uint8_t *vector, float scale, int32_t *index) {
  return (float)vector_get_int16(vector, index) / scale;
}

float vector_get_float32(const uint8_t *vector, float scale, int32_t *index) {
  return (float)vector_get_int32(vector, index) / scale;
}

float vector_get_float32_auto(const uint8_t *vector, int32_t *index) {

  uint32_t res = vector_get_uint32(vector, index);
  int32_t  e     = (res >> 23) & 0xFF;
  uint32_t sig_i = res & 0x7FFFFF;
  bool     neg   = res & (1U << 31);
  float    sig   = 0.0;

  if (e != 0 || sig_i != 0) {
    sig = (float)sig_i / (8388608.0 * 2.0) + 0.5;
    e -= 126;
  }

  if (neg) {
    sig = -sig;
  }

  return ldexpf(sig, e);
}
