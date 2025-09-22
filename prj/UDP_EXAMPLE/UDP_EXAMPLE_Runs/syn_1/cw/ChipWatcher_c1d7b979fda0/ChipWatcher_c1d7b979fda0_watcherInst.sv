module ChipWatcher_c1d7b979fda0 ( 
    input [0:0] probe0, 
    input [0:0] probe1, 
    input [0:0] probe2, 
    input [4:0] probe3, 
    input [5:0] probe4, 
    input [4:0] probe5, 
    input       clk  
);  
    localparam CWC_BUS_NUM = 6;
    localparam CWC_BUS_DIN_NUM = 19;
    localparam CWC_CTRL_LEN = 92;
	localparam CWC_BUS_CTRL_LEN = 72;
    localparam INPUT_PIPE_NUM = 0;
    localparam OUTPUT_PIPE_NUM = 0;
	localparam CWC_CAPTURE_CTRL_EXIST = 0;
    localparam RAM_LEN = 19;
    localparam RAM_DATA_DEPTH = 16384;
    localparam STAT_REG_LEN = 24;
    localparam integer CWC_BUS_WIDTH[0:CWC_BUS_NUM-1] = { 5,6,5,1,1,1 };
    localparam integer CWC_BUS_DIN_POS[0:CWC_BUS_NUM-1] = { 0,5,11,16,17,18 };    
    localparam integer CWC_BUS_CTRL_POS[0:CWC_BUS_NUM-1] = { 0,19,41,60,64,68 };

    wire                     cwc_rst;
    wire [CWC_CTRL_LEN-1:0]  cwc_control;
    wire [STAT_REG_LEN-1:0]  cwc_status;  

	top_cwc_hub #(
		.CWC_BUS_NUM(CWC_BUS_NUM),
		.CWC_BUS_DIN_NUM(CWC_BUS_DIN_NUM),
		.CWC_CTRL_LEN(CWC_CTRL_LEN),
		.CWC_BUS_CTRL_LEN(CWC_BUS_CTRL_LEN),
		.CWC_BUS_WIDTH(CWC_BUS_WIDTH),
		.CWC_BUS_DIN_POS(CWC_BUS_DIN_POS),
		.CWC_BUS_CTRL_POS(CWC_BUS_CTRL_POS),
		.RAM_DATA_DEPTH(RAM_DATA_DEPTH),
		.CWC_CAPTURE_CTRL_EXIST(CWC_CAPTURE_CTRL_EXIST),
		.RAM_LEN(RAM_LEN),
		.INPUT_PIPE_NUM(INPUT_PIPE_NUM),
		.OUTPUT_PIPE_NUM(OUTPUT_PIPE_NUM)
	)

	 wrapper_cwc_top(
		.cwc_trig_clk(clk),
		.cwc_control(cwc_control),
		.cwc_status(cwc_status),
		.cwc_rst(cwc_rst),
		.cwc_bus_din({probe0,probe1,probe2,probe3,probe4,probe5}),
		.ram_data_din({probe0,probe1,probe2,probe3,probe4,probe5})
	);

    AL_LOGIC_DEBUGHUB #(
		.CTRL_LEN(CWC_CTRL_LEN),
		.STAT_LEN(STAT_REG_LEN)
	) wrapper_debughub(
		.clk(clk),
		.control(cwc_control),
		.status(cwc_status),
		.rst(cwc_rst)
	);

endmodule


