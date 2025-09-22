module ChipWatcher_7244eeadc913 ( 
    input [15:0] probe0, 
    input [15:0] probe1, 
    input [0:0] probe2, 
    input [0:0] probe3, 
    input       clk  
);  
    localparam CWC_BUS_NUM = 4;
    localparam CWC_BUS_DIN_NUM = 34;
    localparam CWC_CTRL_LEN = 132;
	localparam CWC_BUS_CTRL_LEN = 112;
    localparam INPUT_PIPE_NUM = 0;
    localparam OUTPUT_PIPE_NUM = 0;
	localparam CWC_CAPTURE_CTRL_EXIST = 0;
    localparam RAM_LEN = 34;
    localparam RAM_DATA_DEPTH = 1024;
    localparam STAT_REG_LEN = 24;
    localparam integer CWC_BUS_WIDTH[0:CWC_BUS_NUM-1] = { 1,1,16,16 };
    localparam integer CWC_BUS_DIN_POS[0:CWC_BUS_NUM-1] = { 0,1,2,18 };    
    localparam integer CWC_BUS_CTRL_POS[0:CWC_BUS_NUM-1] = { 0,4,8,60 };

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
		.cwc_bus_din({probe0,probe1,probe2,probe3}),
		.ram_data_din({probe0,probe1,probe2,probe3})
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


