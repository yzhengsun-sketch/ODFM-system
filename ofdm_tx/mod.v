`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/01/26 17:22:51
// Design Name: 
// Module Name: mod
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// modulation:
// the first symbol: bpsk
// the later symbol: QAM  

// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "header.vh"

module mod#(
    parameter   LEN_PER_SYMBOL_BPSK     =   10'd30,    // the first symbol LEN   subcarrier num = 480;
    parameter   LEN_PER_SYMBOL_16QAM    =   10'd120   // the later symbol constraint_mode
    )
    (
    input              clk    ,
    input              rst_n        ,   
    input   wire    [15:0]      sym_out_tdata,
    input   wire                sym_out_tvalid,
    output  wire                sym_out_tready,
    input   wire                sym_out_tlast,
    input   wire    [7:0]       cur_sym_index,

    output   [31:0]      iqc_in_tdata,
    output               iqc_in_tvalid,
    input          	     iqc_in_tready,
    output               iqc_in_tlast
    );
    
       
 //   parameter       BPSK_SYMBOL     =   1'b0;
 //   parameter       QAM_SYMBOL      =   1'b1;
    
    
    
    
    // the first symbol is BPSK, the later symbol is 16QAM
    wire         cur_sym_type;
    assign       cur_sym_type = (cur_sym_index == 8'd0)? (`BPSK_SYMBOL): (`QAM_SYMBOL);  

    
    
    wire   [15:0]       bpsk_in_tdata;
    wire                bpsk_in_tvaild;
    wire                bpsk_in_tready;
    wire                bpsk_in_tlast;
    
    wire    [31:0]      bpsk_out_tdata;
    wire                bpsk_out_tvalid;
    wire                bpsk_out_tready;
    wire                bpsk_out_tlast;
  
    
    assign  bpsk_in_tvaild      =    (cur_sym_type == `BPSK_SYMBOL)? sym_out_tvalid : 1'd0;
    assign  bpsk_in_tdata       =    (cur_sym_type == `BPSK_SYMBOL)? sym_out_tdata : 16'd0;
    assign  bpsk_in_tlast       =    (cur_sym_type == `BPSK_SYMBOL)? sym_out_tlast : 1'd0;
    
    

    bpsk#(
        .LEN_PER_SYMBOL_BPSK(LEN_PER_SYMBOL_BPSK)   // bit length per symbol
    )
    bpsk_i(
        .clk                (clk),
        .rst_n              (rst_n),
    
        .bit_in_tvalid      (bpsk_in_tvaild),
        .bit_in_tdata       (bpsk_in_tdata),
        .bit_in_tready      (bpsk_in_tready),
        .bit_in_tlast       (bpsk_in_tlast),
        
        .iq_out_tdata       (bpsk_out_tdata),
        .iq_out_tvalid      (bpsk_out_tvalid),
        .iq_out_tready      (bpsk_out_tready),
        .iq_out_tkeep       (),
        .iq_out_tstrb       (),
        .iq_out_tlast       (bpsk_out_tlast)
        );
   
        
    wire    [15:0]      qam16_in_tdata;
    wire                qam16_in_tvaild;
    wire                qam16_in_tready;
    wire                qam16_in_tlast;
    
    wire    [31:0]      qam16_out_tdata;
    wire                qam16_out_tvalid;
    wire                qam16_out_tready;
    wire                qam16_out_tlast;
    
    assign  qam16_in_tvaild      =    (cur_sym_type == `QAM_SYMBOL)? sym_out_tvalid : 1'd0;
    assign  qam16_in_tdata       =    (cur_sym_type == `QAM_SYMBOL)? sym_out_tdata : 16'd0;
    assign  qam16_in_tlast       =    (cur_sym_type == `QAM_SYMBOL)? sym_out_tlast : 1'd0;
    
    QAM_16#(
        .LEN_PER_SYMBOL_16QAM(LEN_PER_SYMBOL_16QAM)   // bit length per symbol
    )
    QAM_16_i(
        .clk                (clk),
        .rst_n              (rst_n),
        
        .bit_in_tvalid      (qam16_in_tvaild),
        .bit_in_tdata       (qam16_in_tdata),
        .bit_in_tready      (qam16_in_tready),
        .bit_in_tlast       (qam16_in_tlast),
        
        .iq_out_tdata       (qam16_out_tdata),
        .iq_out_tvalid      (qam16_out_tvalid),
        .iq_out_tready      (qam16_out_tready),
        .iq_out_tlast       (qam16_out_tlast)
        //        .iq_out_tkeep       (),
        //        .iq_out_tstrb       (),
    );
   
   assign   sym_out_tready       =    (cur_sym_type == `BPSK_SYMBOL)? bpsk_in_tready : qam16_in_tready;
   
  // assign   bpsk_out_tready      =    (cur_sym_index == 8'd0)? iqc_in_tready : 1'b0;  
  // assign   qam16_out_tready     =    (cur_sym_index != 8'd0)? iqc_in_tready : 1'b0;  
   assign   bpsk_out_tready      =    iqc_in_tready;
   assign   qam16_out_tready     =    iqc_in_tready;  
   
    wire    [31:0]  iqc_in_tdata;
    wire            iqc_in_tvalid;
    wire            iqc_in_tready;
    wire            iqc_in_tlast;
    
    assign      iqc_in_tvalid       =   (cur_sym_type == `BPSK_SYMBOL) ? bpsk_out_tvalid : qam16_out_tvalid;
    assign      iqc_in_tdata        =   (cur_sym_type == `BPSK_SYMBOL) ? bpsk_out_tdata : qam16_out_tdata;       
    assign      iqc_in_tlast        =   (cur_sym_type == `BPSK_SYMBOL) ? bpsk_out_tlast : qam16_out_tlast; 
    
endmodule
