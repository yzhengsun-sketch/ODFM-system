`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/06/13 18:06:55
// Design Name: 
// Module Name: bpsk
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


module bpsk#(
    parameter    LEN_PER_SYMBOL_BPSK    =   10'd30   //  length per symbol
//    parameter    DAIA_WIDTH             =   16
)
(
    input                   clk,
    input                   rst_n,

    input                   bit_in_tvalid,
    input           [15:0]  bit_in_tdata,
    output  reg             bit_in_tready,
    input                   bit_in_tlast,
    
    output  wire   [31:0]   iq_out_tdata,
    output  reg             iq_out_tvalid,
    input   wire            iq_out_tready,
    output  reg    [1:0]    iq_out_tkeep,
    output  reg    [1:0]    iq_out_tstrb,
    output  reg             iq_out_tlast

    );
    parameter BIT_PER_SYMBOL_BPSK =  LEN_PER_SYMBOL_BPSK << 4;   //  bit length per symbol
    
    
    reg    [15:0]  wr_data_cnt;
    reg            read_end_flag;
    
    wire           fifo_wr_en;
    wire           fifo_rd_en;
    wire   [15:0]  fifo_dout;
    wire   [15:0]  fifo_din;
    wire           fifo_empty;
    wire           fifo_full;
    wire           fifo_almost_full;
    
    reg            pad_flag;
    reg    [15:0]  pad_data;
    
    reg            fifo_empty_1;
    always @(posedge clk) begin
        fifo_empty_1 <= fifo_empty;
        if (rst_n == 1'b0) begin
            bit_in_tready <= 1'b1;
        end
        else if (bit_in_tlast) begin
            bit_in_tready <= 1'b0;
        end
        else if (fifo_empty & (~fifo_empty_1)) begin
            bit_in_tready <= 1'b1;
        end
     end
        
    
    always @(posedge clk) begin
        if (rst_n == 1'b0) begin
            wr_data_cnt         <=      16'd0;
            pad_flag            <=      1'b0;
            pad_data            <=      16'hffff;
        end
        else if (bit_in_tvalid) begin
            wr_data_cnt       <=      wr_data_cnt + 1'b1;
            
            if (bit_in_tlast) begin
                pad_data    <= 16'd0;
                if (wr_data_cnt < LEN_PER_SYMBOL_BPSK - 1)    pad_flag    <= 1'b1;
            end
        end
        else if ((wr_data_cnt <= LEN_PER_SYMBOL_BPSK - 1) && (wr_data_cnt > 0)) begin
            wr_data_cnt       <=  wr_data_cnt + 1'b1;
            pad_data          <=  16'h0000;
            pad_flag          <=  (wr_data_cnt == LEN_PER_SYMBOL_BPSK - 1)? 1'b0:1'b1;
        end
        else begin
            wr_data_cnt       <=      16'd0;
            pad_flag          <=      1'b0;
            pad_data          <=      16'hffff;
        end
    end   
    assign  fifo_din    = bit_in_tdata & pad_data;
    assign  fifo_wr_en  = bit_in_tvalid | pad_flag;
    
    
    
    
    reg                     tmp_data;
    reg             [9:0]   data_cnt;
    reg   signed    [15:0]  re_tmp;
    reg   signed    [15:0]  im_tmp;
    reg             [3:0]   data_index;
    reg                     iq_out_tvalid_tmp;
    
    assign  fifo_rd_en  = iq_out_tready && (~fifo_empty)&& (data_index == 4'b1111) && (data_cnt <= BIT_PER_SYMBOL_BPSK - 1);
    
    always @(posedge clk) begin
        if (rst_n == 1'b0) begin
            data_cnt        <=  10'd0;
        end
        else if (~fifo_empty & iq_out_tready) begin
            tmp_data        <= fifo_dout[data_index];
            data_cnt        <= data_cnt + 1'b1;   
            data_index      <= data_index + 1'b1;
            iq_out_tvalid_tmp   <= 1'b1; 
        end
        else begin 
            data_cnt        <= 10'd0;
            data_index      <= 4'd0;
            iq_out_tvalid_tmp   <= 1'b0; 
        end
        
        iq_out_tvalid   <= iq_out_tvalid_tmp;
        iq_out_tlast    <= (data_cnt == BIT_PER_SYMBOL_BPSK)? 1'b1 : 1'b0;
        
        case(tmp_data)
            1'b0: begin 
                //re_tmp <= 16'b0000100000000000;  // 这应该是实际值，但是在后面做IFFT的时候发现会出错，不知道是否是因为数据截断的原因，所以适当将IFFT的输入幅度值降低了，从1→0.128；缩小了8倍
                re_tmp <= 16'b0000000100000000;
                im_tmp <= 16'b0000000000000000;
            end
            1'b1: begin 
                //re_tmp <= 16'b1111100000000000;
                re_tmp <= 16'b1111111100000000;
                im_tmp <= 16'b0000000000000000;
            end
        endcase
    end
    
    //assign  re_tmp = (tmp_data == 1'b1) ? 16'b0100000000000000 : 16'b1100000000000000;
    //assign  im_tmp = 16'b0000000000000000;
    
    assign  iq_out_tdata [31:16] = im_tmp;
    assign  iq_out_tdata [15:0]  = re_tmp;

        
    fifo_generator_16_32 fifo_generator_16_32_i (
     .srst          (~rst_n),                   // input wire srst
     .clk           (clk),                     // input wire clk
     .din           (fifo_din),            // input wire [15 : 0] din
     .wr_en         (fifo_wr_en),           // input wire wr_en
     .rd_en         (fifo_rd_en),              // input wire rd_en
     .dout          (fifo_dout),                // output wire [15 : 0] dout
     .full          (fifo_full),                // output wire full
     .empty         (fifo_empty),              // output wire empty
     .wr_rst_busy   (),  // output wire wr_rst_busy
     .rd_rst_busy   ()  // output wire rd_rst_busy
);
    
endmodule
