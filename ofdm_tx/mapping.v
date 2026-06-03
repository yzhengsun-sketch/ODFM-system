`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/06/13 07:19:47
// Design Name: 
// Module Name: QAM_16
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

module mapping#(
    parameter   OFDM_NUM_PER_FRAME      =   8'd10,
    parameter   LEN_PER_SYMBOL_BPSK     =   10'd30,    // the first symbol LEN   subcarrier num = 480;
    parameter   LEN_PER_SYMBOL_16QAM    =   10'd120,   // the later symbol LEN
    parameter   FFT_LENGTH              =   512,
    parameter   CP_LENGTH               =   64
    )
    (
    input                       clk,
    input                       rst_n,
    
    input   wire    [15:0]      sym_out_tdata,
    input   wire                sym_out_tvalid,
    output  wire                sym_out_tready,
    input   wire                sym_out_tlast,
    input   wire    [7:0]       cur_sym_index,
    
    output          [31:0]      mapping_out_tdata , 
    output                      mapping_out_tvalid , 
    input                       mapping_out_tready ,
    output  reg                 mapping_out_tlast  ,
    output  reg     [15:0]      mapping_out_index,
    output                      mapping_out_empty  
    
    );
    
    
    mod#(
        .LEN_PER_SYMBOL_BPSK    (LEN_PER_SYMBOL_BPSK),
        .LEN_PER_SYMBOL_16QAM   (LEN_PER_SYMBOL_16QAM)
    )
    mod_i(
        .clk             (clk),
        .rst_n           (rst_n),
        .sym_out_tdata           (sym_out_tdata),
        .sym_out_tvalid          (sym_out_tvalid),
        .sym_out_tready          (sym_out_tready),
        .sym_out_tlast           (sym_out_tlast),
        .cur_sym_index           (cur_sym_index),

       .iqc_in_tdata     (iqc_in_tdata),
       .iqc_in_tvalid    (iqc_in_tvalid),
       .iqc_in_tready    (iqc_in_tready),
       .iqc_in_tlast     (iqc_in_tlast)
    );
    
 
    wire    [31:0]  iqc_in_tdata;
    wire            iqc_in_tvalid;
    wire            iqc_in_tready;
    wire            iqc_in_tlast;
   // insert the pilots, including the zero pilots and subcarrier pilots
    wire    [31:0]  iqc_out_tdata;
    wire            iqc_out_tvalid;
    wire            iqc_out_tready;
    wire            iqc_out_tlast;
    pilot_insert pilot_insert_i(
       .clk             (clk),
       .rst_n           (rst_n),
       .iq_in_tdata     (iqc_in_tdata),
       .iq_in_tvalid    (iqc_in_tvalid),
       .iq_in_tready    (iqc_in_tready),
       .iq_in_tkeep     (),
       .iq_in_tstrb     (),
       .iq_in_tlast     (iqc_in_tlast),
    
	   .iqc_out_tdata   (iqc_out_tdata), //complete iq data
       .iqc_out_tvalid  (iqc_out_tvalid),
       .iqc_out_tready  (iqc_out_tready),
       .iqc_out_tkeep   (),
       .iqc_out_tstrb   (),
       .iqc_out_tlast   (iqc_out_tlast)
    );
    
    
    wire     [31:0]  ifft_dout     ;
    wire             ifft_dout_vld ;
    reg              ifft_dout_rdy ;
    wire             ifft_dout_last  ;
    reg      [15:0]  ifft_dout_index;
    
    ifft#(
        .OFDM_NUM_PER_FRAME (OFDM_NUM_PER_FRAME),
        .FFT_LENGTH         (FFT_LENGTH),
        .CP_LENGTH          (CP_LENGTH)
    ) 
    ifft_i(
     .clk               (clk),
     .rst_n             (rst_n),   
     .ifft_din          (iqc_out_tdata),
     .ifft_din_vld      (iqc_out_tvalid), 
     .ifft_din_rdy      (iqc_out_tready),
     .ifft_din_last     (iqc_out_tlast),
     
     .ifft_dout         (ifft_dout), 
     .ifft_dout_vld     (ifft_dout_vld), 
     .ifft_dout_rdy     (ifft_dout_rdy),
     .ifft_dout_last    (ifft_dout_last),
     .ifft_dout_index   ( )  
    );
    
    
    
    // store the ifft data in the FIFO
    // waiting the data schedule module for reading the data
 
    wire    [31:0]       fifo_din;
    wire                 fifo_wr_en;
    wire                 fifo_rd_en;
    wire   [31:0]       fifo_dout;
    wire                fifo_empty;
    wire                fifo_full;
    
    //assign  ifft_dout_rdy = ~fifo_empty;
    wire    [9:0]   rd_cnt; 
    always@(posedge clk or negedge rst_n) begin
        if (rst_n == 1'b0) begin
            
        end
        else begin
            if (fifo_empty)             ifft_dout_rdy   <=  1'b1;    // ask for data to store in the FIFO when the FIFO is empty
            else if (ifft_dout_last)    ifft_dout_rdy   <=  1'b0;    // stop asking for data when have stored a completed symbol
        end
    end
    
    assign      fifo_wr_en  =   ifft_dout_vld;
    assign      fifo_din    =   ifft_dout;
    
    fifo_generator_32_1024 fifo_generator_32_1024_i (
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
    
    assign      fifo_rd_en          =   mapping_out_tready  & (~fifo_empty);
    assign      mapping_out_tdata   =   fifo_dout;
    assign      mapping_out_tvalid  =   fifo_rd_en ;
    assign      mapping_out_empty   =   fifo_empty;
    
    // reproduce ifft_dout_index and mapping_out_tlast
    always@(posedge clk or negedge rst_n) begin
        mapping_out_index   <=  (fifo_rd_en)? (mapping_out_index + 1'b1) : 16'd0;
        mapping_out_tlast   <=  (mapping_out_index == (FFT_LENGTH+CP_LENGTH-2))? 1'b1:1'b0;
    end
    
   // assign      mapping_out_index   =  (fifo_rd_en)? (mapping_out_index + 1'b1) : 16'd0;
   // assign      mapping_out_tlast   =  (mapping_out_index == (FFT_LENGTH+CP_LENGTH-1))? 1'b1:1'b0;
    
  //  input                       mapping_out_tready ,
  //  output                      mapping_out_tlast  ,
   // output          [15:0]      mapping_out_index  
    
    
endmodule
