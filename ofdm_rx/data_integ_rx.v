`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/01/29 14:50:06
// Design Name: 
// Module Name: data_integ_rx
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module data_integ_rx#(
    parameter   OFDM_NUM_PER_FRAME      =   8'd10,   // length per symbol
    parameter   FFT_LENGTH              =   512,
    parameter   CP_LENGTH               =   64,
    parameter   LEN_PER_SYMBOL_BPSK     =   10'd30,
    parameter   LEN_PER_SYMBOL_16QAM    =   10'd120
    )
    (
    input                   clk,
    input                   rst_n,
    
    input   wire    [16*OFDM_NUM_PER_FRAME-1:0]     rx_bit_out_tdata,
    input   wire    [OFDM_NUM_PER_FRAME-1:0]        rx_bit_out_tvalid,
    input   wire    [OFDM_NUM_PER_FRAME-1:0]        rx_bit_out_tlast,   
    output  reg     [OFDM_NUM_PER_FRAME-1:0]        rx_bit_out_tready,
    
    output  wire    [15:0]                          bit_out_tdata,
    output  wire                                    bit_out_tvalid,
    input                                           bit_out_tready, 
    output                                          bit_out_tlast
    );

    parameter   IDLE    =   2'b00;
    parameter   CALC    =   2'b01;
    parameter   BUSY    =   2'b11;
    
    
    reg     [1:0]   state;
    reg     [7:0]   cur_sym_index;
    reg     [9:0]   wr_cnt;
    reg     [9:0]   num_per_frame;
    
    reg     [15:0]      fifo_din;
    reg                 fifo_wr_en;
    reg                 fifo_rd_en;
    wire    [15:0]      fifo_dout;
    wire                fifo_empty;
    wire                fifo_full;
    
    
    always @(posedge clk or negedge rst_n) begin
        if (rst_n == 1'b0) begin
            state           <=  IDLE;
            wr_cnt          <=  10'd0;
            fifo_rd_en      <=  1'b0;
        end
        else begin
            num_per_frame   <= ( cur_sym_index ==  8'd0)? LEN_PER_SYMBOL_BPSK : LEN_PER_SYMBOL_16QAM;    // read length for every symbol
            
            case (state) 
                IDLE:  begin  
                    cur_sym_index       <=  8'd0;           //waiting for the first symbol
                    rx_bit_out_tready   <=  10'd1;
                    if (rx_bit_out_tvalid[0])begin               //if the first symbol is comming 
                        state           <=  CALC;
                        wr_cnt          <=  wr_cnt + 1'b1;
                    end
                    else begin
                        wr_cnt          <=  10'd0;
                    end
                end
                CALC:  begin  
                    if (fifo_wr_en) begin                           
                        if (wr_cnt ==  num_per_frame - 1) begin
                            cur_sym_index       <=  cur_sym_index + 1'b1;
                            rx_bit_out_tready   <=  rx_bit_out_tready << 1;
                            wr_cnt              <=  10'd0;
                        end
                        else begin
                            wr_cnt              <=  wr_cnt + 1'b1;
                        end 
                    end
                    if (cur_sym_index == OFDM_NUM_PER_FRAME - 1) begin
                        state           <=  BUSY;
                    end             
                end
                
                BUSY: begin
                    if (bit_out_tready & (~fifo_empty)) begin
                        fifo_rd_en      <=  1'b1;
                    end
                    else if (fifo_empty) begin
                        fifo_rd_en      <=  1'b0;
                        state           <=  IDLE;
                    end
                end 
            endcase
            
            fifo_din        <=   rx_bit_out_tdata[cur_sym_index*16+15 -:16];
            fifo_wr_en      <=   rx_bit_out_tvalid[cur_sym_index];
        end
    end
    
    fifo_generator_16_8192 fifo_generator_16_8192_i (
        .srst          (~rst_n),                   // input wire srst
        .clk           (clk),                     // input wire clk
        .din           (fifo_din),              // input wire [31 : 0] din
        .wr_en         (fifo_wr_en),            // input wire wr_en
        .rd_en         (fifo_rd_en),              // input wire rd_en
        .dout          (fifo_dout),                // output wire [31 : 0] dout
        .full          (fifo_full),                // output wire full
        .empty         (fifo_empty),              // output wire empty
        .wr_rst_busy   (),  // output wire wr_rst_busy
        .rd_rst_busy   ()  // output wire rd_rst_busy
    );

    assign      bit_out_tvalid  =   fifo_rd_en & (~fifo_empty);
    assign      bit_out_tdata   =   fifo_dout;
    
endmodule