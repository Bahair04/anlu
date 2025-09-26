// synthesis syn_black_box 
module ChipWatcher_7244eeadc913 ( 
    input [7:0] probe0, 
    input [0:0] probe1, 
    input [15:0] probe2, 
    input [24:0] probe3, 
    input [1:0] probe4, 
    input [7:0] probe5, 
    input [24:0] probe6, 
    input [9:0] probe7, 
    input [0:0] probe8, 
    input [0:0] probe9, 
    input [15:0] probe10, 
    input       clk  
);
    localparam string IP_TYPE  = "ChipWatcher";
    localparam CWC_BUS_NUM     = 11;
    localparam INPUT_PIPE_NUM  = 0;
    localparam OUTPUT_PIPE_NUM = 0;
    localparam RAM_DATA_DEPTH  = 1024;
    localparam CAPTURE_CONTROL = 0;

    localparam integer CWC_BUS_WIDTH   [CWC_BUS_NUM-1:0] = {8,1,16,25,2,8,25,10,1,1,16};
    localparam integer CWC_DATA_ENABLE [CWC_BUS_NUM-1:0] = {1,1,1,1,1,1,1,1,1,1,1};    
    localparam integer CWC_TRIG_ENABLE [CWC_BUS_NUM-1:0] = {1,1,1,1,1,1,1,1,1,1,1};    
endmodule



