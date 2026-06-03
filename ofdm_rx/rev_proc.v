`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/01/06 11:00:30
// Design Name: 
// Module Name: rev_proc
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// split the whole frame to parallel symbols
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`include "header.vh"

module rev_proc#(
        parameter   OFDM_NUM_PER_FRAME      =   8'd10,   // length per symbol
        parameter   FFT_LENGTH              =   512,
        parameter   CP_LENGTH               =   64
    )
    (
         input                                      clk    ,
         input                                      rst_n        ,   
         input      [31:0]                          rx_in_tdata     ,
         input                                      rx_in_tvalid , 
         
         output reg     [32*OFDM_NUM_PER_FRAME-1:0]     rx_out_tdata  , 
         output reg     [OFDM_NUM_PER_FRAME-1:0]        rx_out_tvalid , 
         input          [OFDM_NUM_PER_FRAME-1:0]        rx_out_tready ,
         output reg     [OFDM_NUM_PER_FRAME-1:0]        rx_out_tlast  
    );


    reg     [7:0]    cur_sym_index;
    reg     [9:0]    data_cnt;
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            data_cnt        <=  10'd0;
            cur_sym_index   <=  8'd0;
        end
        else begin
           if ( rx_in_tvalid ) begin
                data_cnt  <=  (data_cnt == FFT_LENGTH + CP_LENGTH - 1 ) ? 16'b0 : (data_cnt + 1'b1) ;
           end
           
           if ((rx_in_tvalid) && (data_cnt == FFT_LENGTH + CP_LENGTH - 1 )) begin  // move to next symbol
                cur_sym_index   <=  cur_sym_index + 1'b1;
           end
           else if (~rx_in_tvalid) begin   //reset the symbol number 
                cur_sym_index   <=  8'd0;
           end 
           
           if (rx_in_tvalid) begin   
                if (cur_sym_index == 0)  begin   // if the first symbol 
                    rx_out_tvalid   <=  1; 
                end
                else if (data_cnt == 0) begin
                    rx_out_tvalid   <=  rx_out_tvalid << 1;  //move to next symbol
                end
           end
           else begin
                rx_out_tvalid   <=  0; 
           end
           
           rx_out_tdata[cur_sym_index*32+31 -:32]   <=      rx_in_tdata;
           
           if (data_cnt == FFT_LENGTH + CP_LENGTH - 1 ) begin
                rx_out_tlast[cur_sym_index]     <=  1'b1;
           end
           else begin
                rx_out_tlast                    <=  0;
           end
           
        end
    end   
      
        
endmodule
