module mem_pointer (
  input               clk,
  cnt_ker_en,
  cnt_ker_rst_n,  //cnt kernel addr
  reg_init_cnt_inp_ld,
  reg_init_cnt_inp_rst_n,  //registro inizializzazione cnt
  cnt_inp_ld,
  cnt_inp_en,
  cnt_inp_rst_n,  //cnt input addr
  cnt_out_en,
  cnt_out_rst_n,  //cnt output addr
  input  logic [ 1:0] mux_addr_sel,
  output logic        ker_tc4,
  ker_tc20,
  out_tc127,
  output logic [31:0] addr
);

  logic [31:0] reg_in, reg_out;
  logic [31:0] cnt_ker_o;
  logic [31:0] cnt_inp_o;
  logic [31:0] cnt_out_o;

  //cnt kernel
  always @(posedge clk, negedge cnt_ker_rst_n) begin
    if (!cnt_ker_rst_n) begin
      cnt_ker_o <= 0;
      ker_tc4   <= 0;
      ker_tc20  <= 0;
    end else if (cnt_ker_en == 1) begin
      cnt_ker_o <= cnt_ker_o + 1;  //non-blocking assignment 
      ker_tc4   <= (cnt_ker_o == 4 - 1);  //Reg type is used, no glitches sent to the CU
      ker_tc20  <= (cnt_ker_o == 20 - 1);
    end

  end


  //cnt input
  always @(posedge clk, negedge cnt_inp_rst_n) begin
    if (!cnt_inp_rst_n) cnt_inp_o <= 20;  //rst -> 20
    else if (cnt_inp_ld == 1) cnt_inp_o <= reg_out;  //load the register
    else if (cnt_inp_en == 1) cnt_inp_o <= cnt_inp_o + 1;  //enable
  end

  //cnt output
  always @(posedge clk, negedge cnt_out_rst_n) begin
    if (!cnt_out_rst_n) begin
      cnt_out_o <= 108;  //rst -> 108
      out_tc127 <= 0;
    end else if (cnt_out_en == 1) begin
      cnt_out_o <= cnt_out_o + 1;  //enable
      out_tc127 <= (cnt_out_o == 127 - 1);
    end

  end

  //registro inizializzazione cnt
  always @(posedge clk or negedge reg_init_cnt_inp_rst_n) begin
    if (!reg_init_cnt_inp_rst_n) reg_out <= 0;
    else if (reg_init_cnt_inp_ld == 1) reg_out <= reg_in;
  end

  //MUX
  //00 cnt_ker_o, 01 cnt_inp_o, 10 cnt_out_o, 11 -> 0
  assign addr = mux_addr_sel[1] ? (mux_addr_sel[0] ? 0 : cnt_out_o ) : (mux_addr_sel[0] ? cnt_inp_o: cnt_ker_o);
  assign reg_in = cnt_inp_o;

endmodule
