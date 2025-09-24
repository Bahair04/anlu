///////////////////////////////////////////////////////////////////////////////////////
// Module Name: udp_top.v
// Description: ETH UDP顶层模块
// Author/Data: Bahair_, 2025/9/24
// Revision: 2025/9/24 V1.0 released
// Copyright : Bahair_, Inc, All right reserved.
//////////////////////////////////////////////////////////////////////////////////////
module udp_top#(
    // IP地址与端口号
    parameter  DEVICE             = "EG4",                          //"PH1","EG4"
    parameter  LOCAL_UDP_PORT_NUM = 16'h0001,                       // 本地端口1
    parameter  LOCAL_IP_ADDRESS   = 32'hc0a8f001,                   // 本地IP地址192.168.240.1
    parameter  LOCAL_MAC_ADDRESS  = 48'h0123456789ab,               // 本地MAC地址(不重要)
    parameter  DST_UDP_PORT_NUM   = 16'h0002,                       // 目的端口2
    parameter  DST_IP_ADDRESS     = 32'hc0a8f002                    // 目的IP地址192.168.240.2
)(
    input   wire                        clk_50,
    input   wire                        rstn,
    output  wire    [3 : 0]             phy1_rgmii_tx_data,
    output  wire                        phy1_rgmii_tx_ctl,
    output  wire                        phy1_rgmii_tx_clk,
    input   wire    [3 : 0]             phy1_rgmii_rx_data,
    input   wire                        phy1_rgmii_rx_ctl,
    input   wire                        phy1_rgmii_rx_clk

);

// clk_gen
wire                                clk_125_out;
wire                                clk_12_5_out;
wire                                clk_1_25_out;
wire                                clk_25_out;
wire    [1 : 0]                     TRI_speed;
assign                              TRI_speed = 2'b10;          //千兆2'b10 百兆2'b01 十兆2'b00
wire                                reset_reg;                  // reset_reg: 锁相环输出lock信号

// udp_loopback <----> udp_ip_protocol_stack
wire                                app_rx_data_valid; 
wire    [7 : 0]                     app_rx_data;       
wire    [15 : 0]                    app_rx_data_length;
wire    [15 : 0]                    app_rx_port_num;

wire                                udp_tx_ready;
wire                                app_tx_ack;
wire                                app_tx_data_request;
wire                                app_tx_data_valid; 
wire    [7 : 0]                     app_tx_data;       
wire    [15 : 0]                    udp_data_length;

// temac_block
wire                                tx_stop;
wire    [7 : 0]                     tx_ifg_val;
wire                                pause_req;
wire    [15 : 0]                    pause_val;
wire    [47 : 0]                    pause_source_addr;
wire    [47 : 0]                    unicast_address;
wire    [19 : 0]                    mac_cfg_vector;  
//============================================================
// 参数配置逻辑
//============================================================
//需配置的客户端接口（初始默认值）
assign  tx_stop    = 1'b0;
assign  tx_ifg_val = 8'h00;
assign  pause_req  = 1'b0;
assign  pause_val  = 16'h0;
assign  pause_source_addr = 48'h5af1f2f3f4f5;
assign  unicast_address   = {   LOCAL_MAC_ADDRESS[7:0],
                                LOCAL_MAC_ADDRESS[15:8],
                                LOCAL_MAC_ADDRESS[23:16],
                                LOCAL_MAC_ADDRESS[31:24],
                                LOCAL_MAC_ADDRESS[39:32],
                                LOCAL_MAC_ADDRESS[47:40]
                            };
assign  mac_cfg_vector    = {1'b0,2'b00,TRI_speed,8'b00000010,7'b0000010}; //地址过滤模式、流控配置、速度配置、接收器配置、发送器配置

// tx_client_fifo
wire                                temac_tx_ready;
wire                                temac_tx_valid;
wire    [7 : 0]                     temac_tx_data; 
wire                                temac_tx_sof;
wire                                temac_tx_eof;

// rx_client_fifo
wire                                temac_rx_ready;
wire                                temac_rx_valid;
wire    [7 : 0]                     temac_rx_data; 
wire                                temac_rx_sof;
wire                                temac_rx_eof;

