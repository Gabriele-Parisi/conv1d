// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Register Top module auto-generated by `reggen`


`include "common_cells/assertions.svh"

module conv1d_control_reg_top #(
  parameter type reg_req_t = logic,
  parameter type reg_rsp_t = logic,
  parameter int AW = 3
) (
  input                                                  clk_i,
  input                                                  rst_ni,
  input  reg_req_t                                       reg_req_i,
  output reg_rsp_t                                       reg_rsp_o,
  // To HW
  output conv1d_control_reg_pkg::conv1d_control_reg2hw_t reg2hw,     // Write
  input  conv1d_control_reg_pkg::conv1d_control_hw2reg_t hw2reg,     // Read


  // Config
  input devmode_i  // If 1, explicit error return for unmapped register access
);

  import conv1d_control_reg_pkg::*;

  localparam int DW = 32;
  localparam int DBW = DW / 8;  // Byte Width

  // register signals
  logic           reg_we;
  logic           reg_re;
  logic [ AW-1:0] reg_addr;
  logic [ DW-1:0] reg_wdata;
  logic [DBW-1:0] reg_be;
  logic [ DW-1:0] reg_rdata;
  logic           reg_error;

  logic addrmiss, wr_err;

  logic     [DW-1:0] reg_rdata_next;

  // Below register interface can be changed
  reg_req_t          reg_intf_req;
  reg_rsp_t          reg_intf_rsp;


  assign reg_intf_req       = reg_req_i;
  assign reg_rsp_o          = reg_intf_rsp;


  assign reg_we             = reg_intf_req.valid & reg_intf_req.write;
  assign reg_re             = reg_intf_req.valid & ~reg_intf_req.write;
  assign reg_addr           = reg_intf_req.addr;
  assign reg_wdata          = reg_intf_req.wdata;
  assign reg_be             = reg_intf_req.wstrb;
  assign reg_intf_rsp.rdata = reg_rdata;
  assign reg_intf_rsp.error = reg_error;
  assign reg_intf_rsp.ready = 1'b1;

  assign reg_rdata          = reg_rdata_next;
  assign reg_error          = (devmode_i & addrmiss) | wr_err;


  // Define SW related signals
  // Format: <reg>_<field>_{wd|we|qs}
  //        or <reg>_{wd|we|qs} if field == 1 or 0
  logic control_qs;
  logic control_wd;
  logic control_we;
  logic status_running_qs;
  logic status_running_wd;
  logic status_running_we;
  logic status_done_qs;
  logic status_done_wd;
  logic status_done_we;

  // Register instances
  // R[control]: V(False)

  prim_subreg #(
    .DW      (1),
    .SWACCESS("RW"),
    .RESVAL  (1'h0)
  ) u_control (
    .clk_i (clk_i),
    .rst_ni(rst_ni),

    // from register interface
    .we(control_we),
    .wd(control_wd),

    // from internal hardware
    .de(1'b0),
    .d ('0),

    // to internal hardware
    .qe(),
    .q (reg2hw.control.q),

    // to register interface (read)
    .qs(control_qs)
  );


  // R[status]: V(False)

  //   F[running]: 0:0
  prim_subreg #(
    .DW      (1),
    .SWACCESS("RW"),
    .RESVAL  (1'h0)
  ) u_status_running (
    .clk_i (clk_i),
    .rst_ni(rst_ni),

    // from register interface
    .we(status_running_we),
    .wd(status_running_wd),

    // from internal hardware
    .de(hw2reg.status.running.de),
    .d (hw2reg.status.running.d),

    // to internal hardware
    .qe(),
    .q (reg2hw.status.running.q),

    // to register interface (read)
    .qs(status_running_qs)
  );


  //   F[done]: 1:1
  prim_subreg #(
    .DW      (1),
    .SWACCESS("RW"),
    .RESVAL  (1'h0)
  ) u_status_done (
    .clk_i (clk_i),
    .rst_ni(rst_ni),

    // from register interface
    .we(status_done_we),
    .wd(status_done_wd),

    // from internal hardware
    .de(hw2reg.status.done.de),
    .d (hw2reg.status.done.d),

    // to internal hardware
    .qe(),
    .q (reg2hw.status.done.q),

    // to register interface (read)
    .qs(status_done_qs)
  );




  logic [1:0] addr_hit;
  always_comb begin
    addr_hit    = '0;
    addr_hit[0] = (reg_addr == CONV1D_CONTROL_CONTROL_OFFSET);
    addr_hit[1] = (reg_addr == CONV1D_CONTROL_STATUS_OFFSET);
  end

  assign addrmiss = (reg_re || reg_we) ? ~|addr_hit : 1'b0;

  // Check sub-word write is permitted
  always_comb begin
    wr_err = (reg_we &
              ((addr_hit[0] & (|(CONV1D_CONTROL_PERMIT[0] & ~reg_be))) |
               (addr_hit[1] & (|(CONV1D_CONTROL_PERMIT[1] & ~reg_be)))));
  end

  assign control_we        = addr_hit[0] & reg_we & !reg_error;
  assign control_wd        = reg_wdata[0];

  assign status_running_we = addr_hit[1] & reg_we & !reg_error;
  assign status_running_wd = reg_wdata[0];

  assign status_done_we    = addr_hit[1] & reg_we & !reg_error;
  assign status_done_wd    = reg_wdata[1];

  // Read data return
  always_comb begin
    reg_rdata_next = '0;
    unique case (1'b1)
      addr_hit[0]: begin
        reg_rdata_next[0] = control_qs;
      end

      addr_hit[1]: begin
        reg_rdata_next[0] = status_running_qs;
        reg_rdata_next[1] = status_done_qs;
      end

      default: begin
        reg_rdata_next = '1;
      end
    endcase
  end

  // Unused signal tieoff

  // wdata / byte enable are not always fully used
  // add a blanket unused statement to handle lint waivers
  logic unused_wdata;
  logic unused_be;
  assign unused_wdata = ^reg_wdata;
  assign unused_be    = ^reg_be;

  // Assertions for Register Interface
  `ASSERT(en2addrHit, (reg_we || reg_re) |-> $onehot0(addr_hit))

endmodule
