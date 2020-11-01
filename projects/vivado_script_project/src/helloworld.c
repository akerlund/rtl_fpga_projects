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
// Development application for the Arty-Z7 development board.
//
//
////////////////////////////////////////////////////////////////////////////////

#include <stdio.h>
#include "platform.h"

#include "xil_printf.h"
#include "xil_io.h"
#include "xil_exception.h"
#include "xil_types.h"

#include "xparameters.h"
#include "xplatform_info.h"
#include "xuartps.h"
#include "xscugic.h"

// -----------------------------------------------------------------------------
// Constants
// -----------------------------------------------------------------------------

// UART
#define UART_INT_IRQ_ID XPAR_FABRIC_BD_PROJECT_TOP_0_IRQ_0_INTR
#define UART_BUFFER_SIZE_C     100

// IRQ
#define IRQ_F2P_0_C 61

// AXI addresses to the configuration slave
#define FPGA_BASEADDR          0x43C00000
#define CR_LED_0_ADDR          0
#define CR_AXI_ADDRESS_ADDR    4
#define CR_WDATA_ADDR          8
#define CMD_MC_AXI4_WRITE_ADDR 12
#define CMD_MC_AXI4_READ_ADDR  16
#define SR_LED_COUNTER_ADDR    20
#define SR_MC_AXI4_RDATA_ADDR  24
#define SR_HW_VERSION_ADDR     28

// -----------------------------------------------------------------------------
// Functions
// -----------------------------------------------------------------------------

int        setup_uart_irq(XScuGic *irc_uart, XUartPs *uart_ps, u16 uart_id, u16 irq_id);
static int setup_interrupt_system_generic(XScuGic *irc,u16 irq_id, Xil_ExceptionHandler irq_handler, void *callback_reference);
static int setup_interrupt_system_uart(XScuGic *irc, u16 irq_id, XUartPs *uart_ps);
void       reg_write(int baseaddr, int offset, int value);
int        reg_read(int baseaddr, int offset);
void       parse_serial();

void       isr_uart(void *callback_reference, u32 event, unsigned int event_data);
void       isr_f2p(void *callback_reference);
void       nops(unsigned int num);

// -----------------------------------------------------------------------------
// Variables
// -----------------------------------------------------------------------------

// UART
XUartPs      uart_ps;
static       u8 uart_tx_byte;
static       u8 uart_rx_byte;
static       u8 uart_tx_buffer[UART_BUFFER_SIZE_C];
static       u8 uart_rx_buffer[UART_BUFFER_SIZE_C];
static       u8 uart_tx_wr_addr;
static       u8 uart_tx_rd_addr;
static       u8 uart_rx_wr_addr;
static       u8 uart_rx_rd_addr;

volatile int uart_send_to_host;

volatile int uart_rx_counter;
volatile int uart_tx_counter;
int          uart_error_counter;
volatile int led_0;

// Interrupt Controllers
XScuGic irc_uart;
XScuGic irc_f2p;






void parse_serial(){

  int nr_of_rx_bytes;

  if (uart_rx_wr_addr > uart_rx_rd_addr) {
    nr_of_rx_bytes = uart_rx_wr_addr - uart_rx_rd_addr;
  } else {
    nr_of_rx_bytes = (UART_BUFFER_SIZE_C - uart_rx_rd_addr) + uart_rx_wr_addr;
  }

  for (int i = 0; i < nr_of_rx_bytes; i++) {
    XUartPs_Send(&uart_ps, &uart_rx_buffer[i], 1);
  }

}

