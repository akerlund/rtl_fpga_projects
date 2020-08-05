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

module project_top (
    input  wire  clk,

    output logic led_0,
    output logic led_1,
    output logic led_2,
    output logic led_3,

    input  wire  btn_0,
    input  wire  btn_1,
    input  wire  btn_2,
    input  wire  btn_3
  );

  logic btn_0_tgl;
  logic btn_1_tgl;
  logic btn_2_tgl;
  logic btn_3_tgl;
  logic rst_n;

  assign led_0 = btn_0_tgl;
  assign led_1 = btn_1_tgl;
  assign led_2 = btn_2;


  assign rst_n = btn_3;
  //assign led_3 = btn_3_tgl;
  // Buttons
  arty_z7_buttons_top arty_z7_buttons_top_i0(
    .clk       ( clk       ),
    .rst_n     ( rst_n     ),
    .btn_0     ( btn_0     ),
    .btn_1     ( btn_1     ),
    .btn_2     ( btn_2     ),
    .btn_3     ( btn_3     ),
    .btn_0_tgl ( btn_0_tgl ),
    .btn_1_tgl ( btn_1_tgl ),
    .btn_2_tgl ( btn_2_tgl ),
    .btn_3_tgl ( btn_3_tgl )
  );


  // Clock 'clk_sys' (125MHz) with LED process
  always_ff @(posedge clk or negedge rst_n) begin

    int counter_v;

    if (!rst_n) begin
      led_3     <= '0;
      counter_v <= 0;
    end
    else begin
      if ( counter_v == 62500000-1 ) begin
        led_3     <= ~led_3;
        counter_v <= 0;
      end
      else begin
        counter_v <= counter_v + 1;
      end
    end
  end


endmodule

`default_nettype wire
