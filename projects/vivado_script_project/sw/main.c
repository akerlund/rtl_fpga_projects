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

#include <stdio.h>
#include "xil_printf.h"
#include "xscugic.h"
#include "xuartps.h"
#include "xparameters.h"
#include "crc_16.h"
#include "cfg_addr_map.h"
#include "init_ps.h"
#include "byte_vector.h"


// Constants
#define              UART_BUFFER_SIZE_C 256
static const uint8_t LENGTH_8_BITS_C  = 0xAA;
static const uint8_t LENGTH_16_BITS_C = 0x55;


// UART
extern   XUartPs Uart_PS;
extern   uint8_t irq_read_uart;
volatile int32_t is_parsing;
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

rx_state_t       rx_state;
volatile int32_t rx_crc_enabled;
static   uint8_t rx_buffer[UART_BUFFER_SIZE_C];
volatile int32_t rx_length;
volatile int32_t rx_addr;
volatile int16_t rx_crc_high;
volatile int16_t rx_crc_low;

// Functions
void     nops(uint32_t num);
void     parse_uart_rx();
void     handle_rx_data();
void     axi_write(uint32_t baseaddr, uint32_t offset, int32_t value);
uint32_t axi_read(uint32_t  baseaddr, uint32_t offset);


int main() {

  int32_t status;

  irq_read_uart   = 0;
  uart_rx_wr_addr = 0;
  uart_rx_rd_addr = 0;
  rx_state        = RX_IDLE_E;
  rx_addr         = 0;
  rx_length       = 0;
  rx_crc_high     = 0;
  rx_crc_low      = 0;
  is_parsing      = 0;
  rx_crc_enabled  = 1;

  xil_printf("Hello World\r\n");

  init_interrupt();

  status = init_uart(XPAR_XUARTPS_0_DEVICE_ID);

  if (status != XST_SUCCESS) {
    xil_printf("ERROR [uart] UART Initialization Failed\r\n");
    return XST_FAILURE;
  } else {
    xil_printf("INFO [uart] UART Operational 2\r\n");
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
            rx_state = RX_READ_CRC_HIGH_E;
          } else {
            handle_rx_data(rx_buffer);
            rx_state = RX_IDLE_E;
          }
        }
        break;


      case RX_READ_CRC_HIGH_E:

        rx_state    = RX_READ_CRC_LOW_E;
        rx_crc_high = (uint16_t)rx_data << 8;
        break;


      case RX_READ_CRC_LOW_E:

        rx_crc_low = (uint16_t)rx_data;

        if (crc_16(rx_buffer, rx_length) == (uint16_t)(rx_crc_high | rx_crc_low)) {
          handle_rx_data(rx_buffer);
        } else {
          printf("Bad CRC, %x != %x\r\n", crc_16(rx_buffer, rx_length), (rx_crc_high | rx_crc_low));
        }

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
    addr = vector_get_uint32(buffer, &index);
    data = vector_get_uint32(buffer, &index);
    xil_printf("INFO [rx] waddr(%u) wdata(%u)\r", addr, data);
    axi_write(FPGA_BASEADDR, addr, data);
  }

  if (rx_buffer[0] == 'R' && rx_length == 5) {

      addr = vector_get_uint32(buffer, &index);
      data = axi_read(FPGA_BASEADDR, addr);
      xil_printf("INFO [rx] raddr(%u) rdata(%u)\r", addr, data);
  }
}


void nops(uint32_t num) {
  for(int32_t i = 0; i < num; i++) {
    asm("nop");
  }
}



void axi_write(uint32_t baseaddr, uint32_t offset, int32_t value){
  Xil_Out32(baseaddr + offset, value);
}


uint32_t axi_read(uint32_t baseaddr, uint32_t offset){
  return Xil_In32(baseaddr + offset);
}

