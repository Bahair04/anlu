module four_channel_video_splicer
#(
    parameter  integer                   AXI_DATA_WIDTH = 32,	//SDRAM数据位宽
	parameter  integer                   AXI_ADDR_WIDTH = 21	//SDRAM地址位宽
)(

    //////////////////////////////////////////////////////////////////////////////////////
    // 第一路
    input   wire                W_wclk_1,
    input   wire                W_FS_1,
    input   wire                W_wren_1,
    input   wire    [15 : 0]    W_data_1,

    input   wire                R_rclk_1, 
    input   wire                R_FS_1,
    input   wire                R_rden_1,
    output  wire    [15 : 0]    R_data_1, 
    //////////////////////////////////////////////////////////////////////////////////////
    // 第二路
    input   wire                W_wclk_2,
    input   wire                W_FS_2,
    input   wire                W_wren_2,
    input   wire    [15 : 0]    W_data_2,

    //////////////////////////////////////////////////////////////////////////////////////
    // 第三路
    input   wire                W_wclk_3,
    input   wire                W_FS_3,
    input   wire                W_wren_3,
    input   wire    [15 : 0]    W_data_3,

    //////////////////////////////////////////////////////////////////////////////////////
    // 第四路
    input   wire                W_wclk_4,
    input   wire                W_FS_4,
    input   wire                W_wren_4,
    input   wire    [15 : 0]    W_data_4,

    input   wire                fdma_clk,
    input   wire                sdr_init_done,
    input   wire                sdr_busy,

    output  reg     [AXI_ADDR_WIDTH - 1 : 0]            O_fdma_waddr,
    output  reg                                         O_fdma_wareq,
    output  reg     [16 - 1 : 0]                        O_fdma_wsize,
    output  reg     [AXI_DATA_WIDTH - 1 : 0]            O_fdma_wdata,
    output  reg                                         O_fdma_wready,
    input   wire                                        I_fdma_wbusy,
    input   wire                                        I_fdma_wvalid
);

wire 	[20 : 0] 					fdma_waddr1          ;
wire  	     						fdma_wareq1          ;
wire 	[15 : 0] 					fdma_wsize1          ;                                    
wire         						fdma_wbusy1          ;	
wire 	[31  :0] 					fdma_wdata1			 ;//synthesis keep
wire         						fdma_wvalid1         ;
							
wire 	[20 : 0] 					fdma_raddr1          ;
wire         						fdma_rareq1          ;
wire 	[15 : 0] 					fdma_rsize1          ;                                 
wire         						fdma_rbusy1          ;
wire 	[31  :0] 					fdma_rdata1			 ;
wire         						fdma_rvalid1         ;

wire 	[20 : 0] 					fdma_waddr2          ;
wire  	     						fdma_wareq2          ;
wire 	[15 : 0] 					fdma_wsize2          ;                                    
wire         						fdma_wbusy2          ;	
wire 	[31  :0] 					fdma_wdata2			 ;//synthesis keep
wire         						fdma_wvalid2         ;

wire 	[20 : 0] 					fdma_waddr3          ;
wire  	     						fdma_wareq3          ;
wire 	[15 : 0] 					fdma_wsize3          ;                                    
wire         						fdma_wbusy3          ;	
wire 	[31  :0] 					fdma_wdata3			 ;//synthesis keep
wire         						fdma_wvalid3         ;

uidbuf#(
    .APP_DATA_WIDTH 	(32)    ,
    .APP_ADDR_WIDTH 	(21)    ,

    .W_BUFDEPTH     	(1024)  ,
    .W_DATAWIDTH    	(16)    ,
    .W_BASEADDR     	(0)     ,
    .W_XSIZE        	(512)   ,
    .W_YSIZE        	(384)   ,
    .W_BUFSIZE        	(3)     ,

    .R_BUFDEPTH     	(2048)  ,
    .R_DATAWIDTH    	(16)    ,
    .R_BASEADDR     	(0)     ,
    .R_XSIZE        	(1024)  ,
    .R_YSIZE        	(768)   ,
    .R_BUFSIZE        	(3)     ,
    .USE_WFIFO          (1)     ,
    .USE_RFIFO          (1)     
)
uidbuf_inst_1
(
    .I_ui_clk		(fdma_clk    ),
    .I_ui_rstn		(sdr_init_done),
    .I_sdr_busy		(sdr_busy	 ),
    //----------sensor input -W_FIFO--------------
    .I_W_wclk		(W_wclk_1    ),
    .I_W_FS			(W_FS_1      ),
    .I_W_wren		(W_wren_1    ),
    .I_W_data		(W_data_1 	 ),	 
    //----------fdma signals write-------          
    .O_fdma_waddr	(fdma_waddr1  ),
    .O_fdma_wareq	(fdma_wareq1  ),
    .O_fdma_wsize	(fdma_wsize1  ),                                    
    .I_fdma_wbusy	(fdma_wbusy1  ),	
    .O_fdma_wdata	(fdma_wdata1  ),
    .I_fdma_wvalid	(fdma_wvalid1 ),
    //----------sensor input -W_FIFO--------------
    .I_R_rclk		(R_rclk_1    ),
    .I_R_FS			(R_FS_1      ),
    .I_R_rden		(R_rden_1    ),
    .O_R_data		(R_data_1    ),
    //----------fdma signals read-------  
    .O_fdma_raddr	(fdma_raddr1  ),
    .O_fdma_rareq	(fdma_rareq1  ),
    .O_fdma_rsize	(fdma_rsize1  ),                                  
    .I_fdma_rbusy	(fdma_rbusy1  ),
    .I_fdma_rdata	(fdma_rdata1  ),
    .I_fdma_rvalid	(fdma_rvalid1 )
); 

