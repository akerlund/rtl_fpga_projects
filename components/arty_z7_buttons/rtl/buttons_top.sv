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

module arty_z7_buttons_top (
    input  wire  clk,
    input  wire  rst_n,

    input  wire  btn_0,
    input  wire  btn_1,
    input  wire  btn_2,
    input  wire  btn_3,

    output logic btn_0_tgl,
    output logic btn_1_tgl,
    output logic btn_2_tgl,
    output logic btn_3_tgl
  );


  button_core button_core_i0 (
    .clk                 ( clk       ),
    .rst_n               ( rst_n     ),
    .button_in_pin       ( btn_0     ),
    .button_press_toggle ( btn_0_tgl )
  );

  // Buttons
  button_core button_core_i1 (
    .clk                 ( clk       ),
    .rst_n               ( rst_n     ),
    .button_in_pin       ( btn_1     ),
    .button_press_toggle ( btn_1_tgl )
  );


  button_core button_core_i2 (
    .clk                 ( clk       ),
    .rst_n               ( rst_n     ),
    .button_in_pin       ( btn_2     ),
    .button_press_toggle ( btn_2_tgl )
  );

  button_core button_core_i3 (
    .clk                 ( clk       ),
    .rst_n               ( rst_n     ),
    .button_in_pin       ( btn_3     ),
    .button_press_toggle ( btn_3_tgl )
  );

endmodule

`default_nettype wire
