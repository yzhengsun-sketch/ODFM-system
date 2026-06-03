`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/01/27 09:26:04
// Design Name: 
// Module Name: add_window
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
//  ADD THE WINDOW FOR the data
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module add_windowc#(
        parameter   OFDM_NUM_PER_FRAME      =   8'd10,   // length per symbol
        parameter   FFT_LENGTH              =   512,
        parameter   CP_LENGTH               =   64
    )
    (
    input                       clk,
    input                       rst_n,
    
    input          [31:0]      win_in_tdata , 
    input                      win_in_tvalid , 
    
    output     reg  [31:0]     win_out_tdata ,    //windowed data out
    output     reg              win_out_tvalid 
    );
    
    reg     [15:0]  tmp_dataI; 
    reg     [15:0]  tmp_dataQ; 
    
    reg     [15:0]  data_cnt;
    
    always @(posedge clk or negedge rst_n) begin   
        if (rst_n == 1'b0) begin
            tmp_dataI   <=  16'd0;
            tmp_dataQ   <=  16'd0;
            data_cnt    <=  16'b0;
        end
        else begin
            win_out_tvalid  <=  win_in_tvalid;
            
            if (win_in_tvalid) begin
                data_cnt  <=  (data_cnt == FFT_LENGTH + CP_LENGTH - 1 ) ? 16'b0 : (data_cnt + 1'b1) ;
            end
            else begin
                data_cnt    <=  16'b0;
            end
            
            if ((win_in_tvalid) && (data_cnt ==  CP_LENGTH )) begin  // store the first vaild data of each symbol
                tmp_dataI   <=  win_in_tdata[31:16];
                tmp_dataQ   <=  win_in_tdata[15:0];
            end
            else if (~win_in_tvalid) begin   //reset the data 
                tmp_dataI   <=  16'd0;
                tmp_dataQ   <=  16'd0;
            end
            
             if ((win_in_tvalid) && (data_cnt ==  0 )) begin
                win_out_tdata[31:16]    <=   ($signed(tmp_dataI) + $signed(win_in_tdata[31:16])) / 2;   
                win_out_tdata[15:0]     <=   ($signed(tmp_dataQ) + $signed(win_in_tdata[15:0]))  / 2;   
             end
             else begin
                win_out_tdata            <=  win_in_tdata;
             end
            
        end
    end
    
endmodule
