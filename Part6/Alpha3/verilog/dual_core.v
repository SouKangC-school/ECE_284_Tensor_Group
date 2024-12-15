module dual_core #(
    parameter row = 8,
    parameter col = 8,
    parameter psum_bw = 16,
    parameter bw = 4
)(
    input clk,
    input reset,
    input [35:0] inst,
    input [bw*row-1:0] d_xmem,
    output [1:0] ofifo_valid,
    output [2*psum_bw*col-1:0] sfp_out
);

    // Instantiate two cores
    core #(
        .row(row),
        .col(col),
        .psum_bw(psum_bw),
        .bw(bw)
    ) core0 (
        .clk(clk),
        .reset(reset),
        .inst(inst),
        .d_xmem(d_xmem),
        .ofifo_valid(ofifo_valid[0]),
        .sfp_out(sfp_out[psum_bw*col-1:0])
    );

    core #(
        .row(row),
        .col(col),
        .psum_bw(psum_bw),
        .bw(bw)
    ) core1 (
        .clk(clk),
        .reset(reset),
        .inst(inst),
        .d_xmem(d_xmem),
        .ofifo_valid(ofifo_valid[1]),
        .sfp_out(sfp_out[2*psum_bw*col-1:psum_bw*col])
    );

endmodule
