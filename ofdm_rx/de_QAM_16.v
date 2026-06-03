`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/01/04 11:54:25
// Design Name: 
// Module Name: de_QAM_16
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


module de_QAM_16#(
    parameter    LEN_PER_SYMBOL_16QAM    =   10'd120   //  length per symbol
)
(
    input                   clk,
    input                   rst_n,

    input                   iq_in_tvalid,
    input           [31:0]  iq_in_tdata,
    output  reg             iq_in_tready,
    input                   iq_in_tlast,
    
    output  reg    [15:0]   bit_out_tdata,
    output  reg             bit_out_tvalid,
    input   wire            bit_out_tready,
    output  reg             bit_out_tlast
    );
    
    parameter   FACTOR_POS  =   2000;
    parameter   FACTOR_NEG  =   -2000; 
    
    
    wire  signed  [15:0]  iq_in_tdata_re;
    wire  signed  [15:0]  iq_in_tdata_im;
    assign  iq_in_tdata_re =  iq_in_tdata[15:0];
    assign  iq_in_tdata_im =  iq_in_tdata[31:16];
    
    
    reg     iq_in_tvalid_d1;
    reg     [3:0]   tmp_data;
    always @(posedge clk or negedge rst_n) begin
        if (iq_in_tdata_re[15] == 0) begin
            tmp_data[3:2]   <= (iq_in_tdata_re > FACTOR_POS) ?  2'b10 : 2'b11;
        end
        else begin
            tmp_data[3:2]   <= (iq_in_tdata_re > FACTOR_NEG) ?  2'b01 : 2'b00;
        end
        
        if (iq_in_tdata_im[15] == 0) begin
            tmp_data[1:0]   <= (iq_in_tdata_im > FACTOR_POS) ?  2'b10 : 2'b11;
        end
        else begin
            tmp_data[1:0]   <= (iq_in_tdata_im > FACTOR_NEG) ?  2'b01 : 2'b00;
        end
    end 
  
    reg     [1:0]   data_cnt;   

    always @(posedge clk or negedge rst_n) begin
        if (rst_n == 1'b0) begin
            data_cnt        <=  2'd0;
        end
        else begin
            iq_in_tvalid_d1 <=  iq_in_tvalid;
            if (iq_in_tvalid_d1) begin
                bit_out_tdata[(data_cnt+1)*4-1 -: 4]   <=  tmp_data;
                data_cnt          <= data_cnt + 1'b1;
            end
            else begin
                data_cnt          <=  2'd0;
            end
        end
    end
    
    
    reg     iq_in_tlast_d1;
    always @(posedge clk) begin
        iq_in_tlast_d1      <=  iq_in_tlast;
        if (iq_in_tvalid_d1 && (data_cnt == 2'd3)) begin
            bit_out_tvalid  <=  1'b1;
        end
        else begin
            bit_out_tvalid  <=  1'b0;
        end
        
        bit_out_tlast   <= iq_in_tlast_d1;
    end
    
    
endmodule
