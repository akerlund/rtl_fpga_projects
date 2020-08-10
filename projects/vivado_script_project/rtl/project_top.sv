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

`default_nettype none

module project_top #(
    parameter integer C_S00_AXI_DATA_WIDTH = 32,
    parameter integer C_S00_AXI_ADDR_WIDTH = 7
  )(

    // Clock and reset
    input  wire                                   clk,
    input  wire                                   rst_n,

    // Arty Z7 LEDS
    output logic                                  led_0,
    output logic                                  led_1,
    output logic                                  led_2,
    output logic                                  led_3,

    // Arty Z7 buttons
    input  wire                                   btn_0,
    input  wire                                   btn_1,
    input  wire                                   btn_2,
    input  wire                                   btn_3,


    // ---------------------------------------------------------------------------
    // AXI register ports
    // ---------------------------------------------------------------------------

    // Clock and reset
    input  wire                                   s00_axi_aclk,
    input  wire                                   s00_axi_aresetn,

    // Write Address Channel
    input  wire      [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
    input  wire                           [2 : 0] s00_axi_awprot,
    input  wire                                   s00_axi_awvalid,
    output logic                                  s00_axi_awready,

    // Write Data Channel
    input  wire      [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
    input  wire  [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
    input  wire                                   s00_axi_wvalid,
    output logic                                  s00_axi_wready,

    // Write Response Channel
    output logic                          [1 : 0] s00_axi_bresp,
    output logic                                  s00_axi_bvalid,
    input  wire                                   s00_axi_bready,

    // Read Address Channel
    input  wire      [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
    input  wire                           [2 : 0] s00_axi_arprot,
    input  wire                                   s00_axi_arvalid,
    output logic                                  s00_axi_arready,

    // Read Data Channel
    output logic     [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
    output logic                          [1 : 0] s00_axi_rresp,
    output logic                                  s00_axi_rvalid,
    input  wire                                   s00_axi_rready
  );


  logic btn_0_tgl;
  logic btn_1_tgl;
  logic btn_2_tgl;


  // AXI4-S registers
  logic [C_S00_AXI_DATA_WIDTH-1 : 0] cr_led_0;
  logic [C_S00_AXI_DATA_WIDTH-1 : 0] sr_led_2;


  // Toggles the LEDs
  always_ff @(posedge clk or negedge rst_n) begin : led_toggle_p0
    if (!rst_n) begin

      led_0 <= '0;
      led_1 <= '0;
      led_2 <= '0;

    end
    else begin

      // if (btn_0_tgl) begin
      //   led_0 <= ~led_0;
      // end

      led_0 <= cr_led_0[0];

      if (btn_1_tgl) begin
        led_1 <= ~led_1;
      end

      if (btn_2_tgl) begin
        led_2 <= ~led_2;
      end

    end
  end


  // Clock 'clk_sys' (125MHz) with LED process
  always_ff @(posedge clk or negedge rst_n) begin : led_blink_p0

    int counter_v;

    if (!rst_n) begin

      led_3     <= '0;
      counter_v <= 0;
      sr_led_2  <= '0;

    end
    else begin

      if ( counter_v == 62500000-1 ) begin
        led_3     <= ~led_3;
        counter_v <= 0;
        sr_led_2  <= sr_led_2 + 1;
      end
      else begin
        counter_v <= counter_v + 1;
      end

    end
  end


  // Buttons
  arty_z7_buttons_top arty_z7_buttons_top_i0 (
    .clk       ( clk       ),
    .rst_n     ( rst_n     ),
    .btn_0     ( btn_0     ),
    .btn_1     ( btn_1     ),
    .btn_2     ( btn_2     ),
    .btn_3     (           ),
    .btn_0_tgl ( btn_0_tgl ),
    .btn_1_tgl ( btn_1_tgl ),
    .btn_2_tgl ( btn_2_tgl ),
    .btn_3_tgl (           )
  );


  register_axi_slave #(
    .AXI_DATA_WIDTH_C ( C_S00_AXI_DATA_WIDTH ),
    .AXI_ADDR_WIDTH_C ( C_S00_AXI_ADDR_WIDTH )
  ) register_axi_slave_i0 (

    .clk              ( s00_axi_aclk         ), // input
    .rst_n            ( s00_axi_aresetn      ), // input

    .awaddr           ( s00_axi_awaddr       ), // input
    .awvalid          ( s00_axi_awvalid      ), // input
    .awready          ( s00_axi_awready      ), // output

    .wdata            ( s00_axi_wdata        ), // input
    .wstrb            ( s00_axi_wstrb        ), // input
    .wvalid           ( s00_axi_wvalid       ), // input
    .wready           ( s00_axi_wready       ), // output

    .bresp            ( s00_axi_bresp        ), // output
    .bvalid           ( s00_axi_bvalid       ), // output
    .bready           ( s00_axi_bready       ), // input

    .araddr           ( s00_axi_araddr       ), // input
    .arvalid          ( s00_axi_arvalid      ), // input
    .arready          ( s00_axi_arready      ), // output

    .rdata            ( s00_axi_rdata        ), // output
    .rresp            ( s00_axi_rresp        ), // output
    .rvalid           ( s00_axi_rvalid       ), // output
    .rready           ( s00_axi_rready       ), // input

    .cr_led_0         ( cr_led_0             ), // output
    .sr_led_2         ( sr_led_2             )  // input
  );







endmodule

`default_nettype wire
