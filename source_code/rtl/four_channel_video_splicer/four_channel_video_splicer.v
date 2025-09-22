module four_channel_video_splicer
#(
    parameter  integer                   AXI_DATA_WIDTH = 32,    //AXI总线数据位宽
	parameter  integer                   AXI_ADDR_WIDTH = 23,    //AXI总线地址位宽
    parameter  integer                   VID_DATA_WIDTH = 16
)(
    input   wire                            fdma_clk0,
    input   wire                            sdr_init_done,
    //////////////////////////////////////////////////////////////////////////////////////
    // 四路输入视频信号
    // #1
    input   wire                            vid_clk1,
    input   wire                            vid_vs1,
    input   wire                            vid_de1,
    input   wire    [VID_DATA_WIDTH-1:0]    vid_data1,

    // #2
    input   wire                            vid_clk2,
    input   wire                            vid_vs2,
    input   wire                            vid_de2,
    input   wire    [VID_DATA_WIDTH-1:0]    vid_data2,

    // #3
    input   wire                            vid_clk3,
    input   wire                            vid_vs3,
    input   wire                            vid_de3,
    input   wire    [VID_DATA_WIDTH-1:0]    vid_data3,

    // #4
    input   wire                            vid_clk4,
    input   wire                            vid_vs4,
    input   wire                            vid_de4,
    input   wire    [VID_DATA_WIDTH-1:0]    vid_data4,

    //////////////////////////////////////////////////////////////////////////////////////
    // 单路输出视频信号
    input   wire                            vid_clk,
    input   wire                            vid_vs,
    input   wire                            vid_de,
    output  wire    [VID_DATA_WIDTH-1:0]    vid_data,

    //////////////////////////////////////////////////////////////////////////////////////
    // 单路FDMA读写信号
    output  wire    [AXI_ADDR_WIDTH-1'b1: 0]    fdma_waddr,
    output  wire                                fdma_wareq,
    output  wire    [15  :0]                    fdma_wsize,                                     
    input   wire                                fdma_wbusy,
    output  wire    [AXI_DATA_WIDTH-1'b1:0]     fdma_wdata, //wdata要立刻输出
    input   wire                                fdma_wvalid,

    output  wire    [AXI_ADDR_WIDTH-1'b1:0]     fdma_raddr,
    output  wire                                fdma_rareq,
    output  wire    [15  :0]                    fdma_rsize,
    input   wire                                fdma_rbusy,
    input   wire    [AXI_DATA_WIDTH-1'b1:0]     fdma_rdata,
    input   wire                                fdma_rvalid
);

wire                            ds_vid_clk1 = vid_clk1;
wire                            ds_vid_vs1;
wire                            ds_vid_de1;
wire    [VID_DATA_WIDTH-1:0]    ds_vid_data1;

wire                            ds_vid_clk2 = vid_clk2;
wire                            ds_vid_vs2;
wire                            ds_vid_de2;
wire    [VID_DATA_WIDTH-1:0]    ds_vid_data2;

wire                            ds_vid_clk3 = vid_clk3;
wire                            ds_vid_vs3;
wire                            ds_vid_de3;
wire    [VID_DATA_WIDTH-1:0]    ds_vid_data3;

wire                            ds_vid_clk4 = vid_clk4;
wire                            ds_vid_vs4;
wire                            ds_vid_de4;
wire    [VID_DATA_WIDTH-1:0]    ds_vid_data4;

uidown_sample u_uidown_sample1(
    .I_clk(vid_clk1),
    .I_rstn(sdr_init_done),
    .I_vid_vs(vid_vs1),
    .I_vid_de(vid_de1),
    .I_vid_data(vid_data1),
    .O_vid_vs(ds_vid_vs1),
    .O_vid_de(ds_vid_de1),
    .O_vid_data(ds_vid_data1)
);

uidown_sample u_uidown_sample2(
    .I_clk(vid_clk2),
    .I_rstn(sdr_init_done),
    .I_vid_vs(vid_vs2),
    .I_vid_de(vid_de2),
    .I_vid_data(vid_data2),
    .O_vid_vs(ds_vid_vs2),
    .O_vid_de(ds_vid_de2),
    .O_vid_data(ds_vid_data2)
);

uidown_sample u_uidown_sample3(
    .I_clk(vid_clk3),
    .I_rstn(sdr_init_done),
    .I_vid_vs(vid_vs3),
    .I_vid_de(vid_de3),
    .I_vid_data(vid_data3),
    .O_vid_vs(ds_vid_vs3),
    .O_vid_de(ds_vid_de3),
    .O_vid_data(ds_vid_data3)
);

uidown_sample u_uidown_sample4(
    .I_clk(vid_clk4),
    .I_rstn(sdr_init_done),
    .I_vid_vs(vid_vs4),
    .I_vid_de(vid_de4),
    .I_vid_data(vid_data4),
    .O_vid_vs(ds_vid_vs4),
    .O_vid_de(ds_vid_de4),
    .O_vid_data(ds_vid_data4)
);

wire    [7 : 0]                     W_sync_cnt_o1;
wire    [7 : 0]                     R_buf_i;
wire    [AXI_ADDR_WIDTH-1'b1: 0]    fdma_waddr1;
wire                                fdma_wareq1;
wire    [15  :0]                    fdma_wsize1;                                     
wire                                fdma_wbusy1;
wire    [AXI_DATA_WIDTH-1'b1:0]     fdma_wdata1; //wdata要立刻输出
wire                                fdma_wvalid1;

uisetvbuf uisetvbuf_i
(
    .ui_clk(fdma_clk0),
    .bufn_i(W_sync_cnt_o1),
    .bufn_o(R_buf_i)
);

uidbuf #(
    .SDRAM_MAX_BURST_LEN 	(256                ),
    .VIDEO_ENABLE        	(1                  ),
    .ENABLE_WRITE        	(1                  ),
    .ENABLE_READ         	(1                  ),
    .AXI_DATA_WIDTH      	(32                 ),
    .AXI_ADDR_WIDTH      	(23                 ),
    
    .W_BUFDEPTH          	(1024               ),
    .W_DATAWIDTH         	(16                 ),
    .W_BASEADDR          	(0                  ),
    .W_DSIZEBITS         	(21                 ),
    .W_XSIZE             	(512                ),
    .W_YSIZE             	(384                ),
    .W_BUFSIZE           	(3                  ),
    .W_XSTRIDE           	(512                ),

    .R_BUFDEPTH          	(2048               ),
    .R_DATAWIDTH         	(16                 ),
    .R_BASEADDR          	(0                  ),
    .R_DSIZEBITS         	(21                 ),
    .R_XSIZE             	(1024               ),
    .R_YSIZE             	(768                ),
    .R_BUFSIZE           	(3                  ),
    .R_XSTRIDE           	(0                  ))
u_uidbuf_1(
    .ui_clk       	(fdma_clk0     ),
    .ui_rstn      	(sdr_init_done ),
    .W_wclk_i     	(ds_vid_clk1   ),
    .W_FS_i       	(ds_vid_vs1    ),
    .W_wren_i     	(ds_vid_de1    ),
    .W_data_i     	(ds_vid_data1  ),
    .W_sync_cnt_o 	(W_sync_cnt_o1 ),
    .W_buf_i      	(W_sync_cnt_o1 ),

    .fdma_waddr   	(fdma_waddr1    ),
    .fdma_wareq   	(fdma_wareq1    ),
    .fdma_wsize   	(fdma_wsize1    ),
    .fdma_wbusy   	(fdma_wbusy1    ),
    .fdma_wdata   	(fdma_wdata1    ),
    .fdma_wvalid  	(fdma_wvalid1   ),

    .R_rclk_i     	(vid_clk       ),
    .R_FS_i       	(vid_vs        ),
    .R_rden_i     	(vid_de        ),
    .R_data_o     	(vid_data      ),
    .R_buf_i      	(R_buf_i       ),

    .fdma_raddr   	(fdma_raddr    ),
    .fdma_rareq   	(fdma_rareq    ),
    .fdma_rsize   	(fdma_rsize    ),
    .fdma_rbusy   	(fdma_rbusy    ),
    .fdma_rdata   	(fdma_rdata    ),
    .fdma_rvalid  	(fdma_rvalid   )
);

wire    [7 : 0]                     W_sync_cnt_o2;
wire    [AXI_ADDR_WIDTH-1'b1: 0]    fdma_waddr2;
wire                                fdma_wareq2;
wire    [15  :0]                    fdma_wsize2;                                     
wire                                fdma_wbusy2;
wire    [AXI_DATA_WIDTH-1'b1:0]     fdma_wdata2; //wdata要立刻输出
wire                                fdma_wvalid2;
uidbuf #(
    .SDRAM_MAX_BURST_LEN 	(256                ),
    .VIDEO_ENABLE        	(1                  ),
    .ENABLE_WRITE        	(1                  ),
    .ENABLE_READ         	(0                  ),
    .AXI_DATA_WIDTH      	(32                 ),
    .AXI_ADDR_WIDTH      	(23                 ),
    
    .W_BUFDEPTH          	(1024               ),
    .W_DATAWIDTH         	(16                 ),
    .W_BASEADDR          	(512*2              ),
    .W_DSIZEBITS         	(21                 ),
    .W_XSIZE             	(512                ),
    .W_YSIZE             	(384                ),
    .W_BUFSIZE           	(3                  ),
    .W_XSTRIDE           	(512                ))
u_uidbuf_2(
    .ui_clk       	(fdma_clk0     ),
    .ui_rstn      	(sdr_init_done ),
    .W_wclk_i     	(ds_vid_clk2   ),
    .W_FS_i       	(ds_vid_vs2    ),
    .W_wren_i     	(ds_vid_de2    ),
    .W_data_i     	(ds_vid_data2  ),
    .W_sync_cnt_o 	(W_sync_cnt_o2 ),
    .W_buf_i      	(W_sync_cnt_o2 ),

    .fdma_waddr   	(fdma_waddr2    ),
    .fdma_wareq   	(fdma_wareq2    ),
    .fdma_wsize   	(fdma_wsize2    ),
    .fdma_wbusy   	(fdma_wbusy2    ),
    .fdma_wdata   	(fdma_wdata2    ),
    .fdma_wvalid  	(fdma_wvalid2   )
);

wire    [7 : 0]                     W_sync_cnt_o3;
wire    [AXI_ADDR_WIDTH-1'b1: 0]    fdma_waddr3;
wire                                fdma_wareq3;
wire    [15  :0]                    fdma_wsize3;                                     
wire                                fdma_wbusy3;
wire    [AXI_DATA_WIDTH-1'b1:0]     fdma_wdata3; //wdata要立刻输出
wire                                fdma_wvalid3;
uidbuf #(
    .SDRAM_MAX_BURST_LEN 	(256                ),
    .VIDEO_ENABLE        	(1                  ),
    .ENABLE_WRITE        	(1                  ),
    .ENABLE_READ         	(0                  ),
    .AXI_DATA_WIDTH      	(32                 ),
    .AXI_ADDR_WIDTH      	(23                 ),
    
    .W_BUFDEPTH          	(1024               ),
    .W_DATAWIDTH         	(16                 ),
    .W_BASEADDR          	(1024*384*2         ),
    .W_DSIZEBITS         	(21                 ),
    .W_XSIZE             	(512                ),
    .W_YSIZE             	(384                ),
    .W_BUFSIZE           	(3                  ),
    .W_XSTRIDE           	(512                ))
u_uidbuf_3(
    .ui_clk       	(fdma_clk0     ),
    .ui_rstn      	(sdr_init_done ),
    .W_wclk_i     	(ds_vid_clk3   ),
    .W_FS_i       	(ds_vid_vs3    ),
    .W_wren_i     	(ds_vid_de3    ),
    .W_data_i     	(ds_vid_data3  ),
    .W_sync_cnt_o 	(W_sync_cnt_o3 ),
    .W_buf_i      	(W_sync_cnt_o3 ),

    .fdma_waddr   	(fdma_waddr3    ),
    .fdma_wareq   	(fdma_wareq3    ),
    .fdma_wsize   	(fdma_wsize3    ),
    .fdma_wbusy   	(fdma_wbusy3    ),
    .fdma_wdata   	(fdma_wdata3    ),
    .fdma_wvalid  	(fdma_wvalid3   )
);

wire    [7 : 0]                     W_sync_cnt_o4;
wire    [AXI_ADDR_WIDTH-1'b1: 0]    fdma_waddr4;
wire                                fdma_wareq4;
wire    [15  :0]                    fdma_wsize4;                                     
wire                                fdma_wbusy4;
wire    [AXI_DATA_WIDTH-1'b1:0]     fdma_wdata4; //wdata要立刻输出
wire                                fdma_wvalid4;
uidbuf #(
    .SDRAM_MAX_BURST_LEN 	(256                ),
    .VIDEO_ENABLE        	(1                  ),
    .ENABLE_WRITE        	(1                  ),
    .ENABLE_READ         	(0                  ),
    .AXI_DATA_WIDTH      	(32                 ),
    .AXI_ADDR_WIDTH      	(23                 ),
    
    .W_BUFDEPTH          	(1024               ),
    .W_DATAWIDTH         	(16                 ),
    .W_BASEADDR          	(1024*384*2+512*2   ),
    .W_DSIZEBITS         	(21                 ),
    .W_XSIZE             	(512                ),
    .W_YSIZE             	(384                ),
    .W_BUFSIZE           	(3                  ),
    .W_XSTRIDE           	(512                ))
u_uidbuf_4(
    .ui_clk       	(fdma_clk0     ),
    .ui_rstn      	(sdr_init_done ),
    .W_wclk_i     	(ds_vid_clk4   ),
    .W_FS_i       	(ds_vid_vs4    ),
    .W_wren_i     	(ds_vid_de4    ),
    .W_data_i     	(ds_vid_data4  ),
    .W_sync_cnt_o 	(W_sync_cnt_o4 ),
    .W_buf_i      	(W_sync_cnt_o4 ),

    .fdma_waddr   	(fdma_waddr4    ),
    .fdma_wareq   	(fdma_wareq4    ),
    .fdma_wsize   	(fdma_wsize4    ),
    .fdma_wbusy   	(fdma_wbusy4    ),
    .fdma_wdata   	(fdma_wdata4    ),
    .fdma_wvalid  	(fdma_wvalid4   )
);


uidbufw_interconnect #(
    .AXI_DATA_WIDTH 	(32                       ),
    .AXI_ADDR_WIDTH 	(23                       ))
u_uidbufw_interconnect(
    .ui_clk        	(fdma_clk0      ),
    .ui_rstn       	(sdr_init_done  ),
    .fdma_waddr_1  	(fdma_waddr1   ),
    .fdma_wareq_1  	(fdma_wareq1   ),
    .fdma_wsize_1  	(fdma_wsize1   ),
    .fdma_wbusy_1  	(fdma_wbusy1   ),
    .fdma_wdata_1  	(fdma_wdata1   ),
    .fdma_wvalid_1 	(fdma_wvalid1  ),
    .fdma_waddr_2  	(fdma_waddr2   ),
    .fdma_wareq_2  	(fdma_wareq2   ),
    .fdma_wsize_2  	(fdma_wsize2   ),
    .fdma_wbusy_2  	(fdma_wbusy2   ),
    .fdma_wdata_2  	(fdma_wdata2   ),
    .fdma_wvalid_2 	(fdma_wvalid2  ),
    .fdma_waddr_3  	(fdma_waddr3   ),
    .fdma_wareq_3  	(fdma_wareq3   ),
    .fdma_wsize_3  	(fdma_wsize3   ),
    .fdma_wbusy_3  	(fdma_wbusy3   ),
    .fdma_wdata_3  	(fdma_wdata3   ),
    .fdma_wvalid_3 	(fdma_wvalid3  ),
    .fdma_waddr_4  	(fdma_waddr4   ),
    .fdma_wareq_4  	(fdma_wareq4   ),
    .fdma_wsize_4  	(fdma_wsize4   ),
    .fdma_wbusy_4  	(fdma_wbusy4   ),
    .fdma_wdata_4  	(fdma_wdata4   ),
    .fdma_wvalid_4 	(fdma_wvalid4  ),
    .fdma_waddr    	(fdma_waddr     ),
    .fdma_wareq    	(fdma_wareq     ),
    .fdma_wsize    	(fdma_wsize     ),
    .fdma_wbusy    	(fdma_wbusy     ),
    .fdma_wdata    	(fdma_wdata     ),
    .fdma_wvalid   	(fdma_wvalid    )
);

endmodule