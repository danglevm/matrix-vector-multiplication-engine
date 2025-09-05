/***************************************************/
/* ECE 327: Digital Hardware Systems - Spring 2025 */
/* Lab 4                                           */
/* Matrix Vector Multiplication (MVM) Module       */
/***************************************************/

module mvm # (
    parameter IWIDTH = 8,
    parameter OWIDTH = 32,
    parameter MEM_DATAW = IWIDTH * 8,
    parameter VEC_MEM_DEPTH = 256,
    parameter VEC_ADDRW = $clog2(VEC_MEM_DEPTH),
    parameter MAT_MEM_DEPTH = 512,
    parameter MAT_ADDRW = $clog2(MAT_MEM_DEPTH),
    parameter NUM_OLANES = 8
)(
    input clk,
    input rst,
    input [MEM_DATAW-1:0] i_vec_wdata,
    input [VEC_ADDRW-1:0] i_vec_waddr,
    input i_vec_wen,
    input [MEM_DATAW-1:0] i_mat_wdata,
    input [MAT_ADDRW-1:0] i_mat_waddr,
    input [NUM_OLANES-1:0] i_mat_wen,
    input i_start,
    input [VEC_ADDRW-1:0] i_vec_start_addr,
    input [VEC_ADDRW:0] i_vec_num_words,
    input [MAT_ADDRW-1:0] i_mat_start_addr,
    input [MAT_ADDRW:0] i_mat_num_rows_per_olane,
    output o_busy,
    output [OWIDTH-1:0] o_result [0:NUM_OLANES-1],
    output o_valid
);

/******* Your code starts here *******/
// assign o_valid = ;

/* VECTOR MEMORY */
logic signed [VEC_ADDRW-1:0] vec_raddr;
logic signed [MEM_DATAW-1:0] vec_rdata;


mem #(
    .DATAW(MEM_DATAW),
    .DEPTH(VEC_MEM_DEPTH),
    .ADDRW(VEC_ADDRW)
) mem_vec (
    .clk(clk),
    .wdata(i_vec_wdata),
    .waddr(i_vec_waddr),
    .wen(i_vec_wen),
    .raddr(vec_raddr),
    .rdata(vec_rdata)
);


/* CONTROLLER */
logic signed [MAT_ADDRW-1:0] mat_raddr;
logic ctrl_ovalid, ctrl_ovalid_s1, dot_ivalid;
logic ctrl_accum_first, ctrl_accum_last;
ctrl #(
    .VEC_ADDRW(VEC_ADDRW),
    .MAT_ADDRW(MAT_ADDRW),
    .VEC_SIZEW(VEC_ADDRW + 1),
    .MAT_SIZEW(MAT_ADDRW + 1)
) ctrl_inst (
    .clk(clk),
    .rst(rst),
    .start(i_start),
    .vec_start_addr(i_vec_start_addr),
    .vec_num_words(i_vec_num_words),
    .mat_start_addr(i_mat_start_addr),
    .mat_num_rows_per_olane(i_mat_num_rows_per_olane),
    .vec_raddr(vec_raddr),
    .mat_raddr(mat_raddr),
    .accum_first(ctrl_accum_first),
    .accum_last(ctrl_accum_last),
    .ovalid(ctrl_ovalid),
    .busy(o_busy)
);


//Delay chain for dot product
//1 cycle delay
always_ff @(posedge clk) begin
    if (rst) begin
        dot_ivalid <= 0;
    end else begin
        dot_ivalid <= ctrl_ovalid;
    end
end

logic [5:0] accum_first_pipe, accum_last_pipe;
logic accum_first_delayed, accum_last_delayed;
always_ff @(posedge clk) begin 
    if (rst) begin 
        accum_first_pipe <= 0;
        accum_last_pipe <= 0;
    end else begin 
        //6 stage pipeline signals shifting
        accum_first_pipe <= {accum_first_pipe[4:0], ctrl_accum_first};
        accum_last_pipe <= {accum_last_pipe[4:0], ctrl_accum_last};
    end 
end

assign accum_first_delayed = accum_first_pipe[5];
assign accum_last_delayed = accum_last_pipe[5];

/* GENERATE COMPUTE LANES */
logic signed[OWIDTH-1:0] dot8_results[NUM_OLANES];
logic signed[MEM_DATAW-1:0] mat_rdata[NUM_OLANES];
logic accum_ovalid[NUM_OLANES];
logic dot_ovalid[NUM_OLANES];

genvar i;
generate
    for (i = 0; i < NUM_OLANES; i = i + 1) begin : compute_lanes
        mem #(
            .DATAW(MEM_DATAW),
            .DEPTH(MAT_MEM_DEPTH),
            .ADDRW(MAT_ADDRW)
        ) mat_mem_inst (
            .clk(clk),
            .wdata(i_mat_wdata),
            .waddr(i_mat_waddr),
            .wen(i_mat_wen[i]),
            .raddr(mat_raddr),
            .rdata(mat_rdata[i])
        );
        
        dot8 #(
            .IWIDTH(IWIDTH),
            .OWIDTH(OWIDTH)
        ) dot8_inst (
            .clk(clk),
            .rst(rst),
            .vec0(vec_rdata), //every lane get the same vector input
            .vec1(mat_rdata[i]),
            .ivalid(dot_ivalid),
            .result(dot8_results[i]),
            .ovalid(dot_ovalid[i])
        );

         accum #(
             .DATAW(OWIDTH),
             .ACCUMW(OWIDTH)
         ) accum_inst (
             .clk(clk),
             .rst(rst),
             .data(dot8_results[i]),
             .ivalid(dot_ovalid[i]),
             .first(accum_first_delayed),
             .last(accum_last_delayed),
             .result(o_result[i]),
             .ovalid(accum_ovalid[i])
         );
    end
endgenerate

assign o_valid = accum_ovalid[0];

/******* Your code ends here ********/

endmodule