uidbuf#(
    .APP_DATA_WIDTH 	(32)    ,
    .APP_ADDR_WIDTH 	(21)    ,

    .W_BUFDEPTH     	(1024)  ,
    .W_DATAWIDTH    	(16)    ,
    .W_BASEADDR     	(0)     ,
    .W_XSIZE        	(512)   ,
    .W_YSIZE        	(384)   ,
    .W_BUFSIZE        	(3)     ,

    .USE_WFIFO          (1)     ,
    .USE_RFIFO          (0)     
)
uidbuf_inst_2
(
    .I_ui_clk		(fdma_clk    ),
    .I_ui_rstn		(sdr_init_done),
    .I_sdr_busy		(sdr_busy	 ),
    //----------sensor input -W_FIFO--------------
    .I_W_wclk		(W_wclk_2    ),
    .I_W_FS			(W_FS_2      ),
    .I_W_wren		(W_wren_2    ),
    .I_W_data		(W_data_2 	 ),	 
    //----------fdma signals write-------          
    .O_fdma_waddr	(fdma_waddr2  ),
    .O_fdma_wareq	(fdma_wareq2  ),
    .O_fdma_wsize	(fdma_wsize2  ),                                    
    .I_fdma_wbusy	(fdma_wbusy2  ),	
    .O_fdma_wdata	(fdma_wdata2  ),
    .I_fdma_wvalid	(fdma_wvalid2 )
); 

uidbuf#(
    .APP_DATA_WIDTH 	(32)    ,
    .APP_ADDR_WIDTH 	(21)    ,

    .W_BUFDEPTH     	(1024)  ,
    .W_DATAWIDTH    	(16)    ,
    .W_BASEADDR     	(0)     ,
    .W_XSIZE        	(512)   ,
    .W_YSIZE        	(384)   ,
    .W_BUFSIZE        	(3)     ,

    .USE_WFIFO          (1)     ,
    .USE_RFIFO          (0)     
)
uidbuf_inst_3
(
    .I_ui_clk		(fdma_clk    ),
    .I_ui_rstn		(sdr_init_done),
    .I_sdr_busy		(sdr_busy	 ),
    //----------sensor input -W_FIFO--------------
    .I_W_wclk		(W_wclk_3    ),
    .I_W_FS			(W_FS_3      ),
    .I_W_wren		(W_wren_3    ),
    .I_W_data		(W_data_3 	 ),	 
    //----------fdma signals write-------          
    .O_fdma_waddr	(fdma_waddr3  ),
    .O_fdma_wareq	(fdma_wareq3  ),
    .O_fdma_wsize	(fdma_wsize3  ),                                    
    .I_fdma_wbusy	(fdma_wbusy3  ),	
    .O_fdma_wdata	(fdma_wdata3  ),
    .I_fdma_wvalid	(fdma_wvalid3 )
); 

uidbuf#(
    .APP_DATA_WIDTH 	(32)    ,
    .APP_ADDR_WIDTH 	(21)    ,

    .W_BUFDEPTH     	(1024)  ,
    .W_DATAWIDTH    	(16)    ,
    .W_BASEADDR     	(0)     ,
    .W_XSIZE        	(512)   ,
    .W_YSIZE        	(384)   ,
    .W_BUFSIZE        	(3)     ,

    .USE_WFIFO          (1)     ,
    .USE_RFIFO          (0)     
)
uidbuf_inst_4
(
    .I_ui_clk		(fdma_clk    ),
    .I_ui_rstn		(sdr_init_done),
    .I_sdr_busy		(sdr_busy	 ),
    //----------sensor input -W_FIFO--------------
    .I_W_wclk		(W_wclk_4    ),
    .I_W_FS			(W_FS_4      ),
    .I_W_wren		(W_wren_4    ),
    .I_W_data		(W_data_4 	 ),	 
    //----------fdma signals write-------          
    .O_fdma_waddr	(fdma_waddr4  ),
    .O_fdma_wareq	(fdma_wareq4  ),
    .O_fdma_wsize	(fdma_wsize4  ),                                    
    .I_fdma_wbusy	(fdma_wbusy4  ),	
    .O_fdma_wdata	(fdma_wdata4  ),
    .I_fdma_wvalid	(fdma_wvalid4 )
); 
uidbufw_interconnect u_uidbufw_interconnect
(
    .I_fdma_clk(fdma_clk),
    .I_fdma_rstn(sdr_init_done),
    .I_fdma_waddr({fdma_waddr4, fdma_waddr3, fdma_waddr2, fdma_waddr1}),
    .I_fdma_wareq({fdma_wareq4, fdma_wareq3, fdma_wareq2, fdma_wareq1}),
    .I_fdma_wsize({fdma_wsize4, fdma_wsize3, fdma_wsize2, fdma_wsize1}),
    .O_fdma_wbusy({fdma_wbusy4, fdma_wbusy3, fdma_wbusy2, fdma_wbusy1}),
    .I_fdma_wdata({fdma_wdata4, fdma_wdata3, fdma_wdata2, fdma_wdata1}),
    .O_fdma_wvalid({fdma_wvalid4, fdma_wvalid3, fdma_wvalid2, fdma_wvalid1}),
    .O_fdma_waddr(O_fdma_waddr),
    .O_fdma_wareq(O_fdma_wareq),
    .O_fdma_wsize(O_fdma_wsize),
    .O_fdma_wdata(O_fdma_wdata),
    .I_fdma_wbusy(I_fdma_wbusy),
    .I_fdma_wvalid(I_fdma_wvalid)
    
);
endmodule