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


module register_axi_slave #(
    parameter integer AXI_DATA_WIDTH_C = -1,
    parameter integer AXI_ADDR_WIDTH_C = -1
  )(

    // ---------------------------------------------------------------------------
    // AXI ports
    // ---------------------------------------------------------------------------

    // Clock and reset
    input  wire                               clk,
    input  wire                               rst_n,

    // Write Address Channel
    input  wire      [AXI_ADDR_WIDTH_C-1 : 0] awaddr,
    input  wire                               awvalid,
    output logic                              awready,

    // Write Data Channel
    input  wire      [AXI_DATA_WIDTH_C-1 : 0] wdata,
    input  wire  [(AXI_DATA_WIDTH_C/8)-1 : 0] wstrb,
    input  wire                               wvalid,
    output logic                              wready,

    // Write Response Channel
    output logic                      [1 : 0] bresp,
    output logic                              bvalid,
    input  wire                               bready,

    // Read Address Channel
    input  wire      [AXI_ADDR_WIDTH_C-1 : 0] araddr,
    input  wire                               arvalid,
    output logic                              arready,

    // Read Data Channel
    output logic     [AXI_DATA_WIDTH_C-1 : 0] rdata,
    output logic                      [1 : 0] rresp,
    output logic                              rvalid,
    input  wire                               rready,

    // ---------------------------------------------------------------------------
    // Register Ports
    // ---------------------------------------------------------------------------

    output logic       [AXI_DATA_WIDTH_C-1:0] cr_led_0,
    input  wire        [AXI_DATA_WIDTH_C-1:0] sr_led_2
  );

  // ---------------------------------------------------------------------------
  // Internal AXI signals
  // ---------------------------------------------------------------------------


  // Example-specific design signals
  // local parameter for addressing 32 bit / 64 bit AXI_DATA_WIDTH_C
  // ADDR_LSB_C is used for addressing 32/64 bit registers/memories
  // ADDR_LSB_C = 2 for 32 bits (n downto 2)
  // ADDR_LSB_C = 3 for 64 bits (n downto 3)
  localparam int ADDR_LSB_C          = (AXI_DATA_WIDTH_C / 32) + 1;
  localparam int OPT_MEM_ADDR_BITS_C = 4;

  //----------------------------------------------
  // Signals for user logic register space example
  //------------------------------------------------

  // ---------------------------------------------------------------------------
  // Slave Registers
  // ---------------------------------------------------------------------------

  logic [AXI_DATA_WIDTH_C-1 : 0] slv_reg0;
  logic [AXI_DATA_WIDTH_C-1 : 0] slv_reg1;
  logic [AXI_DATA_WIDTH_C-1 : 0] slv_reg2;
  logic [AXI_DATA_WIDTH_C-1 : 0] slv_reg3;
  logic [AXI_DATA_WIDTH_C-1 : 0] slv_reg4;
  logic [AXI_DATA_WIDTH_C-1 : 0] slv_reg5;
  logic [AXI_DATA_WIDTH_C-1 : 0] slv_reg6;
  logic [AXI_DATA_WIDTH_C-1 : 0] slv_reg7;
  logic [AXI_DATA_WIDTH_C-1 : 0] slv_reg8;
  logic [AXI_DATA_WIDTH_C-1 : 0] slv_reg9;
  logic [AXI_DATA_WIDTH_C-1 : 0] slv_reg10;
  logic [AXI_DATA_WIDTH_C-1 : 0] slv_reg11;
  logic [AXI_DATA_WIDTH_C-1 : 0] slv_reg12;
  logic [AXI_DATA_WIDTH_C-1 : 0] slv_reg13;
  logic [AXI_DATA_WIDTH_C-1 : 0] slv_reg14;
  logic [AXI_DATA_WIDTH_C-1 : 0] slv_reg15;
  logic [AXI_DATA_WIDTH_C-1 : 0] slv_reg16;
  logic [AXI_DATA_WIDTH_C-1 : 0] slv_reg17;
  logic [AXI_DATA_WIDTH_C-1 : 0] slv_reg18;
  logic [AXI_DATA_WIDTH_C-1 : 0] slv_reg19;
  logic [AXI_DATA_WIDTH_C-1 : 0] slv_reg20;
  logic [AXI_DATA_WIDTH_C-1 : 0] slv_reg21;
  logic [AXI_DATA_WIDTH_C-1 : 0] slv_reg22;
  logic [AXI_DATA_WIDTH_C-1 : 0] slv_reg23;
  logic [AXI_DATA_WIDTH_C-1 : 0] slv_reg24;
  logic [AXI_DATA_WIDTH_C-1 : 0] slv_reg25;
  logic [AXI_DATA_WIDTH_C-1 : 0] slv_reg26;
  logic [AXI_DATA_WIDTH_C-1 : 0] slv_reg27;
  logic [AXI_DATA_WIDTH_C-1 : 0] slv_reg28;
  logic [AXI_DATA_WIDTH_C-1 : 0] slv_reg29;
  logic [AXI_DATA_WIDTH_C-1 : 0] slv_reg30;
  logic [AXI_DATA_WIDTH_C-1 : 0] slv_reg31;

  // ---------------------------------------------------------------------------
  // Internal signals
  // ---------------------------------------------------------------------------

  logic                          aw_enable;
  logic [AXI_ADDR_WIDTH_C-1 : 0] awaddr_d0;
  logic                          write_enable;
  logic                          read_enable;
  logic [AXI_ADDR_WIDTH_C-1 : 0] araddr_d0;
  logic [AXI_DATA_WIDTH_C-1 : 0] rdata_d0;

  integer                        byte_index;

  // ---------------------------------------------------------------------------
  // Internal assignments
  // ---------------------------------------------------------------------------

  assign write_enable = wready  & wvalid  & awready && awvalid;
  assign read_enable  = arready & arvalid & ~rvalid;

  // ---------------------------------------------------------------------------
  // Register assignments
  // ---------------------------------------------------------------------------

  assign cr_led_0 = slv_reg0;



  // ---------------------------------------------------------------------------
  // Write Address Channel
  // Generate "awready" and internal address write enable
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      awaddr_d0 <= '0;
      awready   <= '0;
      aw_enable <= '1;
    end
    else begin

      // awready
      if (!awready && awvalid && wvalid && aw_enable) begin
        awready   <= '1;
        aw_enable <= '0;
      end
      else if (bready && bvalid) begin
        aw_enable <= '1;
        awready   <= '0;
      end
      else begin
        awready   <= '0;
      end

      // awaddr
      if (!awready && awvalid && wvalid && aw_enable) begin
        awaddr_d0 <= awaddr;
      end

    end
  end


  // ---------------------------------------------------------------------------
  // Write Data Channel
  // Generate "wready"
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wready <= '0;
    end
    else begin

      if (!wready && wvalid && awvalid && aw_enable) begin
        wready <= '1;
      end
      else begin
        wready <= '0;
      end

    end
  end



  // ---------------------------------------------------------------------------
  // Register writes
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      slv_reg0  <= 0;
      //slv_reg1  <= 0;
      slv_reg2  <= 0;
      slv_reg3  <= 0;
      slv_reg4  <= 0;
      slv_reg5  <= 0;
      slv_reg6  <= 0;
      slv_reg7  <= 0;
      slv_reg8  <= 0;
      slv_reg9  <= 0;
      slv_reg10 <= 0;
      slv_reg11 <= 0;
      slv_reg12 <= 0;
      slv_reg13 <= 0;
      slv_reg14 <= 0;
      slv_reg15 <= 0;
      slv_reg16 <= 0;
      slv_reg17 <= 0;
      slv_reg18 <= 0;
      slv_reg19 <= 0;
      slv_reg20 <= 0;
      slv_reg21 <= 0;
      slv_reg22 <= 0;
      slv_reg23 <= 0;
      slv_reg24 <= 0;
      slv_reg25 <= 0;
      slv_reg26 <= 0;
      slv_reg27 <= 0;
      slv_reg28 <= 0;
      slv_reg29 <= 0;
      slv_reg30 <= 0;
      slv_reg31 <= 0;

    end
    else begin

      if (write_enable) begin

        case (awaddr_d0[ADDR_LSB_C+OPT_MEM_ADDR_BITS_C : ADDR_LSB_C])

          5'h00: begin
            for (byte_index = 0; byte_index <= (AXI_DATA_WIDTH_C/8)-1; byte_index++) begin
              if (wstrb[byte_index] == 1) begin
                slv_reg0[(byte_index*8) +: 8] <= wdata[(byte_index*8) +: 8];
              end
            end
          end

          5'h01: begin
            for (byte_index = 0; byte_index <= (AXI_DATA_WIDTH_C/8)-1; byte_index++) begin
              if (wstrb[byte_index] == 1) begin
                //slv_reg1[(byte_index*8) +: 8] <= wdata[(byte_index*8) +: 8];
              end
            end
          end

          5'h02: begin
            for (byte_index = 0; byte_index <= (AXI_DATA_WIDTH_C/8)-1; byte_index++) begin
              if (wstrb[byte_index] == 1) begin
                slv_reg2[(byte_index*8) +: 8] <= wdata[(byte_index*8) +: 8];
              end
            end
          end

          5'h03: begin
            for (byte_index = 0; byte_index <= (AXI_DATA_WIDTH_C/8)-1; byte_index++) begin
              if (wstrb[byte_index] == 1) begin
                slv_reg3[(byte_index*8) +: 8] <= wdata[(byte_index*8) +: 8];
              end
            end
          end

          5'h04: begin
            for (byte_index = 0; byte_index <= (AXI_DATA_WIDTH_C/8)-1; byte_index++) begin
              if (wstrb[byte_index] == 1) begin
                slv_reg4[(byte_index*8) +: 8] <= wdata[(byte_index*8) +: 8];
              end
            end
          end

          5'h05: begin
            for (byte_index = 0; byte_index <= (AXI_DATA_WIDTH_C/8)-1; byte_index++) begin
              if (wstrb[byte_index] == 1) begin
                slv_reg5[(byte_index*8) +: 8] <= wdata[(byte_index*8) +: 8];
              end
            end
          end

          5'h06: begin
            for (byte_index = 0; byte_index <= (AXI_DATA_WIDTH_C/8)-1; byte_index++) begin
              if (wstrb[byte_index] == 1) begin
                slv_reg6[(byte_index*8) +: 8] <= wdata[(byte_index*8) +: 8];
              end
            end
          end

          5'h07: begin
            for (byte_index = 0; byte_index <= (AXI_DATA_WIDTH_C/8)-1; byte_index++) begin
              if (wstrb[byte_index] == 1) begin
                slv_reg7[(byte_index*8) +: 8] <= wdata[(byte_index*8) +: 8];
              end
            end
          end

          5'h08: begin
            for (byte_index = 0; byte_index <= (AXI_DATA_WIDTH_C/8)-1; byte_index++) begin
              if (wstrb[byte_index] == 1) begin
                slv_reg8[(byte_index*8) +: 8] <= wdata[(byte_index*8) +: 8];
              end
            end
          end

          5'h09: begin
            for (byte_index = 0; byte_index <= (AXI_DATA_WIDTH_C/8)-1; byte_index++) begin
              if (wstrb[byte_index] == 1) begin
                slv_reg9[(byte_index*8) +: 8] <= wdata[(byte_index*8) +: 8];
              end
            end
          end

          5'h0A: begin
            for (byte_index = 0; byte_index <= (AXI_DATA_WIDTH_C/8)-1; byte_index++) begin
              if (wstrb[byte_index] == 1) begin
                slv_reg10[(byte_index*8) +: 8] <= wdata[(byte_index*8) +: 8];
              end
            end
          end

          5'h0B: begin
            for (byte_index = 0; byte_index <= (AXI_DATA_WIDTH_C/8)-1; byte_index++) begin
              if (wstrb[byte_index] == 1) begin
                slv_reg11[(byte_index*8) +: 8] <= wdata[(byte_index*8) +: 8];
              end
            end
          end

          5'h0C: begin
            for (byte_index = 0; byte_index <= (AXI_DATA_WIDTH_C/8)-1; byte_index++) begin
              if (wstrb[byte_index] == 1) begin
                slv_reg12[(byte_index*8) +: 8] <= wdata[(byte_index*8) +: 8];
              end
            end
          end

          5'h0D: begin
            for (byte_index = 0; byte_index <= (AXI_DATA_WIDTH_C/8)-1; byte_index++) begin
              if (wstrb[byte_index] == 1) begin
                slv_reg13[(byte_index*8) +: 8] <= wdata[(byte_index*8) +: 8];
              end
            end
          end

          5'h0E: begin
            for (byte_index = 0; byte_index <= (AXI_DATA_WIDTH_C/8)-1; byte_index++) begin
              if (wstrb[byte_index] == 1) begin
                slv_reg14[(byte_index*8) +: 8] <= wdata[(byte_index*8) +: 8];
              end
            end
          end

          5'h0F: begin
            for (byte_index = 0; byte_index <= (AXI_DATA_WIDTH_C/8)-1; byte_index++) begin
              if (wstrb[byte_index] == 1) begin
                slv_reg15[(byte_index*8) +: 8] <= wdata[(byte_index*8) +: 8];
              end
            end
          end

          5'h10: begin
            for (byte_index = 0; byte_index <= (AXI_DATA_WIDTH_C/8)-1; byte_index++) begin
              if (wstrb[byte_index] == 1) begin
                slv_reg16[(byte_index*8) +: 8] <= wdata[(byte_index*8) +: 8];
              end
            end
          end

          5'h11: begin
            for (byte_index = 0; byte_index <= (AXI_DATA_WIDTH_C/8)-1; byte_index++) begin
              if (wstrb[byte_index] == 1) begin
                slv_reg17[(byte_index*8) +: 8] <= wdata[(byte_index*8) +: 8];
              end
            end
          end

          5'h12: begin
            for (byte_index = 0; byte_index <= (AXI_DATA_WIDTH_C/8)-1; byte_index++) begin
              if (wstrb[byte_index] == 1) begin
                slv_reg18[(byte_index*8) +: 8] <= wdata[(byte_index*8) +: 8];
              end
            end
          end

          5'h13: begin
            for (byte_index = 0; byte_index <= (AXI_DATA_WIDTH_C/8)-1; byte_index++) begin
              if (wstrb[byte_index] == 1) begin
                slv_reg19[(byte_index*8) +: 8] <= wdata[(byte_index*8) +: 8];
              end
            end
          end

          5'h14: begin
            for (byte_index = 0; byte_index <= (AXI_DATA_WIDTH_C/8)-1; byte_index++) begin
              if (wstrb[byte_index] == 1) begin
                slv_reg20[(byte_index*8) +: 8] <= wdata[(byte_index*8) +: 8];
              end
            end
          end

          5'h15: begin
            for (byte_index = 0; byte_index <= (AXI_DATA_WIDTH_C/8)-1; byte_index++) begin
              if (wstrb[byte_index] == 1) begin
                slv_reg21[(byte_index*8) +: 8] <= wdata[(byte_index*8) +: 8];
              end
            end
          end

          5'h16: begin
            for (byte_index = 0; byte_index <= (AXI_DATA_WIDTH_C/8)-1; byte_index++) begin
              if (wstrb[byte_index] == 1) begin
                slv_reg22[(byte_index*8) +: 8] <= wdata[(byte_index*8) +: 8];
              end
            end
          end

          5'h17: begin
            for (byte_index = 0; byte_index <= (AXI_DATA_WIDTH_C/8)-1; byte_index++) begin
              if (wstrb[byte_index] == 1) begin
                slv_reg23[(byte_index*8) +: 8] <= wdata[(byte_index*8) +: 8];
              end
            end
          end

          5'h18: begin
            for (byte_index = 0; byte_index <= (AXI_DATA_WIDTH_C/8)-1; byte_index++) begin
              if (wstrb[byte_index] == 1) begin
                slv_reg24[(byte_index*8) +: 8] <= wdata[(byte_index*8) +: 8];
              end
            end
          end

          5'h19: begin
            for (byte_index = 0; byte_index <= (AXI_DATA_WIDTH_C/8)-1; byte_index++) begin
              if (wstrb[byte_index] == 1) begin
                slv_reg25[(byte_index*8) +: 8] <= wdata[(byte_index*8) +: 8];
              end
            end
          end

          5'h1A: begin
            for (byte_index = 0; byte_index <= (AXI_DATA_WIDTH_C/8)-1; byte_index++) begin
              if (wstrb[byte_index] == 1) begin
                slv_reg26[(byte_index*8) +: 8] <= wdata[(byte_index*8) +: 8];
              end
            end
          end

          5'h1B: begin
            for (byte_index = 0; byte_index <= (AXI_DATA_WIDTH_C/8)-1; byte_index++) begin
              if (wstrb[byte_index] == 1) begin
                slv_reg27[(byte_index*8) +: 8] <= wdata[(byte_index*8) +: 8];
              end
            end
          end

          5'h1C: begin
            for (byte_index = 0; byte_index <= (AXI_DATA_WIDTH_C/8)-1; byte_index++) begin
              if (wstrb[byte_index] == 1) begin
                slv_reg28[(byte_index*8) +: 8] <= wdata[(byte_index*8) +: 8];
              end
            end
          end

          5'h1D: begin
            for (byte_index = 0; byte_index <= (AXI_DATA_WIDTH_C/8)-1; byte_index++) begin
              if (wstrb[byte_index] == 1) begin
                slv_reg29[(byte_index*8) +: 8] <= wdata[(byte_index*8) +: 8];
              end
            end
          end

          5'h1E: begin
            for (byte_index = 0; byte_index <= (AXI_DATA_WIDTH_C/8)-1; byte_index++) begin
              if (wstrb[byte_index] == 1) begin
                slv_reg30[(byte_index*8) +: 8] <= wdata[(byte_index*8) +: 8];
              end
            end
          end

          5'h1F: begin
            for (byte_index = 0; byte_index <= (AXI_DATA_WIDTH_C/8)-1; byte_index++) begin
              if (wstrb[byte_index] == 1) begin
                slv_reg31[(byte_index*8) +: 8] <= wdata[(byte_index*8) +: 8];
              end
            end
          end

          default : begin
            slv_reg0  <= slv_reg0;
            //slv_reg1  <= slv_reg1;
            slv_reg2  <= slv_reg2;
            slv_reg3  <= slv_reg3;
            slv_reg4  <= slv_reg4;
            slv_reg5  <= slv_reg5;
            slv_reg6  <= slv_reg6;
            slv_reg7  <= slv_reg7;
            slv_reg8  <= slv_reg8;
            slv_reg9  <= slv_reg9;
            slv_reg10 <= slv_reg10;
            slv_reg11 <= slv_reg11;
            slv_reg12 <= slv_reg12;
            slv_reg13 <= slv_reg13;
            slv_reg14 <= slv_reg14;
            slv_reg15 <= slv_reg15;
            slv_reg16 <= slv_reg16;
            slv_reg17 <= slv_reg17;
            slv_reg18 <= slv_reg18;
            slv_reg19 <= slv_reg19;
            slv_reg20 <= slv_reg20;
            slv_reg21 <= slv_reg21;
            slv_reg22 <= slv_reg22;
            slv_reg23 <= slv_reg23;
            slv_reg24 <= slv_reg24;
            slv_reg25 <= slv_reg25;
            slv_reg26 <= slv_reg26;
            slv_reg27 <= slv_reg27;
            slv_reg28 <= slv_reg28;
            slv_reg29 <= slv_reg29;
            slv_reg30 <= slv_reg30;
            slv_reg31 <= slv_reg31;
          end
        endcase
      end
    end
  end


  // ---------------------------------------------------------------------------
  // Write Response Channel
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      bvalid <= '0;
      bresp  <= '0;
    end
    else begin

      if (awready && awvalid && !bvalid && wready && wvalid) begin
        bvalid <= '1;
        bresp  <= '0;
      end
      else begin
        if (bready && bvalid) begin
          bvalid <= '0;
        end
      end
    end
  end


  // ---------------------------------------------------------------------------
  // Read Address Channel
  // Generate "arready"
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      arready   <= '0;
      araddr_d0 <= '0;
    end
    else begin

      if (!arready && arvalid) begin
        arready   <= '1;
        araddr_d0 <= araddr;
      end
      else begin
        arready <= '0;
      end

    end
  end

  // ---------------------------------------------------------------------------
  // Read Data Channel
  // Generate "rvalid"
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rdata  <= 0;
      rresp  <= 0;
      rvalid <= 0;
    end
    else begin

      if (read_enable) begin
        rdata <= rdata_d0;
      end

      if (arready && arvalid && !rvalid) begin
        rvalid <= '1;
        rresp  <= '0;
      end
      else if (rvalid && rready) begin
        rvalid <= '0;
      end

    end
  end


  always_comb begin
    // Address decoding for reading registers
    case (araddr_d0[ADDR_LSB_C+OPT_MEM_ADDR_BITS_C : ADDR_LSB_C])

      5'h00   : rdata_d0 <= slv_reg0;
      5'h01   : rdata_d0 <= slv_reg1;
      5'h02   : rdata_d0 <= slv_reg2;
      5'h03   : rdata_d0 <= slv_reg3;
      5'h04   : rdata_d0 <= slv_reg4;
      5'h05   : rdata_d0 <= slv_reg5;
      5'h06   : rdata_d0 <= slv_reg6;
      5'h07   : rdata_d0 <= slv_reg7;
      5'h08   : rdata_d0 <= slv_reg8;
      5'h09   : rdata_d0 <= slv_reg9;
      5'h0A   : rdata_d0 <= slv_reg10;
      5'h0B   : rdata_d0 <= slv_reg11;
      5'h0C   : rdata_d0 <= slv_reg12;
      5'h0D   : rdata_d0 <= slv_reg13;
      5'h0E   : rdata_d0 <= slv_reg14;
      5'h0F   : rdata_d0 <= slv_reg15;
      5'h10   : rdata_d0 <= slv_reg16;
      5'h11   : rdata_d0 <= slv_reg17;
      5'h12   : rdata_d0 <= slv_reg18;
      5'h13   : rdata_d0 <= slv_reg19;
      5'h14   : rdata_d0 <= slv_reg20;
      5'h15   : rdata_d0 <= slv_reg21;
      5'h16   : rdata_d0 <= slv_reg22;
      5'h17   : rdata_d0 <= slv_reg23;
      5'h18   : rdata_d0 <= slv_reg24;
      5'h19   : rdata_d0 <= slv_reg25;
      5'h1A   : rdata_d0 <= slv_reg26;
      5'h1B   : rdata_d0 <= slv_reg27;
      5'h1C   : rdata_d0 <= slv_reg28;
      5'h1D   : rdata_d0 <= slv_reg29;
      5'h1E   : rdata_d0 <= slv_reg30;
      5'h1F   : rdata_d0 <= slv_reg31;
      default : rdata_d0 <= '0;
    endcase
  end


  // Add user logic here
  always_ff @(posedge clk) begin
    slv_reg1 <= sr_led_2;
  end

endmodule
