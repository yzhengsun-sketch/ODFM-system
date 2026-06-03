`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/06/12 17:54:51
// Design Name: 
// Module Name: testForBaseband
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

module testForBaseband(

    );
    
    
    reg         clk;
    reg         rst_n;
    reg         data_to_dac_pls;
    
    parameter   TX_FRAME_LENGTH     =   32'd1000;
    parameter   TX_INTERVAL         =   6*TX_FRAME_LENGTH;
    parameter   OFDM_NUM_PER_FRAME  =   8'd10;
    parameter    LEN_PER_SYMBOL_BPSK     =   10'd30;    // the first symbol LEN   subcarrier num = 480;
    parameter    LEN_PER_SYMBOL_16QAM    =   10'd120;   // the later symbol LEN
    parameter   FFT_LENGTH              =   512;
    parameter   CP_LENGTH               =   64;
    
    initial 
    begin       
        clk             =   1'b0;
        rst_n           =   1'b0;
        data_to_dac_pls  =   1'b0;
        # 200
        rst_n = 1'b0;
        # 200
        rst_n = 1'b1;
        
        # 5000
        data_to_dac_pls  =   1'b1;
        # 100
        data_to_dac_pls  =   1'b0;
        
        #14400
        data_to_dac_pls  =   1'b1;
        # 100
        data_to_dac_pls  =   1'b0;
        
    end
    always #1.25 clk = !clk;
    
    wire    [15:0]  bit_out_tdata;
    wire            bit_out_tvalid;
    wire    [1:0]   bit_out_tkeep;
    wire    [1:0]   bit_out_tstrb;
    wire            bit_out_tlast;
    wire            bit_out_tready;

    tx_ofdm_bit_axis_rom tx_ofdm_bit_axis_rom_i
    (
        .clk                (clk)               ,
        .rst_n              (rst_n)             ,
    
        .tx_interval        (TX_INTERVAL)       ,
        .tx_frame_length    (TX_FRAME_LENGTH)   ,
    
        .bit_out_tdata      (bit_out_tdata)     ,
        .bit_out_tvalid     (bit_out_tvalid)    ,
        .bit_out_tready     (bit_out_tready)    ,
        .bit_out_tkeep      (bit_out_tkeep)    ,
        .bit_out_tstrb      (bit_out_tstrb)     ,
        .bit_out_tlast      (bit_out_tlast)
    );
    
`ifdef IF_WRITE_TX_DATA
    integer file_handle;
    // 在时钟上升沿捕获有效数据
    reg [11:0] wr_txt_cnt;
    always @(posedge clk) begin
        if(!rst_n) begin
            file_handle = $fopen("E:/project_FPGA/shanxxi_project/baseband/MATLAB/tx_bit.txt", "w");  // 以写入模式打开文件
            wr_txt_cnt = 0;
        end
        else begin
            if (bit_out_tvalid) begin
                wr_txt_cnt = wr_txt_cnt + 1;
                // 以十六进制格式写入数据
                //$fwrite(file_handle, "%016b\n", fifo_dout);
                $fwrite(file_handle, "%0d\n", bit_out_tdata);
                // 可选：在控制台显示写入的数据
                //$display("[%0t] Writing data: %d", $time, bit_out_tdata);
            end
        end
    end
