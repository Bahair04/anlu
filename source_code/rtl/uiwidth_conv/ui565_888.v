//////////////////////////////////////////////////////////////////////////////////////
// Module Name: ui565_888
// Description: 565数据格式转888数据格式
//              COMPLEMENT_ENABLE = 1 : 565低位补位
//              COMPLEMENT_ENABLE = 0 : 用0补位
// Author/Data: Bahair_, 2025/9/21
// Revision: 2025/9/21 V1.0 released
// Copyright : Bahair_, Inc, All right reserved.
//////////////////////////////////////////////////////////////////////////////////////
module ui565_888 
#(
    parameter COMPLEMENT_ENABLE = 1
)(
    input   [15 : 0]            data_565,
    output  [23 : 0]            data_888
);
    
wire    [23 : 0]    data_888_1 = {data_565[15 : 11], 3'b0, data_565[10 : 5], 2'b0, data_565[4 : 0], 3'b0};
wire    [23 : 0]    data_888_2 = {data_565[15 : 11], data_565[13 : 11], data_565[10 : 5], data_565[6 : 5], data_565[4 : 0], data_565[2 : 0]};

assign data_888 = COMPLEMENT_ENABLE ? data_888_2 : data_888_1;

endmodule