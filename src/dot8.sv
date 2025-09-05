/***************************************************/
/* ECE 327: Digital Hardware Systems - Spring 2025 */
/* Lab 4                                           */
/* 8-Lane Dot Product Module                       */
/***************************************************/

module dot8 # (
    parameter IWIDTH = 8,
    parameter OWIDTH = 32
)(
    input clk,
    input rst,
	//inputs are registered
    input signed [8*IWIDTH-1:0] vec0,
    input signed [8*IWIDTH-1:0] vec1,
    input ivalid,
    output signed [OWIDTH-1:0] result,
    output ovalid
);

/******* Your code starts here *******/
localparam NUM_STAGES = 5;

/* register declarations */
logic signed [IWIDTH-1:0] a[8];
logic signed [IWIDTH-1:0] b[8];
logic valid[NUM_STAGES];

// multiplication pipeline
logic signed [8*IWIDTH-1:0] v0_r, v1_r;
logic signed [2*IWIDTH-1:0] m[8];

//addition pipelines     
logic signed [2*IWIDTH:0] add1[4]; //first adders  
logic signed [2*IWIDTH+1:0] add2[2]; //second adders  
logic signed [2*IWIDTH+2:0] add3; //last adder   


//wire the inputs
always_comb begin 
	for (int i = 0; i < 8; i++) begin 
		//from whatever multiple of IWIDTH-1 down 8 bits
		a[i] = v0_r[(i+1)*IWIDTH-1 -: IWIDTH];
		b[i] = v1_r[(i+1)*IWIDTH-1 -: IWIDTH];
	end
end

assign ovalid = valid[4];
//replication operator to get only OWIDTH Bits
assign result = {{(OWIDTH - (2*IWIDTH+3)){add3[2*IWIDTH+2]}}, add3};
                         
always_ff @(posedge clk) begin
    if (rst) begin 
        //resets all elements to 0;
         m <= '{default:0};
         valid <= '{default:0};
         add1 <= '{default:0};
         add2 <= '{default:0};
         add3 <= '{default:0};
         v0_r <= '{default:0};
         v1_r <= '{default:0};
    end else begin 
        //stage 0 - restoring inputs
		v0_r <= vec0;
		v1_r <= vec1;
		valid[0] <= ivalid;
		//stage 1 - multiplier
		valid[1] <= valid[0];
	    for (int i = 0; i < 8; i++) begin
	         m[i] <= a[i] * b[i];
        end	
        
        //stage 2 - first addition   
         valid[2] <= valid[1];
        for (int i = 0; i < 4; i++) begin
            add1[i] <= m[i*2] + m[i*2 + 1];
        end
        
        //stage 3 - second addition    
       valid[3] <= valid[2];
        add2[0] <= add1[0] + add1[1];
        add2[1] <= add1[2] + add1[3];
        
        //stage 4 - third and final addition
	     valid[4] <= valid[3];
	     add3 <= add2[0] + add2[1];
    end
end

/******* Your code ends here ********/

endmodule