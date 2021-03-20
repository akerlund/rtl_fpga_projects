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
class dafx_block extends uvm_reg_block;

  `uvm_object_utils(dafx_block)

  rand hardware_version_reg hardware_version;
  rand mixer_output_gain_reg mixer_output_gain;
  rand mixer_channel_gain_0_reg mixer_channel_gain_0;
  rand mixer_channel_gain_1_reg mixer_channel_gain_1;
  rand mixer_channel_gain_2_reg mixer_channel_gain_2;
  rand osc0_waveform_select_reg osc0_waveform_select;
  rand osc0_frequency_reg osc0_frequency;
  rand osc0_duty_cycle_reg osc0_duty_cycle;
  rand cir_min_adc_amplitude_reg cir_min_adc_amplitude;
  rand cir_max_adc_amplitude_reg cir_max_adc_amplitude;
  rand cir_min_dac_amplitude_reg cir_min_dac_amplitude;
  rand cir_max_dac_amplitude_reg cir_max_dac_amplitude;
  rand clear_adc_amplitude_reg clear_adc_amplitude;
  rand clear_irq_0_reg clear_irq_0;
  rand clear_irq_1_reg clear_irq_1;
  rand mix_out_left_reg mix_out_left;
  rand mix_out_right_reg mix_out_right;


  function new (string name = "dafx_block");
    super.new(name, build_coverage(UVM_NO_COVERAGE));
  endfunction


  function void build();

    hardware_version = hardware_version_reg::type_id::create("hardware_version");
    hardware_version.build();
    hardware_version.configure(this);

    mixer_output_gain = mixer_output_gain_reg::type_id::create("mixer_output_gain");
    mixer_output_gain.build();
    mixer_output_gain.configure(this);

    mixer_channel_gain_0 = mixer_channel_gain_0_reg::type_id::create("mixer_channel_gain_0");
    mixer_channel_gain_0.build();
    mixer_channel_gain_0.configure(this);

    mixer_channel_gain_1 = mixer_channel_gain_1_reg::type_id::create("mixer_channel_gain_1");
    mixer_channel_gain_1.build();
    mixer_channel_gain_1.configure(this);

    mixer_channel_gain_2 = mixer_channel_gain_2_reg::type_id::create("mixer_channel_gain_2");
    mixer_channel_gain_2.build();
    mixer_channel_gain_2.configure(this);

    osc0_waveform_select = osc0_waveform_select_reg::type_id::create("osc0_waveform_select");
    osc0_waveform_select.build();
    osc0_waveform_select.configure(this);

    osc0_frequency = osc0_frequency_reg::type_id::create("osc0_frequency");
    osc0_frequency.build();
    osc0_frequency.configure(this);

    osc0_duty_cycle = osc0_duty_cycle_reg::type_id::create("osc0_duty_cycle");
    osc0_duty_cycle.build();
    osc0_duty_cycle.configure(this);

    cir_min_adc_amplitude = cir_min_adc_amplitude_reg::type_id::create("cir_min_adc_amplitude");
    cir_min_adc_amplitude.build();
    cir_min_adc_amplitude.configure(this);

    cir_max_adc_amplitude = cir_max_adc_amplitude_reg::type_id::create("cir_max_adc_amplitude");
    cir_max_adc_amplitude.build();
    cir_max_adc_amplitude.configure(this);

    cir_min_dac_amplitude = cir_min_dac_amplitude_reg::type_id::create("cir_min_dac_amplitude");
    cir_min_dac_amplitude.build();
    cir_min_dac_amplitude.configure(this);

    cir_max_dac_amplitude = cir_max_dac_amplitude_reg::type_id::create("cir_max_dac_amplitude");
    cir_max_dac_amplitude.build();
    cir_max_dac_amplitude.configure(this);

    clear_adc_amplitude = clear_adc_amplitude_reg::type_id::create("clear_adc_amplitude");
    clear_adc_amplitude.build();
    clear_adc_amplitude.configure(this);

    clear_irq_0 = clear_irq_0_reg::type_id::create("clear_irq_0");
    clear_irq_0.build();
    clear_irq_0.configure(this);

    clear_irq_1 = clear_irq_1_reg::type_id::create("clear_irq_1");
    clear_irq_1.build();
    clear_irq_1.configure(this);

    mix_out_left = mix_out_left_reg::type_id::create("mix_out_left");
    mix_out_left.build();
    mix_out_left.configure(this);

    mix_out_right = mix_out_right_reg::type_id::create("mix_out_right");
    mix_out_right.build();
    mix_out_right.configure(this);



    default_map = create_map("dafx_map", 0, 4, UVM_LITTLE_ENDIAN);

    default_map.add_reg(hardware_version, 0, "RO");
    default_map.add_reg(mixer_output_gain, 4, "RW");
    default_map.add_reg(mixer_channel_gain_0, 8, "RW");
    default_map.add_reg(mixer_channel_gain_1, 12, "RW");
    default_map.add_reg(mixer_channel_gain_2, 16, "RW");
    default_map.add_reg(osc0_waveform_select, 20, "RW");
    default_map.add_reg(osc0_frequency, 24, "RW");
    default_map.add_reg(osc0_duty_cycle, 28, "RW");
    default_map.add_reg(cir_min_adc_amplitude, 32, "RO");
    default_map.add_reg(cir_max_adc_amplitude, 36, "RO");
    default_map.add_reg(cir_min_dac_amplitude, 40, "RO");
    default_map.add_reg(cir_max_dac_amplitude, 44, "RO");
    default_map.add_reg(clear_adc_amplitude, 48, "WO");
    default_map.add_reg(clear_irq_0, 52, "WO");
    default_map.add_reg(clear_irq_1, 56, "WO");
    default_map.add_reg(mix_out_left, 60, "RO");
    default_map.add_reg(mix_out_right, 64, "RO");


    lock_model();

  endfunction

endclass
