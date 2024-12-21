module CONV1D_DP (
  input  logic [31:0] in_data,     //input data on 32 bus
  input  logic        clk,         //clock signal
  input  logic        reg_in_ld,
  input  logic        reg_ker_ld,
  input  logic        reg_sum_ld,  //synchronous load signal 
  input  logic        alu_rst_n,   //general logicynchronous reset
  input logic         reg_sum_rst_n, //reg sum reset
  output logic [31:0] result
);  //output 


  //SIGNALS -----------------------------------------------------------------------------------
  logic [7:0] m0_A, m0_B;
  logic [7:0] m1_A, m1_B;
  logic [7:0] m2_A, m2_B;
  logic [7:0] m3_A, m3_B;
  logic [15:0] m0_out, m1_out, m2_out, m3_out;
  logic [16:0] A0_out, A1_out;
  logic [17:0] A2_out;
  logic [31:0] A3_A, A3_B;
  logic [31:0] A3_out;

  //-------------------------------------------------------------------------------------------

  assign result = A3_B;

  // Input registers

  n_bit_reg #(8) reg_in0 (
    .reg_in (in_data[7:0]),
    .clk    (clk),
    .ld     (reg_in_ld),
    .rst_n  (alu_rst_n),
    .reg_out(m0_A)
  );

  n_bit_reg #(8) reg_in1 (
    .reg_in (in_data[15:8]),
    .clk    (clk),
    .ld     (reg_in_ld),
    .rst_n  (alu_rst_n),
    .reg_out(m1_A)
  );

  n_bit_reg #(8) reg_in2 (
    .reg_in (in_data[23:16]),
    .clk    (clk),
    .ld     (reg_in_ld),
    .rst_n  (alu_rst_n),
    .reg_out(m2_A)
  );

  n_bit_reg #(8) reg_in3 (
    .reg_in (in_data[31:24]),
    .clk    (clk),
    .ld     (reg_in_ld),
    .rst_n  (alu_rst_n),
    .reg_out(m3_A)
  );


  n_bit_reg #(8) reg_ker0 (
    .reg_in (in_data[7:0]),
    .clk    (clk),
    .ld     (reg_ker_ld),
    .rst_n  (alu_rst_n),
    .reg_out(m0_B)
  );

  n_bit_reg #(8) reg_ker1 (
    .reg_in (in_data[15:8]),
    .clk    (clk),
    .ld     (reg_ker_ld),
    .rst_n  (alu_rst_n),
    .reg_out(m1_B)
  );

  n_bit_reg #(8) reg_ker2 (
    .reg_in (in_data[23:16]),
    .clk    (clk),
    .ld     (reg_ker_ld),
    .rst_n  (alu_rst_n),
    .reg_out(m2_B)
  );

  n_bit_reg #(8) reg_ker3 (
    .reg_in (in_data[31:24]),
    .clk    (clk),
    .ld     (reg_ker_ld),
    .rst_n  (alu_rst_n),
    .reg_out(m3_B)
  );

  n_bit_reg #(32) reg_sum (
    .reg_in (A3_out),
    .clk    (clk),
    .ld     (reg_sum_ld),
    .rst_n  (reg_sum_rst_n),
    .reg_out(A3_B)
  );

  //multipliers-------------------------------------------------

  multiplier #(8) mult0 (
    .a(m0_A),
    .b(m0_B),
    .p(m0_out)
  );

  multiplier #(8) mult1 (
    .a(m1_A),
    .b(m1_B),
    .p(m1_out)
  );

  multiplier #(8) mult2 (
    .a(m2_A),
    .b(m2_B),
    .p(m2_out)
  );

  multiplier #(8) mult3 (
    .a(m3_A),
    .b(m3_B),
    .p(m3_out)
  );

  //adders-------------------------------------------------				
  adder #(16) add0 (
    .a(m0_out),
    .b(m1_out),
    .s(A0_out)
  );

  adder #(16) add1 (
    .a(m2_out),
    .b(m3_out),
    .s(A1_out)
  );

  adder #(17) add2 (
    .a(A0_out),
    .b(A1_out),
    .s(A2_out)
  );

  final_adder #(32) add3 (
    .a(A3_A),
    .b(A3_B),
    .s(A3_out)
  );

  //sign extension

  sign_ext #(18) s_ext (
    .data_in (A2_out),
    .data_out(A3_A)
  );



endmodule
