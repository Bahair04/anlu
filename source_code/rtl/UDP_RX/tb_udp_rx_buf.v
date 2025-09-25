`timescale  1ns / 1ps

module tb_udp_rx_buf;

// udp_rx_buf Parameters
parameter PERIOD      = 8          ;
parameter FRAME_HEAD  = 32'hF3ED7A93;
parameter APP_RX_DATA_TOTAL = 'd60;
// udp_rx_buf Inputs
reg   rstn                                 = 0 ;
reg   app_rx_clk                           = 1 ;
reg   app_rx_data_valid                    = 0 ;
reg   [7 : 0]  app_rx_data                 = 0 ;
reg   [15 : 0]  app_rx_data_length         = 0 ;
reg   [24 : 0]  app_rx_data_total          = APP_RX_DATA_TOTAL ;
reg   vid_clk                              = 0 ;

// udp_rx_buf Outputs
wire  vid_vs                               ;
wire  vid_de                               ;
wire  [15 : 0]  vid_data                   ;


initial
begin
    forever #(PERIOD/2)  app_rx_clk=~app_rx_clk;
end

initial
begin
    repeat (20) @(posedge app_rx_clk);
    rstn  =  1;
end

integer i = 0;
initial begin
    repeat (60) @(posedge app_rx_clk);
    app_rx_data_valid <= 1'b1;
    app_rx_data <= 8'h01;
    @(posedge app_rx_clk);
    app_rx_data <= 8'h02;
    @(posedge app_rx_clk);
    app_rx_data <= 8'h03;
    @(posedge app_rx_clk);
    app_rx_data <= FRAME_HEAD[31 : 24];
    @(posedge app_rx_clk);
    app_rx_data <= FRAME_HEAD[23 : 16];
    @(posedge app_rx_clk);
    app_rx_data <= FRAME_HEAD[15 : 8];
    @(posedge app_rx_clk);
    app_rx_data <= FRAME_HEAD[7 : 0];
    @(posedge app_rx_clk);
    repeat (APP_RX_DATA_TOTAL) begin
        app_rx_data <= i;
        i <= i + 1'b1;
        @(posedge app_rx_clk);
    end
    app_rx_data_valid <= 1'b0;
    repeat (20) @(posedge app_rx_clk);
    $finish;
end

udp_rx_buf #(
    .FRAME_HEAD ( FRAME_HEAD ))
 u_udp_rx_buf (
    .rstn                    ( rstn                         ),
    .app_rx_clk              ( app_rx_clk                   ),
    .app_rx_data_valid       ( app_rx_data_valid            ),
    .app_rx_data             ( app_rx_data         [7 : 0]  ),
    .app_rx_data_length      ( app_rx_data_length  [15 : 0] ),
    .app_rx_data_total       ( app_rx_data_total   [24 : 0] ),
    .vid_clk                 ( vid_clk                      ),

    .vid_vs                  ( vid_vs                       ),
    .vid_de                  ( vid_de                       ),
    .vid_data                ( vid_data            [15 : 0] )
);

endmodule