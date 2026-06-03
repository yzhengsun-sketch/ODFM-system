`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/01/23 11:48:53
// Design Name: 
// Module Name: bit_to_symbol
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 

// transform the input data to symbols

// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module bit_to_symbol#(
    parameter   OFDM_NUM_PER_FRAME      =   8'd10,
    parameter   LEN_PER_SYMBOL_BPSK     =   10'd30,    // the first symbol LEN   subcarrier num = 480;
    parameter   LEN_PER_SYMBOL_16QAM    =   10'd120   // the later symbol LEN
    )
    (
    input                   clk,
    input                   rst_n,
    
    input   wire    [15:0]                          bit_in_tdata,
    input   wire                                    bit_in_tvalid,
    output  wire                                    bit_in_tready, 
    input   wire                                    bit_in_tlast,
    
    
    output   [16*OFDM_NUM_PER_FRAME-1:0]            sym_out_tdata,
    output   [OFDM_NUM_PER_FRAME-1:0]               sym_out_tvalid,
    input    [OFDM_NUM_PER_FRAME-1:0]               sym_out_tready,
    output   [OFDM_NUM_PER_FRAME-1:0]               sym_out_tlast,
    
    output   [7:0]                                  cur_sym_index   

    );
    
       
    wire    [16*OFDM_NUM_PER_FRAME-1:0]     sym_out_tdata;
    wire    [OFDM_NUM_PER_FRAME-1:0]        sym_out_tvalid;
    wire    [OFDM_NUM_PER_FRAME-1:0]        sym_out_tlast;
    
   
   parameter    INITIAL_TIME            =   8'd100;
   
   reg  [7:0]  initial_cnt;
   always @(posedge clk)
     begin
        if (rst_n == 1'b0)                   initial_cnt <= 8'd0;
        else if(initial_cnt < INITIAL_TIME)  initial_cnt <= initial_cnt + 8'd1;
     end   
     assign   bit_in_tready      =  (initial_cnt < INITIAL_TIME)? 1'b0 : ~fifo_full;
    
    reg            fifo_rd_en;
    wire   [15:0]  fifo_dout;
    wire           fifo_empty;
    wire           fifo_full;
    
    reg     [15:0] read_data_cnt;
    wire           read_data_clk;
    
    reg   [15:0]   avail_data_len;
    reg            is_first_symbol;

    
    reg     fifo_empty_d1;
    reg     read_data_start;
    
    reg [7:0]   cur_sym_index;       //indicating current symbol index
    reg         move_state;
    reg [7:0]   state_cnt;
    reg [7:0]   read_data_length;
    
    
    reg             bit_in_tvalid_d1; 
    reg   [15:0]    total_data_len;
    reg             sym_out_tlast_tmp;
    
    // obtain the total length of current frame
     always @(posedge clk) begin
        bit_in_tvalid_d1    <= bit_in_tvalid;
        if (bit_in_tvalid & (~bit_in_tvalid_d1)) begin
            total_data_len  <= bit_in_tdata;
        end
     end  
 
    always @(posedge clk)begin
        if (rst_n == 1'b0) begin
            read_data_start <= 1'b1;
            cur_sym_index   <= 8'hff;         // default state
            fifo_rd_en      <= 1'b0;
            read_data_cnt   <= 16'd0;
            move_state      <= 1'b0;
            state_cnt       <= 8'd0;
            sym_out_tlast_tmp <= 1'b0;
        end
        else begin
            fifo_empty_d1   <= fifo_empty;
            if (fifo_empty_d1 &(~fifo_empty)) begin
                read_data_start <= 1'b1;
                cur_sym_index   <= 8'd0;
                read_data_cnt   <= 16'd0;
                avail_data_len  <= total_data_len;
                sym_out_tlast_tmp <= 0;
            end
            else begin
                case (cur_sym_index)
                    8'd0: begin             // the first symbol
                        state_cnt     <= state_cnt + 1'b1;
                        read_data_length    <=  (avail_data_len < LEN_PER_SYMBOL_BPSK)? avail_data_len : LEN_PER_SYMBOL_BPSK;
                        if ((state_cnt >= 1) && (state_cnt < read_data_length + 1))  begin
                            fifo_rd_en <= 1'b1;
                        end
                        else begin
                            fifo_rd_en <= 1'b0;
                        end
                        
                        if (state_cnt == read_data_length)  begin
                            sym_out_tlast_tmp <= 1'b1;
                        end
                        else begin
                            sym_out_tlast_tmp <= 1'b0;
                        end
                        
                        //if (state_cnt == read_data_length + 10) begin                //delay 10 clk before moving to next symbol
                        if (sym_out_tlast_tmp) begin
                            avail_data_len <= avail_data_len - read_data_length;
                            cur_sym_index  <= cur_sym_index + 8'd1;                                          // move to next symbol
                            state_cnt      <= 8'd0;
                        end
                    end 
                    8'hff: begin 
                    end
                    default: begin           // the later symbol
                        if (avail_data_len == 0) begin
                            cur_sym_index   <= 8'hff;         // default state
                        end
                        else if (sym_out_tready[cur_sym_index]) begin
                            state_cnt     <= state_cnt + 1'b1;
                            read_data_length    <=  (avail_data_len < LEN_PER_SYMBOL_16QAM)? avail_data_len : LEN_PER_SYMBOL_16QAM;
                            if ((state_cnt >= 1) && (state_cnt < read_data_length + 1))  begin
                                fifo_rd_en <= 1'b1;
                            end
                            else begin
                                fifo_rd_en <= 1'b0;
                            end
                            
                            if (state_cnt == read_data_length)  begin
                                sym_out_tlast_tmp <= 1'b1;
                            end
                            else begin
                                sym_out_tlast_tmp <= 1'b0;
                            end
                            
                            //if (state_cnt == read_data_length + 10) begin                //delay 10 clk before moving to next symbol
                            if (sym_out_tlast_tmp) begin
                                avail_data_len <= avail_data_len - read_data_length;
                                cur_sym_index  <= cur_sym_index + 8'd1;                                          // move to next symbol
                                state_cnt      <= 8'd0;
                            end
                        end
                    end
                endcase 
            end        
        end
    end
   
    genvar j    ;
    generate
        for(j=0; j<OFDM_NUM_PER_FRAME; j=j+1)                     // the first OFDM symbol is empty;
        begin: qam_data_assignment
            assign    sym_out_tdata[j*16+15 -:16]  = (cur_sym_index == j)? fifo_dout : 16'd0;
            assign    sym_out_tvalid[j]            = (cur_sym_index == j)? fifo_rd_en : 1'b0;
            assign    sym_out_tlast[j]             = (cur_sym_index == j)? sym_out_tlast_tmp : 1'b0;
            assign    sym_out_tready[j]            = 1'b1;
        end
    endgenerate
 
 
  fifo_generator_16_8192 fifo_generator_16_8192_i (
     .srst          (~rst_n),                   // input wire srst
     .clk           (clk),                     // input wire clk
     .din           (bit_in_tdata),            // input wire [15 : 0] din
     .wr_en         (bit_in_tvalid),           // input wire wr_en
     .rd_en         (fifo_rd_en),              // input wire rd_en
     .dout          (fifo_dout),                // output wire [15 : 0] dout
     .full          (fifo_full),                // output wire full
     .empty         (fifo_empty),              // output wire empty
     .wr_rst_busy   (),  // output wire wr_rst_busy
     .rd_rst_busy   ()  // output wire rd_rst_busy
    );

endmodule
