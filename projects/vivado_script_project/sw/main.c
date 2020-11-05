#include <stdio.h>
#include "xil_printf.h"
#include "xscugic.h"
#include "xuartps.h"
#include "xparameters.h"
#include "crc_16.h"
#include "cfg_addr_map.h"


// Constants
static const uint8_t LENGTH_8_BITS_C  = 0xAA;
static const uint8_t LENGTH_16_BITS_C = 0x55;

// IRQ
extern XScuGic InterruptController;
extern XScuGic_Config *GicConfig;

// UART
#define UART_BUFFER_SIZE_C 256
extern uint8_t irq_read_uart;
//static uint8_t uart_tx_buffer[UART_BUFFER_SIZE_C];
volatile int32_t is_parsing;
volatile uint8_t uart_tx_wr_addr;
volatile uint8_t uart_tx_rd_addr;
static   uint8_t uart_rx_buffer[UART_BUFFER_SIZE_C];
volatile uint8_t uart_rx_wr_addr;
volatile uint8_t uart_rx_rd_addr;

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
volatile int32_t rx_crc_enabled;
static   uint8_t rx_buffer[UART_BUFFER_SIZE_C];
volatile int32_t rx_length;
volatile int32_t rx_addr;
volatile int32_t rx_crc_high;
volatile int32_t rx_crc_low;

extern XUartPs Uart_PS;

void nops(uint32_t num);
void parse_uart_rx();
void handle_rx_data();
int32_t get_axi_offset();
int32_t get_axi_wdata();
void axi_write(int32_t baseaddr, int32_t offset, int32_t value);
int32_t  axi_read(int32_t baseaddr, int32_t offset);

extern int32_t  UartPsPolledExample(u16 DeviceId);
extern void ExtIrq_Handler(void *InstancePtr);
extern int32_t  interrupt_init();

uint16_t buffer_get_uint16(const uint8_t *buffer, int32_t *index);
uint32_t buffer_get_uint32(const uint8_t *buffer, int32_t *index);

int main() {

  int32_t Status;

  // Reset
  irq_read_uart   = 0;
  uart_tx_wr_addr = 0;
  uart_tx_rd_addr = 0;
  uart_rx_wr_addr = 0;
  uart_rx_rd_addr = 0;
  rx_state        = RX_IDLE_E;
  rx_addr         = 0;
  rx_length       = 0;
  rx_crc_high     = 0;
  rx_crc_low      = 0;
  is_parsing      = 0;

  xil_printf("Hello World\r\n");

  interrupt_init();

  Status = UartPsPolledExample(XPAR_XUARTPS_0_DEVICE_ID);

  if (Status != XST_SUCCESS) {
    xil_printf("ERROR [uart] UART Initialization Failed\r\n");
    return XST_FAILURE;
  } else {
    xil_printf("INFO [uart] UART Operational\r\n");
  }

  while (1) {

    if (irq_read_uart) {
      uart_rx_wr_addr += XUartPs_Recv(&Uart_PS, &uart_rx_buffer[uart_rx_wr_addr], (UART_BUFFER_SIZE_C - uart_rx_wr_addr));
      irq_read_uart = 0;
    }

    if (uart_rx_rd_addr != uart_rx_wr_addr && !is_parsing) {
    	is_parsing = 1;
        parse_uart_rx();
        is_parsing = 0;
    }

    if (uart_rx_wr_addr == UART_BUFFER_SIZE_C) {
      uart_rx_wr_addr = 0;
    }
  }

  return 0;
}

void parse_uart_rx() {

  uint8_t rx_data;
  int32_t nr_of_bytes = uart_rx_wr_addr - uart_rx_rd_addr;

  for (int32_t i = uart_rx_rd_addr; i < uart_rx_rd_addr+nr_of_bytes; i++) {

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

        rx_length  = (uint32_t)rx_data << 8;
        rx_state   = RX_LENGTH_LOW_E;
        break;


      case RX_LENGTH_LOW_E:

        rx_length |= (uint32_t)rx_data;

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
            handle_rx_data(rx_buffer);
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


void handle_rx_data(const uint8_t *buffer) {

  int32_t  index = 1;
  uint32_t data;
  uint32_t addr;


  if (rx_buffer[0] == 'W' && rx_length == 9) {
      addr = buffer_get_uint32(buffer, &index);
      data = buffer_get_uint32(buffer, &index);
      xil_printf("INFO [rx] waddr(%u) wdata(%u)\r", addr, data);
  }

  if (rx_buffer[0] == 'R' && rx_length == 5) {

    addr = buffer_get_uint32(buffer, &index);
    xil_printf("INFO [rx] raddr(%u)\r", addr);
  }
}


void nops(uint32_t num) {
  for(int32_t i = 0; i < num; i++) {
    asm("nop");
  }
}



void axi_write(int32_t baseaddr, int32_t offset, int32_t value){
  Xil_Out32(baseaddr + offset, value);
}


int32_t axi_read(int32_t baseaddr, int32_t offset){
  return Xil_In32(baseaddr + offset);
}


uint16_t buffer_get_uint16(const uint8_t *buffer, int32_t *index) {
  uint16_t res = ((uint16_t) buffer[*index]) << 8 |
                 ((uint16_t) buffer[*index + 1]);
  *index += 2;
  return res;
}


uint32_t buffer_get_uint32(const uint8_t *buffer, int32_t *index) {
  uint32_t res = ((uint32_t) buffer[*index])     << 24 |
                 ((uint32_t) buffer[*index + 1]) << 16 |
                 ((uint32_t) buffer[*index + 2]) << 8  |
                 ((uint32_t) buffer[*index + 3]);
  *index += 4;
  return res;
}
