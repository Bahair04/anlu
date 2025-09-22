//////////////////////////////////////////////////////////////////////////////////////
// Module Name: uidown_sample.v
// Description: 下采样模块
// Author/Data: Bahair_, 2025/9/21
// Revision: 2025/9/21 V1.0 released
// Copyright : Bahair_, Inc, All right reserved.
//////////////////////////////////////////////////////////////////////////////////////
module uidown_sample #(
    parameter VID_DATA_WIDTH = 16,
    parameter ORI_WIDTH = 1024,
    parameter ORI_HEIGHT = 768
)(
    input   wire                                I_clk,
    input   wire                                I_rstn,
    input   wire                                I_vid_vs,
    input   wire                                I_vid_de,
    input   wire    [VID_DATA_WIDTH - 1 : 0]    I_vid_data,

    output  reg                                 O_vid_vs,
    output  reg                                 O_vid_de,
    output  reg     [VID_DATA_WIDTH - 1 : 0]    O_vid_data
);

reg     [15 : 0]                col_cnt;
reg     [15 : 0]                row_cnt;

reg                             I_vid_vs_d;
wire                            I_vid_vs_posedge = {I_vid_vs_d, I_vid_vs} == 2'b01;
always @(posedge I_clk or negedge I_rstn) begin
    if (!I_rstn)
        I_vid_vs_d <= 1'b0;
    else 
        I_vid_vs_d <= I_vid_vs;
end

always @(posedge I_clk or negedge I_rstn) begin
    if (!I_rstn)
        col_cnt <= 'd0;
    else if (I_vid_vs_posedge)
        col_cnt <= 'd0;
    else if (I_vid_de) begin
        if (col_cnt == ORI_WIDTH - 1)
            col_cnt <= 'd0;
        else 
            col_cnt <= col_cnt + 1'b1;
    end
    else
        col_cnt <= col_cnt;
end

always @(posedge I_clk or negedge I_rstn) begin
    if (!I_rstn)
        row_cnt <= 'd0;
    else if (I_vid_vs_posedge)
        row_cnt <= 'd0;
    else if (I_vid_de && col_cnt == ORI_WIDTH - 1) begin
        if (row_cnt == ORI_HEIGHT - 1)
            row_cnt <= 'd0;
        else
            row_cnt <= row_cnt + 1'b1;
    end
    else 
        row_cnt <= row_cnt;
end

reg                     sample_en;
always @(*) begin
    if (!I_rstn)
        sample_en <= 1'b0;
    else 
        sample_en <= (col_cnt % 2 == 0) && (row_cnt % 2 == 0);
end

always @(posedge I_clk or negedge I_rstn) begin
    if (!I_rstn)
        O_vid_vs <= 1'b0;
    else 
        O_vid_vs <= I_vid_vs;
end

always @(posedge I_clk or negedge I_rstn) begin
    if (!I_rstn)
        O_vid_de <= 1'b0;
    else if (I_vid_de)
        O_vid_de <= sample_en;
    else 
        O_vid_de <= 1'b0;
end

always @(posedge I_clk or negedge I_rstn) begin
    if (!I_rstn)
        O_vid_data <= 'd0;
    else if (sample_en)
        O_vid_data <= I_vid_data;
    else 
        O_vid_data <= O_vid_data;
end
endmodule
