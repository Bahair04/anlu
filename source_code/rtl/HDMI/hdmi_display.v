//////////////////////////////////////////////////////////////////////////////////////
// Module Name: hdmi_display.v(Top)
// Description: HDMI显示顶层模块
// Author/Data: Bahair_, 2025/9/11
// Revision: 2025/9/11 V1.0 released
// Copyright : Bahair_, Inc, All right reserved.
//////////////////////////////////////////////////////////////////////////////////////
module hdmi_display(
    input   wire                    i_clk50m,               // 50MHz系统时钟    
    input   wire                    i_rst_n,                // 系统低电平复位信号

    output  wire                    o_pix_clk_1x,           // 1x像素时钟
    output  wire                    o_pix_clk_5x,           // 5x像素时钟

    output  wire                    HDMI_CLK_P,             // HDMI时钟（硬件差分）
    output  wire                    HDMI_CLK_N,             // HDMI时钟（硬件差分）
    output  wire                    HDMI_D2_P,              // HDMI数据2（硬件差分）
    output  wire                    HDMI_D2_N,              // HDMI数据2（硬件差分）
    output  wire                    HDMI_D1_P,              // HDMI数据1（硬件差分）
    output  wire                    HDMI_D1_N,              // HDMI数据1（硬件差分）
    output  wire                    HDMI_D0_P,              // HDMI数据0（硬件差分）
    output  wire                    HDMI_D0_N,              // HDMI数据0（硬件差分）

    output	wire				    vga_data_request,       // VGA数据请求信号
	input	wire	[23 : 0]	    vga_data                // VGA数据
);

//////////////////////////////////////////////////////////////////////////////////////
// HDMI时钟产生模块
// VESA时序参数参考vga_parameter_cfg.v
// 保证时钟与刷新率和分辨率匹配
wire                    clk_1x;
wire                    clk_5x;
assign o_pix_clk_1x = clk_1x;
assign o_pix_clk_5x = clk_5x;
PLL_HDMI_CLK u_PLL_HDMI_CLK(
    .refclk(i_clk50m),
    .reset(~i_rst_n),
    .clk0_out(clk_1x),
    .clk1_out(clk_5x) 
);

//////////////////////////////////////////////////////////////////////////////////////
// VGA时序
wire                    VGA_EN;
wire                    VGA_HSYNC;
wire                    VGA_VSYNC;
wire    [23 : 0]        VGA_D;

vga_disp u_vga_disp(
    .clk_1x           	(clk_1x            ),
    .reset_n          	(i_rst_n           ),
    .VGA_EN           	(VGA_EN            ),
    .VGA_HSYNC        	(VGA_HSYNC         ),
    .VGA_VSYNC        	(VGA_VSYNC         ),
    .VGA_D            	(VGA_D             ),   // 最终输出数据
    .vga_data_request 	(vga_data_request  ),   // 数据请求
    .vga_data         	(vga_data          )    // 输入数据
);

//////////////////////////////////////////////////////////////////////////////////////
// VGA时序转差分HDMI信号输出
// 包括时钟线与颜色数据线
hdmi_tx #(
	.FAMILY("EG4") //EF2、EF3、EG4、AL3、PH1
)u3_hdmi_tx
(
	.PXLCLK_I(clk_1x),
	.PXLCLK_5X_I(clk_5x),

	.RST_N (i_rst_n),
	
	//VGA
	.VGA_HS (VGA_HSYNC ),
	.VGA_VS (VGA_VSYNC ),
	.VGA_DE (VGA_EN ),
	.VGA_RGB(VGA_D),

	//HDMI
	.HDMI_CLK_P(HDMI_CLK_P),
	.HDMI_D2_P (HDMI_D2_P ),
	.HDMI_D1_P (HDMI_D1_P ),
	.HDMI_D0_P (HDMI_D0_P )	
	
);
assign  HDMI_CLK_N = HDMI_CLK_P;
assign  HDMI_D2_N = HDMI_D2_P;
assign  HDMI_D1_N = HDMI_D1_P;
assign  HDMI_D0_N = HDMI_D0_P;
endmodule
