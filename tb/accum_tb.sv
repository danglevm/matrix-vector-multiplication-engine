`timescale  1ns/1ps

module accum_tb();

localparam DATAW = 19;
localparam ACCUMW = 32;
localparam CLK_PERIOD = 4;
localparam NUM_TESTS = 50;

logic clk, rst;

logic ivalid, first, last, ovalid;

logic signed[DATAW-1:0] data;
logic signed[ACCUMW-1:0] result;
logic signed[ACCUMW-1:0] golden_sum;
logic sim_failed;
integer len;

accum #(
    .DATAW(DATAW),
    .ACCUMW(ACCUMW)
) dut (
    .clk(clk),
    .rst(rst),
    .data(data),
    .ivalid(ivalid),
    .first(first),
    .last(last),
    .result(result),
    .ovalid(ovalid)
);


initial begin 
    clk = 0;
    forever #(CLK_PERIOD/2) clk = ~clk;
end

initial begin
    rst = 1'b1;
    ivalid = 0;
    first = 0;
    last = 0;
    data = 0;

    #(CLK_PERIOD);
    rst = 1'b0;
    $display("Starting randomized tests...");

    for (int test = 0; test < NUM_TESTS; test++) begin 
        len = $urandom_range(1, 10); //random accumulation begins

        //first input sequence
        ivalid = 1; first = 1; last = (len == 1); data = $random;
        golden_sum = data;
        #(CLK_PERIOD);
        first = 0;

        for (int j = 1; j < len; j++) begin 
            last = (j == len - 1);
            data = $random;
            golden_sum += data;
            #(CLK_PERIOD);
        end
        ivalid = 0; 

        wait(ovalid);
        if (result == golden_sum) begin 
            $display("TEST %0d PASSED: Result: %d, Expected: %d", test, result, golden_sum);
        end else begin 
            $display("TEST %0d FAILED: Result: %d, Expected: %d", test, result, golden_sum);
            sim_failed = 1;
        end  
        #(CLK_PERIOD);
    end

    /* Single-input accumulation */
    $display("\nRunning specific test: Single-Input Accumulation");
    ivalid = 1; first = 1; last = 1; data = -50;
    golden_sum = data;
    #(CLK_PERIOD);
    ivalid = 0; first = 0; last = 0;

    wait (ovalid);
    if (result == golden_sum) $display("PASSED single-input accumulation");
    else begin $display("FAILED single-input accumulation"); sim_failed = 1; end

    if (sim_failed) $display("\nSIMULATION FAILED");
    else $display("\nSIMULATION PASSED");

    $finish;

end

endmodule