`timescale 1ns/1ps

module sfp #(
    parameter col = 8,
    parameter bw = 16
)(
    input clk,
    input reset,
    input [col*bw-1:0] data_in,
    input acc,
    input [col*bw-1:0] acc_data,
    input relu_en,
    input mode,
    output reg [col*bw-1:0] data_out
);

    reg [col*bw-1:0] acc_reg;
    wire [col*bw-1:0] acc_out;
    wire [col*bw-1:0] relu_out;

    // Accumulation
    assign acc_out = mode ? data_in : (acc ? acc_reg + data_in : data_in);

    // ReLU
    genvar i;
    generate
        for (i=0; i<col; i=i+1) begin: relu_gen
            assign relu_out[bw*(i+1)-1:bw*i] = mode ? 
                acc_out[bw*(i+1)-1:bw*i] :  // OS mode: bypass ReLU
                (relu_en && $signed(acc_out[bw*(i+1)-1:bw*i]) < 0) ? 0 : acc_out[bw*(i+1)-1:bw*i];  // WS mode: normal ReLU
        end
    endgenerate

    always @(posedge clk) begin
        if (reset) begin
            acc_reg <= 0;
            data_out <= 0;
        end
        else begin
            acc_reg <= acc_data;
            data_out <= relu_out;
        end
    end

endmodule




