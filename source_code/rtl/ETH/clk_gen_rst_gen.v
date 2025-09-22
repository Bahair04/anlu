`timescale 1ns / 1ps
//******************************************************************** 
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
//--------------------------------------------------------------------
// Author: suluyang 
// Email:luyang.su@anlogic.com 
// Date:2022/03/08
// Description: 
// 		时钟复位输出模块
// 
// web：www.anlogic.com 
//--------------------------------------------------------------------
//
// Revision History :
//--------------------------------------------------------------------
// Revision 1.0 Date:2022/03/08 初版建立
//
//
//--------------------------------------------------------------------
//*******************************************************************/
//////////////////////////////////////////////////////////////////////////////////////
// Module Name: clk_gen_rst_gen.v
// Description: 生成同步复位信号和三速时钟
//				[input] reset : 高电平复位信号
//				[input] clk_in : 50MHz 输入时钟
//				[output]rst_out : 同步高电平复位信号(由PLL lock信号产生)
//				[output]clk_125_out0 : 125Mhz 时钟输出
//				[output]clk_125_out1 : 125Mhz 时钟输出
//				[output]clk_125_out2 : 125Mhz 时钟输出 相移90度
//				[output]clk_12_5_out : 12.5Mhz 时钟输出
//				[output]clk_1_25_out : 1.25Mhz
//				[output]clk_25_out : 25Mhz 时钟输出
// 处理逻辑 : 
//				使用PLL锁相环IP核产生多路时钟
//				当PLL输出信号稳定时 lock信号为高电平
//				所以高电平复位信号相当于lock信号取反
//////////////////////////////////////////////////////////////////////////////////////
module clk_gen_rst_gen(
	input        reset,
	input        clk_in,
	
	output       rst_out,
	output 		 clk_125_out0,
	output 		 clk_125_out1,
	output 		 clk_125_out2,
	output 		 clk_12_5_out,
	output 		 clk_1_25_out,
	output 		 clk_25_out	
);
parameter  DEVICE             = "EG4";//"PH1","EG4"
wire extlock;
assign rst_out = !extlock;

generate
if(DEVICE == "EG4")
begin
	pll_gen	u_pll_0(
		.refclk  		(clk_in			),//50.000Mhz
		.reset   		(reset  		),
		.extlock 		(extlock		),//Frequency 	| Phase shift
		.clk0_out		(clk_125_out0	),//125.000000MHZ	| 0  DEG     
		.clk1_out		(clk_125_out1	),//125.000000MHZ	| 0  DEG     
		.clk2_out		(clk_12_5_out	),//12.500000 MHZ	| 0  DEG     
		.clk3_out		(clk_25_out  	),//25.000000 MHZ	| 0  DEG  
		.clk4_out		(clk_125_out2  	) //125.000000MHZ	| 90  DEG
	);
end
else if(DEVICE == "PH1")
begin
	pll_gen u_pll_0(
		.refclk  		(clk_in			),
		.reset   		(reset  		),
		.lock       	(extlock		),
		.clk0_out		(clk_125_out0	),
		.clk1_out		(clk_125_out1	),
		.clk2_out		(clk_12_5_out	),
		.clk3_out		(clk_25_out  	),
		.clk4_out		(clk_125_out2  	)
	);
end

endgenerate


div_clk_gen u_udp_clk_gen_1p25(
	.reset			(!extlock		),
	.clk_en			(1'b1			),
	.clk_in			(clk_12_5_out	), // 12.5Mhz
	.clk_out		(clk_1_25_out   ) // 1.25Mhz
);

endmodule
