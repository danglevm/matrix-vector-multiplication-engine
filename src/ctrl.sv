/***************************************************/
/* ECE 327: Digital Hardware Systems - Spring 2025 */
/* Lab 4                                           */
/* MVM Control FSM                                 */
/***************************************************/

module ctrl # (
    parameter VEC_ADDRW = 8,
    parameter MAT_ADDRW = 9,
    parameter VEC_SIZEW = VEC_ADDRW + 1,
    parameter MAT_SIZEW = MAT_ADDRW + 1
)(
    input  clk,
    input  rst,
    input  start,
    input  [VEC_ADDRW-1:0] vec_start_addr,
    input  [VEC_SIZEW-1:0] vec_num_words,
    input  [MAT_ADDRW-1:0] mat_start_addr,
    input  [MAT_SIZEW-1:0] mat_num_rows_per_olane,
    output [VEC_ADDRW-1:0] vec_raddr,
    output [MAT_ADDRW-1:0] mat_raddr,
    output accum_first,
    output accum_last,
    output ovalid,
    output busy
);

/******* Your code starts here *******/
logic o_valid, o_busy, o_first, o_last;
assign busy = o_busy;
assign ovalid = o_valid;
assign accum_first = o_first;
assign accum_last = o_last;

/* counter variables */
logic [VEC_SIZEW-1:0] word_count;
logic [MAT_SIZEW-1:0] row_count;

logic [VEC_ADDRW-1:0] i_vec_start_addr, o_vec_raddr;
logic [VEC_SIZEW-1:0] i_vec_num_words;
logic [MAT_ADDRW-1:0] o_mat_raddr;
logic [MAT_SIZEW-1:0] i_mat_num_rows_per_olane;

logic [MAT_ADDRW-1:0] current_row_base_addr;

assign vec_raddr = o_vec_raddr;
assign mat_raddr = o_mat_raddr;

enum {IDLE, COMPUTE} state, next_state;
always_ff @ (posedge clk) begin 
    if (rst) begin 
        state <= IDLE;
        word_count <= 0;
        row_count <= 0;
        i_vec_start_addr <= 0;
        i_vec_num_words <= 0;
        current_row_base_addr <= 0;
    end else begin
        state <= next_state;
        if (state == IDLE) begin 
            i_vec_start_addr <= vec_start_addr;
            i_vec_num_words <= vec_num_words;
            i_mat_num_rows_per_olane <= mat_num_rows_per_olane;
            current_row_base_addr <= mat_start_addr;
        end

        if (state == COMPUTE) begin 
            if (word_count == i_vec_num_words - 1) begin 
                current_row_base_addr <= current_row_base_addr + i_vec_num_words;
                word_count <= 0;
                row_count <= row_count + 1;
            end else begin 
                word_count <= word_count + 1;
            end 
        end else begin 
            word_count <= 0;
            row_count <= 0;
        end
    end
end



always_comb begin : state_decoder
    case (state) 
        IDLE: begin 
            if (start) next_state = COMPUTE;
            else next_state = IDLE;
        end 
        COMPUTE: begin
            if (word_count == i_vec_num_words - 1 && row_count == i_mat_num_rows_per_olane - 1) begin 
                next_state = IDLE;
            end else begin
                next_state = COMPUTE;
            end
        end
        default: next_state = IDLE; 
    endcase
end 

always_comb begin : state_output
    case (state)
        IDLE: begin 
            o_valid = 0;
            o_busy = 0;
            o_first = 0;
            o_last = 0;    
            o_vec_raddr = 0;
            o_mat_raddr = 0;

        end 
        COMPUTE: begin 
            o_valid = 1;
            o_busy = 1;
            o_vec_raddr = i_vec_start_addr + word_count;
            o_mat_raddr =  current_row_base_addr + word_count;

            if (word_count == 0) o_first = 1; 
            else o_first = 0;

            if (word_count == i_vec_num_words - 1) o_last = 1;
            else o_last = 0; 
        end
        default: begin 
            o_valid = 0;
            o_busy = 0;
            o_first = 0;
            o_last = 0;
            o_vec_raddr = 0;
            o_mat_raddr = 0;
        end 
    endcase
end


/******* Your code ends here ********/

endmodule