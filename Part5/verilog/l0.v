// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module l0 (clk, in, out, rd, wr, o_full, reset, o_ready);

  parameter row  = 8;
  parameter bw = 4;

  input  clk;
  input  wr;
  input  rd;
  input  reset;
  input  [row*bw-1:0] in;
  output [row*bw-1:0] out;
  output o_full;
  output o_ready;

  wire [row-1:0] empty;
  wire [row-1:0] full;
  reg [row-1:0] rd_en;
  
  genvar i;

  assign o_ready = (|full==0)? 1:0;
  assign o_full  = (|full==1)? 1:0;

  for (i=0; i<row ; i=i+1) begin : row_num
    fifo_depth64 #(.bw(bw)) fifo_instance (
      .rd_clk(clk),
      .wr_clk(clk),
      .rd(rd_en[i]),
      .wr(wr),
      .o_empty(empty[i]),
      .o_full(full[i]),
	    .in(in[bw*(i+1)-1:bw*i]),
	    .out(out[bw*(i+1)-1:bw*i]),
      .reset(reset));
  end

  always @ (posedge clk) begin
   if (reset) begin
      rd_en <= 8'b00000000;
   end
   else begin
      /////////////// version1: read all row at a time ////////////////
      rd_en <= {rd_en[row-2:0],rd};  // All rows read simultaneously when rd=1
      ///////////////////////////////////////////////////////

      //////////////// version2: read 1 row at a time /////////////////
      // Uncomment this section and comment version1 to use version2
      /*
      if (rd) begin
          rd_en <= {rd_en[6:0], rd_en[7]};  // Rotate read enable
          if (rd_en == 8'b00000000)
              rd_en[0] <= 1'b1;  // Start with row0
      end
      else begin
          rd_en <= 8'b00000000;  // Disable all reads when rd=0
      end
      */
      ///////////////////////////////////////////////////////
    end
  end

endmodule
