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

`uvm_analysis_imp_decl(_mst0_awaddr_port)
`uvm_analysis_imp_decl(_mst0_bresp_port)
`uvm_analysis_imp_decl(_mst1_araddr_port)
`uvm_analysis_imp_decl(_mst1_rdata_port)
`uvm_analysis_imp_decl(_slv2_bresp_port)
`uvm_analysis_imp_decl(_slv2_rdata_port)
`uvm_analysis_imp_decl(_slv3_araddr_port)
`uvm_analysis_imp_decl(_slv3_rdata_port)
`uvm_analysis_imp_decl(_mst4_araddr_port)
`uvm_analysis_imp_decl(_mst4_rdata_port)

class dafx_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(dafx_scoreboard)

  // For raising objections
  uvm_phase current_phase;

  // Test counters
  int number_of_compared    = 0;
  int number_of_passed      = 0;
  int number_of_failed      = 0;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  function void start_of_simulation_phase(uvm_phase phase);
    current_phase = phase;
    super.start_of_simulation_phase(phase);
  endfunction

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  function void connect_phase(uvm_phase phase);
    current_phase = phase;
    super.connect_phase(current_phase);
  endfunction

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  virtual task run_phase(uvm_phase phase);
    current_phase = phase;
    super.run_phase(current_phase);
  endtask

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  function void check_phase(uvm_phase phase);
    current_phase = phase;
    super.check_phase(current_phase);
  endfunction

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  virtual function void handle_reset();
  endfunction

endclass
