module n_bit_reg #(
  parameter N = 32
) (
  input      [N-1:0] reg_in,  //input register
  input              clk,     //clock signal
  input              ld,      //synchronous load signal 
  input              rst_n,   //asynchronous reset
  output reg [N-1:0] reg_out
);  //output register



  always @(posedge clk or negedge rst_n) begin

    if (!rst_n) reg_out <= 0;
    else if (ld) reg_out <= reg_in;
  end

endmodule