`endif 
    
    wire            tx_out_tvalid;    // data output to DAC
    wire  [31:0]    tx_out_tdata;
    ofdm_tx#(
        .OFDM_NUM_PER_FRAME     (OFDM_NUM_PER_FRAME),
        .LEN_PER_SYMBOL_BPSK    (LEN_PER_SYMBOL_BPSK),
        .LEN_PER_SYMBOL_16QAM   (LEN_PER_SYMBOL_16QAM),
        .FFT_LENGTH             (FFT_LENGTH),
        .CP_LENGTH              (CP_LENGTH)
    )
    ofdm_tx_i(
    .clk                    (clk),
    .rst_n                  (rst_n),
    
    .bit_in_tdata           (bit_out_tdata),
    .bit_in_tvalid          (bit_out_tvalid),
    .bit_in_tready          (bit_out_tready),
    .bit_in_tlast           (bit_out_tlast),
    
    .data_to_dac_pls        (data_to_dac_pls),
    
    .tx_out_tdata           (tx_out_tdata),  
    .tx_out_tvalid          (tx_out_tvalid)
    );
    
    
    
    
    wire            rx_in_tvaild;    // data input from ADC
    wire  [31:0]    rx_in_tdata;
    
    wire    [15:0]  rx_bit_out_tdata;
    wire            rx_bit_out_tvalid;
    wire            rx_bit_out_tready;
    wire            rx_bit_out_tlast;
    
    assign      rx_bit_out_tready = 1'b1;
    ofdm_rx#(
        .OFDM_NUM_PER_FRAME     (OFDM_NUM_PER_FRAME),
        .LEN_PER_SYMBOL_BPSK    (LEN_PER_SYMBOL_BPSK),
        .LEN_PER_SYMBOL_16QAM   (LEN_PER_SYMBOL_16QAM),
        .FFT_LENGTH             (FFT_LENGTH),
        .CP_LENGTH              (CP_LENGTH)
    )
    ofdm_rx_i(
    .clk                    (clk),
    .rst_n                  (rst_n),
    
    .rx_in_tdata           (tx_out_tdata),  
    .rx_in_tvalid          (tx_out_tvalid),
    
    .bit_out_tdata           (rx_bit_out_tdata),
    .bit_out_tvalid          (rx_bit_out_tvalid),
    .bit_out_tready          (rx_bit_out_tready),
    .bit_out_tlast           (rx_bit_out_tlast)
    );
    
    
`ifdef IF_WRITE_RX_DATA
    integer file_handle;
    // 在时钟上升沿捕获有效数据
    reg [11:0] wr_txt_cnt;
    always @(posedge clk) begin
        if(!rst_n) begin
            file_handle = $fopen("E:/project_FPGA/shanxxi_project/baseband/MATLAB/rx_bit.txt", "w");  // 以写入模式打开文件
            wr_txt_cnt = 0;
        end
        else begin
            if (rx_bit_out_tvalid) begin
                wr_txt_cnt = wr_txt_cnt + 1;
                // 以十六进制格式写入数据
                //$fwrite(file_handle, "%016b\n", fifo_dout);
                $fwrite(file_handle, "%0d\n", rx_bit_out_tdata);
                // 可选：在控制台显示写入的数据
                //$display("[%0t] Writing data: %d", $time, rx_bit_out_tdata);
            end
        end
    end
`endif  
    /*
    assign  rx_din          =   ifft_dout;
    assign  rx_din_tvalid   =   ifft_dout_vld;
    assign  ifft_dout_rdy   =   rx_din_tready ;
    assign  rx_din_tlast    =   ifft_dout_last;
    
    rev_proc#(
        .OFDM_NUM_PER_FRAME (OFDM_NUM_PER_FRAME),
        .FFT_LENGTH         (FFT_LENGTH),
        .CP_LENGTH          (CP_LENGTH)
    ) 
    rev_proc_i(
     .clk               (clk),
     .rst_n             (rst_n),   
     .rx_din            (rx_din),
     .rx_din_tvalid     (rx_din_tvalid), 
     .rx_din_tready     (rx_din_tready),
     .rx_din_tlast      (rx_din_tlast),
     
     .rx_dout           (rx_dout), 
     .rx_dout_tvalid    (rx_dout_tvalid), 
     .rx_dout_tready    (rx_dout_tready),
     .rx_dout_tlast     (rx_dout_tlast) 
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
    
    assign      fft_din         =   ifft_dout;
    assign      fft_din_vld     =   ifft_dout_vld;
 //   assign      ifft_dout_rdy   =   fft_din_rdy;
    assign      fft_din_last    =   ifft_dout_last;
    
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
    
    wire    [15:0]  rx_bit_out_tdata;
    wire            rx_bit_out_tvalid;
    wire            rx_bit_out_tlast;    
    wire            rx_bit_out_tready;
    demapping     #(
        .OFDM_NUM_PER_FRAME     (OFDM_NUM_PER_FRAME),   // bit length per symbol
        .LEN_PER_SYMBOL_BPSK    (LEN_PER_SYMBOL_BPSK),
        .LEN_PER_SYMBOL_16QAM   (LEN_PER_SYMBOL_16QAM)
    )
    demapping_i(
    .clk                    (clk),
    .rst_n                  (rst_n),
    
    .rx_iq_in_tdata           (rx_iq_in_tdata),
    .rx_iq_in_tvalid          (rx_iq_in_tvalid),
    .rx_iq_in_tready          (rx_iq_in_tready),
    .rx_iq_in_tkeep           (),
    .rx_iq_in_tstrb           (),
    .rx_iq_in_tlast           (rx_iq_in_tlast),
    
    .rx_bit_out_tdata           (rx_bit_out_tdata),
    .rx_bit_out_tvalid          (rx_bit_out_tvalid),
    .rx_bit_out_tready          (rx_bit_out_tready),
    .rx_bit_out_tkeep           (),
    .rx_bit_out_tstrb           (),
    .rx_bit_out_tlast           (rx_bit_out_tlast)
    );
   */
    
endmodule
