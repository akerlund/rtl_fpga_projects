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

#include <stdint.h>
#include <stdio.h>
#include "xil_printf.h"
#include "xscugic.h"
#include "xuartps.h"

#ifndef INIT_PS_H
#define INIT_PS_H

int32_t init_uart(uint16_t DeviceId);
int32_t init_interrupt();
int32_t init_irq_1();
void    irq_0_handler(void *InstancePtr);
void    irq_1_handler(void *InstancePtr);

#endif
