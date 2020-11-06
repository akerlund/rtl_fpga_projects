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

module recorder #(
    parameter int AXI_ID_P              = -1,
    parameter int AXI_ID_WIDTH_P        = -1,
    parameter int AXI_ADDR_WIDTH_P      = -1,
    parameter int AXI_DATA_WIDTH_P      = -1,
    parameter int AXI_STRB_WIDTH_P      = AXI_DATA_WIDTH_P/8,
    parameter int RECORD_BIT_WIDTH_P    = -1,
    parameter int MEMORY_BASE_ADDRESS_P = -1,
    parameter int MEMORY_HIGH_ADDRESS_P = -1
  )(

    // Clock and reset
    input  wire                                   clk,
    input  wire                                   rst_n,

    // Record (Ingress)
    input  wire        [RECORD_BIT_WIDTH_P-1 : 0] ing_tdata,
    input  wire                                   ing_tvalid,
    output logic                                  ing_tready,

    // Playback (Egress)
    output logic       [RECORD_BIT_WIDTH_P-1 : 0] egr_tdata,
    output logic                                  egr_tvalid,
    input  wire                                   egr_tready,

    // Configuration
    input  wire                                   cr_recording_enabled,
    input  wire                                   cr_playback_enabled,

    // -------------------------------------------------------------------------
    // Memory
    // -------------------------------------------------------------------------

    // Write Address Channel
    output logic           [AXI_ID_WIDTH_P-1 : 0] awid,
    output logic         [AXI_ADDR_WIDTH_P-1 : 0] awaddr,
    output logic                          [7 : 0] awlen,
    output logic                                  awvalid,
    input  wire                                   awready,

    // Write Data Channel
    output logic         [AXI_DATA_WIDTH_P-1 : 0] wdata,
    output logic     [(AXI_DATA_WIDTH_P/8)-1 : 0] wstrb,
    output logic                                  wlast,
    output logic                                  wvalid,
    input  wire                                   wready,

    // Read Address Channel
    output logic           [AXI_ID_WIDTH_P-1 : 0] arid,
    output logic         [AXI_ADDR_WIDTH_P-1 : 0] araddr,
    output logic                          [7 : 0] arlen,
    output logic                                  arvalid,
    input  wire                                   arready,

    // Read Data Channel
    input  wire            [AXI_ID_WIDTH_P-1 : 0] rid,
    input  wire          [AXI_DATA_WIDTH_P-1 : 0] rdata,
    input  wire                                   rlast,
    input  wire                                   rvalid,
    output logic                                  rready
  );

  // -------------------------------------------------------------------------
  // Record to memory
  // -------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin : mem_recorder_p0
    if (!rst_n) begin

      awid       <= AXI_ID_P;
      awaddr     <= MEMORY_BASE_ADDRESS_P;
      awlen      <= '0;
      awvalid    <= '0;
      wdata      <= '0;
      wstrb      <= '1;
      wlast      <= '1;
      wvalid     <= '0;
      ing_tready <= '1;

    end
    else begin

      if (wvalid) begin
        if (wready) begin
          wvalid     <= '0;
          ing_tready <= '1;
        end
      end
      else if (awvalid) begin
        if (awready) begin
          awvalid <= '0;
          if (awaddr != MEMORY_HIGH_ADDRESS_P) begin
            awaddr <= awaddr + 1;
          end
          else begin
            awaddr <= MEMORY_BASE_ADDRESS_P;
          end
          wvalid <= '1;
        end
      end
      else if (cr_recording_enabled && ing_tvalid) begin
        ing_tready <= '0;
        wdata      <= ing_tdata;
        awvalid    <= '1;
      end

    end
  end

  // -------------------------------------------------------------------------
  // Playback from memory
  // -------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin : mem_playback_p0
    if (!rst_n) begin

      arid       <= AXI_ID_P;
      araddr     <= MEMORY_BASE_ADDRESS_P;
      arlen      <= '0;
      arvalid    <= '0;
      rready     <= '0;
      egr_tdata  <= '0;
      egr_tvalid <= '0;

    end
    else begin

      if (egr_tvalid) begin
        if (egr_tready) begin
          egr_tvalid <= '0;
        end
      end
      else if (rready) begin
        if (rvalid) begin
          rready     <= '0;
          egr_tdata  <= rdata;
          egr_tvalid <= '1;
        end
      end
      else if (arvalid) begin
        if (arready) begin
          arvalid <= '0;
          if (araddr != MEMORY_HIGH_ADDRESS_P) begin
            araddr <= araddr + 1;
          end
          else begin
            araddr <= MEMORY_BASE_ADDRESS_P;
          end
          rready  <= '1;
        end
      end
      else if (cr_playback_enabled && ing_tvalid) begin // Using ing_tvalid to synchronize
        arvalid <= '1;
      end

    end
  end

endmodule

`default_nettype wire
