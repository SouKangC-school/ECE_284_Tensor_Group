// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
`timescale 1ns/1ps

module core_tb;

parameter bw = 4;
parameter psum_bw = 16;
parameter len_kij = 9;
parameter len_onij = 16;
parameter col = 8;
parameter row = 8;
parameter len_nij = 36;

reg clk = 0;
reg reset = 1;

wire [48:0] inst_q; // Expanded instruction width for OS mode

reg [10:0] A_w_mem = 0;
reg CEN_w_mem = 1;
reg WEN_w_mem = 1;
reg [bw*row-1:0] D_w_mem_q = 0;
reg CEN_w_mem_q = 1;
reg WEN_w_mem_q = 1;
reg [10:0] A_w_mem_q = 0;
reg [1:0]  inst_w_q = 0; 
reg [bw*row-1:0] D_xmem_q = 0;
reg CEN_xmem = 1;
reg WEN_xmem = 1;
reg [10:0] A_xmem = 0;
reg CEN_xmem_q = 1;
reg WEN_xmem_q = 1;
reg [10:0] A_xmem_q = 0;
reg CEN_pmem = 1;
reg WEN_pmem = 1;
reg [10:0] A_pmem = 0;
reg CEN_pmem_q = 1;
reg WEN_pmem_q = 1;
reg [10:0] A_pmem_q = 0;
reg ofifo_rd_q = 0;
reg ififo_wr_q = 0;
reg ififo_rd_q = 0;
reg l0_rd_q = 0;
reg l0_wr_q = 0;
reg execute_q = 0;
reg load_q = 0;
reg acc_q = 0;
reg acc = 0;
reg relu = 0;
reg relu_q = 0;
reg mode = 1;
reg mode_q = 1;

reg [1:0]  inst_w; 
reg [bw*row-1:0] D_xmem;
reg [bw*row-1:0] D_w_mem;
reg [psum_bw*col-1:0] answer;


reg ofifo_rd;
reg ififo_wr;
reg ififo_rd;
reg l0_rd;
reg l0_wr;
reg execute;
reg load;
reg [8*30:1] stringvar;
reg [8*30:1] w_file_name;
wire ofifo_valid;
wire [col*psum_bw-1:0] sfp_out;
wire [psum_bw*col*row-1:0] tile_psum_array;

integer x_file, x_scan_file ; // file_handler
integer w_file, w_scan_file ; // file_handler
integer acc_file, acc_scan_file ; // file_handler
integer out_file, out_scan_file ; // file_handler
integer captured_data; 
integer t, i, j, k, kij;
integer error;

assign inst_q[48] = mode;      // OS/WS mode select
assign inst_q[47] = relu_q;
assign inst_q[46] = acc_q;
assign inst_q[45] = CEN_w_mem_q;
assign inst_q[44] = WEN_w_mem_q;
assign inst_q[43:33] = A_w_mem_q;
assign inst_q[32] = CEN_pmem_q;
assign inst_q[31] = WEN_pmem_q;
assign inst_q[30:20] = A_pmem_q;
assign inst_q[19] = CEN_xmem_q;
assign inst_q[18] = WEN_xmem_q;
assign inst_q[17:7] = A_xmem_q;
assign inst_q[6] = ofifo_rd_q;
assign inst_q[5] = ififo_wr_q;
assign inst_q[4] = ififo_rd_q;
assign inst_q[3] = l0_rd_q;
assign inst_q[2] = l0_wr_q;
assign inst_q[1] = execute_q;
assign inst_q[0] = load_q;


core  #(.bw(bw), .col(col), .row(row)) core_instance (
	  .clk(clk), 
	  .reset(reset),
	  .inst(inst_q),
	  .ofifo_valid(ofifo_valid),
	  .d_xmem(D_xmem_q), 
	  .d_w_mem(D_w_mem_q), 
	  .sfp_out(sfp_out), 
	  .tile_psum_array(tile_psum_array)); 


initial begin 

    mode     = 1;
    inst_w   = 0; 
    D_xmem   = 0;
    CEN_xmem = 1;
    WEN_xmem = 1;
    A_xmem   = 0;
    ofifo_rd = 0;
    ififo_wr = 0;
    ififo_rd = 0;
    l0_rd    = 0;
    l0_wr    = 0;
    execute  = 0;
    load     = 0;

    $dumpfile("core_tb.vcd");
    $dumpvars(0,core_tb);

    x_file = $fopen("activation.txt", "r");
    // Following three lines are to remove the first three comment lines of the file
    x_scan_file = $fscanf(x_file,"%s", captured_data);
    x_scan_file = $fscanf(x_file,"%s", captured_data);
    x_scan_file = $fscanf(x_file,"%s", captured_data);

    //////// Reset /////////
    #0.5 clk = 1'b0;   reset = 1;
    #0.5 clk = 1'b1; 

    for (i=0; i<10 ; i=i+1) begin
        #0.5 clk = 1'b0;
        #0.5 clk = 1'b1;  
    end

    #0.5 clk = 1'b0;   reset = 0;
    #0.5 clk = 1'b1; 

    #0.5 clk = 1'b0;   
    #0.5 clk = 1'b1;   
    /////////////////////////

    /////// Activation data writing to memory ///////
    for (t=0; t<len_nij; t=t+1) begin  
        #0.5 clk = 1'b0;  
        x_scan_file = $fscanf(x_file,"%32b", D_xmem); 
        WEN_xmem = 0; 
        CEN_xmem = 0; 
        if (t>0) A_xmem = A_xmem + 1;
        #0.5 clk = 1'b1;   
    end

    #0.5 clk = 1'b0;  WEN_xmem = 1;  CEN_xmem = 1; A_xmem = 0;
    #0.5 clk = 1'b1; 

    $fclose(x_file);
    /////////////////////////////////////////////////

    /////////////////////////////////////////////////
    w_file_name = "weight.txt";
    w_file = $fopen(w_file_name, "r");
    // Following three lines are to remove the first three comment lines of the file
    w_scan_file = $fscanf(w_file,"%s", captured_data);
    w_scan_file = $fscanf(w_file,"%s", captured_data);
    w_scan_file = $fscanf(w_file,"%s", captured_data);
  
    /////////////////////////////////////////////////




    /////// Kernel data writing to memory ///////

    for (t=0; t<27; t=t+1) begin  // Write all 27 weights at once for OS mode
        #0.5 clk = 1'b0;  
        w_scan_file = $fscanf(w_file,"%32b", D_w_mem); 
        WEN_w_mem = 0; 
        CEN_w_mem = 0; 
        if (t>0) A_w_mem = A_w_mem + 1;
        #0.5 clk = 1'b1;   
    end

    #0.5 clk = 1'b0;  WEN_w_mem = 1;  CEN_w_mem = 1; A_w_mem = 0;
    #0.5 clk = 1'b1; 
    $fclose(w_file);
    ///////////////////////////////////////

    // Add delay cycles
    for (i=0; i<10 ; i=i+1) begin
        #0.5 clk = 1'b0;
        #0.5 clk = 1'b1;  
    end

    /////// Kernel data writing to L0 ///////
    A_xmem = 0;   
    l0_rd = 0;  
    WEN_xmem = 1; 
    CEN_xmem = 0; 
    l0_wr = 1;    
    

    for (i=0; i<len_nij; i=i+1) begin
        #0.5 clk = 1'b0;
        if (i>0) A_xmem = A_xmem + 1;
        #0.5 clk = 1'b1; 
    end

    #0.5 clk = 1'b0;l0_wr = 0;    
    #0.5 clk = 1'b1;

    for (i=0; i<10 ; i=i+1) begin
      #0.5 clk = 1'b0;
      #0.5 clk = 1'b1;  
    end

    #0.5 clk = 1'b0;
    /////////////////////////////////////

    /////// Weight data writing to IFIFO ///////
    A_w_mem = 0;   
    ififo_rd = 0;  
    WEN_w_mem = 1; 
    CEN_w_mem = 0; 
    ififo_wr = 1;    

    // Write weights from w_mem to IFIFO
    for (i=0; i<28; i=i+1) begin  // Write all 27 weights
        #0.5 clk = 1'b0;
        if (i>0) A_w_mem = A_w_mem + 1;
        #0.5 clk = 1'b1; 
    end

    #0.5 clk = 1'b0; ififo_wr = 0;    
    #0.5 clk = 1'b1;

    // Add delay cycles
    for (i=0; i<10 ; i=i+1) begin
        #0.5 clk = 1'b0;
        #0.5 clk = 1'b1;  
    end

    #0.5 clk = 1'b0;
    /////////////////////////////////////



    
    /////// Execution ///////
    l0_rd = 1;   
    #0.5 clk = 1'b1;
    #0.5 clk = 1'b0;

    ififo_rd = 1;  
    #0.5 clk = 1'b1;

    for (i=0; i<27; i=i+1) begin
        #0.5 clk = 1'b0;  execute = 1;      
        #0.5 clk = 1'b1; 
    end

    // Hold ififo_rd for one more cycle to maintain last value
    #0.5 clk = 1'b0;  
    execute = 1;      
    #0.5 clk = 1'b1; 

    // One final execution cycle with ififo_rd disabled
    #0.5 clk = 1'b0;  
    execute = 1;
    ififo_rd = 0;     // Disable ififo_rd
    l0_rd = 0;
    #0.5 clk = 1'b1;

    #0.5 clk = 1'b0;  
    execute = 0;      // Finally disable execute
    #0.5 clk = 1'b1;

    // Additional cycles for pipeline flush
    for (i=0; i<50; i=i+1) begin
        #0.5 clk = 1'b0;
        #0.5 clk = 1'b1;  
    end

    //#0.5 clk = 1'b0;  l0_rd = 0; ififo_rd = 0; execute = 0;              
    //#0.5 clk = 1'b1;  
    /////////////////////////////////////



    //////// OFIFO READ ////////
    // Ideally, OFIFO should be read while execution, but we have enough ofifo
    // depth so we can fetch out after execution.
    
    #0.5 clk = 1'b0;
    ofifo_rd = 1;    
    #0.5 clk = 1'b1;

    for (t=0; t<len_nij+1; t=t+1) begin  
      #0.5 clk = 1'b0; CEN_pmem = 0; WEN_pmem = 0; if (t>0) A_pmem = A_pmem + 1; 
      #0.5 clk = 1'b1;  
    end

    #0.5 clk = 1'b0; CEN_pmem = 1; WEN_pmem = 1; ofifo_rd = 0;
    #0.5 clk = 1'b1;

    for (i=0; i<10 ; i=i+1) begin
      #0.5 clk = 1'b0;
      #0.5 clk = 1'b1;  
    end

  


    ////////// Accumulation /////////
    out_file = $fopen("output.txt", "r");  

    // Following three lines are to remove the first three comment lines of the file
    out_scan_file = $fscanf(out_file,"%s", answer); 
    out_scan_file = $fscanf(out_file,"%s", answer); 
    out_scan_file = $fscanf(out_file,"%s", answer); 

    error = 0;

    // Wait for execute signal and initial computation
    for (t=0; t<500; t=t+1) begin  // Wait for first computation to complete
        #0.5 clk = 1'b0;  
        #0.5 clk = 1'b1;  
    end

    $display("############ Verification Start for OS mode #############"); 

    for (i=0; i<8; i=i+1) begin  // Check each row output
        if (i>-1) begin  // Skip first row since it's initialization
            out_scan_file = $fscanf(out_file,"%128b", answer); // Read 128 bits per row
            if (tile_psum_array[i*128 +: 128] == answer)  // Compare corresponding row
                $display("%2d-th output tile Data matched! :D", i); 
            else begin
                $display("tile_psum_array[%d]: %128b", i, tile_psum_array[i*128 +: 128]);
                $display("answer: %128b", answer);
                error = 1;
            end
        end
    end


    if (error == 0) begin
        $display("############ No error detected ##############"); 
        $display("########### Project Completed !! ############"); 

    end

    for (t=0; t<10; t=t+1) begin  
        #0.5 clk = 1'b0;  
        #0.5 clk = 1'b1;  
    end

    #10 $finish;

end

always @ (posedge clk) begin
   inst_w_q   <= inst_w; 
   D_xmem_q   <= D_xmem;
   CEN_xmem_q <= CEN_xmem;
   WEN_xmem_q <= WEN_xmem;
   A_pmem_q   <= A_pmem;
   CEN_pmem_q <= CEN_pmem;
   WEN_pmem_q <= WEN_pmem;
   A_xmem_q   <= A_xmem;
   ofifo_rd_q <= ofifo_rd;
   acc_q      <= acc;
   ififo_wr_q <= ififo_wr;
   ififo_rd_q <= ififo_rd;
   l0_rd_q    <= l0_rd;
   l0_wr_q    <= l0_wr ;
   execute_q  <= execute;
   load_q     <= load;
   relu_q     <= relu;
   D_w_mem_q  <= D_w_mem;
   CEN_w_mem_q <= CEN_w_mem;
   WEN_w_mem_q <= WEN_w_mem;
   A_w_mem_q  <= A_w_mem;
   mode_q     <= mode;
end


endmodule