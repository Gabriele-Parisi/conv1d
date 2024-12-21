module sign_ext #(
  parameter N = 18
) (
  input  logic [     N-1:0] data_in,
  output logic [(N+14)-1:0] data_out
);

  always @* begin
    if (data_in[N-1] == 1'b0) data_out = {{14{1'b0}}, data_in};
    else data_out = {{14{1'b1}}, data_in};
  end
endmodule
