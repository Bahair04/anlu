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
`define   ADDR_WIDTH                        23										// 地址位宽 单位 字节
`define   APP_ADDR_WIDTH                    (`ADDR_WIDTH - 2)                       // SDR地址位宽 单位 字
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
        output  wire                        cmos_pwdn,

        //////////////////////////////////////////////////////////////////////////////////////
        // ETH UDP
        input   wire                        phy1_rgmii_rx_clk,                  // RGMI接收时钟
        input   wire                        phy1_rgmii_rx_ctl,                  // RGMI接收控制
        input   wire    [3 : 0]             phy1_rgmii_rx_data,                 // RGMI接收数据
                                
        output  wire                        phy1_rgmii_tx_clk,                  // RGMI发送时钟
        output  wire                        phy1_rgmii_tx_ctl,                  // RGMI发送控制
        output  wire    [3 : 0]             phy1_rgmii_tx_data                  // RGMI发送数据
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
wire    [23 : 0]                    O_tpg_data1; // TPG测试数据
wire    [23 : 0]                    O_tpg_data2; // TPG测试数据
wire    [23 : 0]                    O_tpg_data3; // TPG测试数据
wire    [23 : 0]                    O_tpg_data4; // TPG测试数据

//*------------------------------------------------------------
//* SDRAM
//*------------------------------------------------------------
// PLL
wire                                lock;
wire                                fdma_clk0;          // 150MHz
wire                                fdma_clk90; 
wire                                fdma_clk180;

wire    [`ADDR_WIDTH - 1 : 0]       fdma_waddr; // 单位 字节
wire  	     	                    fdma_wareq;
wire    [15 : 0] 	                fdma_wsize;                                    
wire         	                    fdma_wbusy;	
wire    [`DATA_WIDTH - 1 : 0]       fdma_wdata;
wire         	                    fdma_wvalid;

wire    [`ADDR_WIDTH - 1 : 0]       fdma_raddr; // 单位 字节
wire         	                    fdma_rareq;
wire    [15 : 0] 	                fdma_rsize;                                 
wire         	                    fdma_rbusy;
wire    [`DATA_WIDTH - 1 : 0]       fdma_rdata;
wire         	                    fdma_rvalid;

wire 			                    sdr_init_done;
wire 			                    sdr_init_ref_vld;
wire 			                    app_wr_en;
wire    [`APP_ADDR_WIDTH - 1 : 0]	app_wr_addr; // 单位 字
wire    [3  : 0]	                app_wr_dm;
wire    [`DATA_WIDTH - 1 : 0]       app_wr_din;
wire 			                    app_rd_en;
wire    [`APP_ADDR_WIDTH - 1 : 0]	app_rd_addr; // 单位 字
wire 			                    sdr_rd_en;
wire    [`DATA_WIDTH - 1 : 0]       sdr_rd_dout;
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
//* ETH UDP
//*------------------------------------------------------------

// IP地址与端口号
parameter  DEVICE             = "EG4";                          //"PH1","EG4"
parameter  LOCAL_UDP_PORT_NUM = 16'h0001;                       // 本地端口1
parameter  LOCAL_IP_ADDRESS   = 32'hc0a8f001;                   // 本地IP地址192.168.240.1
parameter  LOCAL_MAC_ADDRESS  = 48'h0123456789ab;               // 本地MAC地址(不重要)
parameter  DST_UDP_PORT_NUM   = 16'h0002;                       // 目的端口2
parameter  DST_IP_ADDRESS     = 32'hc0a8f002;                   // 目的IP地址192.168.240.2

// clk_gen
wire                                clk_125_out;
wire                                clk_12_5_out;
wire                                clk_1_25_out;
wire                                clk_25_out;
wire    [1 : 0]                     TRI_speed;
assign                              TRI_speed = 2'b10;          //千兆2'b10 百兆2'b01 十兆2'b00
wire                                reset_reg;                  // reset_reg: 锁相环输出lock信号

// udp_loopback <----> udp_ip_protocol_stack
wire                                app_rx_data_valid; 
wire    [7 : 0]                     app_rx_data;       
wire    [15 : 0]                    app_rx_data_length;
wire    [15 : 0]                    app_rx_port_num;

wire                                udp_tx_ready;
wire                                app_tx_ack;
wire                                app_tx_data_request;
wire                                app_tx_data_valid; 
wire    [7 : 0]                     app_tx_data;       
wire    [15 : 0]                    udp_data_length;

// temac_block
wire                                tx_stop;
wire    [7 : 0]                     tx_ifg_val;
wire                                pause_req;
wire    [15 : 0]                    pause_val;
wire    [47 : 0]                    pause_source_addr;
wire    [47 : 0]                    unicast_address;
wire    [19 : 0]                    mac_cfg_vector;  
//============================================================
// 参数配置逻辑
//============================================================
//需配置的客户端接口（初始默认值）
assign  tx_stop    = 1'b0;
assign  tx_ifg_val = 8'h00;
assign  pause_req  = 1'b0;
assign  pause_val  = 16'h0;
assign  pause_source_addr = 48'h5af1f2f3f4f5;
assign  unicast_address   = {   LOCAL_MAC_ADDRESS[7:0],
                                LOCAL_MAC_ADDRESS[15:8],
                                LOCAL_MAC_ADDRESS[23:16],
                                LOCAL_MAC_ADDRESS[31:24],
                                LOCAL_MAC_ADDRESS[39:32],
                                LOCAL_MAC_ADDRESS[47:40]
                            };
assign  mac_cfg_vector    = {1'b0,2'b00,TRI_speed,8'b00000010,7'b0000010}; //地址过滤模式、流控配置、速度配置、接收器配置、发送器配置

// tx_client_fifo
wire                                temac_tx_ready;
wire                                temac_tx_valid;
wire    [7 : 0]                     temac_tx_data; 
wire                                temac_tx_sof;
wire                                temac_tx_eof;

// rx_client_fifo
wire                                temac_rx_ready;
wire                                temac_rx_valid;
wire    [7 : 0]                     temac_rx_data; 
wire                                temac_rx_sof;
wire                                temac_rx_eof;

// temac <----> tx/rx_client_fifo
wire                                rx_correct_frame;       //synthesis keep
wire                                rx_error_frame;         //synthesis keep
wire                                rx_clk_int; 
wire                                rx_clk_en_int;
wire                                tx_clk_int; 
wire                                tx_clk_en_int;
wire                                temac_clk;              //synthesis keep
wire                                temac_clk90;
wire                                udp_clk;                //synthesis keep
wire                                rx_valid;               //synthesis keep
wire    [7 : 0]                     rx_data;                //synthesis keep 
wire    [7 : 0]                     tx_data;    
wire                                tx_valid;   
wire                                tx_rdy;         
wire                                tx_collision;   
wire                                tx_retransmit;
wire                                reset; 
reg     [7 : 0]                     soft_reset_cnt=8'hff;
assign                              reset = ~rstn || reset_reg || (soft_reset_cnt != 'd0);
always @(posedge udp_clk or negedge rstn) // 按键释放后延迟退出复位
begin
    if(~rstn)
        soft_reset_cnt<=8'hff;
    else if(soft_reset_cnt > 0)
        soft_reset_cnt<= soft_reset_cnt-1;
    else
        soft_reset_cnt<=soft_reset_cnt;
end




//*------------------------------------------------------------
//*------------------------------------------------------------
//* main_process
//*------------------------------------------------------------
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
uitpg u_uitpg_1(
    .I_tpg_clk(vid_clk),
    .I_tpg_rstn(vtc_pll_lock),
    .I_tpg_vs(vid_vs),
    .I_tpg_hs(vid_hs),
    .I_tpg_de(vid_de),
    .O_tpg_vs(O_tpg_vs),
    .O_tpg_hs(O_tpg_hs),
    .O_tpg_de(O_tpg_de),
    .O_tpg_data(O_tpg_data1)
);
uitpg_static u_uitpg_2(
    .I_tpg_clk(vid_clk),
    .I_tpg_rstn(vtc_pll_lock),
    .I_tpg_vs(vid_vs),
    .I_tpg_hs(vid_hs),
    .I_tpg_de(vid_de),
    .O_tpg_vs(O_tpg_vs),
    .O_tpg_hs(O_tpg_hs),
    .O_tpg_de(O_tpg_de),
    .O_tpg_data(O_tpg_data2),
    .dis_mode('d12)
);
uitpg_static u_uitpg_3(
    .I_tpg_clk(vid_clk),
    .I_tpg_rstn(vtc_pll_lock),
    .I_tpg_vs(vid_vs),
    .I_tpg_hs(vid_hs),
    .I_tpg_de(vid_de),
    .O_tpg_vs(O_tpg_vs),
    .O_tpg_hs(O_tpg_hs),
    .O_tpg_de(O_tpg_de),
    .O_tpg_data(O_tpg_data3),
    .dis_mode('d13)
);
uitpg u_uitpg_4(
    .I_tpg_clk(vid_clk),
    .I_tpg_rstn(vtc_pll_lock),
    .I_tpg_vs(vid_vs),
    .I_tpg_hs(vid_hs),
    .I_tpg_de(vid_de),
    .O_tpg_vs(O_tpg_vs),
    .O_tpg_hs(O_tpg_hs),
    .O_tpg_de(O_tpg_de),
    .O_tpg_data(O_tpg_data4)
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

wire [15:0] data_565_1;
wire [15:0] data_565_2;
wire [15:0] data_565_3;
wire [15:0] data_565_4;
ui888_565 u_ui888_565_1(
    .data_888 	(O_tpg_data1  ),
    .data_565 	(data_565_1  )
);
ui888_565 u_ui888_565_2(
    .data_888 	(O_tpg_data2  ),
    .data_565 	(data_565_2  )
);
ui888_565 u_ui888_565_3(
    .data_888 	(O_tpg_data3  ),
    .data_565 	(data_565_3  )
);
ui888_565 u_ui888_565_4(
    .data_888 	(O_tpg_data4  ),
    .data_565 	(data_565_4  )
);

wire [15:0]    	vid_data;

four_channel_video_splicer #(
	.AXI_DATA_WIDTH 	( 32  ),
	.AXI_ADDR_WIDTH 	( 23  ),
	.VID_DATA_WIDTH 	( 16  ))
u_four_channel_video_splicer(
	.fdma_clk0     	( fdma_clk0      ),
	.sdr_init_done 	( sdr_init_done  ),

	.vid_clk1      	( cmos_pclk       ),
	.vid_vs1       	( cmos_vs_o        ),
	.vid_de1       	( cmos_de_o        ),
	.vid_data1     	( cmos_rgb_o      ),
	.vid_clk2      	( cmos_pclk       ),
	.vid_vs2       	( cmos_vs_o        ),
	.vid_de2       	( cmos_de_o        ),
	.vid_data2     	( cmos_rgb_o      ),
	.vid_clk3      	( cmos_pclk       ),
	.vid_vs3       	( cmos_vs_o        ),
	.vid_de3       	( cmos_de_o        ),
	.vid_data3     	( cmos_rgb_o      ),
	.vid_clk4      	( cmos_pclk       ),
	.vid_vs4       	( cmos_vs_o        ),
	.vid_de4       	( cmos_de_o        ),
	.vid_data4     	( cmos_rgb_o      ),

	.vid_clk       	( vid_clk        ),
	.vid_vs        	( vid_vs         ),
	.vid_de        	( vid_de         ),
	.vid_data      	( vid_data       ),

	.fdma_waddr    	( fdma_waddr     ),
	.fdma_wareq    	( fdma_wareq     ),
	.fdma_wsize    	( fdma_wsize     ),
	.fdma_wbusy    	( fdma_wbusy     ),
	.fdma_wdata    	( fdma_wdata     ),
	.fdma_wvalid   	( fdma_wvalid    ),

	.fdma_raddr    	( fdma_raddr     ),
	.fdma_rareq    	( fdma_rareq     ),
	.fdma_rsize    	( fdma_rsize     ),
	.fdma_rbusy    	( fdma_rbusy     ),
	.fdma_rdata    	( fdma_rdata     ),
	.fdma_rvalid   	( fdma_rvalid    )
);

//*******************app fdma controller********************
app_fdma app_fdma_inst
(
    .fdma_clk      	    (fdma_clk0     ) 	
    ,.fdma_rstn         (sdr_init_done	  )
    //===========fdma interface=======
    ,.fdma_waddr        (fdma_waddr   ) // 单位 字节
    ,.fdma_wareq        (fdma_wareq   )
    ,.fdma_wsize        (fdma_wsize   )                                     
    ,.fdma_wbusy        (fdma_wbusy   )
    ,.fdma_wdata		(fdma_wdata   )
    ,.fdma_wvalid       (fdma_wvalid  )


    ,.fdma_raddr        (fdma_raddr   ) // 单位 字节
    ,.fdma_rareq        (fdma_rareq   )
    ,.fdma_rsize        (fdma_rsize   )                                     
    ,.fdma_rbusy        (fdma_rbusy   )
    ,.fdma_rdata		(fdma_rdata   )
    ,.fdma_rvalid       (fdma_rvalid  )

    //===========ddr interface====================================
    ,.sdr_init_done   	(sdr_init_done)
    ,.sdr_init_ref_vld	(sdr_init_ref_vld)
        
    ,.app_wr_en       	(app_wr_en    )
    ,.app_wr_addr     	(app_wr_addr  ) // 单位 字 
    ,.app_wr_dm       	(app_wr_dm    )
    ,.app_wr_din     	(app_wr_din   )
        
    ,.app_rd_en       	(app_rd_en    )
    ,.app_rd_addr     	(app_rd_addr  ) // 单位 字
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
    .H2_ActiveSize('d1023),
    .V2_ActiveSize('d768)
) uivtc_inst(
    .I_vtc_rstn(vtc_pll_lock),
    .I_vtc_clk(vid_clk),
    .O_vtc_vs(vid_vs),//场同步输出
    .O_vtc_hs(vid_hs),//行同步输出
    .O_vtc_de(vid_de),//视频数据有效
    .vtc2_offset_x('d1),
    .vtc2_offset_y('d0),
    .vtc2_de_o(vtc2_de)
);
wire [23:0] data_888;
ui565_888 #(
    .COMPLEMENT_ENABLE 	(1  ))
u_ui565_888(
    .data_565 	(vid_data  ),
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
    .RGB_i(vtc2_de ? data_888 : 24'h000000),
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

//*------------------------------------------------------------
//* ETH UDP
//*------------------------------------------------------------
//------------------------------------------------------------
//clk_gen
//------------------------------------------------------------
clk_gen_rst_gen#(                                   //产生三速时钟信号
    .DEVICE         (DEVICE     )
) 
u_clk_gen
(
    .reset          (~rstn      ),
    .clk_in         (clk_50     ),
    .rst_out        (reset_reg  ),
    .clk_125_out0   (temac_clk  ),
    .clk_125_out1   (clk_125_out),
    .clk_125_out2   (temac_clk90),
    .clk_12_5_out   (clk_12_5_out),
    .clk_1_25_out   (clk_1_25_out),
    .clk_25_out     (clk_25_out )
);
udp_clk_gen#(                                        //根据设备和速度选择一路时钟信号输出
    .DEVICE               (DEVICE                   )
)
u5_temac_clk_gen
(           
    .reset                (~rstn                    ),
    .tri_speed            (TRI_speed                ),
    .clk_125_in           (clk_125_out              ),//125M  
    .clk_12_5_in          (clk_12_5_out             ),//12.5M 
    .clk_1_25_in          (clk_1_25_out             ),//1.25M 
    .udp_clk_out          (udp_clk                  )
);

//------------------------------------------------------------
//udp_loopback
//------------------------------------------------------------
udp_loopback#(
    .DEVICE(DEVICE)
)
u2_udp_loopback
(
    .app_rx_clk                 (udp_clk                ),
    .app_tx_clk                 (udp_clk                ),
    .reset                      (reset                  ),

    .app_rx_data                (app_rx_data            ),
    .app_rx_data_valid          (app_rx_data_valid      ),
    .app_rx_data_length         (app_rx_data_length     ),
    
    .udp_tx_ready               (udp_tx_ready           ),
    .app_tx_ack                 (app_tx_ack             ),
    .app_tx_data                (app_tx_data            ),
    .app_tx_data_request        (app_tx_data_request    ),
    .app_tx_data_valid          (app_tx_data_valid      ),
    .udp_data_length            (udp_data_length        )   
);

//------------------------------------------------------------
//--------------            --------------                  --------------                  --------------                              
//|             |           |             |   --------      |             |                 |             |
//|             |           |             |  |rx_fifo|      |             |                 |   APP       |
//|             |           |             |  |-------|      |             |                 |             |              
//|    PHY      |  --->     | temac_      |    ----->       |   udp_ip_   |   ------->      | udp_loopback|              
//|             |  <---     | block       |    <-----       |   protocol  |   <------       | led         |
//|             |           |             |   --------      |   _stack    |                 |             |
//|             |           |             |  |tx_fifo|      |             |                 |             |
//|             |           |             |  |-------|      |             |                 |             |
//--------------            --------------                  --------------                  --------------
//------------------------------------------------------------

//------------------------------------------------------------  
//UDP
//------------------------------------------------------------       
udp_ip_protocol_stack #
(
    .DEVICE                     (DEVICE                 ),
    .LOCAL_UDP_PORT_NUM         (LOCAL_UDP_PORT_NUM     ),
    .LOCAL_IP_ADDRESS           (LOCAL_IP_ADDRESS       ),
    .LOCAL_MAC_ADDRESS          (LOCAL_MAC_ADDRESS      )
)   
u3_udp_ip_protocol_stack    
(   
    .udp_rx_clk                 (udp_clk                ),//input
    .udp_tx_clk                 (udp_clk                ),//input
    .reset                      (reset                  ),//input
    .udp2app_tx_ready           (udp_tx_ready           ),//output 
    .udp2app_tx_ack             (app_tx_ack             ),//output 
    .app_tx_request             (app_tx_data_request    ),//input 
    .app_tx_data_valid          (app_tx_data_valid      ),//input 
    .app_tx_data                (app_tx_data            ),//input 
    .app_tx_data_length         (udp_data_length        ),//input 
    .app_tx_dst_port            (DST_UDP_PORT_NUM       ),//input 
    .ip_tx_dst_address          (DST_IP_ADDRESS         ),//input 
    
    .input_local_udp_port_num      (LOCAL_UDP_PORT_NUM  ),//input
    .input_local_udp_port_num_valid(1'b1),                //input
    
    .input_local_ip_address     (32'hc0a8f001),           //input
    .input_local_ip_address_valid(1'b1),                  //input
    
    .app_rx_data_valid          (app_rx_data_valid      ),//output
    .app_rx_data                (app_rx_data            ),//output 
    .app_rx_data_length         (app_rx_data_length     ),//output
    .app_rx_port_num            (app_rx_port_num        ),//output 
    .temac_rx_ready             (temac_rx_ready         ),//output
    .temac_rx_valid             (!temac_rx_valid        ),//input
    .temac_rx_data              (temac_rx_data          ),//input
    .temac_rx_sof               (temac_rx_sof           ),//input
    .temac_rx_eof               (temac_rx_eof           ),//input
    .temac_tx_ready             (temac_tx_ready         ),//input
    .temac_tx_valid             (temac_tx_valid         ),//output
    .temac_tx_data              (temac_tx_data          ),//output
    .temac_tx_sof               (temac_tx_sof           ),//output
    .temac_tx_eof               (temac_tx_eof           ),//output

    .ip_rx_error                (                       ),//output
    .arp_request_no_reply_error (                       ) //output
);

//------------------------------------------------------------  
//TEMAC
//------------------------------------------------------------  
temac_block#(
    .DEVICE               (DEVICE                   )
)
u4_trimac_block
(
    .reset                (reset                    ),
    .gtx_clk              (temac_clk                ),//input   125M
    .gtx_clk_90           (temac_clk90              ),//input   125M
    .rx_clk               (rx_clk_int               ),//output  125M 25M    2.5M
    .rx_clk_en            (rx_clk_en_int            ),//output  1    12.5M  1.25M
    .rx_data              (rx_data                  ),
    .rx_data_valid        (rx_valid                 ),
    .rx_correct_frame     (rx_correct_frame         ),
    .rx_error_frame       (rx_error_frame           ),
    .rx_status_vector     (                         ),
    .rx_status_vld        (                         ),
//  .tri_speed            (tri_speed                       ),//output
    .tx_clk               (tx_clk_int               ),//output  125M
    .tx_clk_en            (tx_clk_en_int            ),//output  1    12.5M  1.25M 占空比不对
    .tx_data              (tx_data                  ),
    .tx_data_en           (tx_valid                 ),
    .tx_rdy               (tx_rdy                   ),//temac_tx_ready
    .tx_stop              (tx_stop                  ),//input
    .tx_collision         (tx_collision             ),
    .tx_retransmit        (tx_retransmit            ),
    .tx_ifg_val           (tx_ifg_val               ),//input
    .tx_status_vector     (                         ),
    .tx_status_vld        (                         ),
    .pause_req            (pause_req                ),//input
    .pause_val            (pause_val                ),//input
    .pause_source_addr    (pause_source_addr        ),//input
    .unicast_address      (unicast_address          ),//input
    .mac_cfg_vector       (mac_cfg_vector           ),//input
    .rgmii_txd            (phy1_rgmii_tx_data       ),
    .rgmii_tx_ctl         (phy1_rgmii_tx_ctl        ),
    .rgmii_txc            (phy1_rgmii_tx_clk        ),
    .rgmii_rxd            (phy1_rgmii_rx_data       ),
    .rgmii_rx_ctl         (phy1_rgmii_rx_ctl        ),
    .rgmii_rxc            (phy1_rgmii_rx_clk        ),
    .inband_link_status   (                         ),
    .inband_clock_speed   (                         ),
    .inband_duplex_status (                         )
);

//------------------------------------------------------------  
//tx_fifo
//------------------------------------------------------------  
tx_client_fifo#
(
    .DEVICE               (DEVICE                   )
)
u6_tx_fifo
(
    .rd_clk               (tx_clk_int               ),
    .rd_sreset            (reset                    ),
    .rd_enable            (tx_clk_en_int            ),
    .tx_data              (tx_data                  ),
    .tx_data_valid        (tx_valid                 ),
    .tx_ack               (tx_rdy                   ),
    .tx_collision         (tx_collision             ),
    .tx_retransmit        (tx_retransmit            ),
    .overflow             (                         ),
                            
    .wr_clk               (udp_clk                  ),
    .wr_sreset            (reset                    ),
    .wr_data              (temac_tx_data            ),
    .wr_sof_n             (temac_tx_sof             ),
    .wr_eof_n             (temac_tx_eof             ),
    .wr_src_rdy_n         (temac_tx_valid           ),
    .wr_dst_rdy_n         (temac_tx_ready           ),//temac_tx_ready
    .wr_fifo_status       (                         )
);

//------------------------------------------------------------  
//rx_fifo
//------------------------------------------------------------  
rx_client_fifo#
(
    .DEVICE               (DEVICE                   )
)
u7_rx_fifo                  
(                           
    .wr_clk               (rx_clk_int               ),
    .wr_enable            (rx_clk_en_int            ),
    .wr_sreset            (reset                    ),
    .rx_data              (rx_data                  ),
    .rx_data_valid        (rx_valid                 ),
    .rx_good_frame        (rx_correct_frame         ),
    .rx_bad_frame         (rx_error_frame           ),
    .overflow             (                         ),
    .rd_clk               (udp_clk                  ),
    .rd_sreset            (reset                    ),
    .rd_data_out          (temac_rx_data            ),//output reg [7:0] rd_data_out,
    .rd_sof_n             (temac_rx_sof             ),//output reg       rd_sof_n,
    .rd_eof_n             (temac_rx_eof             ),//output           rd_eof_n,
    .rd_src_rdy_n         (temac_rx_valid           ),//output reg       rd_src_rdy_n,
    .rd_dst_rdy_n         (temac_rx_ready           ),//input            rd_dst_rdy_n,
    .rx_fifo_status       (                         )
);
endmodule