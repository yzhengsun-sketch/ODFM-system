`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/12/26 14:41:06
// Design Name: 
// Module Name: fft_test
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


module fft_test(

    );
    
    parameter  FFT_LENGTH = 512;
    reg clk,rstn;
    reg signed [31:0]TIME_DATA[FFT_LENGTH-1:0];                            //存放输入数据
    wire fft_s_config_tready;

    reg signed[31:0]fft_s_data_tdata;
    reg fft_s_data_tvalid;
    wire fft_s_data_tready;
    reg fft_s_data_tlast;
    
    wire signed[31:0]fft_m_data_tdata;
    wire signed[31:0]ifft_m_data_tdata;
    wire signed[7:0]fft_m_data_tuser;
    wire fft_m_data_tvalid;
    reg fft_m_data_tready;
    wire fft_m_data_tlast;
    
    reg[10:0]  count;
    reg signed [15:0]fft_i_out;
    reg signed [15:0]fft_r_out;
    reg signed [15:0]ifft_i_out;
    reg signed [15:0]ifft_r_out;
    reg signed [31:0]fft_abs;
    reg signed [31:0]ifft_abs;


    initial begin
         clk=1'b1;
         rstn=1'b0;
         fft_m_data_tready=1'b1;
         #100;
         rstn<=1'b1;  
         $readmemb("E:/project_FPGA/shanxxi_project/baseband/MATLAB/IFFT_IP_core_64point_exam.txt",TIME_DATA);

    //这里注意要改成matlab生成数据时的路径，而且注意不是\，而是/。
    end
    
    always #5 clk=~clk;

    
 //循环给fft核输入128位数据
 //数据循环产生次数： LOOP_NUM
    parameter  LOOP_NUM = 1;
    reg     [7:0]   loop_index;
    always @(posedge clk or negedge rstn)begin
    if(!rstn)begin
        fft_s_data_tvalid<=1'b0;
        count<=0;
       fft_s_data_tlast<=1'b0;
       loop_index <= 8'd0;
    end
    else if(fft_s_data_tready &&( loop_index < LOOP_NUM) )begin
        if(count<FFT_LENGTH)
        begin
            fft_s_data_tvalid<=1;
            fft_s_data_tdata<=TIME_DATA[count];      //这里虚部直接给的0
            count<=count+1;
         fft_s_data_tlast<=1'b0;
         
         loop_index <= (count == FFT_LENGTH-1)? (loop_index + 1):loop_index;
        end
        else begin
            fft_s_data_tvalid<=0;
            fft_s_data_tlast<=1'b1;
            #3000;                                          
            count<=0;
        end    
    end
    else begin
        fft_s_data_tvalid<=0;
    end
    end
    
    //高位赋值给虚部，低位赋值给实部
    always @(posedge clk)begin
        if(fft_m_data_tvalid)
        begin
            fft_i_out=fft_m_data_tdata[31:16];
            fft_r_out=fft_m_data_tdata[15:0];
        end
    end
    
   
    //求幅值，这里的值是没有开方的
    always @(posedge clk)begin
        fft_abs<=$signed(fft_i_out)*$signed(fft_i_out)+$signed(fft_r_out)*$signed(fft_r_out);
    end
   
    //实例化fft核
    xfft_0 fft0(
      .aclk                        (clk), 
      .aresetn                     (rstn),
      .s_axis_config_tdata         (24'b0),
      .s_axis_config_tvalid        (1'b1),
      .s_axis_config_tready        (fft_s_config_tready),
      
      .s_axis_data_tdata           (fft_s_data_tdata),
      .s_axis_data_tvalid          (fft_s_data_tvalid),
      .s_axis_data_tready          (fft_s_data_tready),
      .s_axis_data_tlast           (fft_s_data_tlast),
      
      .m_axis_data_tdata           (fft_m_data_tdata),
      .m_axis_data_tuser           (fft_m_data_tuser),
      .m_axis_data_tvalid          (fft_m_data_tvalid),
      .m_axis_data_tready          (fft_m_data_tready),
      .m_axis_data_tlast           (fft_m_data_tlast)
    );


    wire signed[31:0] ifft_s_data_tdata;
    assign ifft_s_data_tdata [31:16]    = (fft_m_data_tdata[31] == 0)? (fft_m_data_tdata[31:16] >> 6): {5'b11111, fft_m_data_tdata[30:12] >> 4};
    assign ifft_s_data_tdata [15:0]     = (fft_m_data_tdata[15] == 0)? (fft_m_data_tdata[15:0] >> 6) : {5'b11111, fft_m_data_tdata[14:4] >> 4};
    
    
    wire ifft_s_data_tready;
    wire ifft_s_data_tvalid;
    assign ifft_s_data_tvalid=fft_m_data_tvalid;
    wire ifft_s_data_tlast;
    assign ifft_s_data_tlast=fft_m_data_tlast;
    wire signed[7:0]ifft_m_data_tuser;
    wire ifft_m_data_tlast;
    wire ifft_m_data_tvalid;
    wire ifft_s_config_tready;
    
    //实例化ifft核，把fft核输出的数据直接作为它的输入
    xfft_0 ifft0(
      .aclk                        (clk), 
      .aresetn                     (rstn),
      .s_axis_config_tdata         (24'b1),  //因为是做ifft，所以这里配置为0
      .s_axis_config_tvalid        (1'b1),  
      .s_axis_config_tready        (ifft_s_config_tready),
       .s_axis_data_tdata          (ifft_s_data_tdata),
      .s_axis_data_tvalid          (ifft_s_data_tvalid),
      .s_axis_data_tready          (ifft_s_data_tready),
      .s_axis_data_tlast           (ifft_s_data_tlast),
      
      .m_axis_data_tdata           (ifft_m_data_tdata),
      .m_axis_data_tuser           (ifft_m_data_tuser),
      .m_axis_data_tvalid          (ifft_m_data_tvalid),
      .m_axis_data_tready          (fft_m_data_tready),
      .m_axis_data_tlast           (ifft_m_data_tlast)
      
    );
    
    
     always @(posedge clk)begin
        if(ifft_m_data_tvalid)
        begin
            ifft_i_out=ifft_m_data_tdata[31:16];
            ifft_r_out=ifft_m_data_tdata[15:0];
        end
    end
    
    always @(posedge clk)begin
        ifft_abs<=$signed(ifft_i_out)*$signed(ifft_i_out)+$signed(ifft_r_out)*$signed(ifft_r_out);
    end
    
endmodule