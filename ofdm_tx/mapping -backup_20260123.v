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


module mapping#(
    parameter   OFDM_NUM_PER_FRAME      =   8'd10,
    parameter   LEN_PER_SYMBOL_BPSK     =   10'd30,    // the first symbol LEN   subcarrier num = 480;
    parameter   LEN_PER_SYMBOL_16QAM    =   10'd120   // the later symbol LEN
    )
    (
    input                   clk,
    input                   rst_n,
    
    input   wire    [15:0]                          bit_in_tdata,
    input   wire                                    bit_in_tvalid,
    output  wire                                    bit_in_tready, 
    input   wire                                    bit_in_tlast
    

    
    );
    
    wire   [32*OFDM_NUM_PER_FRAME-1:0]      iq_out_tdata;
    wire   [OFDM_NUM_PER_FRAME-1:0]         iq_out_tvalid;
    wire   [OFDM_NUM_PER_FRAME-1:0]         iq_out_tready;
    wire   [OFDM_NUM_PER_FRAME-1:0]         iq_out_tlast;
    
    
   
   parameter    INITIAL_TIME            =   8'd100;
   
   reg  [7:0]  initial_cnt;
   always @(posedge clk)
     begin
        if (rst_n == 1'b0)                   initial_cnt <= 8'd0;
        else if(initial_cnt < INITIAL_TIME)  initial_cnt <= initial_cnt + 8'd1;
     end   
 
   
   wire clk_100M;
   wire clk_25M;
   wire clk_100M_locked; 
   clk_wiz_400_to_100MHz clk_wiz_400_to_100MHz_i
   (
    .clk_in1    (clk),              // input clk_in1
    .reset      (),                 // input reset
    .clk_out1   (clk_100M),         // output clk_out1
    .clk_out2   (clk_25M),          // output clk_out1
    .locked     (clk_100M_locked)   // output locked
    ); 
    

    
    reg            fifo_rd_en;
    wire   [15:0]  fifo_dout;
    wire           fifo_empty;
    wire           fifo_full;
    
    reg     [15:0] read_data_cnt;
    wire           read_data_clk;
    
    reg   [15:0]   avail_data_len;
    reg            is_first_symbol;
    
    //assign   bit_in_tready      =  (initial_cnt < INITIAL_TIME)? 1'b0 : bpsk_in_tready;
    assign   bit_in_tready      =  (initial_cnt < INITIAL_TIME)? 1'b0 : ~fifo_full;
    
    wire   [15:0]   bpsk_in_tdata;
    wire            bpsk_in_tvaild;
    wire            bpsk_in_tready;
    reg             bpsk_in_tlast;
    
    wire    [31:0]  bpsk_out_tdata;
    wire            bpsk_out_tvalid;
    wire            bpsk_out_tready;
    wire            bpsk_out_tlast;
    
   
    wire    [16*OFDM_NUM_PER_FRAME-1:0]     qam16_in_tdata;
    wire    [OFDM_NUM_PER_FRAME-1:0]        qam16_in_tvaild;
    wire    [OFDM_NUM_PER_FRAME-1:0]        qam16_in_tready;
    wire    [OFDM_NUM_PER_FRAME-1:0]        qam16_in_tlast;
    
    wire    [32*OFDM_NUM_PER_FRAME-1:0]     qam16_out_tdata;
    wire    [OFDM_NUM_PER_FRAME-1:0]        qam16_out_tvalid;
    wire    [OFDM_NUM_PER_FRAME-1:0]        qam16_out_tready;
    wire    [OFDM_NUM_PER_FRAME-1:0]        qam16_out_tlast; 
    
   /*  
    wire    [15:0]      qam16_in_tdata;
    wire                qam16_in_tvaild;
    wire                qam16_in_tready;
    reg                 qam16_in_tlast;
    
    wire    [31:0]      qam16_out_tdata;
    wire                qam16_out_tvalid;
    wire                qam16_out_tready;
    wire                qam16_out_tlast;*/
    
    
    reg     fifo_empty_d1;
    reg     read_data_start;
    
    reg [7:0]   cur_sym_index;       //indicating current symbol index
    reg         move_state;
    reg [7:0]   state_cnt;
    reg [7:0]   read_data_length;
    
    
    reg             bit_in_tvalid_d1; 
    reg   [15:0]    total_data_len;
    reg             qam16_in_tlast_tmp;
    
    // obtain the total length of current frame
     always @(posedge clk) begin
        bit_in_tvalid_d1    <= bit_in_tvalid;
        if (bit_in_tvalid & (~bit_in_tvalid_d1)) begin
            total_data_len  <= bit_in_tdata;
        end
     end  
 
    always @(posedge clk)begin
        if (rst_n == 1'b0) begin
            read_data_start <= 1'b1;
            cur_sym_index   <= 8'hff;         // default state
            fifo_rd_en      <= 1'b0;
            read_data_cnt   <= 16'd0;
            move_state      <= 1'b0;
            state_cnt       <= 8'd0;
        end
        else begin
            fifo_empty_d1   <= fifo_empty;
            if (fifo_empty_d1 &(~fifo_empty)) begin
                read_data_start <= 1'b1;
                cur_sym_index   <= 8'd0;
                read_data_cnt   <= 16'd0;
                avail_data_len  <= total_data_len;
                qam16_in_tlast_tmp <= 0;
            end
            else begin
                case (cur_sym_index)
                    8'd0: begin             // the first symbol
                        state_cnt     <= state_cnt + 1'b1;
                        read_data_length    <=  (avail_data_len < LEN_PER_SYMBOL_BPSK)? avail_data_len : LEN_PER_SYMBOL_BPSK;
                        if ((state_cnt >= 1) && (state_cnt < read_data_length + 1))  begin
                            fifo_rd_en <= 1'b1;
                        end
                        else begin
                            fifo_rd_en <= 1'b0;
                        end
                        
                        if (state_cnt == read_data_length)  begin
                            bpsk_in_tlast <= 1'b1;
                        end
                        else begin
                            bpsk_in_tlast <= 1'b0;
                        end
                        
                        //if (state_cnt == read_data_length + 10) begin                //delay 10 clk before moving to next symbol
                        if (bpsk_in_tlast) begin
                            avail_data_len <= avail_data_len - read_data_length;
                            cur_sym_index  <= cur_sym_index + 8'd1;                                          // move to next symbol
                            state_cnt      <= 8'd0;
                        end
                    end 
                    8'hff: begin 
                    end
                    default: begin           // the later symbol
                        if (avail_data_len == 0) begin
                            cur_sym_index   <= 8'hff;         // default state
                        end
                        else if (qam16_in_tready) begin
                            state_cnt     <= state_cnt + 1'b1;
                            read_data_length    <=  (avail_data_len < LEN_PER_SYMBOL_16QAM)? avail_data_len : LEN_PER_SYMBOL_16QAM;
                            if ((state_cnt >= 1) && (state_cnt < read_data_length + 1))  begin
                                fifo_rd_en <= 1'b1;
                            end
                            else begin
                                fifo_rd_en <= 1'b0;
                            end
                            
                            if (state_cnt == read_data_length)  begin
                                qam16_in_tlast_tmp <= 1'b1;
                            end
                            else begin
                                qam16_in_tlast_tmp <= 1'b0;
                            end
                            
                            //if (state_cnt == read_data_length + 10) begin                //delay 10 clk before moving to next symbol
                            if (qam16_in_tlast_tmp) begin
                                avail_data_len <= avail_data_len - read_data_length;
                                cur_sym_index  <= cur_sym_index + 8'd1;                                          // move to next symbol
                                state_cnt      <= 8'd0;
                            end
                        end
                    end
                endcase 
            end        
        end
    end

    assign     bpsk_in_tdata      = (cur_sym_index == 8'd0)? fifo_dout : 16'd0;     // the first symbol is bpsk signal (denoted by cur_sym_index)
    assign     bpsk_in_tvaild     = (cur_sym_index == 8'd0)? fifo_rd_en : 1'b0;
    
    assign     bpsk_out_tready    = 1'b1;
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
        
   
   
    genvar j    ;
    generate
        for(j=1; j<OFDM_NUM_PER_FRAME; j=j+1)                     // the first OFDM symbol is empty;
        begin: qam_data_assignment
            assign    qam16_in_tdata[j*16+15 -:16]  = (cur_sym_index == j)? fifo_dout : 16'd0;
            assign    qam16_in_tvaild[j]            = (cur_sym_index == j)? fifo_rd_en : 1'b0;
            assign    qam16_in_tlast[j]             = (cur_sym_index == j)? qam16_in_tlast_tmp : 1'b0;
            assign    qam16_out_tready[j]            = 1'b1;
        end
    endgenerate
    
    
     
    genvar i    ;
    generate
        for(i=1; i<OFDM_NUM_PER_FRAME; i=i+1) 
        begin: OFDM_mapping
            QAM_16#(
            .LEN_PER_SYMBOL_16QAM(LEN_PER_SYMBOL_16QAM)   // bit length per symbol
            )
            QAM_16_i(
                .clk                (clk),
                 .rst_n              (rst_n),
            
                .bit_in_tvalid      (qam16_in_tvaild[i]),
                .bit_in_tdata       (qam16_in_tdata[i*16+15 -:16]),
                .bit_in_tready      (qam16_in_tready[i]),
                .bit_in_tlast       (qam16_in_tlast[i]),
                
                .iq_out_tdata       (qam16_out_tdata[i*32+31 -:32]),
                .iq_out_tvalid      (qam16_out_tvalid[i]),
                .iq_out_tready      (qam16_out_tready[i]),
                .iq_out_tlast       (qam16_out_tlast[i])
        //        .iq_out_tkeep       (),
        //        .iq_out_tstrb       (),
                );
        end
    endgenerate

  
  /* 
  assign     qam16_in_tdata      = (cur_sym_index != 8'd0)? fifo_dout : 16'd0;    //the other symbols (beside the first symbol) are 16qam signal (denoted by cur_sym_index)
  assign     qam16_in_tvaild     = (cur_sym_index != 8'd0)? fifo_rd_en : 1'b0;
   assign qam16_out_tready = ~bpsk_out_tvalid & iq_out_tready;
   
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
 */
  fifo_generator_16_8192 fifo_generator_16_8192_i (
     .srst          (~rst_n),                   // input wire srst
     .clk           (clk),                     // input wire clk
     .din           (bit_in_tdata),            // input wire [15 : 0] din
     .wr_en         (bit_in_tvalid),           // input wire wr_en
     .rd_en         (fifo_rd_en),              // input wire rd_en
     .dout          (fifo_dout),                // output wire [15 : 0] dout
     .full          (fifo_full),                // output wire full
     .empty         (fifo_empty),              // output wire empty
     .wr_rst_busy   (),  // output wire wr_rst_busy
     .rd_rst_busy   ()  // output wire rd_rst_busy
    );
    
   /* assign iq_out_tdata     = (qam16_out_tvalid == 1)? qam16_out_tdata : bpsk_out_tdata;
    assign iq_out_tvalid    = qam16_out_tvalid | bpsk_out_tvalid;
    assign iq_out_tlast     = qam16_out_tlast  | bpsk_out_tlast;
   */ 
endmodule
