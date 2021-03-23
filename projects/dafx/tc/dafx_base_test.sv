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

class dafx_base_test extends uvm_test;

  `uvm_component_utils(dafx_base_test)

  // ---------------------------------------------------------------------------
  // UVM variables
  // ---------------------------------------------------------------------------

  uvm_table_printer uvm_table_printer0;
  report_server     report_server0;

  // ---------------------------------------------------------------------------
  // Testbench variables
  // ---------------------------------------------------------------------------

  dafx_env               tb_env;
  dafx_virtual_sequencer v_sqr;
  register_model         reg_model;
  uvm_status_e           uvm_status;
  uvm_reg_data_t         value;
  real                   memory_size;

  // ---------------------------------------------------------------------------
  // VIP Agent configurations
  // ---------------------------------------------------------------------------

  clk_rst_config  clk_rst_config0;
  clk_rst_config  clk_rst_config1;
  vip_axi4_config axi4_mem_cfg0;

  // ---------------------------------------------------------------------------
  // Sequences
  // ---------------------------------------------------------------------------

  reset_sequence     reset_seq0;
  cir_send_audio_seq cir_send_audio_seq0;

  logic  [GAIN_WIDTH_C-1 : 0] cr_mix_output_gain;
  logic  [GAIN_WIDTH_C-1 : 0] cr_mix_channel_gain_0;
  logic  [GAIN_WIDTH_C-1 : 0] cr_mix_channel_gain_1;
  logic  [GAIN_WIDTH_C-1 : 0] cr_mix_channel_gain_2;
  logic               [1 : 0] cr_osc0_waveform_select;
  logic      [N_BITS_C-1 : 0] cr_osc0_frequency;
  logic      [N_BITS_C-1 : 0] cr_osc0_duty_cycle;
  logic [AUDIO_WIDTH_C-1 : 0] sr_cir_min_adc_amplitude;
  logic [AUDIO_WIDTH_C-1 : 0] sr_cir_max_adc_amplitude;
  logic [AUDIO_WIDTH_C-1 : 0] sr_cir_min_dac_amplitude;
  logic [AUDIO_WIDTH_C-1 : 0] sr_cir_max_dac_amplitude;


  function new(string name = "dafx_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction


  virtual function void build_phase(uvm_phase phase);

    super.build_phase(phase);

    // UVM
    uvm_config_db #(uvm_verbosity)::set(this, "*", "recording_detail", UVM_FULL);

    report_server0 = new("report_server0");
    uvm_report_server::set_server(report_server0);

    uvm_table_printer0                     = new();
    uvm_table_printer0.knobs.depth         = 3;
    uvm_table_printer0.knobs.default_radix = UVM_DEC;

    // Environment
    tb_env = dafx_env::type_id::create("tb_env", this);

    // Configurations
    clk_rst_config0 = clk_rst_config::type_id::create("clk_rst_config0", this);
    clk_rst_config1 = clk_rst_config::type_id::create("clk_rst_config1", this);
    axi4_mem_cfg0   = vip_axi4_config::type_id::create("axi4_mem_cfg0",  this);

    axi4_mem_cfg0.vip_axi4_agent_type     = VIP_AXI4_SLAVE_AGENT_E;
    axi4_mem_cfg0.mem_slave               = TRUE;
    axi4_mem_cfg0.max_wready_delay_period = 8;
    axi4_mem_cfg0.max_rready_delay_period = 8;

    clk_rst_config0.clock_period = 8;
    clk_rst_config1.clock_period = 44;

    uvm_config_db #(clk_rst_config)::set(this,  {"tb_env.clk_rst_agent0", "*"}, "cfg", clk_rst_config0);
    uvm_config_db #(clk_rst_config)::set(this,  {"tb_env.clk_rst_agent1", "*"}, "cfg", clk_rst_config1);
    uvm_config_db #(vip_axi4_config)::set(this, {"tb_env.mem_agent0",     "*"}, "cfg", axi4_mem_cfg0);

  endfunction


  function void end_of_elaboration_phase(uvm_phase phase);

    super.end_of_elaboration_phase(phase);

    if (!uvm_config_db #(register_model)::get(null, "*", "reg_model", reg_model)) begin
      `uvm_fatal("NOREG", "No registered register model in the factory")
    end

    v_sqr = tb_env.virtual_sequencer;

    `uvm_info(get_type_name(), $sformatf("Topology of the test:\n%s", this.sprint(uvm_table_printer0)), UVM_LOW)
    `uvm_info(get_name(), {"VIP AXI4 Agent (Memory):\n", axi4_mem_cfg0.sprint()}, UVM_LOW)

  endfunction


  function void start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
    reset_seq0          = reset_sequence::type_id::create("reset_seq0");
    cir_send_audio_seq0 = cir_send_audio_seq::type_id::create("cir_send_audio_seq0");
  endfunction


  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    phase.raise_objection(this);
    reset_seq0.start(v_sqr.clk_rst_sequencer0);
    phase.drop_objection(this);
  endtask


  task clk_delay(int delay);
    #(delay*clk_rst_config0.clock_period);
  endtask

endclass