// temac <----> tx/rx_client_fifo
wire                                rx_correct_frame;       //synthesis keep
wire                                rx_error_frame;         //synthesis keep
wire                                rx_clk_int; 
wire                                rx_clk_en_int;
wire                                tx_clk_int; 
wire                                tx_clk_en_int;
wire                                temac_clk;              //synthesis keep
wire                                temac_clk90;
wire                                udp_clk;                //synthesis keep
wire                                rx_valid;               //synthesis keep
wire    [7 : 0]                     rx_data;                //synthesis keep 
wire    [7 : 0]                     tx_data;    
wire                                tx_valid;   
wire                                tx_rdy;         
wire                                tx_collision;   
wire                                tx_retransmit;
wire                                reset; 
reg     [7 : 0]                     soft_reset_cnt=8'hff;
assign                              reset = ~rstn || reset_reg || (soft_reset_cnt != 'd0);
always @(posedge udp_clk or negedge rstn) // 按键释放后延迟退出复位
begin
    if(~rstn)
        soft_reset_cnt<=8'hff;
    else if(soft_reset_cnt > 0)
        soft_reset_cnt<= soft_reset_cnt-1;
    else
        soft_reset_cnt<=soft_reset_cnt;
end

//------------------------------------------------------------
//clk_gen
//------------------------------------------------------------
clk_gen_rst_gen#(                                   //产生三速时钟信号
    .DEVICE         (DEVICE     )
) 
u_clk_gen
(
    .reset          (~rstn      ),
    .clk_in         (clk_50     ),
    .rst_out        (reset_reg  ),
    .clk_125_out0   (temac_clk  ),
    .clk_125_out1   (clk_125_out),
    .clk_125_out2   (temac_clk90),
    .clk_12_5_out   (clk_12_5_out),
    .clk_1_25_out   (clk_1_25_out),
    .clk_25_out     (clk_25_out )
);
udp_clk_gen#(                                        //根据设备和速度选择一路时钟信号输出
    .DEVICE               (DEVICE                   )
)
u5_temac_clk_gen
(           
    .reset                (~rstn                    ),
    .tri_speed            (TRI_speed                ),
    .clk_125_in           (clk_125_out              ),//125M  
    .clk_12_5_in          (clk_12_5_out             ),//12.5M 
    .clk_1_25_in          (clk_1_25_out             ),//1.25M 
    .udp_clk_out          (udp_clk                  )
);

//------------------------------------------------------------
//udp_loopback
//------------------------------------------------------------
udp_loopback#(
    .DEVICE(DEVICE)
)
u2_udp_loopback
(
    .app_rx_clk                 (udp_clk                ),
    .app_tx_clk                 (udp_clk                ),
    .reset                      (reset                  ),

    .app_rx_data                (app_rx_data            ),
    .app_rx_data_valid          (app_rx_data_valid      ),
    .app_rx_data_length         (app_rx_data_length     ),
    
    .udp_tx_ready               (udp_tx_ready           ),
    .app_tx_ack                 (app_tx_ack             ),
    .app_tx_data                (app_tx_data            ),
    .app_tx_data_request        (app_tx_data_request    ),
    .app_tx_data_valid          (app_tx_data_valid      ),
    .udp_data_length            (udp_data_length        )   
);

//------------------------------------------------------------
//--------------            --------------                  --------------                  --------------                              
//|             |           |             |   --------      |             |                 |             |
//|             |           |             |  |rx_fifo|      |             |                 |   APP       |
//|             |           |             |  |-------|      |             |                 |             |              
//|    PHY      |  --->     | temac_      |    ----->       |   udp_ip_   |   ------->      | udp_loopback|              
//|             |  <---     | block       |    <-----       |   protocol  |   <------       | led         |
//|             |           |             |   --------      |   _stack    |                 |             |
//|             |           |             |  |tx_fifo|      |             |                 |             |
//|             |           |             |  |-------|      |             |                 |             |
//--------------            --------------                  --------------                  --------------
//------------------------------------------------------------

