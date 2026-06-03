`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/06/26 14:58:53
// Design Name: 
// Module Name: pilot_insert
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// inset pilots
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module pilot_insert(
    input               clk,
    input               rst_n,
    input   [31:0]      iq_in_tdata,
    input               iq_in_tvalid,
    output  wire       	iq_in_tready,
    input   [1:0]       iq_in_tkeep,
    input   [1:0]       iq_in_tstrb,
    input               iq_in_tlast,
    
	output   reg    [31:0]      iqc_out_tdata, //complete iq data
    output   reg        iqc_out_tvalid,
    input         		iqc_out_tready,
    output   [1:0]      iqc_out_tkeep,
    output   [1:0]      iqc_out_tstrb,
    output   reg       	iqc_out_tlast
	
    );
    
	parameter  CP_LENGTH       = 64;
	parameter  BIT_PER_SYMBOL  = 512;
	
	reg 		ena;
	reg 		wea;
	reg	[8:0]	addra;
	reg [31:0]	dina;
	reg 		enb;
	reg [8:0]   addrb;
	wire [31:0]	doutb;
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
	
	reg 	[4:0]	pilot_cnt;
	reg 	[1:0]	state;
	reg 			data_ready;
	reg             rd_data_ready;
	reg             rd_all_data;
	
	assign  iq_in_tready = (state == 2'b10);
	
    always @(posedge clk or negedge rst_n) begin
        if (rst_n == 1'b0) begin
            addra		<= 9'd0;
			pilot_cnt	<= 5'd0;
			state		<= 2'b00;
            wea			<= 1'b0;
			data_ready	<= 1'b0;
			rd_data_ready <= 1'b0;
        end
        else begin 
			case(state)
			2'b00: begin             //write pilot
			    if (pilot_cnt < 5'd16) begin
			        pilot_cnt    <=  pilot_cnt + 1'b1;
                    wea          <=  1'b1; 
                    addra		 <=  pilot_index[pilot_cnt];
                    dina		 <=  (pilot[pilot_cnt] == 1)? 32'b000000000000000000000100000000000 :32'b00000000000000001111100000000000;
			    end

				if (pilot_cnt == 5'd16) begin
				    state		<= state + 2'b01;
				    wea         <= 1'b0;
				    pilot_cnt   <= 5'd0;
				end
			end
			
			2'b01: begin		     //write zero pilot
			    if (pilot_cnt < 5'd16) begin
			        pilot_cnt    <=  pilot_cnt + 1'b1;
                    wea          <=  1'b1; 
                    addra		 <=  zero_index[pilot_cnt];
                    dina		 <=  32'd0;
			    end
				if (pilot_cnt == 5'd16) begin
				    state		<= state + 2'b01;
				    wea         <= 1'b0;
				    pilot_cnt   <= 5'd0;
				    addra		<= 9'd5;
				end

			end
			2'b10: begin               //waiting for: write data
				if (iq_in_tvalid) begin  
				    rd_data_ready <= 1'b1; 
				    dina    <=   iq_in_tdata;
				    wea     <=   1'b1;
					data_ready	<= 1'b1;
					if (addra == pilot_index[pilot_cnt] - 1) begin
						addra		<= addra + 9'd2;
						pilot_cnt	<= pilot_cnt + 1'b1;
					end
					else if (addra == 9'd253) begin    //jump the zero pilot
						addra	<= addra + 9'd5;
					end
					else if (addra	< 9'd505) begin  
						addra	<= addra + 9'd1;
					end
				end
				else if (addra	== 9'd505) begin                    // have written all the data
                    state		<= state + 2'b01;
                    pilot_cnt	<= 5'd0;
                    wea         <= 1'b0;
				end
			end
			default: begin   // waiting for read data
				if (iqc_out_tlast) begin   //read out the data 
					state 		<= 2'b00;
					data_ready 	<= 1'b0;
					rd_data_ready <= 1'b0;
				end
			end
			endcase
		end
    end
	
	// read data from the RAM
	reg 	      start_read;
	reg     [9:0] rd_data_cnt;
	reg           data_last;
	always @(posedge clk or negedge rst_n) begin
        if (rst_n == 1'b0) begin
            addrb		<= 9'd0;
			enb			<= 1'b0;
			start_read	<= 1'b0;
			rd_data_cnt <= 10'd0;
			data_last   <= 1'b0;
        end
		else begin
            if (iqc_out_tready & rd_data_ready) begin
                enb           <= (rd_data_cnt < 512) ? 1'b1:1'b0;
                rd_data_cnt   <= rd_data_cnt + 1'b1;
            end
            else begin
                enb		    <=  1'b0;
                rd_data_cnt <= (rd_data_ready)? rd_data_cnt : 10'd0;
		    end
		    
            if (enb) begin
                addrb     <= addrb + 1'b1;
            end
            if (rd_data_cnt ==  511) begin
                data_last     <= 1'b1;
            end
            else begin
                data_last     <= 1'b0;
            end
        end
	end
	
	reg        enb_tmp;
	reg        data_last_tmp;
	
	reg        enb_tmp1;
	reg        data_last_tmp1;
	
	// delay 2 clks before assigning the output data
	always @(posedge clk or negedge rst_n) begin
	   if (rst_n == 1'b0) begin
            iqc_out_tvalid		<= 1'd0;
			iqc_out_tlast		<= 1'b0;
			enb_tmp             <= 1'b0;
			enb_tmp1            <= 1'b0; 
			data_last_tmp       <= 1'b0;
			data_last_tmp1      <= 1'b0;
        end
		else begin
		   enb_tmp         <= enb;
		   enb_tmp1        <= enb_tmp;
		   
	       data_last_tmp   <= data_last;
	       data_last_tmp1  <= data_last_tmp;
	   
	       iqc_out_tvalid  <= enb_tmp1;
	       iqc_out_tlast   <= data_last_tmp1;
	       
	       iqc_out_tdata   <= doutb;
	    end
	end
	
	//assign iqc_out_tdata = doutb;
    
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
