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
// This module contains a PLL which is configured to produce a clock and
// reset (CAR) for
//
// Cirrus CS5343 Multi-Bit Audio A/D Converter
// Cirrus CS4344 Stereo D/A Converter
// See; https://www.cirrus.com/products/cs5343-44/
//
// Both ICs are placed on the Digilent Pmod I2S2.
//
// Clock in:  125MHz
// Clock out: 22.591MHz
//
// The PLL parameters are generated with Vivado's Clocking Wizard.
//
////////////////////////////////////////////////////////////////////////////////

`default_nettype none

module car_cs5343 (

    input  wire  clk,
    input  wire  rst_n,
    output logic clk_mclk,
    output logic rst_mclk_n
  );

  // Parameters which yields a clock frequency of:
  // 125000000 / 5 * 56 / 62 = 22580645.16129032
  localparam int  CLKFBOUT_MULT_C  = 56;
  localparam real CLKIN1_PERIOD_C  = 8.0;
  localparam int  DIVCLK_DIVIDE_C  = 5;
  localparam int  CLKOUT0_DIVIDE_C = 62;


  logic clk_mclk_int;
  logic rst_mclk_int_n;

  logic clk_pll0_fb0;
  logic clk_pll_locked0;

  assign rst_mclk_int_n = (rst_n && clk_pll_locked0) ? 1'b1 : 1'b0;

  // Synchronizing the reset for the PMOD with the system reset
  reset_synchronizer reset_synchronizer_i0 (
    .clk         ( clk_mclk       ),
    .rst_async_n ( rst_mclk_int_n ),
    .rst_sync_n  ( rst_mclk_n     )
  );

  // Output buffer
  BUFG bufg_i0 (
    .O ( clk_mclk     ),
    .I ( clk_mclk_int )
  );

  // clk_mclk_int = 22.580645MHz
  PLLE2_BASE #(
    .BANDWIDTH          ( "OPTIMIZED"      ), // OPTIMIZED,HIGH,LOW
    .CLKFBOUT_MULT      ( CLKFBOUT_MULT_C  ), // Multiply value for all CLKOUT,(2-64)
    .CLKFBOUT_PHASE     ( 0.0              ), // Phase offset in degrees of CLKFB,(-360.000-360.000).
    .CLKIN1_PERIOD      ( CLKIN1_PERIOD_C  ), // Input clock period in nstops resolution (i.e.33.333is30MHz).
    // CLKOUT0_DIVIDE-CLKOUT5_DIVIDE:Divide amount for each CLKOUT(1-128)
    .CLKOUT0_DIVIDE     ( CLKOUT0_DIVIDE_C ),
    .CLKOUT1_DIVIDE     ( 1                ),
    .CLKOUT2_DIVIDE     ( 1                ),
    .CLKOUT3_DIVIDE     ( 1                ),
    .CLKOUT4_DIVIDE     ( 1                ),
    .CLKOUT5_DIVIDE     ( 1                ),
    // CLKOUT0_DUTY_CYCLE-CLKOUT5_DUTY_CYCLE: Duty cycle for each CLKOUT(0.01-0.99).
    .CLKOUT0_DUTY_CYCLE ( 0.5              ),
    .CLKOUT1_DUTY_CYCLE ( 0.5              ),
    .CLKOUT2_DUTY_CYCLE ( 0.5              ),
    .CLKOUT3_DUTY_CYCLE ( 0.5              ),
    .CLKOUT4_DUTY_CYCLE ( 0.5              ),
    .CLKOUT5_DUTY_CYCLE ( 0.5              ),
    // CLKOUT0_PHASE-CLKOUT4_PHASE: Phase offset for each CLKOUT(-360.000-360.000).
    .CLKOUT0_PHASE      ( 0.0              ),
    .CLKOUT1_PHASE      ( 0.0              ),
    .CLKOUT2_PHASE      ( 0.0              ),
    .CLKOUT3_PHASE      ( 0.0              ),
    .CLKOUT4_PHASE      ( 0.0              ),
    .CLKOUT5_PHASE      ( 0.0              ),
    .DIVCLK_DIVIDE      ( DIVCLK_DIVIDE_C  ), // Master division value, (1-56)
    .REF_JITTER1        ( 0.1              ), // Reference input jitter in UI,(0.000-0.999).
    .STARTUP_WAIT       ( "FALSE"          )  // Delay DONE until PLL Locks, ("TRUE"/"FALSE")
  ) plle2_base_i0 (
    // Clock Outputs: 1-bit (each) output: User configurable clock outputs
    .CLKOUT0            ( clk_mclk_int     ), // 1-bit output: CLKOUT0
    .CLKOUT1            (                  ), // 1-bit output: CLKOUT1
    .CLKOUT2            (                  ), // 1-bit output: CLKOUT2
    .CLKOUT3            (                  ), // 1-bit output: CLKOUT3
    .CLKOUT4            (                  ), // 1-bit output: CLKOUT4
    .CLKOUT5            (                  ), // 1-bit output: CLKOUT5
    // Feedback Clocks: 1-bit (each) output: Clock feedback ports
    .CLKFBOUT           ( clk_pll0_fb0     ), // 1-bit output: Feedback clock
    .LOCKED             ( clk_pll_locked0  ), // 1-bit output: LOCK
    .CLKIN1             ( clk              ), // 1-bit input: Input clock
    // Control Ports: 1-bit (each) input: PLL control ports
    .PWRDWN             ( '0               ), // 1-bit input: Power-down
    .RST                ( !rst_n           ), // 1-bit input: Reset
    // Feedback Clocks: 1-bit (each) input: Clock feedback ports
    .CLKFBIN            ( clk_pll0_fb0     )  // 1-bit input: Feedback clock
  );

endmodule

`default_nettype wire
