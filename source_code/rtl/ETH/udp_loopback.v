`timescale 1ns / 1ps
//********************************************************************** 
// -------------------------------------------------------------------
// >>>>>>>>>>>>>>>>>>>>>>>Copyright Notice<<<<<<<<<<<<<<<<<<<<<<<<<<<< 
// ------------------------------------------------------------------- 
//             /\ --------------- 
//            /  \ ------------- 
//           / /\ \ -----------
//          / /  \ \ ---------
//         / /    \ \ ------- 
//        / /      \ \ ----- 
//       / /_ _ _   \ \ --- 
//      /_ _ _ _ _\  \_\ -
//*********************************************************************** 
// Author: suluyang 
// Email:luyang.su@anlogic.com 
// Date:2020/10/26 
// Description: 
// 
// web：www.anlogic.com 
//------------------------------------------------------------------- 
//*********************************************************************/
//////////////////////////////////////////////////////////////////////////////////////
// Module Name: udp_loopback.v
// Description: UDP回环测试模块 将输入的数据存入FIFO缓存中并在特定的条件下进入发送状态，从FIFO中读出缓存的数据并发送出去
// 				[input] app_rx_clk : 接收数据时钟
//				[input] app_tx_clk : 发送数据时钟
//        		[input] reset : 高电平复位信号
//				[input] app_rx_valid : 接收数据有效信号
//				[input] app_rx_data : 接收到的数据
//				[input] app_rx_data_length : 接收到的数据长度
//				[input] udp_tx_ready : sink端准备好接收数据
//				[input] app_tx_ack : source端产生应答信号
//				[output] app_tx_data : source端发送的数据
//				[output] app_tx_data_request : source端发送数据请求信号
//				[output] app_tx_data_valid : source端发送数据有效信号
//				[output] udp_data_length : source端发送数据长度
// 处理逻辑 :
//				1. 只要有接收有效信号就一直接收数据并存入FIFO
//				2. 当不存在接收有效信号时，如果FIFO非空并且sink端准备好接收数据，就产生发送数据请求并进入等待响应状态，否则停留在等待UDP数据状态（持续接收数据状态）
//				3. sink端接收到获取数据请求后会产生应答信号，source端（本模块）接收到应答信号后就复位请求信号并进入发送UDP数据状态，使能读FIFO，根据发送数据的长度，连续发送数据
//				4. 数据发送完成以后重新进入等待UDP数据状态（持续接收数据状态）
//////////////////////////////////////////////////////////////////////////////////////
module udp_loopback(
	input   wire		app_rx_clk		   ,
	input   wire		app_tx_clk		   ,
	input   wire		reset              ,
	input   wire [7:0]	app_rx_data        ,
	input   wire		app_rx_data_valid  ,
	input   wire [15:0] app_rx_data_length ,
				
	input   wire		udp_tx_ready       ,
	input   wire		app_tx_ack         ,
	output  wire  [7:0] app_tx_data        ,
	output	reg  		app_tx_data_request,
	output	reg  		app_tx_data_valid  ,
	output  reg  [15:0]	udp_data_length	   
);
parameter  			 	DEVICE            = "EG4";//"PH1","EG4"

reg         app_tx_data_read;
wire [11:0] udp_packet_fifo_data_cnt;
reg  [15:0] fifo_read_data_cnt;
reg  [15:0] udp_data_length_reg_ff1;
reg  [15:0] udp_data_length_reg_ff2;
wire [7:0]  app_tx_data_reg;

assign app_tx_data = app_tx_data_reg;

reg [1:0]   STATE;
localparam  WAIT_UDP_DATA   = 2'd0;
localparam  WAIT_ACK        = 2'd1;
localparam  SEND_UDP_DATA   = 2'd2;

ram_fifo#
(
	.DEVICE       	(DEVICE       	),//"PH1","EG4","SF1","EF2","EF3","AL"
	.DATA_WIDTH_W 	(8 				),//写数据位宽
	.ADDR_WIDTH_W 	(12 			),//写地址位宽
	.DATA_WIDTH_R 	(8 				),//读数据位宽
	.ADDR_WIDTH_R 	(12 			),//读地址位宽
	.SHOW_AHEAD_EN	(1				)//普通/SHOWAHEAD模式
)
udp_packet_fifo
(
	.rst			(reset				), 
	.di				(app_rx_data		), 
	.clkw			(app_rx_clk			), 
	.we				(app_rx_data_valid	),
	.clkr			(app_tx_clk			), 
	.re				(app_tx_data_read	), 
	.do				(app_tx_data_reg	), 
	.empty_flag		(					), 
	.full_flag		(					), 
	.wrusedw		(					), 
	.rdusedw		(udp_packet_fifo_data_cnt)
);

always@(posedge app_tx_clk or posedge reset)
begin
	if(reset) begin
		udp_data_length_reg_ff1 <= 16'd0;
		udp_data_length_reg_ff2 <= 16'd0;
	end	
	else if(app_rx_data_valid)
	begin 
		udp_data_length_reg_ff1 <= app_rx_data_length;
		udp_data_length_reg_ff2 <= udp_data_length_reg_ff1;
	end
end

always@(posedge app_tx_clk or posedge reset)
begin
	if(reset) begin
		app_tx_data_request <= 1'b0;
		app_tx_data_read 	<= 1'b0;
		app_tx_data_valid 	<= 1'b0;
		fifo_read_data_cnt 	<= 16'd0;
		udp_data_length 	<= 16'd0;
		STATE 				<= WAIT_UDP_DATA;
	end
	else begin
	    case(STATE)
			WAIT_UDP_DATA: // 0
				begin
					if((udp_packet_fifo_data_cnt > 12'd0) && (~app_rx_data_valid) && udp_tx_ready) begin
						app_tx_data_request <= 1'b1;
						STATE 				<= WAIT_ACK;
					end
					else begin
						app_tx_data_request <= 1'b0;
						STATE 				<= WAIT_UDP_DATA;
					end
				end
			WAIT_ACK: // 1
				begin
				   if(app_tx_ack) begin
						app_tx_data_request <= 1'b0;
						app_tx_data_read 	<= 1'b1;
						app_tx_data_valid 	<= 1'b1;
						udp_data_length 	<= udp_data_length_reg_ff2;
						STATE 				<= SEND_UDP_DATA;
					end
					else begin
						app_tx_data_request <= 1'b1;
						app_tx_data_read	<= 1'b0;
						app_tx_data_valid 	<= 1'b0;
						udp_data_length 	<= 16'd0;
						STATE 				<= WAIT_ACK;
					end
				end
			SEND_UDP_DATA: // 2
				begin
					if(fifo_read_data_cnt == (udp_data_length_reg_ff2 - 1'b1)) begin
						fifo_read_data_cnt 	<= 16'd0;
						app_tx_data_valid 	<= 1'b0;
						app_tx_data_read 	<= 1'b0;
						STATE 				<= WAIT_UDP_DATA;
					end
					else begin
						fifo_read_data_cnt 	<= fifo_read_data_cnt + 1'b1;
						app_tx_data_valid  	<= 1'b1;
						app_tx_data_read 	<= 1'b1;
						STATE 				<= SEND_UDP_DATA;
					end						
				end
			default: STATE 		<= WAIT_UDP_DATA;
		endcase
	end
end

endmodule
