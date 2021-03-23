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

#ifndef BYTE_VECTOR_H
#define BYTE_VECTOR_H

#include <stdint.h>

void     vector_append_int16        (uint8_t*       vector, int16_t  number, int32_t *index);
void     vector_append_uint16       (uint8_t*       vector, uint16_t number, int32_t *index);
void     vector_append_int32        (uint8_t*       vector, int32_t  number, int32_t *index);
void     vector_append_uint32       (uint8_t*       vector, uint32_t number, int32_t *index);
int16_t  vector_get_int16           (const uint8_t *vector, int32_t *index);
uint16_t vector_get_uint16          (const uint8_t *vector, int32_t *index);
int32_t  vector_get_int32           (const uint8_t *vector, int32_t *index);
uint32_t vector_get_uint32          (const uint8_t *vector, int32_t *index);

void     vector_append_float16      (uint8_t*       vector, float    number, float    scale, int32_t *index);
void     vector_append_float32      (uint8_t*       vector, float    number, float    scale, int32_t *index);
void     vector_append_float32_auto (uint8_t*       vector, float    number, int32_t *index);
float    vector_get_float16         (const uint8_t *vector, float    scale,  int32_t *index);
float    vector_get_float32         (const uint8_t *vector, float    scale,  int32_t *index);
float    vector_get_float32_auto    (const uint8_t *vector, int32_t *index);

#endif
