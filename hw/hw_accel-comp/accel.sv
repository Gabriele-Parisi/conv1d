module accel (
  input               accel_start,
  clk,
  rst_n,
  input        [31:0] accel_in_data,
  output logic        accel_done,
  accel_done_e,
  accel_running,
  accel_running_e,
  accel_mem_req,
  accel_mem_we,
  accel_ext_sel,
  output logic [31:0] accel_addr,
  output logic [31:0] accel_result
);

  logic
      cnt_ker_en,
      cnt_ker_rst_n,
      reg_init_cnt_inp_ld,
      reg_init_cnt_inp_rst_n,
      cnt_inp_ld,
      cnt_inp_en,
      cnt_inp_rst_n,
      cnt_out_en,
      cnt_out_rst_n,
      ker_tc4,
      ker_tc20,
      out_tc127,
      alu_rst_n,
      reg_ker_ld,
      reg_in_ld,
      reg_sum_ld,
      reg_sum_rst_n;


  logic [1:0] mux_addr_sel;

  mem_pointer pointr (
    .clk                   (clk),
    .cnt_ker_en            (cnt_ker_en),
    .cnt_ker_rst_n         (cnt_ker_rst_n),           //cnt kernel addr
    .reg_init_cnt_inp_ld   (reg_init_cnt_inp_ld),
    .reg_init_cnt_inp_rst_n(reg_init_cnt_inp_rst_n),  //registro inizializzazione cnt
    .cnt_inp_ld            (cnt_inp_ld),
    .cnt_inp_en            (cnt_inp_en),
    .cnt_inp_rst_n         (cnt_inp_rst_n),           //cnt input addr
    .cnt_out_en            (cnt_out_en),
    .cnt_out_rst_n         (cnt_out_rst_n),           //cnt output addr
    .mux_addr_sel          (mux_addr_sel),
    .ker_tc4               (ker_tc4),
    .ker_tc20              (ker_tc20),
    .out_tc127             (out_tc127),
    .addr                  (accel_addr)
  );

  CONV1D_DP alu (
    .clk       (clk),
    .in_data   (accel_in_data),
    .alu_rst_n (alu_rst_n),
    .reg_sum_rst_n(reg_sum_rst_n),
    .reg_ker_ld(reg_ker_ld),
    .reg_in_ld (reg_in_ld),
    .reg_sum_ld(reg_sum_ld),
    .result    (accel_result)
  );

  CU control_unit (
    .clk      (clk),
    .rst_n    (rst_n),
    .start    (accel_start),
    .ker_tc4  (ker_tc4),
    .ker_tc20 (ker_tc20),
    .out_tc127(out_tc127),
    .done     (accel_done),
    .done_e   (accel_done_e),
    .running  (accel_running),
    .running_e(accel_running_e),
    .ext_sel  (accel_ext_sel),
    //mem signals
    .mem_req  (accel_mem_req),
    .mem_we   (accel_mem_we),

    //Alu signals
    .alu_rst_n (alu_rst_n),
    .reg_ker_ld(reg_ker_ld),
    .reg_in_ld (reg_in_ld),
    .reg_sum_ld(reg_sum_ld),
    .reg_sum_rst_n(reg_sum_rst_n),

    //pointer signals
    .reg_init_cnt_inp_ld   (reg_init_cnt_inp_ld),
    .reg_init_cnt_inp_rst_n(reg_init_cnt_inp_rst_n),
    .cnt_inp_en            (cnt_inp_en),
    .cnt_inp_ld            (cnt_inp_ld),
    .cnt_inp_rst_n         (cnt_inp_rst_n),
    .cnt_ker_en            (cnt_ker_en),
    .cnt_ker_rst_n         (cnt_ker_rst_n),
    .cnt_out_en            (cnt_out_en),
    .cnt_out_rst_n         (cnt_out_rst_n),
    .mux_addr_sel          (mux_addr_sel)
  );

endmodule
