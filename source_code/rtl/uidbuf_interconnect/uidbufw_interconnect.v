//////////////////////////////////////////////////////////////////////////////////////
// Module Name: uidbufw_interconnect.v
// Description: uidbuf写仲裁模块 多路FDMA输入 单路FDMA输出
// Author/Data: Bahair_, 2025/9/21
// Revision: 2025/9/21 V1.0 released
// Copyright : Bahair_, Inc, All right reserved.
//////////////////////////////////////////////////////////////////////////////////////
module uidbufw_interconnect
#(
    parameter  integer                   AXI_DATA_WIDTH = 32,	//SDRAM数据位宽
	parameter  integer                   AXI_ADDR_WIDTH = 21,	//SDRAM地址位宽
    parameter  integer                   MUX_NUM        = 4     // 输入通道数量
)(
    input   wire                                        I_fdma_clk,
    input   wire                                        I_fdma_rstn,

    //////////////////////////////////////////////////////////////////////////////////////
    // FDMA 接口 接收 MUX_NUM 个uidbuf的输出
    // 高位存uidbufw[MUX_NUM - 1] 低位存uidbufw[0]
    input   wire    [MUX_NUM * AXI_ADDR_WIDTH - 1 : 0]  I_fdma_waddr,
    input   wire    [MUX_NUM - 1 : 0]                   I_fdma_wareq,
    input   wire    [MUX_NUM * 16 - 1 : 0]              I_fdma_wsize,
    output  reg     [MUX_NUM - 1 : 0]                   O_fdma_wbusy,
    input   wire    [MUX_NUM * AXI_DATA_WIDTH - 1 : 0]  I_fdma_wdata,
    input   wire    [MUX_NUM - 1 : 0]                   I_fdma_wready,
    output  reg     [MUX_NUM - 1 : 0]                   O_fdma_wvalid,

    //////////////////////////////////////////////////////////////////////////////////////
    // FDMA 接口 仲裁后发送 一个fdma信号给app_fdma模块
    output  reg     [AXI_ADDR_WIDTH - 1 : 0]            O_fdma_waddr,
    output  reg                                         O_fdma_wareq,
    output  reg     [16 - 1 : 0]                        O_fdma_wsize,
    output  reg     [AXI_DATA_WIDTH - 1 : 0]            O_fdma_wdata,
    output  reg                                         O_fdma_wready,
    input   wire                                        I_fdma_wbusy,
    input   wire                                        I_fdma_wvalid
);

localparam              IDLE = 0;
localparam              W_1  = 1;
localparam              W_2  = 2;
localparam              W_3  = 3;
localparam              W_4  = 4;
reg     [3 : 0]         state;

reg                     I_fdma_wbusy_d;
wire                    I_fdma_wbusy_neg_edge;
always @(posedge I_fdma_clk or negedge I_fdma_rstn) begin
    if (!I_fdma_rstn)
        I_fdma_wbusy_d <= 1'b0;
    else 
        I_fdma_wbusy_d <= I_fdma_wbusy;
end
assign I_fdma_wbusy_neg_edge = I_fdma_wbusy_d & ~I_fdma_wbusy;

reg [2:0] last_grant;

always @(posedge I_fdma_clk or negedge I_fdma_rstn) begin
    if (!I_fdma_rstn) begin
        state <= IDLE;
        last_grant <= 3'd0;
    end else begin
        case(state)
            IDLE: begin
                if (I_fdma_wareq[0] | I_fdma_wareq[1] | I_fdma_wareq[2] | I_fdma_wareq[3]) begin
                    // Round-robin arbitration
                    case (last_grant)
                        3'd0: if (I_fdma_wareq[0]) state <= W_1;
                              else if (I_fdma_wareq[1]) state <= W_2;
                              else if (I_fdma_wareq[2]) state <= W_3;
                              else if (I_fdma_wareq[3]) state <= W_4;
                        3'd1: if (I_fdma_wareq[1]) state <= W_2;
                              else if (I_fdma_wareq[2]) state <= W_3;
                              else if (I_fdma_wareq[3]) state <= W_4;
                              else if (I_fdma_wareq[0]) state <= W_1;
                        3'd2: if (I_fdma_wareq[2]) state <= W_3;
                              else if (I_fdma_wareq[3]) state <= W_4;
                              else if (I_fdma_wareq[0]) state <= W_1;
                              else if (I_fdma_wareq[1]) state <= W_2;
                        3'd3: if (I_fdma_wareq[3]) state <= W_4;
                              else if (I_fdma_wareq[0]) state <= W_1;
                              else if (I_fdma_wareq[1]) state <= W_2;
                              else if (I_fdma_wareq[2]) state <= W_3;
                        default: state <= IDLE;
                    endcase
                end
            end
            W_1: if (I_fdma_wbusy_neg_edge) begin state <= IDLE; last_grant <= 3'd0; end
            W_2: if (I_fdma_wbusy_neg_edge) begin state <= IDLE; last_grant <= 3'd1; end
            W_3: if (I_fdma_wbusy_neg_edge) begin state <= IDLE; last_grant <= 3'd2; end
            W_4: if (I_fdma_wbusy_neg_edge) begin state <= IDLE; last_grant <= 3'd3; end
        endcase
    end
end

