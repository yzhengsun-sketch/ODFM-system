`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/01/27 09:04:57
// Design Name: 
// Module Name: ofdm_rx
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


module ofdm_rx#(
    parameter   OFDM_NUM_PER_FRAME      =   8'd10,
    parameter   LEN_PER_SYMBOL_BPSK     =   10'd30,    // the first symbol LEN   subcarrier num = 480;
    parameter   LEN_PER_SYMBOL_16QAM    =   10'd120,   // the later symbol LEN
    parameter   FFT_LENGTH              =   512,
    parameter   CP_LENGTH               =   64
    )
    (
    input                   clk,
    input                   rst_n,
    
    input   [31:0]          rx_in_tdata,
    input                   rx_in_tvalid,
    
    output  [15:0]          bit_out_tdata,
    input                   bit_out_tvalid,
    output                  bit_out_tready, 
    output                  bit_out_tlast
    );
    
    wire     [32*OFDM_NUM_PER_FRAME-1:0]     rx_out_tdata ;
    wire     [OFDM_NUM_PER_FRAME-1:0]        rx_out_tvalid ;
    wire     [OFDM_NUM_PER_FRAME-1:0]        rx_out_tready ;
    wire     [OFDM_NUM_PER_FRAME-1:0]        rx_out_tlast ;
    rev_proc#(
        .OFDM_NUM_PER_FRAME (OFDM_NUM_PER_FRAME),
        .FFT_LENGTH         (FFT_LENGTH),
        .CP_LENGTH          (CP_LENGTH)
    ) 
    rev_proc_i(
     .clk                   (clk),
     .rst_n                 (rst_n),   
     .rx_in_tdata           (rx_in_tdata),
     .rx_in_tvalid          (rx_in_tvalid), 
     
     .rx_out_tdata          (rx_out_tdata), 
     .rx_out_tvalid         (rx_out_tvalid), 
     .rx_out_tready         (rx_out_tready),
     .rx_out_tlast          (rx_out_tlast) 
    );
    
    wire    [16*OFDM_NUM_PER_FRAME-1:0]     rx_bit_out_tdata;
    wire    [OFDM_NUM_PER_FRAME-1:0]        rx_bit_out_tvalid;
    wire    [OFDM_NUM_PER_FRAME-1:0]        rx_bit_out_tlast;    
    wire    [OFDM_NUM_PER_FRAME-1:0]        rx_bit_out_tready;
    
   genvar j    ;
    generate
        for(j=0; j<OFDM_NUM_PER_FRAME; j=j+1)                     
        //for(j=0; j<1; j=j+1)                     
        begin: data_demapping 
            demapping#(
                .OFDM_NUM_PER_FRAME     (OFDM_NUM_PER_FRAME),   // bit length per symbol
                .LEN_PER_SYMBOL_BPSK    (LEN_PER_SYMBOL_BPSK),
                .LEN_PER_SYMBOL_16QAM   (LEN_PER_SYMBOL_16QAM)
            )
            demapping_i(
                .clk                    (clk),
                .rst_n                  (rst_n),
                
                .rx_out_tdata           (rx_out_tdata[j*32+31 -:32]),
                .rx_out_tvalid          (rx_out_tvalid[j]),
                .rx_out_tready          (rx_out_tready[j]),
                .rx_out_tlast           (rx_out_tlast[j]),
                .cur_sym_index          (j),
                
                .rx_bit_out_tdata       (rx_bit_out_tdata[j*16+15 -:16]  ),
                .rx_bit_out_tvalid      (rx_bit_out_tvalid[j] ),
                .rx_bit_out_tready      (rx_bit_out_tready[j] ),
                .rx_bit_out_tlast       (rx_bit_out_tlast[j] )
            );
        end
    endgenerate 
    
    
    data_integ_rx#(
        .OFDM_NUM_PER_FRAME     (OFDM_NUM_PER_FRAME),   // bit length per symbol
        .LEN_PER_SYMBOL_BPSK    (LEN_PER_SYMBOL_BPSK),
        .LEN_PER_SYMBOL_16QAM   (LEN_PER_SYMBOL_16QAM),
        .FFT_LENGTH             (FFT_LENGTH),
        .CP_LENGTH              (CP_LENGTH)
    )
    data_integ_rx_i(
        .clk                    (clk),
        .rst_n                  (rst_n),
        
        .rx_bit_out_tdata       (rx_bit_out_tdata ),
        .rx_bit_out_tvalid      (rx_bit_out_tvalid ),
        .rx_bit_out_tready      (rx_bit_out_tready ),
        .rx_bit_out_tlast       (rx_bit_out_tlast ),
        
        .bit_out_tdata           (bit_out_tdata),
        .bit_out_tvalid          (bit_out_tvalid),
        .bit_out_tready          (bit_out_tready),
        .bit_out_tlast           (bit_out_tlast)
    );
       
    
endmodule
