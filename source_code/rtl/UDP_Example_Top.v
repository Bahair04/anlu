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
//* SDRAM
//*------------------------------------------------------------
// PLL
wire                                lock;
wire                                fdma_clk0;          // 150MHz
wire                                fdma_clk90; 
wire                                fdma_clk180;

wire           	                    W_wclk_i;
wire                                W_FS_i;
wire                                W_wren_i;
wire    [15 : 0]                    W_data_i;
wire    [7  : 0]                    W_sync_cnt_o;
wire    [7  : 0]                    W_buf_i;

wire           	                    R_rclk_i;
wire                                R_FS_i;
wire                                R_rden_i;
wire    [15 : 0]                    R_data_o;
wire    [7  : 0]                    R_buf_i;

wire    [20 : 0] 	                fdma_waddr;
wire  	     	                    fdma_wareq;
wire    [15 : 0] 	                fdma_wsize;                                    
wire         	                    fdma_wbusy;	
wire    [31 : 0] 	                fdma_wdata;
wire         	                    fdma_wvalid;

wire    [20 : 0] 	                fdma_raddr;
wire         	                    fdma_rareq;
wire    [15 : 0] 	                fdma_rsize;                                 
wire         	                    fdma_rbusy;
wire    [31 : 0] 	                fdma_rdata;
wire         	                    fdma_rvalid;

wire 			                    sdr_init_done;
wire 			                    sdr_init_ref_vld;
wire 			                    app_wr_en;
wire    [22 : 0]	                app_wr_addr;
wire    [1  : 0]	                app_wr_dm;
wire    [31 : 0]	                app_wr_din;
wire 			                    app_rd_en;
wire    [22 : 0]	                app_rd_addr;
wire 			                    sdr_rd_en;
wire    [31 : 0]	                sdr_rd_dout;
wire                                sdr_busy;

wire 						        CLK;
wire 						        CLKN;
wire 						        CS_N;
wire 						        CKE;
wire 						        RAS_N;
wire 						        CAS_N;
wire 						        WE_N;
wire    [`BA_WIDTH - 1 : 0]		    BA;
wire    [`ROW_WIDTH - 1 : 0]		ADDR;
wire    [`DM_WIDTH - 1 : 0]		    DM;
wire    [`DATA_WIDTH - 1 : 0]		DQ;

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
//* TPG
//*------------------------------------------------------------
// TPG测试数据
uitpg u_uitpg(
    .I_tpg_clk(vid_clk),
    .I_tpg_rstn(vtc_pll_lock),
    .I_tpg_vs(vid_vs),
    .I_tpg_hs(vid_hs),
    .I_tpg_de(vtc2_de),
    .O_tpg_vs(O_tpg_vs),
    .O_tpg_hs(O_tpg_hs),
    .O_tpg_de(O_tpg_de),
    .O_tpg_data(O_tpg_data)
);

//*------------------------------------------------------------
//* SDRAM
//*------------------------------------------------------------

// PLL
// 产生150MHz读写时钟
fdma_pll u_clk(
	.refclk             (clk_50      	),
	.reset              (!rstn    	    ),
	.extlock            (lock           ),
	.clk0_out           (fdma_clk0      ),		//150.000000MHZ	| 0  DEG 
	.clk1_out           (fdma_clk90     ),		//150.000000MHZ	| 90 DEG 
	.clk2_out           (fdma_clk180    )		//150.000000MHZ	| 180DEG 
);

uisetvbuf uisetvbuf_inst
(
    .ui_clk             (fdma_clk0      ),
    .bufn_i             (W_sync_cnt_o   ),
    .bufn_o             (R_buf_i        )
);  

wire [15:0] data_565;
ui888_565 u_ui888_565(
    .data_888 	(O_tpg_data  ),
    .data_565 	(data_565  )
);


assign      W_wclk_i = vid_clk;
assign      W_FS_i	 = vid_vs;
assign      W_wren_i = vtc2_de;
assign      W_data_i = data_565;
assign      W_buf_i  = W_sync_cnt_o;

