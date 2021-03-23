////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2021 Fredrik Åkerlund
// https://github.com/akerlund/VIP
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

class tc_dafx extends dafx_base_test;

  `uvm_component_utils(tc_dafx)

  function new(string name = "tc_dafx", uvm_component parent = null);
    super.new(name, parent);
  endfunction


  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction


  task run_phase(uvm_phase phase);

    super.run_phase(phase);
    phase.raise_objection(this);

    cir_send_audio_seq0.f            = 441.0;
    cir_send_audio_seq0.fs           = 44100.0;
    cir_send_audio_seq0.clock_period = clk_rst_config0.clock_period;

    cr_osc0_frequency  = float_to_fixed_point(1000.0, Q_BITS_C);
    cr_osc0_duty_cycle = float_to_fixed_point(75.0,   Q_BITS_C);
    reg_model.dafx.osc0_frequency.write(uvm_status,  cr_osc0_frequency);
    reg_model.dafx.osc0_duty_cycle.write(uvm_status, cr_osc0_duty_cycle);

    fork
      cir_send_audio_seq0.start(v_sqr.cir_sequencer);
    join_none

    clk_delay(1000000);

    cr_osc0_frequency  = float_to_fixed_point(2000.0, Q_BITS_C);
    cr_osc0_duty_cycle = float_to_fixed_point(55.0,   Q_BITS_C);
    reg_model.dafx.osc0_frequency.write(uvm_status,  cr_osc0_frequency);
    reg_model.dafx.osc0_duty_cycle.write(uvm_status, cr_osc0_duty_cycle);

    clk_delay(100);

    `uvm_info(get_name(), $sformatf("Done!"), UVM_LOW)
    phase.drop_objection(this);

  endtask

endclass
