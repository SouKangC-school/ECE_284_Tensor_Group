module mac_array (clk, reset, out_s, in_w, in_n, inst_w, valid);

  parameter bw = 4;
  parameter psum_bw = 16;
  parameter col = 8;
  parameter row = 8;

  input  clk, reset;
  output wire [psum_bw*col-1:0] out_s;
  input  [row*bw-1:0] in_w;
  input  [1:0] inst_w;
  input  [psum_bw*col-1:0] in_n;
  output wire [col-1:0] valid;

  reg [2*row-1:0] inst_w_temp;
  wire [psum_bw*col*(row+1)-1:0] temp;
  wire [row*col-1:0] valid_temp;

  // Sequential logic for instruction propagation
  always @(posedge clk) begin
    if (reset) begin
      inst_w_temp <= 0;
    end
    else begin
      inst_w_temp[1:0]   <= inst_w;
      inst_w_temp[3:2]   <= inst_w_temp[1:0];
      inst_w_temp[5:4]   <= inst_w_temp[3:2];
      inst_w_temp[7:6]   <= inst_w_temp[5:4];
      inst_w_temp[9:8]   <= inst_w_temp[7:6];
      inst_w_temp[11:10] <= inst_w_temp[9:8];
      inst_w_temp[13:12] <= inst_w_temp[11:10];
      inst_w_temp[15:14] <= inst_w_temp[13:12];
    end
  end

  // Base case: first row gets zeros as input
  assign temp[psum_bw*col-1:0] = in_n;

  // Generate MAC rows
  genvar i;
  generate
    for (i=0; i < row; i=i+1) begin : row_num
      mac_row #(.bw(bw), .psum_bw(psum_bw), .col(col)) mac_row_instance (
        .clk(clk),
        .reset(reset),
        .in_w(in_w[bw*(i+1)-1:bw*i]),
        .inst_w(inst_w_temp[2*i+1:2*i]),
        .in_n(temp[psum_bw*col*(i+1)-1:psum_bw*col*i]),
        .out_s(temp[psum_bw*col*(i+2)-1:psum_bw*col*(i+1)]),
        .valid(valid_temp[col*(i+1)-1:col*i])
      );
    end
  endgenerate

  // Output assignments
  assign out_s = temp[psum_bw*col*(row+1)-1:psum_bw*col*row];
  assign valid = valid_temp[col*row-1:col*(row-1)];

endmodule