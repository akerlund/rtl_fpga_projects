#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xscugic.h"

XScuGic InterruptController;
static XScuGic_Config *GicConfig;

void nops(unsigned int num);

void ExtIrq_Handler(void *InstancePtr) {
  xil_printf("ExtIrq_Handler\r\n");
}

int SetUpInterruptSystem(XScuGic *XScuGicInstancePtr) {
  return XST_SUCCESS;
}

int interrupt_init() {

  int Status;

  GicConfig = XScuGic_LookupConfig(XPAR_PS7_SCUGIC_0_DEVICE_ID);
  if (NULL == GicConfig) {
    print("FAIL [irq] XScuGic_LookupConfig\n\r");
    return XST_FAILURE;
  }


  Status = XScuGic_CfgInitialize(&InterruptController, GicConfig, GicConfig->CpuBaseAddress);
  if (Status != XST_SUCCESS) {
    print("FAIL [irq] XScuGic_CfgInitialize\n\r");
    return XST_FAILURE;
  }

  Status = XScuGic_Connect(&InterruptController, XPAR_FABRIC_BD_PROJECT_TOP_0_IRQ_0_INTR, (Xil_ExceptionHandler)ExtIrq_Handler, (void *)NULL);
  if (Status != XST_SUCCESS) {
    print("FAIL [irq] XScuGic_Connect\n\r");
    return XST_FAILURE;
  }

  XScuGic_SetPriorityTriggerType(&InterruptController, XPAR_FABRIC_BD_PROJECT_TOP_0_IRQ_0_INTR, 0x8, 0x3);
  XScuGic_Enable(&InterruptController, XPAR_FABRIC_BD_PROJECT_TOP_0_IRQ_0_INTR);

  Xil_ExceptionInit();
  Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT, (Xil_ExceptionHandler) XScuGic_InterruptHandler, &InterruptController);
  Xil_ExceptionEnable();

  return XST_SUCCESS;
}


int main() {

  init_platform();

  print("Hello World\n\r");

  interrupt_init();

  while (1) {
  	nops(125000000);
    printf("nops\n\r");
  }

  cleanup_platform();
  return 0;
}

void nops(unsigned int num) {
  for(int i = 0; i < num; i++) {
    asm("nop");
  }
}
