// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module mac (out, a, b, c, clk);

parameter bw = 4;
parameter psum_bw = 16;

output signed [psum_bw-1:0] out;
input [bw-1:0] a;  // activation
input signed [bw-1:0] b;  // weight
input signed [psum_bw-1:0] c;
input clk;

reg signed [2*bw:0] product_reg;
reg signed [psum_bw-1:0] psum_reg;
wire x_zero, w_zero;

// Detect zero values
assign x_zero = (a == 0);
assign w_zero = (b == 0);

// Compute product only if neither input is zero
always @(posedge clk) begin
    if (!x_zero && !w_zero) begin
        product_reg <= a * b;
    end else begin
        product_reg <= 0;
    end
    psum_reg <= product_reg + c;
end

assign out = psum_reg;

endmodule
