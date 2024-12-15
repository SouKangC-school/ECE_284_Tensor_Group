module mac_tile (clk, out_s, in_w, out_e, in_n, inst_w, inst_e, reset, mode, valid_out, tile_out);

parameter bw = 4;
parameter psum_bw = 16;
parameter mac_ops = 27;  // Add at top with other parameters

output [psum_bw-1:0] out_s;
input  [bw-1:0] in_w;      // inst[1]:execute, inst[0]: kernel loading
output [bw-1:0] out_e;     // latched version of in_w
input  [1:0] inst_w;
output [1:0] inst_e;       // latched version of inst_w
input  [psum_bw-1:0] in_n; // in_n is input psum
input  clk;
input  reset;
input mode; //0: WS, 1: OS

output [psum_bw-1:0] tile_out;//OS tile psum output 
output valid_out;

reg [1:0] inst_q;          // connected to inst_e; latched from inst_w
reg [bw-1:0] a_q;         // unsigned activation
reg signed [bw-1:0] b_q;   // signed weight
reg signed [psum_bw-1:0] c_q;  // signed accumulation
reg load_ready_q;
wire signed [psum_bw-1:0] mac_out;
reg [4:0] mac_count;  // Can count up to 32 operations
reg mac_done;
reg signed [psum_bw-1:0] final_result;
reg result_valid;

// Output assignments
assign out_e = a_q;
assign out_s = mode ? {{(psum_bw-bw){b_q[bw-1]}}, b_q} : mac_out;  // unsigned extension for weights
assign inst_e = inst_q;
assign tile_out = mode ? final_result & {psum_bw{result_valid}} : {psum_bw{1'b0}};
assign valid_out = mode ? result_valid : inst_q[1];

// Combined sequential logic
always @(posedge clk) begin
    if(reset) begin
        inst_q <= 'h0;
        load_ready_q <= 'b1;
        a_q <= 'b0;
        b_q <= 'b0;
        c_q <= 'b0;
        mac_count <= 0;
        mac_done <= 0;
        final_result <= 'b0;
        result_valid <= 0;
    end
    else begin
        case(mode)
            0: begin
                inst_q[1] <= inst_w[1];
                c_q <= in_n;

                if(load_ready_q=='b0)
                    inst_q[0] <= inst_w[0];
                
                if(load_ready_q=='b1 && inst_w[0]=='b1)
                    load_ready_q <= 'b0;
                
                if(inst_w[0]=='b1 || inst_w[1]=='b1)
                    a_q <= in_w;
                    
                // Weight register
                if(inst_w[0]=='b1 && load_ready_q=='b1)
                    b_q <= in_w;
            end

            1: begin
                inst_q[1] <= inst_w[1];
                
                // Pass activation east and accumulate
                if(inst_w[1]=='b1) begin
                    a_q <= in_w;
                    b_q <= in_n[bw-1:0];
                    c_q <= mac_out;  // Always take mac_out result
                    
                    // Track MAC operations
                    if(!mac_done) begin
                        mac_count <= mac_count + 1;
                        if(mac_count == (mac_ops-1)) begin  // Count from 0 to 26
                            mac_done <= 1;
                        end
                    end
                    else if(mac_done) begin
                        final_result <= c_q;  // Capture the final c_q value one cycle after mac_done
                        result_valid <= 1;    // Set valid flag
                    end
                end
            end
        endcase
    end
end

// MAC unit instantiation
mac #(.bw(bw), .psum_bw(psum_bw)) mac_instance (
    .a(a_q),
    .b(b_q),
    .c(c_q),
    .out(mac_out)
);

endmodule