assign      R_rclk_i = vid_clk;
assign      R_FS_i	 = vid_vs;
assign      R_rden_i = vtc2_de;
uidbuf#(
    .VIDEO_ENABLE 	 	(1)  ,
    .ENABLE_WRITE   	(1),
    .ENABLE_READ    	(1),
    .AXI_DATA_WIDTH 	(32),
    .AXI_ADDR_WIDTH 	(21),

    .W_BUFDEPTH     	(1024),
    .W_DATAWIDTH    	(32),
    .W_BASEADDR     	(0),
    .W_DSIZEBITS    	(19),
    .W_XSIZE        	(512),
    .W_YSIZE        	(384),
    .W_BUFSIZE      	(3),

    .R_BUFDEPTH     	(1024),
    .R_DATAWIDTH    	(32),
    .R_BASEADDR     	(0),
    .R_DSIZEBITS    	(19),
    .R_XSIZE        	(512),
    .R_YSIZE        	(384),
    .R_BUFSIZE      	(3)
)
uidbuf_inst
(
    .ui_clk			    (fdma_clk0    )
    ,.ui_rstn			(sdr_init_done   )
    //sensor input -W_FIFO--------------
    ,.W_wclk_i			(W_wclk_i    )
    ,.W_FS_i			(W_FS_i      )
    ,.W_wren_i			(W_wren_i    )
    ,.W_data_i			(W_data_i )
    ,.W_sync_cnt_o		(W_sync_cnt_o)
    ,.W_buf_i			(W_buf_i     )
    ,.W_full			()
    //----------fdma signals write-------       
    ,.fdma_waddr		(fdma_waddr  )
    ,.fdma_wareq		(fdma_wareq  )
    ,.fdma_wsize		(fdma_wsize  )                                     
    ,.fdma_wbusy		(fdma_wbusy  )		
    ,.fdma_wdata		(fdma_wdata  )
    ,.fdma_wvalid		(fdma_wvalid )
    ,.fdma_wready		(fdma_wready )
    ,.fmda_wbuf			()
    ,.fdma_wirq			()	
    //----------fdma signals read-------  
    ,.R_rclk_i			(R_rclk_i    )
    ,.R_FS_i			(R_FS_i      )
    ,.R_rden_i			(R_rden_i    )
    ,.R_data_o			(R_data_o    )
    ,.R_sync_cnt_o 		() 
    ,.R_buf_i			(R_buf_i     )
    ,.R_empty			()

    ,.fdma_raddr		(fdma_raddr  )
    ,.fdma_rareq		(fdma_rareq  )
    ,.fdma_rsize		(fdma_rsize  )                                   
    ,.fdma_rbusy		(fdma_rbusy  )	
    ,.fdma_rdata		(fdma_rdata  )
    ,.fdma_rvalid		(fdma_rvalid )
    ,.fdma_rready		(fdma_rready )
    ,.fmda_rbuf			()
    ,.fdma_rirq			()	
);    
//*******************app fdma controller********************
app_fdma app_fdma_inst
(
    .fdma_clk      	    (fdma_clk0     ) 	
    ,.fdma_rstn         (sdr_init_done	  )
    //===========fdma interface=======
    ,.fdma_waddr        (fdma_waddr   )
    ,.fdma_wareq        (fdma_wareq   )
    ,.fdma_wsize        (fdma_wsize   )                                     
    ,.fdma_wbusy        (fdma_wbusy   )
    ,.fdma_wdata		(fdma_wdata   )
    ,.fdma_wvalid       (fdma_wvalid  )


    ,.fdma_raddr        (fdma_raddr   )
    ,.fdma_rareq        (fdma_rareq   )
    ,.fdma_rsize        (fdma_rsize   )                                     
    ,.fdma_rbusy        (fdma_rbusy   )
    ,.fdma_rdata		(fdma_rdata   )
    ,.fdma_rvalid       (fdma_rvalid  )

    //===========ddr interface====================================
    ,.sdr_init_done   	(sdr_init_done)
    ,.sdr_init_ref_vld	(sdr_init_ref_vld)
        
    ,.app_wr_en       	(app_wr_en    )
    ,.app_wr_addr     	(app_wr_addr  ) 
    ,.app_wr_dm       	(app_wr_dm    )
    ,.app_wr_din     	(app_wr_din   )
        
    ,.app_rd_en       	(app_rd_en    )
    ,.app_rd_addr     	(app_rd_addr  )
    ,.sdr_rd_en       	(sdr_rd_en    )
    ,.sdr_rd_dout       (sdr_rd_dout  )
    ,.sdr_busy			(sdr_busy	  )
);
//////////////////////////////////////////////////////////////////////////////////////
// 将SDRAM控制器接口封装成类似于RAM接口的模块
// 用于简化上层逻辑对SDRAM的访问
sdr_as_ram  
#( 
	.self_refresh_open(1'b1)
) u2_ram( 
	.Sdr_clk(fdma_clk0),
	.Sdr_clk_sft(fdma_clk180),
	.Rst(~rstn),
						
	.Sdr_init_done(sdr_init_done),
	.Sdr_init_ref_vld(sdr_init_ref_vld),
	.Sdr_busy(sdr_busy),
	
	.App_ref_req(1'b0),
	
	.App_wr_en(app_wr_en), 
	.App_wr_addr(app_wr_addr),  	
	.App_wr_dm(app_wr_dm),
	.App_wr_din(app_wr_din),

	.App_rd_en(app_rd_en),
	.App_rd_addr(app_rd_addr),
	.Sdr_rd_en	(sdr_rd_en),
	.Sdr_rd_dout(sdr_rd_dout),

	.SDRAM_CLK(CLK),
	.SDR_RAS(RAS_N),
	.SDR_CAS(CAS_N),
	.SDR_WE(WE_N),
	.SDR_BA(BA),
	.SDR_ADDR(ADDR),
	.SDR_DM(DM),
	.SDR_DQ(DQ)	
);
//////////////////////////////////////////////////////////////////////////////////////
// 片内嵌入式SDRAM 只需例化IP核，而不用引出信号，即可对SDRAM进行读写操作
EG_PHY_SDRAM_2M_32 sdram(
	.clk(CLK),
	.ras_n(RAS_N),
	.cas_n(CAS_N),
	.we_n(WE_N),
	.addr(ADDR[10:0]),
	.ba(BA),
	.dq(DQ),
	.cs_n(1'b0),
	.dm0(DM[0]),
	.dm1(DM[1]),
	.dm2(DM[2]),
	.dm3(DM[3]),
	.cke(1'b1)
);
//*------------------------------------------------------------
//* HDMI
//*------------------------------------------------------------
// 产生HDMI时钟
PLL_HDMI_CLK u_PLL_HDMI_CLK(
    .refclk(clk_50),
    .reset(~lock),
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
wire [23:0] data_888;
ui565_888 #(
    .COMPLEMENT_ENABLE 	(1  ))
u_ui565_888(
    .data_565 	(R_data_o  ),
    .data_888 	(data_888  )
);

// HDMI TX
uihdmitx#(
    .FAMILY("EG4")			
) uihdmitx_inst(
    .RSTn_i(vtc_pll_lock),
    .HS_i(O_tpg_hs),
    .VS_i(O_tpg_vs),
    .DE_i(vid_de),
    .RGB_i(vtc2_de ? data_888 : 24'hFFFFFF),
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