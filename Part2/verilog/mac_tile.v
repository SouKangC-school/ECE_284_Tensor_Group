module mac_tile (clk, out_s, in_w, out_e, in_n, inst_w, inst_e, reset);

parameter bw = 4;
parameter psum_bw = 16;

output [psum_bw-1:0] out_s;
input  [bw-1:0] in_w;      // inst[1]:execute, inst[0]: kernel loading
output [bw-1:0] out_e;     // latched version of in_w
input  [1:0] inst_w;
output [1:0] inst_e;       // latched version of inst_w
input  [psum_bw-1:0] in_n; // in_n is input psum
input  clk;
input  reset;

reg [1:0] inst_q;          // connected to inst_e; latched from inst_w
reg [bw-1:0] a_q;         // connected to out_e; latched from in_w
reg signed [bw-1:0] b_q;   // weight register
reg signed [psum_bw-1:0] c_q;
reg load_ready_q;
wire signed [psum_bw-1:0] mac_out;

// Output assignments
assign out_e = a_q;
assign out_s = mac_out;
assign inst_e = inst_q;

// Instruction and load_ready control
always @(posedge clk) begin
    if(reset) begin
        inst_q <= 'h0;
        load_ready_q <= 'b1;
    end
    else begin
        inst_q[1] <= inst_w[1];
        if(load_ready_q=='b0)
            inst_q[0] <= inst_w[0];
        if(load_ready_q=='b1 && inst_w[0]=='b1)
            load_ready_q <= 'b0;
    end
end

// Activation register control
always @(posedge clk) begin
    if(inst_w[0]=='b1 || inst_w[1]=='b1)
        a_q <= in_w;
end

// Weight register control
always @(posedge clk) begin
    if(inst_w[0]=='b1 && load_ready_q=='b1)
        b_q <= in_w;
end

// Partial sum register control
always @(posedge clk) begin
    c_q <= in_n;
end

// MAC unit instantiation
mac #(.bw(bw), .psum_bw(psum_bw)) mac_instance (
    .a(a_q),
    .b(b_q),
    .c(c_q),
    .out(mac_out)
);

endmodule



