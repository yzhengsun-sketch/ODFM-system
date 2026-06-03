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

    module ifft#(
        parameter   OFDM_NUM_PER_FRAME      =   8'd10,   // length per symbol
        parameter   FFT_LENGTH              =   512,
        parameter   CP_LENGTH               =   64
    )
    (
         input              clk    ,
         input              rst_n        ,   
         input      [31:0]  ifft_din     ,
         input              ifft_din_vld , 
         output             ifft_din_rdy ,
         input              ifft_din_last   ,
         
         output     [31:0]  ifft_dout     , 
         output             ifft_dout_vld , 
         input              ifft_dout_rdy ,
         output             ifft_dout_last  ,
         output     [15:0]  ifft_dout_index  
    );
    
    wire  [31 : 0]  s_axis_config_tdata  ;
    wire            s_axis_config_tvalid    ;
    wire            s_axis_config_tready    ;
    
    wire signed [31 : 0]  s_axis_data_tdata       ;
    wire            s_axis_data_tvalid      ;
    wire            s_axis_data_tlast     ;
    wire            s_axis_data_tready      ;
    
    
    wire signed [31 : 0]  m_axis_data_tdata     ;
    wire  [15 : 0]  m_axis_data_tuser     ;
    wire            m_axis_data_tvalid     ;
    wire            m_axis_data_tready     ;
    wire            m_axis_data_tlast     ;


    
  //循环给ifft核输入512位数据
 //数据循环产生次数： LOOP_NUM
    parameter  LOOP_NUM = 1;

    reg         [10:0]  count;
    reg         [7:0]   loop_index;
    reg signed  [31:0]  TIME_DATA[FFT_LENGTH-1:0];                            //存放输入数据
    reg signed  [31:0]  ifft_s_data_tdata;
    reg                 ifft_s_data_tvalid;
    reg                 ifft_s_data_tlast;
    wire                ifft_s_data_tready;

    `ifdef DEBUG_IFFT     
        //assign     ifft_s_data_tready = s_axis_data_tready;
        assign      ifft_s_data_tready  =  fft_s_axis_data_tready;
        initial begin   
            ifft_s_data_tvalid   <= 1'b0;
            $readmemb("E:/project_FPGA/shanxxi_project/baseband/MATLAB/sub_data.txt",TIME_DATA);
        end
        
        always @(posedge clk or negedge rst_n)begin
            if(!rst_n)begin
                ifft_s_data_tvalid   <= 1'b0;
                count               <= 0;
                ifft_s_data_tlast    <= 1'b0;
                loop_index          <= 8'd0;
            end
            else if(ifft_s_data_tready &&( loop_index < LOOP_NUM) )begin
                if(count<FFT_LENGTH)
                begin
                    ifft_s_data_tvalid   <= 1;
                    ifft_s_data_tdata    <= TIME_DATA[count];      
                    count               <= count+1;
                    ifft_s_data_tlast    <= 1'b0;
                 
                    loop_index <= (count == 511)? (loop_index + 1):loop_index;
                end
                else begin
                    ifft_s_data_tvalid   <= 0;
                    ifft_s_data_tlast    <= 1'b1;
                    #3000;                                          
                    count               <= 0;
                end    
            end
            else begin
                ifft_s_data_tvalid   <= 0;
            end
        end
        
    
        assign s_axis_data_tdata    = ifft_s_data_tdata;  
        assign s_axis_data_tvalid   = ifft_s_data_tvalid  ;
        assign s_axis_data_tlast    = ifft_s_data_tlast   ;
    `else
        //assign s_axis_data_tdata = { {5{ifft_din[15]}},ifft_din[15:8],3'b0 ,{5{ifft_din[7]}},ifft_din[7:0],3'b0  };  
        assign s_axis_data_tdata    = ifft_din;  
        assign s_axis_data_tvalid   = ifft_din_vld  ;
        assign s_axis_data_tlast    = ifft_din_last   ;
        assign ifft_din_rdy         = s_axis_data_tready;
    `endif
    
    
         assign     ifft_dout           =        m_axis_data_tdata;
         assign     ifft_dout_vld       =        m_axis_data_tvalid;
         assign     m_axis_data_tready  =        ifft_dout_rdy;
         assign     ifft_dout_last      =        m_axis_data_tlast;
         assign     ifft_dout_index     =        m_axis_data_tuser;

    
    /*
    always @(posedge clk or negedge rst_n) begin
       if (rst_n == 1'b0) begin
            s_axis_data_tdata		<= 32'd0;
            s_axis_data_tlast		<= 1'b0;
            s_axis_data_tvalid      <= 1'b0;
        end
        else begin
            s_axis_data_tdata    <= ifft_din;  
            s_axis_data_tvalid   <= ifft_din_vld ;
            s_axis_data_tlast    <= ifft_din_last ;
        end
    end
    */
    
    
    //bit(26:17) SCALE_SCH
    //bit [16]  FWD_INV_0    IFFT:0  FFT:1
    //bit (8:0) CP_LEN 
    //assign s_axis_config_tdata  = 32'd0000_0000_0000_0000_0000_0000_0100_0000;
    assign s_axis_config_tdata  = 24'd0000_0000_0000_0000_0100_0000;
    assign s_axis_config_tvalid = 1'b1;
//    assign m_axis_data_tready   = 1'b1;
    
    wire    [7:0]   m_axis_status_tdata;
    wire            m_axis_status_tvalid;
    xfft_0 i_fft (
      .aclk(clk),                                                // input wire aclk
      .aresetn(rst_n),                                          // input wire aresetn
      .s_axis_config_tdata(s_axis_config_tdata),                 // input wire [23 : 0] s_axis_config_tdata
      .s_axis_config_tvalid(s_axis_config_tvalid),                // input wire s_axis_config_tvalid
      .s_axis_config_tready(s_axis_config_tready),                // output wire s_axis_config_tready
      
      .s_axis_data_tdata(s_axis_data_tdata),                      // input wire [31 : 0] s_axis_data_tdata
      .s_axis_data_tvalid(s_axis_data_tvalid),                    // input wire s_axis_data_tvalid
      .s_axis_data_tready(s_axis_data_tready),                    // output wire s_axis_data_tready
      .s_axis_data_tlast(s_axis_data_tlast),                      // input wire s_axis_data_tlast
      
      .m_axis_data_tdata(m_axis_data_tdata),                      // output wire [31 : 0] m_axis_data_tdata
      .m_axis_data_tuser(m_axis_data_tuser),                      // output wire [15 : 0] m_axis_data_tuser
      .m_axis_data_tvalid(m_axis_data_tvalid),                    // output wire m_axis_data_tvalid
      .m_axis_data_tready(m_axis_data_tready),                    // input wire m_axis_data_tready
      .m_axis_data_tlast(m_axis_data_tlast),                      // output wire m_axis_data_tlast
      
      .m_axis_status_tdata(),                                     // output wire [7 : 0] m_axis_status_tdata
      .m_axis_status_tvalid(),                                    // output wire m_axis_status_tvalid
      .m_axis_status_tready(1'b1),                                // input wire m_axis_status_tready
      
      .event_frame_started(),                                    // output wire event_frame_started
      .event_tlast_unexpected(),                                // output wire event_tlast_unexpected
      .event_tlast_missing(),                                   // output wire event_tlast_missing
      .event_status_channel_halt(),                             // output wire event_status_channel_halt
      .event_data_in_channel_halt(),                            // output wire event_data_in_channel_halt
      .event_data_out_channel_halt()                            // output wire event_data_out_channel_halt
    );
    
    
    `ifdef IF_WRITE_IFFT_IN_DATA
        integer file_handle;
        // 在时钟上升沿捕获有效数据
        reg [11:0] wr_txt_cnt;
        always @(posedge clk) begin
            if(!rst_n) begin
                file_handle = $fopen("E:/project_FPGA/shanxxi_project/baseband/MATLAB/data_ifft_in_from_FPGA.txt", "w");  // 以写入模式打开文件
                wr_txt_cnt = 0;
            end
            else begin
                if (s_axis_data_tvalid) begin
                    wr_txt_cnt = wr_txt_cnt + 1;
                    // 以十六进制格式写入数据
                    $fwrite(file_handle, "%032b\n", s_axis_data_tdata);
                    //$fwrite(file_handle, "%0d\n", s_axis_data_tdata);
                    // 可选：在控制台显示写入的数据
                    $display("[%0t] Writing data: %d", $time, s_axis_data_tdata);
                end
                else if (wr_txt_cnt == FFT_LENGTH) begin
                    // 仿真结束时关闭文件
                    $fclose(file_handle);
                    wr_txt_cnt = 0;
                end
            end
        end
    `endif
    
    `ifdef IF_WRITE_IFFT_OUT_DATA
        integer file_handle_out;
        // 在时钟上升沿捕获有效数据
        reg [11:0] wr_txt_cnt_out;
        always @(posedge clk) begin
            if(!rst_n) begin
                file_handle_out = $fopen("E:/project_FPGA/shanxxi_project/baseband/MATLAB/data_ifft_out_from_FPGA.txt", "w");  // 以写入模式打开文件
                wr_txt_cnt_out = 0;
            end
            else begin
                if (m_axis_data_tvalid) begin
                    wr_txt_cnt_out = wr_txt_cnt_out + 1;
                    // 以十六进制格式写入数据
                    $fwrite(file_handle_out, "%0d %0d\n", $signed(m_axis_data_tdata[15:0]), $signed(m_axis_data_tdata[31:16]));
                    //$fwrite(file_handle_out, "%032b\n", m_axis_data_tdata);
                    // 可选：在控制台显示写入的数据
                    $display("[%0t] Writing data: %d", $time, m_axis_data_tdata);
                end
                else if (wr_txt_cnt_out == FFT_LENGTH + CP_LENGTH) begin
                    // 仿真结束时关闭文件
                    $fclose(file_handle_out);
                    wr_txt_cnt_out = 0;
                end
            end
        end
    
    `endif
    
    /*
    wire  signed [15:0] ifft_out_real;
    wire  signed [15:0] ifft_out_imag;
    
    assign  ifft_out_imag = (m_axis_data_tvalid== 1)? m_axis_data_tdata[31:16] : 16'd0;
    assign  ifft_out_real = (m_axis_data_tvalid== 1)? m_axis_data_tdata[15:0]  : 16'd0;


    reg     [7:0]   cur_sym_index;
    reg     m_axis_data_tlast_d1;
    always @(posedge clk or negedge rst_n) begin
        if (rst_n == 1'b0) begin
            cur_sym_index   <=  8'd0;           //waiting for the first symbol
        end
        else begin
            m_axis_data_tlast_d1    <=  m_axis_data_tlast;
            if (m_axis_data_tlast_d1) begin
                cur_sym_index   <=  (cur_sym_index == OFDM_NUM_PER_FRAME - 1)? 8'd0 : (cur_sym_index + 8'd1);
            end    
        end
    end
    
    
    reg    [31:0]       fifo_din;
    reg                 fifo_wr_en;
    reg                 fifo_rd_en;
    wire   [31:0]       fifo_dout;
    wire                fifo_empty;
    wire                fifo_full;
    
    // add the window and store the data to the FIFO
    reg     [11:0]  wr_cnt;
    
    reg     [15:0]  tmp_dataI; 
    reg     [15:0]  tmp_dataQ; 
    
    reg     wr_finished;
    always @(posedge clk or negedge rst_n) begin   
        if (rst_n == 1'b0) begin
            wr_cnt      <=  12'b0;
            rd_cnt      <=  12'b0;
            tmp_dataI   <=  16'd0;
            tmp_dataQ   <=  16'd0;
        end
        else begin
            wr_cnt  <=  (m_axis_data_tvalid) ? (wr_cnt + 1'b1) : 12'b0;
            if ((wr_cnt == 0)&&(m_axis_data_tvalid)) begin
                //fifo_din[31:16]    <=   ($signed(tmp_dataI) + $signed(m_axis_data_tdata[31:16])) / 2;   
                //fifo_din[15:0]     <=   ($signed(tmp_dataQ) + $signed(m_axis_data_tdata[15:0]))  / 2;         
                fifo_din            <=  m_axis_data_tdata;   
            end 
            else begin
                fifo_din            <=  m_axis_data_tdata;
            end
            
            if ((m_axis_data_tuser == 0)&&(m_axis_data_tvalid)) begin // store the first symbol data
                tmp_dataI   <=  m_axis_data_tdata[31:16];
                tmp_dataQ   <=  m_axis_data_tdata[15:0];
            end
            else if ((cur_sym_index == OFDM_NUM_PER_FRAME - 1)&&(m_axis_data_tlast_d1)) begin // indicates the last symbol
                tmp_dataI   <=  16'd0;
                tmp_dataQ   <=  16'd0;
            end 
            
            fifo_wr_en      <=  m_axis_data_tvalid; 
            
            if ((cur_sym_index == OFDM_NUM_PER_FRAME - 1)&&(m_axis_data_tlast_d1)) begin
                wr_finished     <=  1'b1;
            end
            else if (fifo_empty) begin
                wr_finished     <=  1'b0;
            end
        end
    end
    
    
    // read the data until all the symbols have been written into the FIFO;
    reg     [15:0]  rd_cnt;
    always @(posedge clk or negedge rst_n) begin   
        if (rst_n == 1'b0) begin
            fifo_rd_en  <=  1'b0;
        end
        else begin
            if (wr_finished & ifft_dout_rdy) begin
                fifo_rd_en  <=  1'b1;
            end
            else begin
                fifo_rd_en  <=  1'b0;
            end
            
            rd_cnt  <=  (fifo_rd_en) ?   (rd_cnt + 1'b1) : 16'd0;
        end
    end
    */
    /*
    assign  ifft_din_rdy    =    ~wr_finished;
    
    assign  ifft_dout       =   fifo_dout;
    assign  ifft_dout_vld   =   fifo_rd_en & (rd_cnt <= ( OFDM_NUM_PER_FRAME * (FFT_LENGTH + CP_LENGTH) - 1 )); 
    assign  ifft_dout_last  =   (rd_cnt == ( OFDM_NUM_PER_FRAME * (FFT_LENGTH + CP_LENGTH) - 1));
    
    fifo_generator_32_8192 fifo_generator_16_8192_i (
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
*/
endmodule
