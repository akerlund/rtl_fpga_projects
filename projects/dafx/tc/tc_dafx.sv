////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2021 Fredrik Åkerlund
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

    cr_osc0_frequency       = float_to_fixed_point(1000.0, Q_BITS_C);
    cr_osc0_duty_cycle      = 255;
    cr_mix_output_gain      = float_to_fixed_point(1.0,    Q_BITS_C);
    cr_mix_channel_gain_0   = float_to_fixed_point(1.0,    Q_BITS_C);
    cr_mix_channel_gain_1   = float_to_fixed_point(1.0,    Q_BITS_C);
    cr_mix_channel_gain_2   = float_to_fixed_point(1.0,    Q_BITS_C);
    cr_osc0_waveform_select = OSC_SQUARE_E;

    `uvm_info(get_name(), $sformatf("Writing to configuration registers"), UVM_LOW)
    reg_model.dafx.osc0_frequency.write(uvm_status,  cr_osc0_frequency);
    reg_model.dafx.osc0_duty_cycle.write(uvm_status, cr_osc0_duty_cycle);
    reg_model.dafx.mixer_output_gain.write(uvm_status, cr_mix_output_gain);
    reg_model.dafx.mixer_channel_gain_0.write(uvm_status, cr_mix_channel_gain_0);
    reg_model.dafx.mixer_channel_gain_1.write(uvm_status, cr_mix_channel_gain_1);
    reg_model.dafx.mixer_channel_gain_2.write(uvm_status, cr_mix_channel_gain_2);

    `uvm_info(get_name(), $sformatf("Forking ADC process"), UVM_LOW)
    fork
      cir_send_audio_seq0.start(v_sqr.cir_sequencer);
    join_none

    clk_delay(10000);

    `uvm_info(get_name(), $sformatf("Changing frequency and duty cycle"), UVM_LOW)
    cr_osc0_frequency  = float_to_fixed_point(2000.0, Q_BITS_C);
    cr_osc0_duty_cycle = 511;
    reg_model.dafx.osc0_frequency.write(uvm_status,  cr_osc0_frequency);
    reg_model.dafx.osc0_duty_cycle.write(uvm_status, cr_osc0_duty_cycle);

    clk_delay(10000);

    `uvm_info(get_name(), $sformatf("Done!"), UVM_LOW)
    phase.drop_objection(this);

  endtask

endclass
