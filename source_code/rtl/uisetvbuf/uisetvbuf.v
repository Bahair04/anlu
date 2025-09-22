`timescale 1ns / 1ps
/*******************************MILIANKE*******************************
*Company : MiLianKe Electronic Technology Co., Ltd.
*WebSite:https://www.milianke.com
*TechWeb:https://www.uisrc.com
*tmall-shop:https://milianke.tmall.com
*jd-shop:https://milianke.jd.com
*taobao-shop: https://milianke.taobao.com
*Create Date: 2021/04/25
*Module Name:
*File Name:
*Description: 
*The reference demo provided by Milianke is only used for learning. 
*We cannot ensure that the demo itself is free of bugs, so users 
*should be responsible for the technical problems and consequences
*caused by the use of their own products.
*Copyright: Copyright (c) MiLianKe
*All rights reserved.
*Revision: 1.0
*Signal description
*1) _i input
*2) _o output
*3) _n activ low
*4) _dg debug signal 
*5) _r delay or register
*6) _s state mechine
*********************************************************************/

module uisetvbuf#(
	parameter  integer                  BUF_DELAY     = 1,
	parameter  integer                  BUF_LENTH     = 3
)(
	input									ui_clk,
	input      	  [7   :0]                 	bufn_i,
	output wire   [7   :0]              	bufn_o
);    
 
assign bufn_o = bufn_i < BUF_DELAY?  (BUF_LENTH - BUF_DELAY + bufn_i) : (bufn_i - BUF_DELAY) ;

endmodule

