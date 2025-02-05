// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Register Package auto-generated by `reggen` containing data structure

package conv1d_control_reg_pkg;

  // Address widths within the block
  parameter int BlockAw = 3;

  ////////////////////////////
  // Typedefs for registers //
  ////////////////////////////

  typedef struct packed {logic q;} conv1d_control_reg2hw_control_reg_t;

  typedef struct packed {
    struct packed {logic q;} running;
    struct packed {logic q;} done;
  } conv1d_control_reg2hw_status_reg_t;

  typedef struct packed {
    struct packed {
      logic d;
      logic de;
    } running;
    struct packed {
      logic d;
      logic de;
    } done;
  } conv1d_control_hw2reg_status_reg_t;

  // Register -> HW type
  typedef struct packed {
    conv1d_control_reg2hw_control_reg_t control;  // [2:2]
    conv1d_control_reg2hw_status_reg_t  status;   // [1:0]
  } conv1d_control_reg2hw_t;

  // HW -> register type
  typedef struct packed {
    conv1d_control_hw2reg_status_reg_t status;  // [3:0]
  } conv1d_control_hw2reg_t;

  // Register offsets
  parameter logic [BlockAw-1:0] CONV1D_CONTROL_CONTROL_OFFSET = 3'h0;
  parameter logic [BlockAw-1:0] CONV1D_CONTROL_STATUS_OFFSET = 3'h4;

  // Register index
  typedef enum int {
    CONV1D_CONTROL_CONTROL,
    CONV1D_CONTROL_STATUS
  } conv1d_control_id_e;

  // Register width information to check illegal writes
  parameter logic [3:0] CONV1D_CONTROL_PERMIT[2] = '{
      4'b0001,  // index[0] CONV1D_CONTROL_CONTROL
      4'b0001  // index[1] CONV1D_CONTROL_STATUS
  };

endpackage