int main(){

  volatile int rdata = 0;
  led_0 = 0;
  uart_send_to_host = 0;

  int status;

  status = setup_interrupt_system_generic(&irc_f2p,  XPAR_FABRIC_BD_PROJECT_TOP_0_IRQ_0_INTR, (Xil_ExceptionHandler)isr_f2p, (void*)&irc_f2p);

  //status = setup_uart_irq(&irc_f2p, &irc_uart, XPAR_XUARTPS_0_DEVICE_ID, XPAR_XUARTPS_0_INTR);
  //status = uart_basic(&irc_uart, &uart_ps);
  if (status != XST_SUCCESS) {
    xil_printf("UART Interrupt Example Test Failed\r\n");
    return XST_FAILURE;
  }

  // Print out for letting the user see the system has started
  rdata = reg_read(FPGA_BASEADDR, SR_HW_VERSION_ADDR);
  printf("Hello World\n\r");
  printf("SR_HW_VERSION_ADDR     = %d\n\r", rdata);

  while (1) {

  	nops(160000000);

      //printf("uart_rx_counter        = %d\n\r", uart_rx_counter);

	  //if (uart_rx_rd_addr != uart_rx_wr_addr) {
	  //  parse_serial();
	  //}

    if (uart_send_to_host != 0) {
      printf("--------------------------------------------------------------------------------\n\r");
      reg_write(FPGA_BASEADDR, CR_LED_0_ADDR, led_0++);
      printf("CR_LED_0_ADDR (w)      = %d\n\r", led_0);

      rdata = reg_read(FPGA_BASEADDR, CR_LED_0_ADDR);
      printf("CR_LED_0_ADDR (r)      = %d\n\r", rdata);

      rdata = reg_read(FPGA_BASEADDR, CR_AXI_ADDRESS_ADDR);
      printf("CR_AXI_ADDRESS_ADDR    = %d\n\r", rdata);

      rdata = reg_read(FPGA_BASEADDR, CR_WDATA_ADDR);
      printf("CR_WDATA_ADDR          = %d\n\r", rdata);

      rdata = reg_read(FPGA_BASEADDR, CMD_MC_AXI4_WRITE_ADDR);
      printf("CMD_MC_AXI4_WRITE_ADDR = %d\n\r", rdata);

      rdata = reg_read(FPGA_BASEADDR, CMD_MC_AXI4_READ_ADDR);
      printf("CMD_MC_AXI4_READ_ADDR  = %d\n\r", rdata);

      rdata = reg_read(FPGA_BASEADDR, SR_LED_COUNTER_ADDR);
      printf("SR_LED_COUNTER_ADDR    = %d\n\r", rdata);

      rdata = reg_read(FPGA_BASEADDR, SR_MC_AXI4_RDATA_ADDR);
      printf("SR_MC_AXI4_RDATA_ADDR  = %d\n\r", rdata);

      rdata = reg_read(FPGA_BASEADDR, SR_MC_AXI4_RDATA_ADDR);
      printf("SR_MC_AXI4_RDATA_ADDR  = %d\n\r", rdata);

      rdata = reg_read(FPGA_BASEADDR, SR_HW_VERSION_ADDR);
      printf("SR_HW_VERSION_ADDR     = %d\n\r", rdata);
    }
  }

  cleanup_platform();

  return 0;
}

// -----------------------------------------------------------------------------
// Setup ZynQ Interrupt for the generic IRQ
// -----------------------------------------------------------------------------
static int setup_interrupt_system_generic(
  XScuGic              *irc,
  u16                   irq_id,
  Xil_ExceptionHandler  irq_handler,
  void                 *callback_reference)
{
  int             status;
  XScuGic_Config *interrupt_config;

  interrupt_config = XScuGic_LookupConfig(irq_id);
  if (interrupt_config == NULL) {
    print("FAIL [irq] XScuGic_LookupConfig\n\r");
    return XST_FAILURE;
  }

  status = XScuGic_CfgInitialize(irc, interrupt_config, interrupt_config->CpuBaseAddress);
  if (status != XST_SUCCESS) {
    print("FAIL [irq] XScuGic_CfgInitialize\n\r");
    return XST_FAILURE;
  }

  // set the priority of IRQ_F2P[0:0] to 0xA0 (highest 0xF8, lowest 0x00) and a trigger for a rising edge 0x3.
  XScuGic_SetPriorityTriggerType(irc, irq_id, 0xA0, 0x3);

  // Connect a device driver handler
  status = XScuGic_Connect(irc, irq_id, irq_handler, callback_reference);
  if (status != XST_SUCCESS) {
    print("FAIL [irq] XScuGic_Connect\n\r"); return XST_FAILURE;
  }

  /* Enable the interrupt for the device */
  XScuGic_Enable(irc, irq_id);

  // initialize the exception table and register the interrupt controller handler with the exception table
  Xil_ExceptionInit();

  // Connect the interrupt controller interrupt handler to the hardware interrupt handling logic in the processor.
  Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT, (Xil_ExceptionHandler) XScuGic_InterruptHandler, irc);

  // Enable interrupts
  Xil_ExceptionEnable();

  print("INFO [irq] XST_SUCCESS\n\r");
  return XST_SUCCESS;
}
// -----------------------------------------------------------------------------
// F2P IRQ
// -----------------------------------------------------------------------------
void isr_f2p (void *callback_reference) {
  xil_printf("isr_f2p called\n\r");
  reg_write(FPGA_BASEADDR, CR_LED_0_ADDR, led_0++);
}

// -----------------------------------------------------------------------------
// AXI Write
// -----------------------------------------------------------------------------
void reg_write(int baseaddr, int offset, int value){
  Xil_Out32(baseaddr + offset, value);
}

// -----------------------------------------------------------------------------
// AXI Read
// -----------------------------------------------------------------------------
int reg_read(int baseaddr, int offset){
  int temp = 0;
  temp = Xil_In32(baseaddr + offset);
  return(temp);
}


