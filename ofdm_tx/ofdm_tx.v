`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/01/08 10:31:56
// Design Name: 
// Module Name: OFDM_tx
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

module ofdm_tx#(
    parameter   OFDM_NUM_PER_FRAME      =   8'd10,
    parameter   LEN_PER_SYMBOL_BPSK     =   10'd30,    // the first symbol LEN   subcarrier num = 480;
    parameter   LEN_PER_SYMBOL_16QAM    =   10'd120,   // the later symbol LEN
    parameter   FFT_LENGTH              =   512,
    parameter   CP_LENGTH               =   64
    )
    (
    input                   clk,
    input                   rst_n,
    
    input   wire    [15:0]  bit_in_tdata,
    input   wire            bit_in_tvalid,
    output  wire            bit_in_tready, 
    input   wire            bit_in_tkeep,
    input   wire            bit_in_tstrb,
    input   wire            bit_in_tlast,
    
    input                   data_to_dac_pls,
    
    output  [31:0]          tx_out_tdata,
    output                  tx_out_tvalid
    );
    
    
    wire    [16*OFDM_NUM_PER_FRAME-1:0]     sym_out_tdata;
    wire    [OFDM_NUM_PER_FRAME-1:0]        sym_out_tvalid;
    wire    [OFDM_NUM_PER_FRAME-1:0]        sym_out_tready;
    wire    [OFDM_NUM_PER_FRAME-1:0]        sym_out_tlast;
    wire    [7:0]                           cur_sym_index;
    
    bit_to_symbol#(
        .OFDM_NUM_PER_FRAME     (OFDM_NUM_PER_FRAME),
        .LEN_PER_SYMBOL_BPSK    (LEN_PER_SYMBOL_BPSK),
        .LEN_PER_SYMBOL_16QAM   (LEN_PER_SYMBOL_16QAM)
     )
     bit_to_symbol_i(
        .clk                    (clk),
        .rst_n                  (rst_n),
        
        .bit_in_tdata           (bit_in_tdata),
        .bit_in_tvalid          (bit_in_tvalid),
        .bit_in_tready          (bit_in_tready),
        .bit_in_tlast           (bit_in_tlast),
        
        .sym_out_tdata           (sym_out_tdata),
        .sym_out_tvalid          (sym_out_tvalid),
        .sym_out_tready          (sym_out_tready),
        .sym_out_tlast           (sym_out_tlast),
        .cur_sym_index           (cur_sym_index)
    );
    
    wire    [32*OFDM_NUM_PER_FRAME-1:0]     mapping_out_tdata;
    wire    [16*OFDM_NUM_PER_FRAME-1:0]     mapping_out_index;
    wire    [OFDM_NUM_PER_FRAME-1:0]        mapping_out_tvalid;
    wire    [OFDM_NUM_PER_FRAME-1:0]        mapping_out_tready;
    wire    [OFDM_NUM_PER_FRAME-1:0]        mapping_out_tlast; 
    wire    [OFDM_NUM_PER_FRAME-1:0]        mapping_out_empty; 
     
    genvar j    ;
    generate
        for(j=0; j<OFDM_NUM_PER_FRAME; j=j+1)                     
        //for(j=0; j<3; j=j+1)                     
        begin: data_mapping
            mapping#(
                .OFDM_NUM_PER_FRAME     (OFDM_NUM_PER_FRAME),
                .LEN_PER_SYMBOL_BPSK    (LEN_PER_SYMBOL_BPSK),
                .LEN_PER_SYMBOL_16QAM   (LEN_PER_SYMBOL_16QAM),
                .FFT_LENGTH             (FFT_LENGTH),
                .CP_LENGTH              (CP_LENGTH)
             )
             mapping_i(
                .clk                    (clk),
                .rst_n                  (rst_n),
                
                .sym_out_tdata           (sym_out_tdata[j*16+15 -:16]),
                .sym_out_tvalid          (sym_out_tvalid[j]),
                .sym_out_tready          (sym_out_tready[j]),
                .sym_out_tlast           (sym_out_tlast[j]),
                .cur_sym_index           (j),
                
                .mapping_out_tdata          (mapping_out_tdata[j*32+31 -:32] ), 
                .mapping_out_tvalid         (mapping_out_tvalid[j] ), 
                .mapping_out_tready         (mapping_out_tready[j]),
                .mapping_out_tlast          (mapping_out_tlast[j]),
                .mapping_out_index          (mapping_out_index[j*16+15 -:16]),
                .mapping_out_empty          (mapping_out_empty[j])  
    );
        end
    endgenerate  
     
     
    wire                data_to_dac_pls;    // a pluse that triggers the data transmission to DAC.
    wire    [31:0]      frame_out_tdata;
    wire                frame_out_tvalid;
    wire                frame_out_tlast;
    data_schedule_tx#(
        .OFDM_NUM_PER_FRAME     (OFDM_NUM_PER_FRAME),
        .LEN_PER_SYMBOL_BPSK    (LEN_PER_SYMBOL_BPSK),
        .LEN_PER_SYMBOL_16QAM   (LEN_PER_SYMBOL_16QAM),
        .FFT_LENGTH             (FFT_LENGTH),
        .CP_LENGTH              (CP_LENGTH)
     )
    data_schedule_tx_i(
        .clk                        (clk),
        .rst_n                      (rst_n),
        
        .mapping_out_tdata             (mapping_out_tdata),
        .mapping_out_tvalid            (mapping_out_tvalid),
        .mapping_out_tready            (mapping_out_tready),
        .mapping_out_tlast             (mapping_out_tlast),
        .mapping_out_index             (mapping_out_index),
        
        .data_to_dac_pls                (data_to_dac_pls),
        
        .frame_out_tdata                (frame_out_tdata),
        .frame_out_tvalid               (frame_out_tvalid),
        .frame_out_tlast                (frame_out_tlast)                               
    );
    
    
    wire          [31:0]     win_out_tdata ;    //windowed data out
    wire                     win_out_tvalid;
    add_windowc#(
        .OFDM_NUM_PER_FRAME     (OFDM_NUM_PER_FRAME),
        .FFT_LENGTH             (FFT_LENGTH),
        .CP_LENGTH              (CP_LENGTH)
     )
    add_windowc_i(
        .clk                        (clk),
        .rst_n                      (rst_n),
        
        .win_in_tdata               (frame_out_tdata),
        .win_in_tvalid              (frame_out_tvalid),
        
        .win_out_tdata              (win_out_tdata),
        .win_out_tvalid             (win_out_tvalid)

    );
    
    assign  tx_out_tdata    =   win_out_tdata;
    assign  tx_out_tvalid   =   win_out_tvalid;
    
endmodule
