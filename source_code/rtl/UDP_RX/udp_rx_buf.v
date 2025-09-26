//////////////////////////////////////////////////////////////////////////////////////
// Module Name: udp_rx_buf.v
// Description: UDP接收缓冲模块前与udp_top连接后与uid_buf连接 用于将app_rx_*接收信号转化为vtc标准信号
// 处理逻辑： 
//              1. IDLE 等待一帧图像数据的到来
//                 时刻捕获接收字节数据 组成32位校验帧头 用于判断是否为一帧图像数据 如果是 则进入接收状态
//              2. REC 接收一帧图像数据
// Author/Data: Bahair_, 2025/9/24
// Revision: 2025/9/24 V1.0 released 
// Copyright : Bahair_, Inc, All right reserved.
//////////////////////////////////////////////////////////////////////////////////////
module udp_rx_buf
#(
    parameter FRAME_HEAD =  32'hF3ED7A93,
    parameter DLY        = 'd200
)(
    input   wire                    rstn,

    input   wire                    app_rx_clk, // 125MHz
    input   wire                    app_rx_data_valid,
    input   wire    [7 : 0]         app_rx_data,
    input   wire    [15 : 0]        app_rx_data_length,
    input   wire    [24 : 0]        app_rx_data_total,

    output  wire                    vid_clk,
    output  reg                     vid_vs,
    output  reg                     vid_de,
    output  wire    [15 : 0]        vid_data
);

reg [31 : 0]            frame_head;

localparam              IDLE = 2'b01;
localparam              REC = 2'b10;
reg [1 : 0]             state;

reg [7 : 0]             app_rx_data_d [DLY : 0];
reg                     app_rx_data_valid_d [DLY : 0];
reg [24 : 0]            app_rx_data_cnt;

reg [9 : 0]             dly_cnt;

reg [15 : 0]            udp_data_cnt;
reg                     app_rx_data_en;
reg [1 : 0]             comb_data_cnt;
reg [15 : 0]            comb_data;


ChipWatcher_0 u_ChipWatcher_0(
    .probe0(app_rx_data),
    .probe1(app_rx_data_valid),
    .probe2(app_rx_data_length),
    .probe3(app_rx_data_total),
    .probe4(state),
    .probe5(app_rx_data_d[DLY]),
    .probe6(app_rx_data_cnt),
    .probe7(dly_cnt),
    .probe8(vid_de),
    .probe9(vid_vs),
    .probe10(vid_data),
    .clk(app_rx_clk)
);

always @(posedge app_rx_clk or negedge rstn) begin
    if (!rstn)
        frame_head <= 'd0;
    else if (app_rx_data_valid)
        frame_head <= {frame_head[23 : 0], app_rx_data}; 
end

always @(posedge app_rx_clk or negedge rstn) begin
    if (!rstn)
        state <= IDLE;
    else begin
        case (state)
        IDLE : begin
            if (frame_head == FRAME_HEAD)
                state <= REC;
            else 
                state <= IDLE;
        end
        REC : begin
            if (app_rx_data_cnt == app_rx_data_total - 1'b1)
                state <= IDLE;
            else 
                state <= REC;
        end
        default : state <= IDLE;
        endcase
    end
end

always @(posedge app_rx_clk or negedge rstn) begin : app_rx_data_delay
    integer i;
    if (!rstn) begin
        for (i = 0 ; i < DLY+1 ; i = i + 1) begin
            app_rx_data_d[i] <= 'd0;
            app_rx_data_valid_d[i] <= 1'b0;
        end
    end
    else begin
        for (i = 0 ; i < DLY ; i = i + 1) begin
            app_rx_data_d[i + 1] <= app_rx_data_d[i];
            app_rx_data_valid_d[i + 1] <= app_rx_data_valid_d[i];
        end
        app_rx_data_d[0] <= app_rx_data;
        app_rx_data_valid_d[0] <= app_rx_data_valid;
    end
end

always @(posedge app_rx_clk or negedge rstn) begin
    if (!rstn)
        udp_data_cnt <= 'd0;
    else if (app_rx_data_valid_d[DLY]) begin
        if (udp_data_cnt == app_rx_data_length - 1'b1)
            udp_data_cnt <= 'd0;
        else
            udp_data_cnt <= udp_data_cnt + 1'b1;
    end
    else 
        udp_data_cnt <= 'd0;
end


always @(posedge app_rx_clk or negedge rstn) begin
    if (!rstn)
        app_rx_data_cnt <= 'd0;
    else if (dly_cnt >= DLY && app_rx_data_valid_d[DLY]) begin
        if (app_rx_data_cnt == app_rx_data_total - 1'b1)
            app_rx_data_cnt <= 'd0;
        else
            app_rx_data_cnt <= app_rx_data_cnt + 1'b1;
    end
end
wire [7 : 0] app_rxdata = app_rx_data_d[DLY];
wire         app_rxdata_valid = app_rx_data_valid_d[DLY];
always @(posedge app_rx_clk or negedge rstn) begin
    if (!rstn)
        dly_cnt <= 'd0;
    else if (state == REC) begin
        if (dly_cnt == DLY+1)
            dly_cnt <= dly_cnt;
        else 
            dly_cnt <= dly_cnt + 11'b1;
    end     
    else 
        dly_cnt <= 'd0;
end

always @(posedge app_rx_clk or negedge rstn) begin
    if (!rstn)
        vid_vs <= 1'b0;
    else if (state == IDLE && frame_head == FRAME_HEAD)
        vid_vs <= 1'b1;
    else 
        vid_vs <= 1'b0;
end

always @(*) begin
    if (!rstn)
        app_rx_data_en <= 1'b0;
    else if (state == REC && dly_cnt >= DLY) 
        app_rx_data_en <= app_rx_data_valid_d[DLY];
    else 
        app_rx_data_en <= 1'b0;
end

always @(posedge app_rx_clk or negedge rstn) begin
    if (!rstn) begin
        comb_data_cnt <= 'd0;
        comb_data <= 'd0;
    end
    else begin
        if (app_rx_data_en) begin
            if (comb_data_cnt == 'd1)
                comb_data_cnt <= 'd0;
            else 
                comb_data_cnt <= comb_data_cnt + 1'b1;
            comb_data <= {comb_data[7 : 0], app_rx_data_d[DLY]};
        end 
    end
end

always @(posedge app_rx_clk or negedge rstn) begin
    if (!rstn)
        vid_de <= 1'b0;
    else if (state == REC && comb_data_cnt == 'd1 && app_rx_data_valid_d[DLY])
        vid_de <= 1'b1;
    else 
        vid_de <= 1'b0;
end

assign vid_data = vid_de ? comb_data : 'd0;
assign vid_clk = app_rx_clk;
endmodule
