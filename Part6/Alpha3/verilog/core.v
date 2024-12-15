module core #(
    parameter row = 8,
    parameter col = 8,
    parameter psum_bw = 16,
    parameter bw = 4
)(
    input clk,
    input reset,
    input [34:0] inst,
    input [bw*row-1:0] d_xmem,
    output ofifo_valid,
    output [psum_bw*col-1:0] sfp_out
);

    wire relu_en = inst[34];
    wire acc = inst[33];
    wire CEN_pmem = inst[32];
    wire WEN_pmem = inst[31];
    wire [10:0] A_pmem = inst[30:20];
    wire CEN_xmem = inst[19];
    wire WEN_xmem = inst[18];
    wire [10:0] A_xmem = inst[17:7];
    wire ofifo_rd = inst[6];
    wire ififo_rd = inst[4];
    wire l0_rd = inst[3];
    wire l0_wr = inst[2];
    wire execute = inst[1];
    wire load = inst[0];

    wire [bw*row-1:0] data_in;
    wire [psum_bw*col-1:0] acc_in;
    wire [psum_bw*col-1:0] data_out;
    wire [psum_bw*col-1:0] spf_out;
    wire [31:0] xmem_data_out;
    wire [127:0] pmem_data_out;

    assign data_in = xmem_data_out;
    assign acc_in = pmem_data_out;
    assign sfp_out = spf_out;

    sram_32b_w2048 xmemory_inst (
        .CLK(clk),
        .D(d_xmem),
        .Q(xmem_data_out),
        .CEN(CEN_xmem),
        .WEN(WEN_xmem),
        .A(A_xmem)
    );

    sram_128b_w2048 #(
    ) pmemory_inst (
        .CLK(clk),
        .D(data_out),
        .Q(pmem_data_out),
        .CEN(CEN_pmem),
        .WEN(WEN_pmem),
        .A(A_pmem)
    );

    corelet #(
        .row(row),
        .col(col),
        .psum_bw(psum_bw),
        .bw(bw)
    ) corelet_insts (
        .clk(clk),
        .reset(reset),
        .execute(execute),
        .load(load),
        .data_to_l0(data_in),
        .l0_rd(l0_rd),
        .l0_wr(l0_wr),
        .l0_full(),
        .l0_ready(),
        .ofifo_rd(ofifo_rd),
        .ofifo_full(),
        .ofifo_ready(),
        .ofifo_valid(ofifo_valid),
        .psum_out(data_out),
        .sram_to_sfu(acc_in),
        .accumulate(acc),
        .relu(relu_en),
        .data_out(spf_out)
    );

endmodule
