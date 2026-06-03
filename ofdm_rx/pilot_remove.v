`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/12/31 09:52:29
// Design Name: 
// Module Name: pilot_remove
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// remove the pilot signals
// 
//////////////////////////////////////////////////////////////////////////////////


module pilot_remove(
    input               clk,
    input               rst_n,
    input   [31:0]      rx_iqc_in_tdata,   //complete iq data, including pilots and data
    input               rx_iqc_in_tvalid,
    output  wire       	rx_iqc_in_tready,
    input   [1:0]       rx_iqc_in_tkeep,
    input   [1:0]       rx_iqc_in_tstrb,
    input               rx_iqc_in_tlast,
    
	output   reg [31:0]      rx_iq_out_tdata, 
    output   reg        rx_iq_out_tvalid,
    input         		rx_iq_out_tready,
    output   [1:0]      rx_iq_out_tkeep,
    output   [1:0]      rx_iq_out_tstrb,
    output   reg       	rx_iq_out_tlast
    );
    
    
    parameter   WRITE_AND_READ_TIME =   64;     // the ram could be read after writing "WRITE_AND_READ_TIME" clks
    
     // remove the pilot and zero pilot
    reg [8:0]	pilot_index[15:0];
	reg [8:0]	zero_index[15:0];
	reg [15:0]  pilot;
	// pilot_index = [25,53,89,117,139,167,203,231,281,309,345,373,395,423,459,487]
    // data_index  = [6:24,26:52,54:88,90:116,118:138,140:166,168:202,204:230,232:253,258:280,282:308,310:344,346:372,374:394,396:422,424:458,460:486,488:505];
    // pilot = [1,1,1,-1,-1,1,1,1,1,1,1,-1,-1,1,1,1]
    // zero_index = [0:5,254:257,506:511] 
	always @(posedge clk or negedge rst_n) begin
        if (rst_n == 1'b0) begin
            pilot_index[0]	<= 25;
			pilot_index[1]	<= 53;
            pilot_index[2]	<= 89;
			pilot_index[3]	<= 117;
			pilot_index[4]	<= 139;
			pilot_index[5]	<= 167;
            pilot_index[6]	<= 203;
			pilot_index[7]	<= 231;
			pilot_index[8]	<= 281;
			pilot_index[9]	<= 309;
            pilot_index[10]	<= 345;
			pilot_index[11]	<= 373;
			pilot_index[12]	<= 395;
			pilot_index[13]	<= 423;
            pilot_index[14]	<= 459;
			pilot_index[15]	<= 487;
			
			pilot			<= 16'b1110011111100111;
			
			zero_index[0]	<= 0;
			zero_index[1]	<= 1;
            zero_index[2]	<= 2;
			zero_index[3]	<= 3;
			zero_index[4]	<= 4;
			zero_index[5]	<= 5;
            zero_index[6]	<= 254;
			zero_index[7]	<= 255;
			zero_index[8]	<= 256;
			zero_index[9]	<= 257;
            zero_index[10]	<= 506;
			zero_index[11]	<= 507;
			zero_index[12]	<= 508;
			zero_index[13]	<= 509;
            zero_index[14]	<= 510;
			zero_index[15]	<= 511;
        end
	end
	
	reg            wea;
	reg    [8:0]   addra;
	reg    [31:0]  dina;
	reg            enb;
	reg    [8:0]   addrb;
	wire   [31:0]  doutb;
	
	// write the data
	always @(posedge clk or negedge rst_n) begin
        if (rst_n == 1'b0) begin
            addra   <=  9'd0;
        end
        else begin
            wea     <=  rx_iqc_in_tvalid;
            dina    <=  rx_iqc_in_tdata;
            addra   <=  (wea)? (addra + 1'b1) : 9'd0;
        end 
    end
	
	// read the data
	reg       read_flag;
	always @(posedge clk or negedge rst_n) begin
        if (rst_n == 1'b0) begin
            read_flag <=   1'b0;
        end
        else begin
            if      (addra >=   WRITE_AND_READ_TIME)    read_flag <=  1'b1;     //start read after writing the data for WRITE_AND_READ_TIME clks;
            else if (addrb ==   9'd504)                 read_flag <=  1'b0;     // have read out all the vaild data;
        end
    end
	
	
	
	
	reg 	[4:0]	pilot_cnt;
	always @(posedge clk or negedge rst_n) begin
        if (rst_n == 1'b0) begin
            addrb       <=  9'd6;           //6 is the first data;
            pilot_cnt   <=  5'd0;
        end
        else begin
           if (read_flag & rx_iq_out_tready)               enb <=  1'b1;
           else if(addrb == 9'd506)     enb <=  1'b0;    // 505 is the last data;
           
           if (enb) begin
                if (addrb == pilot_index[pilot_cnt] - 1) begin
                    addrb		<= addrb + 9'd2;
                    pilot_cnt	<= pilot_cnt + 1'b1;
                end
                else if (addrb == 9'd253) begin    //jump the zero pilot
                    addrb	<= addrb + 9'd5;
                end
                else if (addrb	<= 9'd505) begin  
                    addrb	<= addrb + 9'd1;
                end
           end
           else begin
                addrb       <=  9'd6;           //6 is the first data;
                pilot_cnt   <=  5'd0;
           end
       end
    end 
				
	reg    enb_d1;
	reg    enb_d2;
	always @(posedge clk)  begin
	   enb_d1              <=  enb;
	   enb_d2              <=  enb_d1;
	   
	   rx_iq_out_tvalid    <=  enb_d1  & enb_d2;
	   rx_iq_out_tlast     <= (~enb) & enb_d1;
	   
	   rx_iq_out_tdata     <=  doutb;
	end
//	assign     rx_iq_out_tdata     =  doutb;	
	
	
	assign     rx_iqc_in_tready    =  ~enb;			
	
	blk_mem_gen_32_512 blk_mem_gen_32_512_i (
      .clka(clk),    // input wire clka
      .ena(1'b1),      // input wire ena
      .wea(wea),      // input wire [0 : 0] wea
      .addra(addra),  // input wire [8 : 0] addra
      .dina(dina),    // input wire [31 : 0] dina
      .clkb(clk),    // input wire clkb
      .enb(enb),      // input wire enb
      .addrb(addrb),  // input wire [8 : 0] addrb
      .doutb(doutb)  // output wire [31 : 0] doutb
);

endmodule
