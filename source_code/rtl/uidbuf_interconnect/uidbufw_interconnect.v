//////////////////////////////////////////////////////////////////////////////////////
// Module Name: uidbufw_interconnect.v
// Description: uidbufд�ٲ�ģ�� ��·FDMA���� ��·FDMA���
// Author/Data: Bahair_, 2025/9/21
// Revision: 2025/9/21 V1.0 released
// Copyright : Bahair_, Inc, All right reserved.
//////////////////////////////////////////////////////////////////////////////////////
module uidbufw_interconnect #(
    parameter  integer                   AXI_DATA_WIDTH = 32,//AXI��������λ��
    parameter  integer                   AXI_ADDR_WIDTH = 21 //AXI���ߵ�ַλ��
)
(
    input   wire                                  ui_clk,
    input   wire                                  ui_rstn,


    input   wire        [AXI_ADDR_WIDTH-1'b1: 0]    fdma_waddr_1,
    input   wire                                    fdma_wareq_1,
    input   wire        [15  :0]                    fdma_wsize_1,                                     
    output  reg                                     fdma_wbusy_1,
    input   wire        [AXI_DATA_WIDTH-1'b1:0]     fdma_wdata_1,
    output  reg                                     fdma_wvalid_1, //wvalid Ҫ������� 

    input   wire        [AXI_ADDR_WIDTH-1'b1: 0]    fdma_waddr_2,
    input   wire                                    fdma_wareq_2,
    input   wire        [15  :0]                    fdma_wsize_2,                                     
    output  reg                                     fdma_wbusy_2,
    input   wire        [AXI_DATA_WIDTH-1'b1:0]     fdma_wdata_2,
    output  reg                                     fdma_wvalid_2, //wvalid Ҫ������� 

    input   wire        [AXI_ADDR_WIDTH-1'b1: 0]    fdma_waddr_3,
    input   wire                                    fdma_wareq_3,
    input   wire        [15  :0]                    fdma_wsize_3,                                     
    output  reg                                     fdma_wbusy_3,
    input   wire        [AXI_DATA_WIDTH-1'b1:0]     fdma_wdata_3,
    output  reg                                     fdma_wvalid_3, //wvalid Ҫ������� 

    input   wire        [AXI_ADDR_WIDTH-1'b1: 0]    fdma_waddr_4,
    input   wire                                    fdma_wareq_4,
    input   wire        [15  :0]                    fdma_wsize_4,                                     
    output  reg                                     fdma_wbusy_4,
    input   wire        [AXI_DATA_WIDTH-1'b1:0]     fdma_wdata_4,
    output  reg                                     fdma_wvalid_4, //wvalid Ҫ������� 

    output  reg          [AXI_ADDR_WIDTH-1'b1: 0]   fdma_waddr,
    output  reg                                     fdma_wareq,
    output  reg          [15  :0]                   fdma_wsize,                                     
    input   wire                                    fdma_wbusy,
    output  reg          [AXI_DATA_WIDTH-1'b1:0]    fdma_wdata, //wdataҪ�������
    input   wire                                    fdma_wvalid

);

localparam IDLE = 0;
localparam  W_1 = 1;
localparam  W_2 = 2;
localparam  W_3 = 3;
localparam  W_4 = 4;
  

wire fdma_wbusy_fall;
reg fdma_wbusy_dly;
always @(posedge ui_clk or negedge ui_rstn)begin
    if (ui_rstn == 1'b0) begin
        fdma_wbusy_dly <= 1'b0;
    end else begin
        fdma_wbusy_dly <= fdma_wbusy;
    end
end

assign  fdma_wbusy_fall = (~fdma_wbusy)&(fdma_wbusy_dly) ;



reg [2:0]state;
reg [2:0]grant;
always@(posedge ui_clk or negedge ui_rstn)begin
    if (ui_rstn == 1'b0) begin
        state<=IDLE;
    end else begin
        case (state)
            IDLE:begin
                if (grant=='d0) begin
                    if (fdma_wareq_1)state<=W_1;
                    else if (fdma_wareq_2) state<=W_2;
                    else if (fdma_wareq_3) state<=W_3;
                    else if (fdma_wareq_4) state<=W_4;
                    else state<=state;
                end
                else if (grant=='d1) begin
                    if (fdma_wareq_2) state<=W_2;
                    else if (fdma_wareq_3) state<=W_3;
                    else if (fdma_wareq_4) state<=W_4;
                    else if (fdma_wareq_1) state<=W_1;
                    else state<=state;
                end
                else if (grant=='d2) begin
                    if (fdma_wareq_3) state<=W_3;
                    else if (fdma_wareq_4) state<=W_4;
                    else if (fdma_wareq_1) state<=W_1;
                    else if (fdma_wareq_2) state<=W_2;
                    else state<=state;
                    
                end
                else if (grant=='d3) begin
                    if (fdma_wareq_4) state<=W_4;
                    else if (fdma_wareq_1) state<=W_1;
                    else if (fdma_wareq_2) state<=W_2;
                    else if (fdma_wareq_3) state<=W_3;
                    else state<=state;
                end
            end 
            W_1:begin
                if (fdma_wbusy_fall) begin
                    state<=IDLE;
                    grant<='d0;
                end 
                else state<=state;
            end
            W_2:begin
                if (fdma_wbusy_fall) begin
                    state<=IDLE;
                    grant<='d0;
                end 
                else state<=state;
            end
            W_3:begin
                if (fdma_wbusy_fall) begin
                    state<=IDLE;
                    grant<='d0;
                end 
                else state<=state;
            end
            W_4:begin
                if (fdma_wbusy_fall) begin
                    state<=IDLE;
                    grant<='d0;
                end 
                else state<=state;
            end
            default: state<=IDLE;
        endcase
    end
end



always @(posedge ui_clk) begin
    case (state)
        IDLE:begin
            fdma_waddr   <= 'd0;
            fdma_wareq   <= 'b0;
            fdma_wsize   <= 'd0;
            fdma_wbusy_1 <= 'b0;
            fdma_wbusy_2 <= 'b0;
            fdma_wbusy_3 <= 'b0;
            fdma_wbusy_4 <= 'b0;
        end 
        W_1:begin
            fdma_waddr   <= fdma_waddr_1;
            fdma_wareq   <= fdma_wareq_1;
            fdma_wsize   <= fdma_wsize_1;
            fdma_wbusy_1 <= fdma_wbusy;
            fdma_wbusy_2 <= 'b0;
            fdma_wbusy_3 <= 'b0;
            fdma_wbusy_4 <= 'b0;
        end
        W_2:begin
            fdma_waddr   <= fdma_waddr_2;
            fdma_wareq   <= fdma_wareq_2;
            fdma_wsize   <= fdma_wsize_2;
            fdma_wbusy_1 <= 'b0;
            fdma_wbusy_2 <= fdma_wbusy;
            fdma_wbusy_3 <= 'b0;
            fdma_wbusy_4 <= 'b0;
        end
        W_3:begin
            fdma_waddr   <= fdma_waddr_3;
            fdma_wareq   <= fdma_wareq_3;
            fdma_wsize   <= fdma_wsize_3;
            fdma_wbusy_1 <= 'b0;
            fdma_wbusy_2 <= 'b0;
            fdma_wbusy_3 <= fdma_wbusy;
            fdma_wbusy_4 <= 'b0;
        end
        W_4:begin
            fdma_waddr   <= fdma_waddr_4;
            fdma_wareq   <= fdma_wareq_4;
            fdma_wsize   <= fdma_wsize_4;
            fdma_wbusy_1 <= 'b0;
            fdma_wbusy_2 <= 'b0;
            fdma_wbusy_3 <= 'b0;
            fdma_wbusy_4 <= fdma_wbusy;
        end
        default: begin
            fdma_waddr   <= 'd0;
            fdma_wareq   <= 'b0;
            fdma_wsize   <= 'd0;
            fdma_wbusy_1 <= 'b0;
            fdma_wbusy_2 <= 'b0;
            fdma_wbusy_3 <= 'b0;
            fdma_wbusy_4 <= 'b0;
        end
    endcase
end


//fdma_wdata fdma_wvalid_1Ҫ��������������ӳ�һ��ʱ�����ڣ���Ϊ����FDMA���ԣ���fdma_wvalid��Чʱ��fdma_wdataҲҪ��Ч
always@(*)begin
    case (state)
        IDLE:begin
            fdma_wdata    <= 'd0;
            fdma_wvalid_1 <= 'b0;
            fdma_wvalid_2 <= 'b0;
            fdma_wvalid_3 <= 'b0;
            fdma_wvalid_4 <= 'b0;
        end 
        W_1:begin
            fdma_wdata    <= fdma_wdata_1;
            fdma_wvalid_1 <= fdma_wvalid;
            fdma_wvalid_2 <= 'b0;
            fdma_wvalid_3 <= 'b0;
            fdma_wvalid_4 <= 'b0;
        end
        W_2:begin
            fdma_wdata    <= fdma_wdata_2;
            fdma_wvalid_1 <= 'b0;
            fdma_wvalid_2 <= fdma_wvalid;
            fdma_wvalid_3 <= 'b0;
            fdma_wvalid_4 <= 'b0;
        end
        W_3:begin
            fdma_wdata    <= fdma_wdata_3;
            fdma_wvalid_1 <= 'b0;
            fdma_wvalid_2 <= 'b0;
            fdma_wvalid_3 <= fdma_wvalid;
            fdma_wvalid_4 <= 'b0;
        end
        W_4:begin
            fdma_wdata    <= fdma_wdata_4;
            fdma_wvalid_1 <= 'b0;
            fdma_wvalid_2 <= 'b0;
            fdma_wvalid_3 <= 'b0;
            fdma_wvalid_4 <= fdma_wvalid;
        end
        default: begin
            fdma_wdata    <= 'd0;
            fdma_wvalid_1 <= 'b0;
            fdma_wvalid_2 <= 'b0;
            fdma_wvalid_3 <= 'b0;
            fdma_wvalid_4 <= 'b0;
        end
    endcase
end

endmodule
