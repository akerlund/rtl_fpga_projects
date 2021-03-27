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

#include "init_ps.h"

// IRQ
XScuGic InterruptController;
static XScuGic_Config *gic_config;

// Uart
XUartPs Uart_PS;
uint8_t irq_0_triggered;
uint8_t irq_1_triggered;


void irq_0_handler(void *InstancePtr) {
  if (!irq_0_triggered) {
    irq_0_triggered = 1;
  }
}

void irq_1_handler(void *InstancePtr) {
  irq_1_triggered = 1;
}


int32_t init_interrupt() {

  int32_t status;
  xil_printf("%cINFO [irq] Initializing\n", STR_C);

  gic_config = XScuGic_LookupConfig(XPAR_PS7_SCUGIC_0_DEVICE_ID);
  if (NULL == gic_config) {
    xil_printf("%sFAIL [irq] XScuGic_LookupConfig\n", STR_C);
    return XST_FAILURE;
  } else {
    xil_printf("%cINFO [irq] XScuGic_LookupConfig\n", STR_C);
  }


  status = XScuGic_CfgInitialize(&InterruptController, gic_config, gic_config->CpuBaseAddress);
  if (status != XST_SUCCESS) {
    xil_printf("%sFAIL [irq] XScuGic_CfgInitialize\n", STR_C);
    return XST_FAILURE;
  } else {
    xil_printf("%cINFO [irq] XScuGic_LookupConfig\n", STR_C);
  }

  status = XScuGic_Connect(&InterruptController, XPAR_FABRIC_BD_PROJECT_TOP_0_IRQ_0_INTR, (Xil_ExceptionHandler)irq_0_handler, (void *)NULL);
  if (status != XST_SUCCESS) {
    xil_printf("%sFAIL [irq] XScuGic_Connect\n", STR_C);
    return XST_FAILURE;
  } else {
    xil_printf("%cINFO [irq] XScuGic_LookupConfig\n", STR_C);
  }

  xil_printf("%cINFO [irq] XScuGic_SetPriorityTriggerType\n", STR_C);
  XScuGic_SetPriorityTriggerType(&InterruptController, XPAR_FABRIC_BD_PROJECT_TOP_0_IRQ_0_INTR, 0x8, 0x3);
  xil_printf("%cINFO [irq] XScuGic_Enable\n", STR_C);
  XScuGic_Enable(&InterruptController, XPAR_FABRIC_BD_PROJECT_TOP_0_IRQ_0_INTR);
  //status = init_irq_1();

  xil_printf("%sINFO [irq] Init Exceptions\n", STR_C);
  Xil_ExceptionInit();
  Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT, (Xil_ExceptionHandler) XScuGic_InterruptHandler, &InterruptController);
  Xil_ExceptionEnable();

  if (status != XST_SUCCESS) {
    xil_printf("%cERROR [irq] IRQ Initialization Failed\n", STR_C);
    return XST_FAILURE;
  } else {
    xil_printf("%cINFO [irq] IRQ Operational\n", STR_C);
  }

  return XST_SUCCESS;
}

int32_t init_irq_1() {

  int32_t status;

  status = XScuGic_Connect(&InterruptController, XPAR_FABRIC_BD_PROJECT_TOP_0_IRQ_1_INTR, (Xil_ExceptionHandler)irq_1_handler, (void *)NULL);
  if (status != XST_SUCCESS) {
    xil_printf("%sFAIL [irq_1] XScuGic_Connect\n", STR_C);
    return XST_FAILURE;
  }
  XScuGic_SetPriorityTriggerType(&InterruptController, XPAR_FABRIC_BD_PROJECT_TOP_0_IRQ_1_INTR, 0x8, 0x3);
  XScuGic_Enable(&InterruptController, XPAR_FABRIC_BD_PROJECT_TOP_0_IRQ_1_INTR);

  xil_printf("%sINFO [irq_1] Init complete\n", STR_C);
  return XST_SUCCESS;
}

int32_t init_uart(uint16_t DeviceId){

  xil_printf("%cINFO [uart] Initializing\n", STR_C);
  int32_t         status;
  XUartPs_Config *config;

  config = XUartPs_LookupConfig(DeviceId);
  if (NULL == config) {
    xil_printf("%sFAIL [irq] XUartPs_LookupConfig\n", STR_C);
    return XST_FAILURE;
  }

  status = XUartPs_CfgInitialize(&Uart_PS, config, config->BaseAddress);
  if (status != XST_SUCCESS) {
    xil_printf("%sFAIL [irq] XUartPs_CfgInitialize\n", STR_C);
    return XST_FAILURE;
  }

  status = XUartPs_SelfTest(&Uart_PS);
  if (status != XST_SUCCESS) {
    xil_printf("%sFAIL [irq] XUartPs_SelfTest\n", STR_C);
    return XST_FAILURE;
  }

  XUartPs_SetOperMode(&Uart_PS, XUARTPS_OPER_MODE_NORMAL);

  if (status != XST_SUCCESS) {
    xil_printf("%cERROR [uart] UART Initialization Failed\n", STR_C);
    return XST_FAILURE;
  } else {
    xil_printf("%cINFO [uart] UART Operational\n", STR_C);
  }

  return XST_SUCCESS;
}
