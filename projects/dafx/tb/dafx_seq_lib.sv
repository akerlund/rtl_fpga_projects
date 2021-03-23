////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2020 Fredrik Åkerlund
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

class cir_send_audio_seq extends vip_axi4s_seq;

  const real pi = 3.1415;
  protected logic [VIP_CIR_CFG_C.VIP_AXI4S_TDATA_WIDTH_P-1 : 0] _sine_data [$];
  protected real _samples_per_period;
  protected real _fs_ns;
  protected int  _fs_clk;

  real clock_period;
  real f;
  real fs;

  `uvm_object_utils(cir_send_audio_seq)

  function new(string name = "cir_send_audio_seq");
    super.new(name);
  endfunction


  task body();

    this.set_burst_length(2);
    this.set_data_type(VIP_AXI4S_TDATA_CUSTOM_E);
    this.set_tstrb(VIP_AXI4S_TSTRB_ALL_E);

    generate_sin();
    _fs_ns  = 1 / fs * 1000000000.0;
    _fs_clk = int(_fs_ns/clock_period);

    forever begin
      for (int i = 0; i < _sine_data.size(); i++) begin
        _custom_data.push_back(_sine_data[i]); // Left channel
        _custom_data.push_back('0);            // Right channel
        super.body();
        _custom_data.delete();
        #(_fs_clk*clock_period);
      end
    end

  endtask



  function void generate_sin();

    logic [N_BITS_C-1 : 0] _nq;
    real                   _samples_per_period = fs / f;

    for (int i = 0; i < int'(_samples_per_period); i++) begin
      _nq = float_to_fixed_point($sin(2*pi*i*f/fs), Q_BITS_C);
      //`uvm_info(get_name(), $sformatf("%d: sin = (%f=%f)", i, $sin(2*pi*i*f/fs), fixed_point_to_float(_nq, N_BITS_C, Q_BITS_C)), UVM_LOW)
      _sine_data.push_back(_nq << 9);
    end
  endfunction

endclass
