`timescale 1ns/1ps

module sfp #(
    parameter psum_bw = 16
)(
    input clk,
    input reset,
    input acc,
    input relu_en,
    input signed [psum_bw-1:0] data_in,
    output signed [psum_bw-1:0] data_out
);

    reg signed [psum_bw-1:0] psum_q;

    always @(posedge clk) begin
        if (reset)
            psum_q <= {psum_bw{1'b0}};
        else begin
            case ({acc, relu_en})
                2'b10:   
                    psum_q <= psum_q + data_in;
                2'b01:   
                    psum_q <= (psum_q > 0) ? psum_q : {psum_bw{1'b0}};
                default: 
                    psum_q <= psum_q;
            endcase
        end
    end

    assign data_out = psum_q;

endmodule




