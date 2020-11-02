#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xscugic.h"
#include "xuartps.h"


// AXI addresses to the FPGA
#define FPGA_BASEADDR          0x43C00000
#define CR_LED_0_ADDR          0
#define CR_AXI_ADDRESS_ADDR    4
#define CR_WDATA_ADDR          8
#define CMD_MC_AXI4_WRITE_ADDR 12
#define CMD_MC_AXI4_READ_ADDR  16
#define SR_LED_COUNTER_ADDR    20
#define SR_MC_AXI4_RDATA_ADDR  24
#define SR_HW_VERSION_ADDR     28

// Constants
static const unsigned char LENGTH_8_BITS_C  = 0xAA;
static const unsigned char LENGTH_16_BITS_C = 0x55;

// IRQ
XScuGic InterruptController;
static XScuGic_Config *GicConfig;

// UART
#define UART_BUFFER_SIZE_C 256
static u8 irq_read_uart;
static u8 uart_tx_buffer[UART_BUFFER_SIZE_C];
static u8 uart_tx_wr_addr;
static u8 uart_tx_rd_addr;
static u8 uart_rx_buffer[UART_BUFFER_SIZE_C];
static u8 uart_rx_wr_addr;
static u8 uart_rx_rd_addr;

// UART parsing
typedef enum {
  RX_IDLE_E,
  RX_LENGTH_HIGH_E,
  RX_LENGTH_LOW_E,
  RX_READ_PAYLOAD_E,
  RX_READ_CRC_LOW_E,
  RX_READ_CRC_HIGH_E
} rx_state_t;

rx_state_t rx_state;
static int rx_crc_enabled;
static u8  rx_buffer[UART_BUFFER_SIZE_C];
static int rx_length;
static int rx_addr;
static int rx_crc_high;
static int rx_crc_low;

#define TEST_BUFFER_SIZE 32
XUartPs Uart_PS;
static u8 SendBuffer[TEST_BUFFER_SIZE];	/* Buffer for Transmitting Data */
static u8 RecvBuffer[TEST_BUFFER_SIZE];	/* Buffer for Receiving Data */

int UartPsPolledExample(u16 DeviceId);
void nops(unsigned int num);
void parse_uart_rx();
void handle_rx_data();






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



int main() {

  int Status;

  // Reset
  irq_read_uart      = 0;
  uart_tx_wr_addr    = 0;
  uart_tx_rd_addr    = 0;
  uart_rx_wr_addr    = 0;
  uart_rx_rd_addr    = 0;
  rx_state           = RX_IDLE_E;
  rx_addr            = 0;
  rx_length          = 0;
  rx_crc_high        = 0;
  rx_crc_low         = 0;

  init_platform();

  print("Hello World\n\r");

  interrupt_init();

  Status = UartPsPolledExample(XPAR_XUARTPS_0_DEVICE_ID);

  if (Status != XST_SUCCESS) {
    xil_printf("ERROR [uart] UART Polled Mode Example Test Failed\r\n");
    return XST_FAILURE;
  } else {
    xil_printf("INFO [uart] UART success\r\n");
  }

  while (1) {

    if (irq_read_uart) {

      uart_rx_wr_addr += XUartPs_Recv(&Uart_PS, &uart_rx_buffer[uart_rx_wr_addr], (UART_BUFFER_SIZE_C - uart_rx_wr_addr));

      if (uart_rx_rd_addr != uart_rx_wr_addr) {
        parse_uart_rx();
      }

      if (uart_rx_wr_addr == UART_BUFFER_SIZE_C) {
        uart_rx_wr_addr = 0;
      }

      irq_read_uart = 0;

    }
  }

  cleanup_platform();
  return 0;
}

void parse_uart_rx() {

  u8 rx_data;
  int nr_of_bytes = uart_rx_wr_addr - uart_rx_rd_addr;

  for (int i = uart_rx_rd_addr; i < uart_rx_rd_addr+nr_of_bytes; i++) {

    rx_data = uart_rx_buffer[i];

    switch (rx_state) {

      case RX_IDLE_E:

        rx_addr    = 0;
        rx_length  = 0;

        if (rx_data == LENGTH_8_BITS_C) {
          rx_state = RX_LENGTH_LOW_E;
        } else if (rx_data == LENGTH_16_BITS_C) {
          rx_state = RX_LENGTH_HIGH_E;
        }
        break;


      case RX_LENGTH_HIGH_E:

        rx_length  = (unsigned int)rx_data << 8;
        rx_state   = RX_LENGTH_LOW_E;
        break;


      case RX_LENGTH_LOW_E:

        rx_length |= (unsigned int)rx_data;

        if (rx_length <= UART_BUFFER_SIZE_C && rx_length > 0) {
          rx_state = RX_READ_PAYLOAD_E;
        }
        break;


      case RX_READ_PAYLOAD_E:

        rx_buffer[rx_addr++] = rx_data;

        if (rx_addr == rx_length) {

          if (rx_crc_enabled) {
            rx_state = RX_READ_CRC_LOW_E;
          } else {
            handle_rx_data();
            rx_state = RX_IDLE_E;
          }
        }
        break;


      case RX_READ_CRC_LOW_E:

        rx_state    = RX_READ_CRC_HIGH_E;
        rx_crc_high = rx_data;
        break;


      case RX_READ_CRC_HIGH_E:

        rx_crc_low = rx_data;

        //if (crc_16(rx_buffer, rx_length) == ((unsigned short)rx_crc_high << 8 | (unsigned short)rx_crc_low)) {
        //  handle_rx_data();
        //}

        rx_state = RX_IDLE_E;
        break;


      default:
        rx_state = RX_IDLE_E;
        break;
    }
  }

  uart_rx_rd_addr = uart_rx_wr_addr;

}


void handle_rx_data() {

  int SentCount;

  SentCount = XUartPs_Send(&Uart_PS, rx_buffer, rx_length);
  if (SentCount != rx_length) {
    print("FAIL [irq] XUartPs_Send\n\r");
    return XST_FAILURE;
  }

}







void nops(unsigned int num) {
  for(int i = 0; i < num; i++) {
    asm("nop");
  }
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

  /*
   * Initialize the send buffer bytes with a pattern and zero out
   * the receive buffer.
   */
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
