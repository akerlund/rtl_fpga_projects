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
// -----------------------------------------------------------------------------
// Hardware version
// -----------------------------------------------------------------------------
class hardware_version_reg extends uvm_reg;

  `uvm_object_utils(hardware_version_reg)

  rand uvm_reg_field sr_hardware_version;


  function new (string name = "hardware_version_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction


  function void build();


    // -----------------------------------------------------------------------------
    // Hardware version
    // -----------------------------------------------------------------------------
    sr_hardware_version = uvm_reg_field::type_id::create("sr_hardware_version");
    sr_hardware_version.configure(
      .parent(this),
      .size(AXI_DATA_WIDTH_P),
      .lsb_pos(0),
      .access("RO"),
      .volatile(0),
      .reset(0),
      .has_reset(0),
      .is_rand(0),
      .individually_accessible(0)
    );
    add_hdl_path_slice("sr_hardware_version", 0, AXI_DATA_WIDTH_P);

  endfunction

endclass

// -----------------------------------------------------------------------------
// Mixer's output gain
// -----------------------------------------------------------------------------
class mixer_output_gain_reg extends uvm_reg;

  `uvm_object_utils(mixer_output_gain_reg)

  rand uvm_reg_field cr_mix_output_gain;


  function new (string name = "mixer_output_gain_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction


  function void build();


    // -----------------------------------------------------------------------------
    // Mixer's output gain
    // -----------------------------------------------------------------------------
    cr_mix_output_gain = uvm_reg_field::type_id::create("cr_mix_output_gain");
    cr_mix_output_gain.configure(
      .parent(this),
      .size(GAIN_WIDTH_P),
      .lsb_pos(0),
      .access("RW"),
      .volatile(0),
      .reset((1 <<< Q_BITS_P)),
      .has_reset(1),
      .is_rand(0),
      .individually_accessible(0)
    );
    add_hdl_path_slice("cr_mix_output_gain", 0, GAIN_WIDTH_P);

  endfunction

endclass

// -----------------------------------------------------------------------------
// Mixer's input gain of channel 0
// -----------------------------------------------------------------------------
class mixer_channel_gain_0_reg extends uvm_reg;

  `uvm_object_utils(mixer_channel_gain_0_reg)

  rand uvm_reg_field cr_mix_channel_gain_0;


  function new (string name = "mixer_channel_gain_0_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction


  function void build();


    // -----------------------------------------------------------------------------
    // Mixer's input gain of channel 0
    // -----------------------------------------------------------------------------
    cr_mix_channel_gain_0 = uvm_reg_field::type_id::create("cr_mix_channel_gain_0");
    cr_mix_channel_gain_0.configure(
      .parent(this),
      .size(GAIN_WIDTH_P),
      .lsb_pos(0),
      .access("RW"),
      .volatile(0),
      .reset((1 <<< Q_BITS_P)),
      .has_reset(1),
      .is_rand(0),
      .individually_accessible(0)
    );
    add_hdl_path_slice("cr_mix_channel_gain_0", 0, GAIN_WIDTH_P);

  endfunction

endclass

// -----------------------------------------------------------------------------
// Mixer's input gain of channel 1
// -----------------------------------------------------------------------------
class mixer_channel_gain_1_reg extends uvm_reg;

  `uvm_object_utils(mixer_channel_gain_1_reg)

  rand uvm_reg_field cr_mix_channel_gain_1;


  function new (string name = "mixer_channel_gain_1_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction


  function void build();


    // -----------------------------------------------------------------------------
    // Mixer's input gain of channel 1
    // -----------------------------------------------------------------------------
    cr_mix_channel_gain_1 = uvm_reg_field::type_id::create("cr_mix_channel_gain_1");
    cr_mix_channel_gain_1.configure(
      .parent(this),
      .size(GAIN_WIDTH_P),
      .lsb_pos(0),
      .access("RW"),
      .volatile(0),
      .reset((1 <<< Q_BITS_P)),
      .has_reset(1),
      .is_rand(0),
      .individually_accessible(0)
    );
    add_hdl_path_slice("cr_mix_channel_gain_1", 0, GAIN_WIDTH_P);

  endfunction

endclass

// -----------------------------------------------------------------------------
// Mixer's input gain of channel 2
// -----------------------------------------------------------------------------
class mixer_channel_gain_2_reg extends uvm_reg;

  `uvm_object_utils(mixer_channel_gain_2_reg)

  rand uvm_reg_field cr_mix_channel_gain_2;


  function new (string name = "mixer_channel_gain_2_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction


  function void build();


    // -----------------------------------------------------------------------------
    // Mixer's input gain of channel 2
    // -----------------------------------------------------------------------------
    cr_mix_channel_gain_2 = uvm_reg_field::type_id::create("cr_mix_channel_gain_2");
    cr_mix_channel_gain_2.configure(
      .parent(this),
      .size(GAIN_WIDTH_P),
      .lsb_pos(0),
      .access("RW"),
      .volatile(0),
      .reset((1 <<< Q_BITS_P)),
      .has_reset(1),
      .is_rand(0),
      .individually_accessible(0)
    );
    add_hdl_path_slice("cr_mix_channel_gain_2", 0, GAIN_WIDTH_P);

  endfunction

endclass

// -----------------------------------------------------------------------------
// Sets the waveform output of oscillator 0
// -----------------------------------------------------------------------------
class osc0_waveform_select_reg extends uvm_reg;

  `uvm_object_utils(osc0_waveform_select_reg)

  rand uvm_reg_field cr_osc0_waveform_select;


  function new (string name = "osc0_waveform_select_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction


  function void build();


    // -----------------------------------------------------------------------------
    // Sets the waveform output of oscillator 0
    // -----------------------------------------------------------------------------
    cr_osc0_waveform_select = uvm_reg_field::type_id::create("cr_osc0_waveform_select");
    cr_osc0_waveform_select.configure(
      .parent(this),
      .size(2),
      .lsb_pos(0),
      .access("RW"),
      .volatile(0),
      .reset(0),
      .has_reset(1),
      .is_rand(0),
      .individually_accessible(0)
    );
    add_hdl_path_slice("cr_osc0_waveform_select", 0, 2);

  endfunction

endclass

// -----------------------------------------------------------------------------
// Sets the frequency of oscillator 0
// -----------------------------------------------------------------------------
class osc0_frequency_reg extends uvm_reg;

  `uvm_object_utils(osc0_frequency_reg)

  rand uvm_reg_field cr_osc0_frequency;


  function new (string name = "osc0_frequency_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction


  function void build();


    // -----------------------------------------------------------------------------
    // Sets the frequency of oscillator 0
    // -----------------------------------------------------------------------------
    cr_osc0_frequency = uvm_reg_field::type_id::create("cr_osc0_frequency");
    cr_osc0_frequency.configure(
      .parent(this),
      .size(N_BITS_P),
      .lsb_pos(0),
      .access("RW"),
      .volatile(0),
      .reset((500 << Q_BITS_P)),
      .has_reset(1),
      .is_rand(0),
      .individually_accessible(0)
    );
    add_hdl_path_slice("cr_osc0_frequency", 0, N_BITS_P);

  endfunction

endclass

// -----------------------------------------------------------------------------
// Sets the duty cycle of the square wave
// -----------------------------------------------------------------------------
class osc0_duty_cycle_reg extends uvm_reg;

  `uvm_object_utils(osc0_duty_cycle_reg)

  rand uvm_reg_field cr_osc0_duty_cycle;


  function new (string name = "osc0_duty_cycle_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction


  function void build();


    // -----------------------------------------------------------------------------
    // Sets the duty cycle of the square wave
    // -----------------------------------------------------------------------------
    cr_osc0_duty_cycle = uvm_reg_field::type_id::create("cr_osc0_duty_cycle");
    cr_osc0_duty_cycle.configure(
      .parent(this),
      .size(N_BITS_P),
      .lsb_pos(0),
      .access("RW"),
      .volatile(0),
      .reset(500),
      .has_reset(1),
      .is_rand(0),
      .individually_accessible(0)
    );
    add_hdl_path_slice("cr_osc0_duty_cycle", 0, N_BITS_P);

  endfunction

endclass

// -----------------------------------------------------------------------------
// Lowest value of the ADC
// -----------------------------------------------------------------------------
class cir_min_adc_amplitude_reg extends uvm_reg;

  `uvm_object_utils(cir_min_adc_amplitude_reg)

  rand uvm_reg_field sr_cir_min_adc_amplitude;


  function new (string name = "cir_min_adc_amplitude_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction


  function void build();


    // -----------------------------------------------------------------------------
    // Lowest value of the ADC
    // -----------------------------------------------------------------------------
    sr_cir_min_adc_amplitude = uvm_reg_field::type_id::create("sr_cir_min_adc_amplitude");
    sr_cir_min_adc_amplitude.configure(
      .parent(this),
      .size(AUDIO_WIDTH_P),
      .lsb_pos(0),
      .access("RO"),
      .volatile(0),
      .reset(0),
      .has_reset(0),
      .is_rand(0),
      .individually_accessible(0)
    );
    add_hdl_path_slice("sr_cir_min_adc_amplitude", 0, AUDIO_WIDTH_P);

  endfunction

endclass

// -----------------------------------------------------------------------------
// Highest value of the ADC
// -----------------------------------------------------------------------------
class cir_max_adc_amplitude_reg extends uvm_reg;

  `uvm_object_utils(cir_max_adc_amplitude_reg)

  rand uvm_reg_field sr_cir_max_adc_amplitude;


  function new (string name = "cir_max_adc_amplitude_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction


  function void build();


    // -----------------------------------------------------------------------------
    // Highest value of the ADC
    // -----------------------------------------------------------------------------
    sr_cir_max_adc_amplitude = uvm_reg_field::type_id::create("sr_cir_max_adc_amplitude");
    sr_cir_max_adc_amplitude.configure(
      .parent(this),
      .size(AUDIO_WIDTH_P),
      .lsb_pos(0),
      .access("RO"),
      .volatile(0),
      .reset(0),
      .has_reset(0),
      .is_rand(0),
      .individually_accessible(0)
    );
    add_hdl_path_slice("sr_cir_max_adc_amplitude", 0, AUDIO_WIDTH_P);

  endfunction

endclass

// -----------------------------------------------------------------------------
// Clears the max and min aplitude values
// -----------------------------------------------------------------------------
class clear_adc_amplitude_reg extends uvm_reg;

  `uvm_object_utils(clear_adc_amplitude_reg)

  rand uvm_reg_field cmd_clear_adc_amplitude;


  function new (string name = "clear_adc_amplitude_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction


  function void build();


    // -----------------------------------------------------------------------------
    // Clears the max and min aplitude values
    // -----------------------------------------------------------------------------
    cmd_clear_adc_amplitude = uvm_reg_field::type_id::create("cmd_clear_adc_amplitude");
    cmd_clear_adc_amplitude.configure(
      .parent(this),
      .size(1),
      .lsb_pos(0),
      .access("WO"),
      .volatile(0),
      .reset(0),
      .has_reset(0),
      .is_rand(0),
      .individually_accessible(0)
    );
    add_hdl_path_slice("cmd_clear_adc_amplitude", 0, 1);

  endfunction

endclass

// -----------------------------------------------------------------------------
// Clears the IRQ0 bit
// -----------------------------------------------------------------------------
class clear_irq_0_reg extends uvm_reg;

  `uvm_object_utils(clear_irq_0_reg)

  rand uvm_reg_field cmd_clear_irq_0;


  function new (string name = "clear_irq_0_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction


  function void build();


    // -----------------------------------------------------------------------------
    // Clears the IRQ0 bit
    // -----------------------------------------------------------------------------
    cmd_clear_irq_0 = uvm_reg_field::type_id::create("cmd_clear_irq_0");
    cmd_clear_irq_0.configure(
      .parent(this),
      .size(1),
      .lsb_pos(0),
      .access("WO"),
      .volatile(0),
      .reset(0),
      .has_reset(1),
      .is_rand(0),
      .individually_accessible(0)
    );
    add_hdl_path_slice("cmd_clear_irq_0", 0, 1);

  endfunction

endclass

// -----------------------------------------------------------------------------
// Clears the IRQ1 bit
// -----------------------------------------------------------------------------
class clear_irq_1_reg extends uvm_reg;

  `uvm_object_utils(clear_irq_1_reg)

  rand uvm_reg_field cmd_clear_irq_1;


  function new (string name = "clear_irq_1_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction


  function void build();


    // -----------------------------------------------------------------------------
    // Clears the IRQ1 bit
    // -----------------------------------------------------------------------------
    cmd_clear_irq_1 = uvm_reg_field::type_id::create("cmd_clear_irq_1");
    cmd_clear_irq_1.configure(
      .parent(this),
      .size(1),
      .lsb_pos(0),
      .access("WO"),
      .volatile(0),
      .reset(0),
      .has_reset(1),
      .is_rand(0),
      .individually_accessible(0)
    );
    add_hdl_path_slice("cmd_clear_irq_1", 0, 1);

  endfunction

endclass

