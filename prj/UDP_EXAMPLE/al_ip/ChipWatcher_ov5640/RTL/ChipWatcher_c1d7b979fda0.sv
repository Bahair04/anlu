// synthesis syn_black_box 
module ChipWatcher_c1d7b979fda0 ( 
    input [0:0] probe0, 
    input [0:0] probe1, 
    input [0:0] probe2, 
    input [4:0] probe3, 
    input [5:0] probe4, 
    input [4:0] probe5, 
    input       clk  
);
    localparam string IP_TYPE  = "ChipWatcher";
    localparam CWC_BUS_NUM     = 6;
    localparam INPUT_PIPE_NUM  = 0;
    localparam OUTPUT_PIPE_NUM = 0;
    localparam RAM_DATA_DEPTH  = 16384;
    localparam CAPTURE_CONTROL = 0;

    localparam integer CWC_BUS_WIDTH   [CWC_BUS_NUM-1:0] = {1,1,1,5,6,5};
    localparam integer CWC_DATA_ENABLE [CWC_BUS_NUM-1:0] = {1,1,1,1,1,1};    
    localparam integer CWC_TRIG_ENABLE [CWC_BUS_NUM-1:0] = {1,1,1,1,1,1};    
endmodule



