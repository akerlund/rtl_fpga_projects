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

// AXI addresses to the configuration slave
#define FPGA_BASEADDR          0x43C00000
#define CR_LED_0_ADDR          0
#define CR_AXI_ADDRESS_ADDR    4
#define CR_WDATA_ADDR          8
#define CMD_MC_AXI4_WRITE_ADDR 12
#define CMD_MC_AXI4_READ_ADDR  16
#define SR_LED_COUNTER_ADDR    20
#define SR_MC_AXI4_RDATA_ADDR  24

void reg_write(int baseaddr, int offset, int value);
int  reg_read(int baseaddr, int offset);

int main(){

  volatile int delay;
  volatile int led_0 = 0;
  volatile int rdata = 0;

  init_platform();
  print("Hello World\n\r");

  while (1) {

	for (delay = 0; delay < 40000000; delay++) {};

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

  }

  cleanup_platform();

  return 0;
}


void reg_write(int baseaddr, int offset, int value){
  Xil_Out32(baseaddr + offset, value);
}


int reg_read(int baseaddr, int offset){
  int temp = 0;
  temp = Xil_In32(baseaddr + offset);
  return(temp);
}
