`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/01/24 15:55:05
// Design Name: 
// Module Name: data_schedule_tx
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 

// ask for data to transmit when request 

// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module data_schedule_tx#(
    parameter   OFDM_NUM_PER_FRAME      =   8'd10,
    parameter   LEN_PER_SYMBOL_BPSK     =   10'd30,    // the first symbol LEN   subcarrier num = 480;
    parameter   LEN_PER_SYMBOL_16QAM    =   10'd120,   // the later symbol LEN
    parameter   FFT_LENGTH              =   512,
    parameter   CP_LENGTH               =   64
    )
    (
    input                                   clk,
    input                                   rst_n,
    
    input    [32*OFDM_NUM_PER_FRAME-1:0]    mapping_out_tdata,
    input    [OFDM_NUM_PER_FRAME-1:0]       mapping_out_tvalid,
    output   [OFDM_NUM_PER_FRAME-1:0]       mapping_out_tready,
    input    [OFDM_NUM_PER_FRAME-1:0]       mapping_out_tlast,
    input    [16*OFDM_NUM_PER_FRAME-1:0]    mapping_out_index,
    
    input                                   data_to_dac_pls,          // data transmission request
    
    
    output    [31:0]                        frame_out_tdata,
    output                                  frame_out_tvalid,
    output                                  frame_out_tlast
    );
    
    parameter   IDLE    =   2'b00;
    parameter   CALC    =   2'b01;
    parameter   END     =   2'b11;
    
    reg    [OFDM_NUM_PER_FRAME-1:0]       mapping_out_tready;
    
    reg    [31:0]       cur_mapping_out_tdata;
    reg                 cur_mapping_out_tvalid;
    reg                 cur_mapping_out_tlast;
    reg    [15:0]       cur_mapping_out_index;
    
    reg     [7:0]   cur_sym_index;
    reg     [1:0]   state;
    always @(posedge clk or negedge rst_n) begin
        if (rst_n == 1'b0) begin
            state       <=  IDLE;
        end 
        else begin
            case (state) 
                IDLE:  begin                        // the default state
                    cur_sym_index           <=  8'd0;  
                    cur_mapping_out_tvalid  <=  1'b0;         
                    if (data_to_dac_pls) begin
                        state           <=  CALC;
                        mapping_out_tready[0]      <=  1'b1;    // ask for the first symbol
                    end
                    else begin
                        mapping_out_tready  <=  16'd0;
                    end
                end
                CALC:   begin 
                    if (cur_sym_index < OFDM_NUM_PER_FRAME) begin
                        cur_mapping_out_tdata                  <=  mapping_out_tdata[cur_sym_index*32+31 -:32];
                        cur_mapping_out_tvalid                 <=  mapping_out_tvalid[cur_sym_index];
                        cur_mapping_out_tlast                  <=  mapping_out_tlast[cur_sym_index];
                        cur_mapping_out_index                  <=  mapping_out_index[cur_sym_index*16+15 -:16];  
                        
                        if (cur_mapping_out_index == (FFT_LENGTH+CP_LENGTH-2)) begin                // ask for the next symbol
                            cur_sym_index       <=  cur_sym_index + 1;
                            mapping_out_tready  <=  mapping_out_tready << 1;
                        end
                    end
                    else if (cur_sym_index == OFDM_NUM_PER_FRAME) begin    //have read out all the symbols
                        state                   <=  END;
                        cur_mapping_out_tdata                  <=  32'd0;
                        cur_mapping_out_tvalid                 <=  1'b0;
                        cur_mapping_out_tlast                  <=  1'b0;
                        cur_mapping_out_index                  <=  16'd0; 
                    end
                    
                end 
                
                END : begin
                    state   <=  IDLE;
                end
            
            endcase

        end
    end
    assign  frame_out_tdata  =  cur_mapping_out_tdata;
    assign  frame_out_tvalid =  cur_mapping_out_tvalid;
    assign  frame_out_tlast  =  cur_mapping_out_tlast;
    
    /*
    
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
   
    always @(posedge clk or negedge rst_n) begin
        if (rst_n == 1'b0) begin
        
        end 
        else begin
        
        end
    end
    
endmodule
