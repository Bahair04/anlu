//////////////////////////////////////////////////////////////////////////////////////
// Module Name: two_channel_video_splicer.b
// Description: ˫ͨ����Ƶ�źŶ�ģ�� ʹ������uidbuf����uidbufr_interconnectģ������ٲ� ���һ·fdma�źŵ�app_fdma
// Author/Data: Bahair_, 2025/9/27
// Revision: 2025/9/27 V1.0 released
// Copyright : Bahair_, Inc, All right reserved.
//////////////////////////////////////////////////////////////////////////////////////
module two_channel_video_splicer#(
    parameter  integer                   AXI_DATA_WIDTH = 32,    //AXI��������λ��
	parameter  integer                   AXI_ADDR_WIDTH = 23     //AXI���ߵ�ַλ��
)(
    input   wire                                fdma_clk0,
    input   wire                                sdr_init_done,

    input   wire                                vid_clk1,        // ��ʱ��
    input   wire                                vid_vs1,         // ��֡ͬ���ź� ��ʾһ֡�Ŀ�ʼ
    input   wire                                vid_de1,         // ��ʹ���ź� ���ȡ������ͬ��
    output  wire    [15 : 0]                    vid_data1,       // ������  
    input   wire    [7 : 0]                     R_buf_i,

    //////////////////////////////////////////////////////////////////////////////////////
    // ��·FDMA���ź�
    output  wire    [AXI_ADDR_WIDTH-1'b1:0]     fdma_raddr,
    output  wire                                fdma_rareq,
    output  wire    [15  :0]                    fdma_rsize,
    input   wire                                fdma_rbusy,
    input   wire    [AXI_DATA_WIDTH-1'b1:0]     fdma_rdata,
    input   wire                                fdma_rvalid
);

uidbuf #(
    .SDRAM_MAX_BURST_LEN 	(256                ),
    .VIDEO_ENABLE        	(1                  ),
    .ENABLE_WRITE        	(0                  ),
    .ENABLE_READ         	(1                  ),
    .AXI_DATA_WIDTH      	(AXI_DATA_WIDTH     ),
    .AXI_ADDR_WIDTH      	(AXI_ADDR_WIDTH     ),

    .R_BUFDEPTH          	(2048               ),
    .R_DATAWIDTH         	(16                 ),
    .R_BASEADDR          	(0                  ),
    .R_DSIZEBITS         	(21                 ),
    .R_XSIZE             	(1024               ),
    .R_YSIZE             	(768                ),
    .R_BUFSIZE           	(3                  ),
    .R_XSTRIDE           	('d0                )
)
u_uidbuf(
    .ui_clk       	(fdma_clk0     ),
    .ui_rstn      	(sdr_init_done ),

    .R_rclk_i     	(vid_clk1      ),
    .R_FS_i       	(vid_vs1        ),
    .R_rden_i     	(vid_de1      ),
    .R_data_o     	(vid_data1      ),
    .R_buf_i      	(R_buf_i       ),

    .fdma_raddr   	(fdma_raddr    ),
    .fdma_rareq   	(fdma_rareq    ),
    .fdma_rsize   	(fdma_rsize    ),
    .fdma_rbusy   	(fdma_rbusy    ),
    .fdma_rdata   	(fdma_rdata    ),
    .fdma_rvalid  	(fdma_rvalid   )
);

endmodule
