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

#include <stdio.h>
#include "xil_printf.h"
#include "xscugic.h"
#include "xuartps.h"
#include "xparameters.h"
#include "crc_16.h"
#include "base_addresses.h"
#include "dafx_address.h"
#include "qhost_defines.h"
#include "init_ps.h"
#include "byte_vector.h"


// Constants
#define FPGA_BASEADDR      0x43C00000
#define UART_BUFFER_SIZE_C 256

// UART
extern   XUartPs Uart_PS;
extern   uint8_t irq_0_triggered;
extern   uint8_t irq_1_triggered;
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
static   uint8_t tx_buffer[UART_BUFFER_SIZE_C];
volatile int32_t rx_length;
volatile int32_t rx_addr;
volatile int32_t tx_length;
volatile int32_t tx_addr;
volatile int16_t rx_crc_high;
volatile int16_t rx_crc_low;
volatile int32_t cpu_led;
volatile int32_t led_counter;

// Functions
void     nops(uint32_t num);
void     parse_uart_rx();
void     isr_1(uint8_t *tx_buffer);
void     handle_rx_data(uint8_t *buffer);
void     axi_write(uint32_t addr, int32_t value);
uint32_t axi_read(uint32_t addr);


int main() {

  int32_t status;
  uint32_t data;

  irq_0_triggered = 0;
  uart_rx_wr_addr = 0;
  uart_rx_rd_addr = 0;
  rx_state        = RX_IDLE_E;
  rx_addr         = 0;
  rx_length       = 0;
  rx_crc_high     = 0;
  rx_crc_low      = 0;
  is_parsing      = 0;
  rx_crc_enabled  = 1;

  cpu_led     = 0;
  led_counter = 0;

  init_uart(XPAR_XUARTPS_0_DEVICE_ID);
  init_interrupt();

  data = axi_read(HARDWARE_VERSION_ADDR);
  xil_printf("%cHardware: %d\n", STR_C, data);
  xil_printf("%cSoftware: %d\n", STR_C, 1);

  while (1) {

    // IRQ0: Read the UART RX buffer
    if (irq_0_triggered) {
      uart_rx_wr_addr += XUartPs_Recv(&Uart_PS, &uart_rx_buffer[uart_rx_wr_addr], (UART_BUFFER_SIZE_C - uart_rx_wr_addr));
      irq_0_triggered = 0;
    }

    // IRQ1: Read the mixer's output and send to host
    if (irq_1_triggered) {
      //isr_1(tx_buffer);
      irq_1_triggered = 0;
    }

    // Checking if data has been written to the UART RX buffer
    if (uart_rx_rd_addr != uart_rx_wr_addr && !is_parsing) {
    	is_parsing = 1;
      xil_printf("%cINFO [main] RX Data\n", STR_C);
      parse_uart_rx();
      is_parsing = 0;
    }

    // Reset the RX write address to 0 if it has reached the high address
    if (uart_rx_wr_addr == UART_BUFFER_SIZE_C) {
      uart_rx_wr_addr = 0;
    }

    if (led_counter == 20000000) {
      axi_write(CPU_LED_ADDR, cpu_led);
      cpu_led     = ~cpu_led;
      led_counter = 0;
    } else {
      led_counter++;
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
        } else {
          xil_printf("%c[WARNING] rx_data = %d\n", STR_C, rx_data);
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
          xil_printf("%cBad CRC, %x != %x\r\n", STR_C, crc_16(rx_buffer, rx_length), (rx_crc_high | rx_crc_low));
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


void isr_1(uint8_t *tx_buffer) {

  uint32_t data;
  int32_t  index = 1;
  tx_buffer[0]  = SAMPLE_MIXER_LEFT_C;
  data          = axi_read(MIX_OUT_LEFT_ADDR);
  vector_append_uint32(tx_buffer, data, &index);
  XUartPs_Send(&Uart_PS, tx_buffer, 5);
}

void handle_rx_data(uint8_t *buffer) {

  uint32_t data;
  uint32_t addr;
  int32_t  index = 1;

  if (rx_buffer[0] == 'W' && rx_length == 9) {
    addr = vector_get_uint32(buffer, &index);
    data = vector_get_uint32(buffer, &index);
    xil_printf("%cINFO [rx] waddr(%u) wdata(%u)\r", STR_C, addr, data);
    axi_write(addr, data);

  } else if (rx_buffer[0] == 'R' && rx_length == 5) {
    addr = vector_get_uint32(buffer, &index);
    data = axi_read(addr);
    xil_printf("%cINFO [rx] raddr(%u) rdata(%d)\r", STR_C, addr, data);

  } else {
    xil_printf("%cINFO [rx] Unknown\r", STR_C);
  }
}

void nops(uint32_t num) {
  for(int32_t i = 0; i < num; i++) {
    asm("nop");
  }
}

void axi_write(uint32_t addr, int32_t value){
  Xil_Out32(addr, value);
}


uint32_t axi_read(uint32_t addr){
  return Xil_In32(addr);
}