always @(posedge I_fdma_clk or negedge I_fdma_rstn) begin
    if (!I_fdma_rstn) begin
        O_fdma_waddr <= 'd0;
        O_fdma_wareq <= 'b0; 
        O_fdma_wsize <= 'd0; 
        O_fdma_wready <= 'b0;
        {O_fdma_wbusy[3], O_fdma_wbusy[2], O_fdma_wbusy[1], O_fdma_wbusy[0]} <= 4'b0000;
    end
    else begin
        case (state)
            IDLE: begin
                O_fdma_waddr <= 'd0;
                O_fdma_wareq <= 'b0; 
                O_fdma_wsize <= 'd0; 
                O_fdma_wready <= 'b0;
                {O_fdma_wbusy[3], O_fdma_wbusy[2], O_fdma_wbusy[1], O_fdma_wbusy[0]} <= 4'b0000;
            end
            W_1 : begin
                O_fdma_waddr <= I_fdma_waddr[AXI_ADDR_WIDTH - 1 : 0];
                O_fdma_wareq <= I_fdma_wareq[0];
                O_fdma_wsize <= I_fdma_wsize[16 - 1 : 0];
                O_fdma_wready <= I_fdma_wready[0];
                {O_fdma_wbusy[3], O_fdma_wbusy[2], O_fdma_wbusy[1], O_fdma_wbusy[0]} <= {3'b000, I_fdma_wbusy};
            end
            W_2 : begin
                O_fdma_waddr <= I_fdma_waddr[2 * AXI_ADDR_WIDTH - 1 : AXI_ADDR_WIDTH];
                O_fdma_wareq <= I_fdma_wareq[1];
                O_fdma_wsize <= I_fdma_wsize[2 * 16 - 1 : 16];
                O_fdma_wready <= I_fdma_wready[1];
                {O_fdma_wbusy[3], O_fdma_wbusy[2], O_fdma_wbusy[1], O_fdma_wbusy[0]} <= {2'b00, I_fdma_wbusy, 1'b0};
            end
            W_3 : begin
                O_fdma_waddr <= I_fdma_waddr[3 * AXI_ADDR_WIDTH - 1 : 2 * AXI_ADDR_WIDTH];
                O_fdma_wareq <= I_fdma_wareq[2];
                O_fdma_wsize <= I_fdma_wsize[3 * 16 - 1 : 2 * 16];
                O_fdma_wready <= I_fdma_wready[2];
                {O_fdma_wbusy[3], O_fdma_wbusy[2], O_fdma_wbusy[1], O_fdma_wbusy[0]} <= {1'b0, I_fdma_wbusy, 2'b00};
            end
            W_4 : begin
                O_fdma_waddr <= I_fdma_waddr[4 * AXI_ADDR_WIDTH - 1 : 3 * AXI_ADDR_WIDTH];
                O_fdma_wareq <= I_fdma_wareq[3];
                O_fdma_wsize <= I_fdma_wsize[4 * 16 - 1 : 3 * 16];
                O_fdma_wready <= I_fdma_wready[3];
                {O_fdma_wbusy[3], O_fdma_wbusy[2], O_fdma_wbusy[1], O_fdma_wbusy[0]} <= {I_fdma_wbusy, 3'b000};
            end
            default : begin
                O_fdma_waddr <= 'd0;
                O_fdma_wareq <= 'b0; 
                O_fdma_wsize <= 'd0; 
                O_fdma_wready <= 'b0;
                {O_fdma_wbusy[3], O_fdma_wbusy[2], O_fdma_wbusy[1], O_fdma_wbusy[0]} <= 4'b0000;
            end
        endcase
    end
end

always @(*) begin
    case (state)
        IDLE: begin
            O_fdma_wdata <= 'd0;
            {O_fdma_wvalid[3], O_fdma_wvalid[2], O_fdma_wvalid[1], O_fdma_wvalid[0]} <= 4'b0000;
        end
        W_1 : begin
            O_fdma_wdata <= I_fdma_wdata[AXI_DATA_WIDTH - 1 : 0];
            {O_fdma_wvalid[3], O_fdma_wvalid[2], O_fdma_wvalid[1], O_fdma_wvalid[0]} <= {3'b000, I_fdma_wvalid};
        end
        W_2 : begin
            O_fdma_wdata <= I_fdma_wdata[2 * AXI_DATA_WIDTH - 1 : AXI_DATA_WIDTH];
            {O_fdma_wvalid[3], O_fdma_wvalid[2], O_fdma_wvalid[1], O_fdma_wvalid[0]} <= {2'b00, I_fdma_wvalid, 1'b0};
        end
        W_3 : begin
            O_fdma_wdata <= I_fdma_wdata[3 * AXI_DATA_WIDTH - 1 : 2 * AXI_DATA_WIDTH];
            {O_fdma_wvalid[3], O_fdma_wvalid[2], O_fdma_wvalid[1], O_fdma_wvalid[0]} <= {1'b0, I_fdma_wvalid, 2'b00};
        end
        W_4 : begin
            O_fdma_wdata <= I_fdma_wdata[4 * AXI_DATA_WIDTH - 1 : 3 * AXI_DATA_WIDTH];
            {O_fdma_wvalid[3], O_fdma_wvalid[2], O_fdma_wvalid[1], O_fdma_wvalid[0]} <= {I_fdma_wvalid, 3'b000};    
        end
        default : begin
            O_fdma_wdata <= 'd0;
            {O_fdma_wvalid[3], O_fdma_wvalid[2], O_fdma_wvalid[1], O_fdma_wvalid[0]} <= 4'b0000;
        end
    endcase
end

endmodule
