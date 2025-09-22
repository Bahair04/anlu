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
// Date:2020/11/17 
// Description: 
// 2022/03/10:  修改时钟结构
//              简化约束
//              添加 soft fifo 
//              添加 debug 功能
// 2023/02/16 :add dynamic_local_ip_address port
// 
// web：www.anlogic.com 
//------------------------------------------------------------------- 
//*********************************************************************/
`define UDP_LOOP_BACK

`define   DATA_WIDTH                        32										// 数据位宽
`define   ADDR_WIDTH                        21										// 地址位宽
`define   DM_WIDTH                          4										// 数据掩码位宽
`define   ROW_WIDTH                         11										// 行地址位宽
`define   BA_WIDTH                          2										// Bank位宽
`define	  SDR_CLK_PERIOD				1000000000/150000000						// SDRAM时钟周期
`define   SELF_REFRESH_INTERVAL			64000000/`SDR_CLK_PERIOD/2**(`ROW_WIDTH) 	// SDRAM自刷新时间
`include "HDMI/vga_parameter_cfg.v"
module UDP_Example_Top(
        input   wire                        rstn,                               // 输入按键
        input   wire                        clk_50,                             // 50MHz

        //////////////////////////////////////////////////////////////////////////////////////
        // HDMI
        output  wire                        HDMI_CLK_P,
        output  wire                        HDMI_CLK_N,
        output  wire                        HDMI_D2_P,
        output  wire                        HDMI_D2_N,
        output  wire                        HDMI_D1_P,
        output  wire                        HDMI_D1_N,
        output  wire                        HDMI_D0_P,
        output  wire                        HDMI_D0_N,

        //////////////////////////////////////////////////////////////////////////////////////
        // OV5640
        output  wire                        cmos_scl,
        inout   wire                        cmos_sda,
        input   wire                        cmos_pclk,
        input   wire                        cmos_vsync,
        input   wire                        cmos_href,
        input   wire    [7 : 0]             cmos_data,
        output  wire                        cmos_reset,
        output  wire                        cmos_pwdn
);

//*------------------------------------------------------------
//* OV5640
//*------------------------------------------------------------
wire                                cfg_done; // OV5640配置完成
wire    [15 : 0]                    cmos_rgb_o; // OV5640 视频帧信号
wire                                cmos_de_o;
wire                                cmos_vs_o;
wire                                cmos_hs_o;

//*------------------------------------------------------------
//* HDMI 单倍时钟, 5倍时钟以及TMDS信号
//*------------------------------------------------------------
wire                                hdmi_clk_1x;
wire                                hdmi_clk_5x;
wire                                vtc_pll_lock;
wire                                O_HDMI_CLK_P;
wire    [2 : 0]                     O_HDMI_TX_P;
//*------------------------------------------------------------
//* 视频帧信号
//*------------------------------------------------------------
wire 					            vid_clk = hdmi_clk_1x; // 视频时钟
wire 					            vid_vs; // 视频帧同步信号
wire 					            vid_hs; // 视频行同步信号
wire 					            vid_de; // 视频数据流有效信号
wire                                vtc2_de; // 视频区域有效信号

//*------------------------------------------------------------
//* TPG测试数据
//*------------------------------------------------------------
wire                                O_tpg_vs; // TPG测试帧同步信号
wire                                O_tpg_hs; // TPG测试行同步信号
wire                                O_tpg_de; // TPG测试数据流有效信号
wire    [23 : 0]                    O_tpg_data; // TPG测试数据

//*------------------------------------------------------------
//* main_process
//*------------------------------------------------------------

//*------------------------------------------------------------
//* OV5640
//*------------------------------------------------------------
// OV5640配置模块
uicfg5640 #(
    .CLK_DIV 	(239  ))
u_uicfg5640(
    .clk_i     	(clk_50      ),
    .rst_n     	(rstn      ),
    .cmos_scl  	(cmos_scl   ),
    .cmos_sda  	(cmos_sda   ),
    .CAM_HSIZE 	('d512  ),
    .CAM_VSIZE 	('d384  ),
    .cfg_done  	(cfg_done   )
);
// OV5640时序转标准视频帧时序
uiSensorRGB565 uiSensorRGB565_inst
(
    .rstn_i(cfg_done),
    .cmos_clk_i(clk_50),//cmos senseor clock.
    .cmos_pclk_i(cmos_pclk),//input pixel clock.
    .cmos_href_i(cmos_href),//input pixel hs signal.
    .cmos_vsync_i(cmos_vsync),//input pixel vs signal.
    .cmos_data_i(cmos_data),//data.
    .cmos_xclk_o(),//output clock to cmos sensor.
    .rgb565_o(cmos_rgb_o),
    .de_o(cmos_de_o),
    .vs_o(cmos_vs_o),
    .hs_o(cmos_hs_o)
);
assign cmos_reset = 1'b1;
assign cmos_pwdn = 1'b0;

//*------------------------------------------------------------
//* HDMI
//*------------------------------------------------------------
// 产生HDMI时钟
PLL_HDMI_CLK u_PLL_HDMI_CLK(
    .refclk(clk_50),
    .reset(1'b0),
    .extlock(vtc_pll_lock),
    .clk0_out(hdmi_clk_1x),
    .clk1_out(hdmi_clk_5x) 
);
// 产生视频帧时序
uivtc#(
    .H_ActiveSize(`H_DISP),          //视频时间参数,行视频信号，一行有效(需要显示的部分)像素所占的时钟数，一个时钟对应一个有效像素
    .H_SyncStart(`H_DISP+`H_BP),        //视频时间参数,行同步开始，即多少时钟数后开始产生行同步信号 
    .H_SyncEnd(`H_DISP+`H_BP+`H_SYNC),       //视频时间参数,行同步结束，即多少时钟数后停止产生行同步信号，之后就是行有效数据部分
    .H_FrameSize(`H_DISP+`H_BP+`H_SYNC+`H_FP), //视频时间参数,行视频信号，一行视频信号总计占用的时钟数
    .V_ActiveSize(`V_DISP),          //视频时间参数,场视频信号，一帧图像所占用的有效(需要显示的部分)行数量，通常说的视频分辨率即H_ActiveSize*V_ActiveSize
    .V_SyncStart(`V_DISP+`V_BP),         //视频时间参数,场同步开始，即多少行数后开始产生场同步信号 
    .V_SyncEnd (`V_DISP+`V_BP+`V_SYNC),        //视频时间参数,场同步结束，多少行后停止产生长同步信号
    .V_FrameSize(`V_DISP+`V_BP+`V_SYNC+`V_FP),     //视频时间参数,场视频信号，一帧视频信号总计占用的行数量    
    .H2_ActiveSize('d512),
    .V2_ActiveSize('d384)
) uivtc_inst(
    .I_vtc_rstn(vtc_pll_lock),
    .I_vtc_clk(vid_clk),
    .O_vtc_vs(vid_vs),//场同步输出
    .O_vtc_hs(vid_hs),//行同步输出
    .O_vtc_de(vid_de),//视频数据有效
    .vtc2_offset_x('d0),
    .vtc2_offset_y('d0),
    .vtc2_de_o(vtc2_de)
);
// TPG测试数据
uitpg_static u_uitpg(
    .I_tpg_clk(vid_clk),
    .I_tpg_rstn(vtc_pll_lock),
    .I_tpg_vs(vid_vs),
    .I_tpg_hs(vid_hs),
    .I_tpg_de(vid_de),
    .O_tpg_vs(O_tpg_vs),
    .O_tpg_hs(O_tpg_hs),
    .O_tpg_de(O_tpg_de),
    .O_tpg_data(O_tpg_data),
    .dis_mode('d15)
);
// HDMI TX
uihdmitx#(
    .FAMILY("EG4")			
) uihdmitx_inst(
    .RSTn_i(vtc_pll_lock),
    .HS_i(O_tpg_hs),
    .VS_i(O_tpg_vs),
    .DE_i(O_tpg_de),
    .RGB_i(vtc2_de ? O_tpg_data : 24'hFFFFFF),
    .PCLKX1_i(hdmi_clk_1x),
    .PCLKX5_i(hdmi_clk_5x),
    .HDMI_CLK_P(O_HDMI_CLK_P),
    .HDMI_TX_P(O_HDMI_TX_P)
);
assign HDMI_CLK_P = O_HDMI_CLK_P;
assign HDMI_CLK_N = O_HDMI_CLK_P;
assign HDMI_D2_P = O_HDMI_TX_P[2];
assign HDMI_D2_N = O_HDMI_TX_P[2];
assign HDMI_D1_P = O_HDMI_TX_P[1];
assign HDMI_D1_N = O_HDMI_TX_P[1];
assign HDMI_D0_P = O_HDMI_TX_P[0];
assign HDMI_D0_N = O_HDMI_TX_P[0];
endmodule