void nops(unsigned int num) {
  for(int i = 0; i < num; i++) {
    asm("nop");
  }
}






















static int uart_basic(XScuGic *IntcInstPtr, XUartPs *UartInstancePtr)
{
  int             status;
  XUartPs_Config *xuart_config;
  XScuGic_Config *interrupt_config;
  u32 irq_mask;

  irq_mask = XUARTPS_IXR_TOUT | XUARTPS_IXR_PARITY  | XUARTPS_IXR_FRAMING |
             XUARTPS_IXR_OVER | XUARTPS_IXR_TXEMPTY | XUARTPS_IXR_RXFULL |
             XUARTPS_IXR_RXOVR;


  xuart_config = XUartPs_LookupConfig(XPAR_XUARTPS_0_DEVICE_ID);
  if (xuart_config == NULL) { return XST_FAILURE; }

  status = XUartPs_CfgInitialize(UartInstancePtr, xuart_config, xuart_config->BaseAddress);
  if (status != XST_SUCCESS) { return XST_FAILURE; }

	status = XUartPs_SelfTest(UartInstancePtr);
	if (status != XST_SUCCESS) { return XST_FAILURE; }


  interrupt_config = XScuGic_LookupConfig(XPAR_SCUGIC_SINGLE_DEVICE_ID);
  if (interrupt_config == NULL) { return XST_FAILURE; }

  status = XScuGic_CfgInitialize(IntcInstPtr, interrupt_config, interrupt_config->CpuBaseAddress);
  if (status != XST_SUCCESS) { return XST_FAILURE; }

  Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT, (Xil_ExceptionHandler) XScuGic_InterruptHandler, IntcInstPtr);

  status = XScuGic_Connect(IntcInstPtr, XPAR_XUARTPS_0_INTR, (Xil_ExceptionHandler) XUartPs_InterruptHandler, (void*) UartInstancePtr);
  if (status != XST_SUCCESS) { return XST_FAILURE; }

  // Enable the interrupt for the device
  XScuGic_Enable(IntcInstPtr, XPAR_XUARTPS_0_INTR);

  // Connect the interrupt controller interrupt handler to the hardware interrupt handling logic in the processor.

  // Enable interrupts
  Xil_ExceptionEnable();

  // Setup the handlers for the UART
  XUartPs_SetHandler(UartInstancePtr, (XUartPs_Handler)isr_uart, UartInstancePtr);

  // Enable the interrupt of the UART
  XUartPs_SetInterruptMask(UartInstancePtr, irq_mask);
  XUartPs_SetOperMode(UartInstancePtr, XUARTPS_OPER_MODE_NORMAL);

  // Set the receiver timeout. The setting of 8 will timeout after 8 x 4 = 32 character times.
  // Increase the time out value if baud rate is high, decrease it if baud rate is low.
  //XUartPs_SetRecvTimeout(uart_ps, 8);

  // Initialize the buffers
  uart_tx_wr_addr = 0;
  uart_tx_rd_addr = 0;
  uart_rx_wr_addr = 0;
  uart_rx_rd_addr = 0;

  for (int i = 0; i < UART_BUFFER_SIZE_C; i++) {
    uart_tx_buffer[i] = (i % 26) + 'A';
    uart_rx_buffer[i] = 0;
  }

  // Start
  XUartPs_Recv(UartInstancePtr, &uart_rx_byte, 1);

  return XST_SUCCESS;
}

// -----------------------------------------------------------------------------
// UART IRQ
// -----------------------------------------------------------------------------
void isr_uart(void *callback_reference, u32 event, unsigned int event_data)
{
	reg_write(FPGA_BASEADDR, CR_LED_0_ADDR, led_0++);

  // All of the data has been sent
  if (event == XUARTPS_EVENT_SENT_DATA) {
    uart_tx_counter = event_data;
    printf("XUARTPS_EVENT_SENT_DATA\n\r");
  }

  // All of the data has been received
  if (event == XUARTPS_EVENT_RECV_DATA) {
    printf("XUARTPS_EVENT_RECV_DATA\n\r");

    if (uart_send_to_host == 0) {
      uart_send_to_host = 1;
    } else {
      uart_send_to_host = 1;
    }

    uart_rx_counter = event_data;
    uart_rx_buffer[uart_rx_wr_addr++] = uart_rx_byte;

    if (uart_rx_wr_addr == UART_BUFFER_SIZE_C) {
    	uart_rx_wr_addr = 0;
    }
    XUartPs_Recv(&uart_ps, &uart_rx_byte, 1);

  }

  // Data was received, but not the expected number of bytes, a
  // timeout just indicates the data stopped for 8 character times
  if (event == XUARTPS_EVENT_RECV_TOUT) {
    printf("XUARTPS_EVENT_RECV_TOUT\n\r");
    uart_rx_counter = event_data;
  }

  // Data was received with an error, keep the data but determine
  if (event == XUARTPS_EVENT_RECV_ERROR) {
    printf("XUARTPS_EVENT_RECV_ERROR\n\r");
    uart_rx_counter = event_data;
    uart_error_counter++;
  }

  // Data was received with an parity or frame or break error
  if (event == XUARTPS_EVENT_PARE_FRAME_BRKE) {
    printf("XUARTPS_EVENT_PARE_FRAME_BRKE\n\r");
    uart_rx_counter = event_data;
    uart_error_counter++;
  }

  // Data was received with an overrun error, keep the data but determine
  if (event == XUARTPS_EVENT_RECV_ORERR) {
    printf("XUARTPS_EVENT_RECV_ORERR\n\r");
    uart_rx_counter = event_data;
    uart_error_counter++;
  }
}


