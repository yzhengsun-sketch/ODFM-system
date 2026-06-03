`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/07/07 16:04:43
// Design Name: 
// Module Name: ifft
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

`include "header.vh"

module fft(
 input              clk    ,
 input              rst_n        ,   
 input      [31:0]  fft_din     ,
 input              fft_din_vld , 
 output             fft_din_rdy ,
 input              fft_din_last   ,
 
 output     [31:0]  fft_dout     , 
 output             fft_dout_vld , 
 input              fft_dout_rdy ,
 output             fft_dout_last  ,
 output     [15:0]  fft_dout_Index  
);


wire signed [31 : 0]    fft_s_axis_data_tdata     ;
wire                    fft_s_axis_data_tvalid     ;
wire                    fft_s_axis_data_tready     ;
wire                    fft_s_axis_data_tlast     ;


reg      [9:0] rm_cp_cnt;
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        rm_cp_cnt   <= 10'd0;
    end
    else begin
        rm_cp_cnt <= (fft_din_vld == 1)? rm_cp_cnt + 1'b1:10'd0;
    end  
end
assign      fft_din_rdy = fft_s_axis_data_tready;

assign      fft_s_axis_data_tvalid = fft_din_vld && (rm_cp_cnt >= 64);
assign      fft_s_axis_data_tdata  = fft_din;
assign      fft_s_axis_data_tlast  = fft_din_last;




wire            fft_m_axis_data_tvalid;
wire  signed   [31:0]  fft_m_axis_data_tdata;
wire            fft_m_axis_data_tlast;
wire    [15:0]  fft_m_axis_data_tuser;
wire            fft_m_axis_data_tready;


wire    [31:0]  fft_s_axis_config_tdata;
wire            fft_s_axis_config_tvalid;
wire            fft_s_axis_config_tready;

//bit(26:17) SCALE_SCH
//bit [16]  FWD_INV_0    IFFT:0  FFT:1
//bit (8:0) CP_LEN 
//assign fft_s_axis_config_tdata  = 24'd0000_0001_0000_0000_0000_0000;
assign fft_s_axis_config_tdata  = 24'd0000_0000_0000_0000_0000_0000;
assign fft_s_axis_config_tvalid = 1'b1;
xfft_0 u_fft (
  .aclk(clk),                                                // input wire aclk
  .aresetn(rst_n),                                          // input wire aresetn
  .s_axis_config_tdata(fft_s_axis_config_tdata),                             // input wire [23 : 0] s_axis_config_tdata
  .s_axis_config_tvalid(fft_s_axis_config_tvalid),                // input wire s_axis_config_tvalid
  .s_axis_config_tready(fft_s_axis_config_tready),                // output wire s_axis_config_tready
  
  .s_axis_data_tdata(fft_s_axis_data_tdata),                      // input wire [31 : 0] s_axis_data_tdata
  //.s_axis_data_tdata({16'd0,fft_s_axis_data_tdata[15:0]}),                      // input wire [31 : 0] s_axis_data_tdata
  .s_axis_data_tvalid(fft_s_axis_data_tvalid),                    // input wire s_axis_data_tvalid
  .s_axis_data_tready(fft_s_axis_data_tready),                    // output wire s_axis_data_tready
  .s_axis_data_tlast(fft_s_axis_data_tlast),                      // input wire s_axis_data_tlast
  
  .m_axis_data_tdata(fft_m_axis_data_tdata),                      // output wire [31 : 0] m_axis_data_tdata
  .m_axis_data_tuser(fft_m_axis_data_tuser),                      // output wire [15 : 0] m_axis_data_tuser
  .m_axis_data_tvalid(fft_m_axis_data_tvalid),                    // output wire m_axis_data_tvalid
  .m_axis_data_tready(fft_m_axis_data_tready),                    // input wire m_axis_data_tready
  .m_axis_data_tlast(fft_m_axis_data_tlast),                      // output wire m_axis_data_tlast
  
  .m_axis_status_tdata(),                                     // output wire [7 : 0] m_axis_status_tdata
  .m_axis_status_tvalid(),                                    // output wire m_axis_status_tvalid
  .m_axis_status_tready(1'b1),                                // input wire m_axis_status_tready
  
  .event_frame_started(),                  // output wire event_frame_started
  .event_tlast_unexpected(),            // output wire event_tlast_unexpected
  .event_tlast_missing(),                  // output wire event_tlast_missing
  .event_status_channel_halt(),      // output wire event_status_channel_halt
  .event_data_in_channel_halt(),    // output wire event_data_in_channel_halt
  .event_data_out_channel_halt()  // output wire event_data_out_channel_halt
);

wire  signed [15:0] fft_out_real;
wire  signed [15:0] fft_out_imag;

assign  fft_out_imag = (fft_m_axis_data_tvalid== 1)? fft_m_axis_data_tdata[31:16] : 16'd0;
assign  fft_out_real = (fft_m_axis_data_tvalid== 1)? fft_m_axis_data_tdata[15:0]  : 16'd0;


assign  fft_dout                = fft_m_axis_data_tdata;
assign  fft_dout_Index          = fft_m_axis_data_tuser  ;
assign  fft_dout_vld            = fft_m_axis_data_tvalid ;
assign  fft_m_axis_data_tready  = fft_dout_rdy;
assign  fft_dout_last           = fft_m_axis_data_tlast  ;

endmodule
