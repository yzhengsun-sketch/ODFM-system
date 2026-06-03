`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/12/31 09:23:53
// Design Name: 
// Module Name: demapping
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

module demapping#(
    parameter   OFDM_NUM_PER_FRAME      =   8'd10,   // length per symbol
    parameter   LEN_PER_SYMBOL_BPSK     =   10'd30,
    parameter   LEN_PER_SYMBOL_16QAM    =   10'd120
    )
    (
    input                   clk,
    input                   rst_n,
    
    input   wire    [31:0]  rx_out_tdata,
    input   wire            rx_out_tvalid,
    output  wire            rx_out_tready, 
    input   wire            rx_out_tlast,
    input   wire    [7:0]   cur_sym_index,
    
    output  wire   [15:0]   rx_bit_out_tdata,
    output  wire            rx_bit_out_tvalid,
    input   wire            rx_bit_out_tready,
    output  wire            rx_bit_out_tlast
    );
    
   
    wire     [31:0]  fft_din     ;
    wire             fft_din_vld ;
    wire             fft_din_rdy ;
    wire             fft_din_last  ;
    
    wire     [31:0]  fft_dout     ;
    wire             fft_dout_vld ;
    wire             fft_dout_rdy ;
    wire             fft_dout_last  ;
    wire     [15:0]  fft_dout_Index;
    
    assign      fft_din         =   rx_out_tdata;
    assign      fft_din_vld     =   rx_out_tvalid;
    assign      rx_out_tready   =   fft_din_rdy;
    assign      fft_din_last    =   rx_out_tlast;
    
    assign      fft_dout_rdy = 1'b1;
    fft fft_i(
     .clk               (clk),
     .rst_n             (rst_n),   
     
     .fft_din          (fft_din),
     .fft_din_vld      (fft_din_vld), 
     .fft_din_rdy      (fft_din_rdy),
     .fft_din_last     (fft_din_last),
     
     .fft_dout         (fft_dout), 
     .fft_dout_vld     (fft_dout_vld), 
     .fft_dout_rdy     (fft_dout_rdy),
     .fft_dout_last    (fft_dout_last),
     .fft_dout_Index   (fft_dout_Index)  
    );
    
    
    wire    [31:0]  rx_iqc_in_tdata;
    wire            rx_iqc_in_tvalid;
    wire            rx_iqc_in_tready;
    wire            rx_iqc_in_tlast;

    assign  rx_iqc_in_tdata    =   fft_dout;
    assign  rx_iqc_in_tvalid   =   fft_dout_vld;
    assign  rx_iqc_in_tlast    =   fft_dout_last;
    
    
    wire    [31:0]  rx_iq_out_tdata;
    wire            rx_iq_out_tvalid;
    wire            rx_iq_out_tlast;    
    wire            rx_iq_out_tready;
    //assign  rx_iq_out_tready =  1'b1;    

    pilot_remove pilot_remove_i(
       .clk                 (clk),
       .rst_n               (rst_n),
       .rx_iqc_in_tdata     (rx_iqc_in_tdata),
       .rx_iqc_in_tvalid    (rx_iqc_in_tvalid),
       .rx_iqc_in_tready    (rx_iqc_in_tready),
       .rx_iqc_in_tkeep     (),
       .rx_iqc_in_tstrb     (),
       .rx_iqc_in_tlast     (rx_iqc_in_tlast),
    
	   .rx_iq_out_tdata    (rx_iq_out_tdata ),  
       .rx_iq_out_tvalid   (rx_iq_out_tvalid ),
       .rx_iq_out_tready   (rx_iq_out_tready),
       .rx_iq_out_tkeep    (),
       .rx_iq_out_tstrb    (),
       .rx_iq_out_tlast    (rx_iq_out_tlast )
    );
    
    assign  rx_iq_in_tdata =    rx_iq_out_tdata;
    assign  rx_iq_in_tvalid =   rx_iq_out_tvalid;
    assign  rx_iq_in_tlast  =   rx_iq_out_tlast;
    assign  rx_iq_out_tready =  rx_iq_in_tready;
    
    
    wire    [31:0]  rx_iq_in_tdata;
    wire            rx_iq_in_tvalid;
    wire            rx_iq_in_tlast;    
    wire            rx_iq_in_tready;
   
    
    demod#(
        .OFDM_NUM_PER_FRAME     (OFDM_NUM_PER_FRAME),   // bit length per symbol
        .LEN_PER_SYMBOL_BPSK    (LEN_PER_SYMBOL_BPSK),
        .LEN_PER_SYMBOL_16QAM   (LEN_PER_SYMBOL_16QAM)
    )
    demod_i(
        .clk                    (clk),
        .rst_n                  (rst_n),
        
        .rx_iq_in_tdata           (rx_iq_in_tdata),
        .rx_iq_in_tvalid          (rx_iq_in_tvalid),
        .rx_iq_in_tready          (rx_iq_in_tready),
        .rx_iq_in_tlast           (rx_iq_in_tlast),
        .cur_sym_index            (cur_sym_index),
        
        .rx_bit_out_tdata           (rx_bit_out_tdata),
        .rx_bit_out_tvalid          (rx_bit_out_tvalid),
        .rx_bit_out_tready          (rx_bit_out_tready),
        .rx_bit_out_tlast           (rx_bit_out_tlast)
    );
    
    /*
    reg     [7:0]   cur_sym_index;
    always @(posedge clk or negedge rst_n) begin
        if (rst_n == 1'b0) begin
            cur_sym_index   <=  8'd0;           //waiting for the first symbol
        end
        else begin
            if (bpsk_bit_out_tlast | qam16_bit_out_tlast)
                cur_sym_index   <=  (cur_sym_index == OFDM_NUM_PER_FRAME - 1)? 8'd0 : (cur_sym_index + 8'd1);
        end
    end
    
    
    wire    bpsk_iq_in_tvalid;
    wire    bpsk_iq_in_tvalid;
    
    wire    bpsk_iq_in_tlast;
    wire    qam16_iq_in_tlast;
    
    assign bpsk_iq_in_tvalid    = (cur_sym_index == 8'd0) & rx_iq_in_tvalid;
    assign qam16_iq_in_tvalid   = (cur_sym_index != 8'd0) & rx_iq_in_tvalid;
    
    assign bpsk_iq_in_tlast    = (cur_sym_index == 8'd0) & rx_iq_in_tlast;
    assign qam16_iq_in_tlast   = (cur_sym_index != 8'd0) & rx_iq_in_tlast;
    
    
    wire   [15:0]   bpsk_bit_out_tdata;
    wire            bpsk_bit_out_tvalid;
    wire            bpsk_bit_out_tready;
    wire            bpsk_bit_out_tlast;
    
    de_bpsk#(
        .LEN_PER_SYMBOL_BPSK(LEN_PER_SYMBOL_BPSK)   //  length per symbol
    )
    de_bpsk_i(
        .clk            (clk)                   ,
        .rst_n          (rst_n)                 , 
    
        .iq_in_tvalid   (bpsk_iq_in_tvalid)     ,
        .iq_in_tdata    (rx_iq_in_tdata)   ,
        .iq_in_tready   ()                      ,
        .iq_in_tlast    (bpsk_iq_in_tlast)        ,
        
        .bit_out_tdata  (bpsk_bit_out_tdata)    ,
        .bit_out_tvalid (bpsk_bit_out_tvalid)    ,
        .bit_out_tready (bpsk_bit_out_tready)   ,
        .bit_out_tlast  (bpsk_bit_out_tlast)
    );
    
    
    wire   [15:0]   qam16_bit_out_tdata;
    wire            qam16_bit_out_tvalid;
    wire            qam16_bit_out_tready;
    wire            qam16_bit_out_tlast;
    
    de_QAM_16#(
        .LEN_PER_SYMBOL_BPSK(LEN_PER_SYMBOL_BPSK)   //  length per symbol
    )
    de_QAM_16_i(
        .clk            (clk)                   ,
        .rst_n          (rst_n)                 , 
    
        .iq_in_tvalid   (qam16_iq_in_tvalid)     ,
        .iq_in_tdata    (rx_iq_in_tdata)   ,
        .iq_in_tready   ()       ,
        .iq_in_tlast    (qam16_iq_in_tlast)        ,
        
        .bit_out_tdata  (qam16_bit_out_tdata)    ,
        .bit_out_tvalid (qam16_bit_out_tvalid)    ,
        .bit_out_tready (qam16_bit_out_tready)   ,
        .bit_out_tlast  (qam16_bit_out_tlast)
    );
    
    // write the data from the bpsk and qam16 demodulation module into the FIFO;
    wire    [15:0]  fifo_din;
    wire            fifo_wr_en;
    reg             fifo_rd_en;
    wire    [15:0]  fifo_dout;    
    wire            fifo_full;
    wire            fifo_empty;     
    
    assign fifo_wr_en   = (cur_sym_index == 8'd0) ?  bpsk_bit_out_tvalid : qam16_bit_out_tvalid;
    assign fifo_din     = (cur_sym_index == 8'd0) ?  bpsk_bit_out_tdata  : qam16_bit_out_tdata ;
    
    always @(posedge clk or negedge rst_n) begin
        if (rst_n == 1'b0) begin
            fifo_rd_en  <=  1'b0;
        end
        else begin
            if ((bpsk_bit_out_tlast | qam16_bit_out_tlast) && (cur_sym_index == OFDM_NUM_PER_FRAME - 1))  //have written out all the symbols;
                fifo_rd_en  <=  1'b1;
            else if  (fifo_empty)
                fifo_rd_en  <=  1'b0;
        end
    end
    
    assign  rx_iq_in_tready =   ~fifo_rd_en;
    
    reg     [11:0]  wr_cnt;
    reg     [11:0]  rd_cnt;
    fifo_generator_16_8192 fifo_generator_16_8192_i (
     .srst          (~rst_n),                   // input wire srst
     .clk           (clk),                     // input wire clk
     .din           (fifo_din),            // input wire [15 : 0] din
     .wr_en         (fifo_wr_en),           // input wire wr_en
     .rd_en         (fifo_rd_en),              // input wire rd_en
     .dout          (fifo_dout),                // output wire [15 : 0] dout
     .full          (fifo_full),                // output wire full
     .empty         (fifo_empty),              // output wire empty
     .wr_rst_busy   (),  // output wire wr_rst_busy
     .rd_rst_busy   ()  // output wire rd_rst_busy
    );
    
    always @(posedge clk or negedge rst_n) begin
        if (rst_n == 1'b0) begin
            wr_cnt  <=  12'b0;
            rd_cnt  <=  12'b0;
        end
        else begin
            wr_cnt  <=  (fifo_wr_en) ? (wr_cnt + 1'b1) : wr_cnt;
            rd_cnt  <=  (fifo_rd_en) ? (rd_cnt + 1'b1) : rd_cnt;
        end
    end
    
    
    
    
`ifdef IF_WRITE_DEMOD_DATA
    integer file_handle;
    // 在时钟上升沿捕获有效数据
    reg [11:0] wr_txt_cnt;
    always @(posedge clk) begin
        if(!rst_n) begin
            file_handle = $fopen("E:/project_FPGA/shanxxi_project/baseband/MATLAB/demod_data_from_FPGA.txt", "w");  // 以写入模式打开文件
            wr_txt_cnt = 0;
        end
        else begin
            if (fifo_rd_en) begin
                wr_txt_cnt = wr_txt_cnt + 1;
                // 以十六进制格式写入数据
                //$fwrite(file_handle, "%016b\n", fifo_dout);
                $fwrite(file_handle, "%0d\n", fifo_dout);
                // 可选：在控制台显示写入的数据
                $display("[%0t] Writing data: %d", $time, fifo_dout);
            end
            else if (fifo_empty) begin
                // 仿真结束时关闭文件
                //$fclose(file_handle);
                wr_txt_cnt = 0;
            end
        end
    end
`endif
  */  
    
    
    
    
    
endmodule
