module multiplier #(
  parameter N = 8
) (
  input  [    N-1:0] a,
  input  [    N-1:0] b,
  output [(N*2)-1:0] p
);

  assign p = a * b;

endmodule
