`timescale 1ns/1ps

module ctrl_tb();

localparam VEC_ADDRW = 8;
localparam MAT_ADDRW = 9;
localparam VEC_SIZEW = VEC_ADDRW + 1;
localparam MAT_SIZEW = MAT_ADDRW + 1;

localparam CLK_PERIOD = 4;
localparam NUM_TESTS = 10;

logic clk, rst, start;
logic o_first, o_last, o_valid, o_busy;

logic [VEC_ADDRW-1:0] i_vec_start_addr, o_vec_raddr;
logic [VEC_SIZEW-1:0] i_vec_num_words;
logic [MAT_ADDRW-1:0] i_mat_start_addr, o_mat_raddr;
logic [MAT_SIZEW-1:0] i_mat_num_rows_per_olane;

ctrl #(
    .VEC_ADDRW(VEC_ADDRW),
    .MAT_ADDRW(MAT_ADDRW),
    .VEC_SIZEW(VEC_SIZEW),
    .MAT_SIZEW(MAT_SIZEW)
) dut (
    .clk(clk),
    .rst(rst),
    .start(start),
    .vec_start_addr(i_vec_start_addr),
    .vec_num_words(i_vec_num_words),
    .mat_start_addr(i_mat_start_addr),
    .mat_num_rows_per_olane(i_mat_num_rows_per_olane),
    .vec_raddr(o_vec_raddr),
    .mat_raddr(o_mat_raddr),
    .accum_first(o_first),
    .accum_last(o_last),
    .ovalid(o_valid),
    .busy(o_busy)
);

initial begin 
    clk = 1'b0;
    forever #(CLK_PERIOD/2) clk = ~clk;
end 


logic sim_failed;
initial begin 
    rst = 1;
    start = 0;
    i_vec_start_addr = 0;
    i_vec_num_words = 0;
    i_mat_start_addr = 0;
    i_mat_num_rows_per_olane = 0;
    sim_failed = 0;
    $display("Resetting tests...");
    $display("vec_raddr = %d, mat_radder = %d, accum_first = %d, accum_last = %d, busy = %d, ovalid = %d", o_vec_raddr, o_mat_raddr, o_first, o_last, o_busy, o_valid);

    #(25 * CLK_PERIOD);
    rst = 0;
    #(CLK_PERIOD);

    $display("Starting tests...");
    for (int i = 0; i < NUM_TESTS; i++) begin
        /* Generate random inputs - positive */
        
        i_vec_start_addr = $urandom_range(1, 9);
        i_vec_num_words = $urandom_range(1, 9);
        i_mat_start_addr = $urandom_range(1, 9);
        i_mat_num_rows_per_olane = $urandom_range(1, 9);
        $display("Running test %0d", i);
        $display("vec_start_addr = %d, vec_num_words = %d, mat_start_addr = %d, mat_num_rows_per_olane = %d", i_vec_start_addr, i_vec_num_words, i_mat_start_addr, i_mat_num_rows_per_olane);

        start = 1; #(CLK_PERIOD); start = 0;

        wait(o_busy);
        
        for (int row = 0; row < i_mat_num_rows_per_olane; row = row + 1) begin
            for (int word = 0; word < i_vec_num_words; word = word + 1) begin
                $display("vec_raddr = %d, mat_radder = %d, accum_first = %d, accum_last = %d, busy = %d, ovalid = %d", o_vec_raddr, o_mat_raddr, o_first, o_last, o_busy, o_valid); 
                if(o_vec_raddr != i_vec_start_addr + word) begin 
                    $display("wrong o_vec_raddr");
                    sim_failed = 1;
                end 
                if(o_mat_raddr != i_mat_start_addr + (row * i_vec_num_words) + word) begin
                    $display("wrong o_mat_raddr"); 
                    sim_failed = 1;
                end 
                    
                if (!o_valid) begin 
                    $display("wrong o_valid");
                    sim_failed = 1; 
                end 
                if (!o_busy) begin 
                    $display("wrong o_busy");
                    sim_failed = 1;
                end 
                
                if(word == 0 && !o_first) begin 
                    $display("wrong o_first");
                    sim_failed = 1;
                end 
                
                if (word == i_vec_num_words - 1 && !o_last) begin
                    $display("wrong o_last"); 
                    sim_failed = 1;
                end
                
                #(CLK_PERIOD);
                
            end
        end

        $display("Test %0d finished.", i);

        #(CLK_PERIOD);
    end 

    $display("End tests");

    if (sim_failed) begin
        $display("SIMULATION FAILED");
    end else begin
        $display("SIMULATION PASSED"); 
    end

 

    $finish;
end
endmodule