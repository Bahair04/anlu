//////////////////////////////////////////////////////////////////////////////////////
// Module Name: ui888_565
// Description: 888数据格式转565数据格式
// Author/Data: Bahair_, 2025/9/21
// Revision: 2025/9/21 V1.0 released
// Copyright : Bahair_, Inc, All right reserved.
//////////////////////////////////////////////////////////////////////////////////////
module ui565_888(
    input   [23 : 0]            data_888,
    output  [15 : 0]            data_565
);

assign data_565 = {data_888[23 : 19], data_888[15 : 10], data_888[7 : 3]};

endmodule