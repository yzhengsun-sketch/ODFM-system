`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/01/04 11:54:04
// Design Name: 
// Module Name: de_bpsk
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


module de_bpsk#(
    parameter    LEN_PER_SYMBOL_BPSK    =   10'd30   //  length per symbol
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
    
    wire  signed  [15:0]  iq_in_tdata_re;
    assign  iq_in_tdata_re =  iq_in_tdata[15:0];
    
    wire    bit_stream_tdata;
    assign  bit_stream_tdata  =   (iq_in_tdata_re > 0) ? 1'b0 : 1'b1;
    
    reg     [3:0]   data_cnt;
    
    always @(posedge clk or negedge rst_n) begin
        if (rst_n == 1'b0) begin
            data_cnt        <=  4'd0;
        end
        else begin
             if (iq_in_tvalid)  begin
                bit_out_tdata[data_cnt] <= bit_stream_tdata;
                data_cnt        <= data_cnt + 1'b1;
             end
             else begin
                data_cnt        <=  4'd0;
             end
        end
    end
    
    reg     iq_in_tvalid_d1;
    always @(posedge clk) begin
        iq_in_tvalid_d1 <= iq_in_tvalid;
        if (iq_in_tvalid_d1 && (data_cnt == 4'd15)) begin
            bit_out_tvalid  <=  1'b1;
        end
        else begin
            bit_out_tvalid  <=  1'b0;
        end
        
        bit_out_tlast   <= iq_in_tlast;
    end
    
endmodule
