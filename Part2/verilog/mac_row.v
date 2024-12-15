module mac_row (clk, out_s, in_w, in_n, valid, inst_w, reset);

  parameter bw = 4;
  parameter psum_bw = 16;
  parameter col = 8;

  input  clk; 
  input  reset;
  input  [bw-1:0] in_w;
  input  [1:0] inst_w;
  input  [psum_bw*col-1:0] in_n;
  output wire [psum_bw*col-1:0] out_s;
  output wire [col-1:0] valid;

  wire [(col+1)*bw-1:0] temp;
  wire [(col+1)*2-1:0] temp_inst;
  wire [psum_bw*col-1:0] mac_outs;
  wire [col-1:0] valid_signals;

  // First tile gets direct input
  assign temp[bw-1:0] = in_w;
  assign temp_inst[1:0] = inst_w;

  // Generate MAC tiles
  genvar i;
  generate
    for (i=0; i < col; i=i+1) begin : col_num
      mac_tile #(.bw(bw), .psum_bw(psum_bw)) mac_tile_instance (
        .clk(clk),
        .reset(reset),
        .in_w(temp[bw*i+:bw]),
        .out_e(temp[bw*(i+1)+:bw]),
        .inst_w(temp_inst[2*i+:2]),
        .inst_e(temp_inst[2*(i+1)+:2]),
        .in_n(in_n[psum_bw*i+:psum_bw]),
        .out_s(mac_outs[psum_bw*i+:psum_bw])
      );

      // Valid signal comes from instruction propagation
      assign valid_signals[i] = temp_inst[2*(i+1)+1];
    end
  endgenerate

  // Output assignments
  assign out_s = mac_outs;
  assign valid = valid_signals;

endmodule