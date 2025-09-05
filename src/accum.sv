/***************************************************/
/* ECE 327: Digital Hardware Systems - Spring 2025 */
/* Lab 4                                           */
/* Accumulator Module                              */
/***************************************************/

module accum # (
    parameter DATAW = 19,
    parameter ACCUMW = 32
)(
    input  clk,
    input  rst,
    input  signed [DATAW-1:0] data,
    input  ivalid,
    input  first,
    input  last,
    output signed [ACCUMW-1:0] result,
    output ovalid
);

/******* Your code starts here *******/
logic signed[ACCUMW-1:0] sum_r;
logic valid_r;

//assume there's no overflow 
always_ff @(posedge clk) begin 
    if (rst) begin 
        sum_r <= 0;
        valid_r <= 0;
    end else begin 
        if (ivalid) begin 
           if (first) begin 
                sum_r <= data;
            end else begin 
                sum_r <= sum_r + data;
            end    
        end
          
        valid_r <=  ivalid && last;
    end
end  

assign ovalid = valid_r;   
assign result = sum_r;

/******* Your code ends here ********/

endmodule