//------------------------------------------------------------  
//UDP
//------------------------------------------------------------       
udp_ip_protocol_stack #
(
    .DEVICE                     (DEVICE                 ),
    .LOCAL_UDP_PORT_NUM         (LOCAL_UDP_PORT_NUM     ),
    .LOCAL_IP_ADDRESS           (LOCAL_IP_ADDRESS       ),
    .LOCAL_MAC_ADDRESS          (LOCAL_MAC_ADDRESS      )
)   
u3_udp_ip_protocol_stack    
(   
    .udp_rx_clk                 (udp_clk                ),//input
    .udp_tx_clk                 (udp_clk                ),//input
    .reset                      (reset                  ),//input
    .udp2app_tx_ready           (udp_tx_ready           ),//output 
    .udp2app_tx_ack             (app_tx_ack             ),//output 
    .app_tx_request             (app_tx_data_request    ),//input 
    .app_tx_data_valid          (app_tx_data_valid      ),//input 
    .app_tx_data                (app_tx_data            ),//input 
    .app_tx_data_length         (udp_data_length        ),//input 
    .app_tx_dst_port            (DST_UDP_PORT_NUM       ),//input 
    .ip_tx_dst_address          (DST_IP_ADDRESS         ),//input 
    
    .input_local_udp_port_num      (LOCAL_UDP_PORT_NUM  ),//input
    .input_local_udp_port_num_valid(1'b1),                //input
    
    .input_local_ip_address     (32'hc0a8f001),           //input
    .input_local_ip_address_valid(1'b1),                  //input
    
    .app_rx_data_valid          (app_rx_data_valid      ),//output
    .app_rx_data                (app_rx_data            ),//output 
    .app_rx_data_length         (app_rx_data_length     ),//output
    .app_rx_port_num            (app_rx_port_num        ),//output 
    .temac_rx_ready             (temac_rx_ready         ),//output
    .temac_rx_valid             (!temac_rx_valid        ),//input
    .temac_rx_data              (temac_rx_data          ),//input
    .temac_rx_sof               (temac_rx_sof           ),//input
    .temac_rx_eof               (temac_rx_eof           ),//input
    .temac_tx_ready             (temac_tx_ready         ),//input
    .temac_tx_valid             (temac_tx_valid         ),//output
    .temac_tx_data              (temac_tx_data          ),//output
    .temac_tx_sof               (temac_tx_sof           ),//output
    .temac_tx_eof               (temac_tx_eof           ),//output

    .ip_rx_error                (                       ),//output
    .arp_request_no_reply_error (                       ) //output
);

//------------------------------------------------------------  
//TEMAC
//------------------------------------------------------------  
temac_block#(
    .DEVICE               (DEVICE                   )
)
u4_trimac_block
(
    .reset                (reset                    ),
    .gtx_clk              (temac_clk                ),//input   125M
    .gtx_clk_90           (temac_clk90              ),//input   125M
    .rx_clk               (rx_clk_int               ),//output  125M 25M    2.5M
    .rx_clk_en            (rx_clk_en_int            ),//output  1    12.5M  1.25M
    .rx_data              (rx_data                  ),
    .rx_data_valid        (rx_valid                 ),
    .rx_correct_frame     (rx_correct_frame         ),
    .rx_error_frame       (rx_error_frame           ),
    .rx_status_vector     (                         ),
    .rx_status_vld        (                         ),
//  .tri_speed            (tri_speed                       ),//output
    .tx_clk               (tx_clk_int               ),//output  125M
    .tx_clk_en            (tx_clk_en_int            ),//output  1    12.5M  1.25M 占空比不对
    .tx_data              (tx_data                  ),
    .tx_data_en           (tx_valid                 ),
    .tx_rdy               (tx_rdy                   ),//temac_tx_ready
    .tx_stop              (tx_stop                  ),//input
    .tx_collision         (tx_collision             ),
    .tx_retransmit        (tx_retransmit            ),
    .tx_ifg_val           (tx_ifg_val               ),//input
    .tx_status_vector     (                         ),
    .tx_status_vld        (                         ),
    .pause_req            (pause_req                ),//input
    .pause_val            (pause_val                ),//input
    .pause_source_addr    (pause_source_addr        ),//input
    .unicast_address      (unicast_address          ),//input
    .mac_cfg_vector       (mac_cfg_vector           ),//input
    .rgmii_txd            (phy1_rgmii_tx_data       ),
    .rgmii_tx_ctl         (phy1_rgmii_tx_ctl        ),
    .rgmii_txc            (phy1_rgmii_tx_clk        ),
    .rgmii_rxd            (phy1_rgmii_rx_data       ),
    .rgmii_rx_ctl         (phy1_rgmii_rx_ctl        ),
    .rgmii_rxc            (phy1_rgmii_rx_clk        ),
    .inband_link_status   (                         ),
    .inband_clock_speed   (                         ),
    .inband_duplex_status (                         )
);

//------------------------------------------------------------  
//tx_fifo
//------------------------------------------------------------  
tx_client_fifo#
(
    .DEVICE               (DEVICE                   )
)
u6_tx_fifo
(
    .rd_clk               (tx_clk_int               ),
    .rd_sreset            (reset                    ),
    .rd_enable            (tx_clk_en_int            ),
    .tx_data              (tx_data                  ),
    .tx_data_valid        (tx_valid                 ),
    .tx_ack               (tx_rdy                   ),
    .tx_collision         (tx_collision             ),
    .tx_retransmit        (tx_retransmit            ),
    .overflow             (                         ),
                            
    .wr_clk               (udp_clk                  ),
    .wr_sreset            (reset                    ),
    .wr_data              (temac_tx_data            ),
    .wr_sof_n             (temac_tx_sof             ),
    .wr_eof_n             (temac_tx_eof             ),
    .wr_src_rdy_n         (temac_tx_valid           ),
    .wr_dst_rdy_n         (temac_tx_ready           ),//temac_tx_ready
    .wr_fifo_status       (                         )
);

//------------------------------------------------------------  
//rx_fifo
//------------------------------------------------------------  
rx_client_fifo#
(
    .DEVICE               (DEVICE                   )
)
u7_rx_fifo                  
(                           
    .wr_clk               (rx_clk_int               ),
    .wr_enable            (rx_clk_en_int            ),
    .wr_sreset            (reset                    ),
    .rx_data              (rx_data                  ),
    .rx_data_valid        (rx_valid                 ),
    .rx_good_frame        (rx_correct_frame         ),
    .rx_bad_frame         (rx_error_frame           ),
    .overflow             (                         ),
    .rd_clk               (udp_clk                  ),
    .rd_sreset            (reset                    ),
    .rd_data_out          (temac_rx_data            ),//output reg [7:0] rd_data_out,
    .rd_sof_n             (temac_rx_sof             ),//output reg       rd_sof_n,
    .rd_eof_n             (temac_rx_eof             ),//output           rd_eof_n,
    .rd_src_rdy_n         (temac_rx_valid           ),//output reg       rd_src_rdy_n,
    .rd_dst_rdy_n         (temac_rx_ready           ),//input            rd_dst_rdy_n,
    .rx_fifo_status       (                         )
);

endmodule