// -----------------------------------------------------------------------------
// Setup ZynQ UART
// -----------------------------------------------------------------------------
int setup_uart_irq(XScuGic *irc_uart, XUartPs *uart_ps, u16 uart_id, u16 irq_id) {

  XUartPs_Config *xuart_config;
  int status;
  int i;
  u32 irq_mask;

  irq_mask = XUARTPS_IXR_TOUT | XUARTPS_IXR_PARITY  | XUARTPS_IXR_FRAMING |
             XUARTPS_IXR_OVER | XUARTPS_IXR_TXEMPTY | XUARTPS_IXR_RXFULL |
             XUARTPS_IXR_RXOVR;

  // Initialize the UART driver
  xuart_config = XUartPs_LookupConfig(uart_id);
  if (xuart_config == NULL) { return XST_FAILURE; }

  status = XUartPs_CfgInitialize(uart_ps, xuart_config, xuart_config->BaseAddress);
  if (status != XST_SUCCESS) { return XST_FAILURE; }

  // Check hardware build
  status = XUartPs_SelfTest(uart_ps);
  if (status != XST_SUCCESS) { return XST_FAILURE; }

  // Connect the UART to the interrupt subsystem
  status = setup_interrupt_system_uart(irc_uart, irq_id, uart_ps);
  if (status != XST_SUCCESS) { return XST_FAILURE; }

  // Setup the handlers for the UART
  XUartPs_SetHandler(uart_ps, (XUartPs_Handler)isr_uart, uart_ps);

  // Enable the interrupt of the UART
  XUartPs_SetInterruptMask(uart_ps, irq_mask);
  XUartPs_SetOperMode(uart_ps, XUARTPS_OPER_MODE_NORMAL);

  // Set the receiver timeout. The setting of 8 will timeout after 8 x 4 = 32 character times.
  // Increase the time out value if baud rate is high, decrease it if baud rate is low.
  XUartPs_SetRecvTimeout(uart_ps, 8);

  // Initialize the buffers
  uart_tx_wr_addr = 0;
  uart_tx_rd_addr = 0;
  uart_rx_wr_addr = 0;
  uart_rx_rd_addr = 0;

  for (i = 0; i < UART_BUFFER_SIZE_C; i++) {
    uart_tx_buffer[i] = (i % 26) + 'A';
    uart_rx_buffer[i] = 0;
  }

  // Start
  XUartPs_Recv(uart_ps, &uart_rx_byte, 1);

  return XST_SUCCESS;
}



// -----------------------------------------------------------------------------
// Setup ZynQ Interrupt for the UART
// -----------------------------------------------------------------------------
static int setup_interrupt_system_uart(
  XScuGic *irc,
  u16      irq_id,
  XUartPs *uart_ps)
{
  int             status;
  XScuGic_Config *interrupt_config;

  interrupt_config = XScuGic_LookupConfig(XPAR_SCUGIC_SINGLE_DEVICE_ID);
  if (interrupt_config == NULL) { return XST_FAILURE; }

  status = XScuGic_CfgInitialize(irc, interrupt_config, interrupt_config->CpuBaseAddress);
  if (status != XST_SUCCESS) { return XST_FAILURE; }

  // Connect a device driver handler
  status = XScuGic_Connect(irc, irq_id, (Xil_ExceptionHandler) XUartPs_InterruptHandler, (void*) uart_ps);
  if (status != XST_SUCCESS) { return XST_FAILURE; }

  // Enable the interrupt for the device
  XScuGic_Enable(irc, irq_id);

  // Connect the interrupt controller interrupt handler to the hardware interrupt handling logic in the processor.
  Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT, (Xil_ExceptionHandler) XScuGic_InterruptHandler, irc);

  // Enable interrupts
  Xil_ExceptionEnable();

  return XST_SUCCESS;
}



