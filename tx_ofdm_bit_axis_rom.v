`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Tsinghua University
// Engineer: Yucong Wang
// 
// Create Date: 2023/04/28 17:34:16
// Design Name: RFSoC HLS OFDM Baseband Project
// Module Name: tx_ofdm_bit_axis_rom
// Project Name: RFSoC HLS OFDM Baseband Project
// Target Devices: XCZU47DR-2FFVE1156I
// Tool Versions: Vivado 2021.2
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module tx_ofdm_bit_axis_rom
(
    input wire clk,
    input wire rst_n,
    
    input wire  [31:0] tx_interval,
    input wire  [31:0] tx_frame_length,
    
    output wire [15:0] bit_out_tdata,
    output wire        bit_out_tvalid,
    input  wire        bit_out_tready,
    output wire  [1:0] bit_out_tkeep,
    output wire  [1:0] bit_out_tstrb,
    output reg         bit_out_tlast
);

reg [31:0] cnt_tlast;
reg [31:0] cnt_point_transed;

wire [31:0] tx_frame_length_counted;
assign tx_frame_length_counted = tx_frame_length + frame_num;

// tdata和tlast提前准备好等待,一旦tready为1,tvalid也就为1,立刻写进去
assign bit_out_tvalid = (cnt_point_transed < tx_frame_length_counted) ? bit_out_tready : 1'b0;

assign bit_out_tkeep = 2'b11;
assign bit_out_tstrb = 2'b00;



reg     [15:0]  frame_num;

always @(posedge clk)
begin
    if (rst_n == 1'b0) begin
        cnt_point_transed <= 32'd0;
        frame_num         <= 16'd0;
    end
    else begin
        if (cnt_point_transed < tx_frame_length_counted) begin
            if (bit_out_tready == 1'b1) begin
                cnt_point_transed <= cnt_point_transed + 32'd1;
            end
        end
        else if (cnt_point_transed < tx_interval) begin
            cnt_point_transed <= cnt_point_transed + 32'd1;
        end
        else if (cnt_point_transed == tx_interval) begin
            cnt_point_transed <= 32'd0;
            frame_num         <= frame_num + 1'd1;
        end
    end
end

//data format:
//--data_length:16bit 
//--frame count: 16bit;
//--data 
assign bit_out_tdata = (cnt_point_transed <= 32'd1)? ((cnt_point_transed ==32'd0)? tx_frame_length_counted:frame_num) : cnt_point_transed[15:0];
//assign bit_out_tdata = (cnt_point_transed <= 32'd1)? ((cnt_point_transed ==32'd0)? tx_frame_length_counted:frame_num) : 16'd0;

always @(posedge clk)
begin
    if (rst_n == 1'b0) begin
        cnt_tlast <= 32'd0;
        bit_out_tlast <= 1'b0;
    end
    else begin
        if (cnt_point_transed < tx_frame_length_counted) begin
            if (bit_out_tready == 1'b1) begin
                if (cnt_tlast == (tx_frame_length_counted - 32'd2)) begin
                    cnt_tlast <= cnt_tlast + 32'd1;
                    bit_out_tlast <= 1'b1;
                end
                else if (cnt_tlast == (tx_frame_length_counted - 32'd1)) begin
                    cnt_tlast <= 32'd0;
                    bit_out_tlast <= 1'b0;
                end
                else begin
                    cnt_tlast <= cnt_tlast + 32'd1;
                    bit_out_tlast <= 1'b0;
                end
            end
        end
        else if (cnt_point_transed < tx_interval) begin
            cnt_tlast <= 32'd0;
            bit_out_tlast <= 1'b0;
        end
        else if (cnt_point_transed == tx_interval) begin
            cnt_tlast <= 32'd0;
            bit_out_tlast <= 1'b0;
        end
    end
end

endmodule
