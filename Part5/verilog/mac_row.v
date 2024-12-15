module mac_row (clk, out_s, in_w, in_n, valid, inst_w, reset, mode, tile_row_out);

  parameter bw = 4;
  parameter psum_bw = 16;
  parameter col = 8;
  parameter mac_ops = 27;

  input  clk; 
  input  reset;
  input  [bw-1:0] in_w;
  input  [1:0] inst_w;
  input  [psum_bw*col-1:0] in_n;
  input  mode;
  output wire [psum_bw*col-1:0] out_s;
  output wire [col-1:0] valid;
  output wire [psum_bw*col-1:0] tile_row_out;

  wire [(col+1)*bw-1:0] temp;
  wire [(col+1)*2-1:0] temp_inst;
  wire [psum_bw*col-1:0] mac_outs;
  wire [psum_bw*col-1:0] tile_outs;
  wire [col-1:0] valid_signals;

  // First tile gets direct input
  assign temp[bw-1:0] = in_w;
  assign temp_inst[1:0] = inst_w;

  // Generate MAC tiles
  genvar i;
  generate
    for (i=0; i < col; i=i+1) begin : col_num
      mac_tile #(.bw(bw), .psum_bw(psum_bw), .mac_ops(mac_ops)) mac_tile_instance (
        .clk(clk),
        .reset(reset),
        .in_w(temp[bw*i+:bw]),
        .out_e(temp[bw*(i+1)+:bw]),
        .inst_w(temp_inst[2*i+:2]),
        .inst_e(temp_inst[2*(i+1)+:2]),
        .in_n(in_n[psum_bw*i+:psum_bw]),
        .out_s(mac_outs[psum_bw*i+:psum_bw]),
        .mode(mode),
        .valid_out(valid_signals[i]),
        .tile_out(tile_outs[psum_bw*i+:psum_bw])
      );
    end
  endgenerate

  // Output assignments
  assign out_s = mac_outs;
  assign tile_row_out = tile_outs;
  assign valid = valid_signals;

endmodule