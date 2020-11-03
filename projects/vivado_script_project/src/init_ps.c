#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xscugic.h"
#include "xuartps.h"


int  UartPsPolledExample(u16 DeviceId);
void ExtIrq_Handler(void *InstancePtr);
int  interrupt_init();

// IRQ
XScuGic InterruptController;
static XScuGic_Config *GicConfig;

#define TEST_BUFFER_SIZE 32
XUartPs Uart_PS;
static u8 SendBuffer[TEST_BUFFER_SIZE];	/* Buffer for Transmitting Data */
static u8 RecvBuffer[TEST_BUFFER_SIZE];	/* Buffer for Receiving Data */


void ExtIrq_Handler(void *InstancePtr) {
  xil_printf("ExtIrq_Handler\r\n");
  irq_read_uart = 1;
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

int UartPsPolledExample(u16 DeviceId){

  int Status;
  XUartPs_Config *Config;
  unsigned int SentCount;
  unsigned int ReceivedCount;
  u16 Index;
  u32 LoopCount = 0;


  Config = XUartPs_LookupConfig(DeviceId);
  if (NULL == Config) {
    print("FAIL [irq] XUartPs_LookupConfig\n\r");
    return XST_FAILURE;
  }

  Status = XUartPs_CfgInitialize(&Uart_PS, Config, Config->BaseAddress);
  if (Status != XST_SUCCESS) {
    print("FAIL [irq] XUartPs_CfgInitialize\n\r");
    return XST_FAILURE;
  }

  /* Check hardware build. */
  Status = XUartPs_SelfTest(&Uart_PS);
  if (Status != XST_SUCCESS) {
    print("FAIL [irq] XUartPs_SelfTest\n\r");
    return XST_FAILURE;
  }

  /* Use local loopback mode. */
  XUartPs_SetOperMode(&Uart_PS, XUARTPS_OPER_MODE_LOCAL_LOOP);

  // Initialize the send buffer bytes with a pattern and zero out the receive buffer.
  for (Index = 0; Index < TEST_BUFFER_SIZE; Index++) {
    SendBuffer[Index] = '0' + Index;
    RecvBuffer[Index] = 0;
  }

  /* Block sending the buffer. */
  SentCount = XUartPs_Send(&Uart_PS, SendBuffer, TEST_BUFFER_SIZE);
  if (SentCount != TEST_BUFFER_SIZE) {
    print("FAIL [irq] XUartPs_Send\n\r");
    return XST_FAILURE;
  }

  /*
   * Wait while the UART is sending the data so that we are guaranteed
   * to get the data the 1st time we call receive, otherwise this function
   * may enter receive before the data has arrived
   */
  while (XUartPs_IsSending(&Uart_PS)) {
    LoopCount++;
  }

  /* Block receiving the buffer. */
  ReceivedCount = 0;
  while (ReceivedCount < TEST_BUFFER_SIZE) {
    ReceivedCount +=
      XUartPs_Recv(&Uart_PS, &RecvBuffer[ReceivedCount],
              (TEST_BUFFER_SIZE - ReceivedCount));
  }

  /*
   * Check the receive buffer against the send buffer and verify the
   * data was correctly received
   */
  for (Index = 0; Index < TEST_BUFFER_SIZE; Index++) {
    if (SendBuffer[Index] != RecvBuffer[Index]) {
    print("FAIL [irq] SendBuffer != RecvBuffer\n\r");
      return XST_FAILURE;
    }
  }

  /* Restore to normal mode. */
  XUartPs_SetOperMode(&Uart_PS, XUARTPS_OPER_MODE_NORMAL);

  return XST_SUCCESS;
}


