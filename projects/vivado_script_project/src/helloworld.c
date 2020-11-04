#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xscugic.h"
#include "xuartps.h"
#include "xparameters.h"


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
extern XScuGic InterruptController;
extern XScuGic_Config *GicConfig;

// UART
#define UART_BUFFER_SIZE_C 256
extern u8 irq_read_uart;
//static u8 uart_tx_buffer[UART_BUFFER_SIZE_C];
volatile int is_parsing;
volatile u8 uart_tx_wr_addr;
volatile u8 uart_tx_rd_addr;
static u8 uart_rx_buffer[UART_BUFFER_SIZE_C];
volatile u8 uart_rx_wr_addr;
volatile u8 uart_rx_rd_addr;

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
volatile int rx_crc_enabled;
static   u8  rx_buffer[UART_BUFFER_SIZE_C];
volatile int rx_length;
volatile int rx_addr;
volatile int rx_crc_high;
volatile int rx_crc_low;

extern XUartPs Uart_PS;

void nops(unsigned int num);
void parse_uart_rx();
void handle_rx_data();
int  get_axi_offset();
int  get_axi_wdata();
void axi_write(int baseaddr, int offset, int value);
int  axi_read(int baseaddr, int offset);

extern int  UartPsPolledExample(u16 DeviceId);
extern void ExtIrq_Handler(void *InstancePtr);
extern int  interrupt_init();

uint16_t buffer_get_uint16(const uint8_t *buffer, int32_t *index);
uint32_t buffer_get_uint32(const uint8_t *buffer, int32_t *index);

int main() {

  int Status;

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

  init_platform();

  xil_printf("Hello World\r\n");

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
  uint32_t addr;


  if (rx_buffer[0] == 'W' && rx_length == 9) {
    xil_printf("INFO [rx] waddr(%u) wdata(%u)\r", get_axi_offset(), get_axi_wdata());
    //reg_write(FPGA_BASEADDR, get_axi_offset(), get_axi_wdata());
  }

  if (rx_buffer[0] == 'R' && rx_length == 5) {

    addr = buffer_get_uint32(buffer, &index);
    xil_printf("INFO [rx] raddr(%u)\r", addr);
  }
}


void nops(unsigned int num) {
  for(int i = 0; i < num; i++) {
    asm("nop");
  }
}



void axi_write(int baseaddr, int offset, int value){
  Xil_Out32(baseaddr + offset, value);
}


int axi_read(int baseaddr, int offset){
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
