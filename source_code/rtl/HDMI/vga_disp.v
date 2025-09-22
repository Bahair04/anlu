`include "vga_parameter_cfg.v"
module vga_disp	
(
	input	wire				clk_1x,
	input	wire				reset_n,
    output	wire				VGA_EN,
	output	wire				VGA_HSYNC,
	output	wire				VGA_VSYNC,

	output 	reg		[23 : 0] 	VGA_D,
	output	wire				vga_data_request,
	input	wire	[23 : 0]	vga_data
);		

reg		[11 : 0]			hcnt;
reg		[11 : 0]			vcnt;		
reg							hs;	
reg   						vs;


wire 	[2 : 0]  			rgb;
wire 	[11 : 0] 			x;
wire 	[11 : 0] 			y;
wire 						dis_en;

assign x = hcnt;
assign y = vcnt;
assign VGA_VSYNC = vs;
assign VGA_HSYNC = hs;
assign dis_en = (x < `H_DISP && y < `V_DISP);
assign rgb = 3'b111;
assign VGA_EN  = (((hcnt >= 0) && (hcnt < `H_DISP))
                 &&((vcnt >= 0) && (vcnt < `V_DISP)))
                 ?  1'b1 : 1'b0;
assign vga_data_request = (x < `H_DISP && y < `V_DISP);

always @(posedge clk_1x or negedge reset_n) begin			//水平扫描计数器
	if(!reset_n)
		hcnt <= 1'b0;
	else begin
		if (hcnt == `H_TOTAL - 1)
			hcnt <= 'd0;
		else
			hcnt <= hcnt + 1'b1;
	end
end
			
always @(posedge clk_1x or negedge reset_n) begin			//垂直扫描计数器
	if(!reset_n)
		vcnt <= 1'b0;
	else begin
		if (hcnt == `H_DISP - 1) begin
			if (vcnt == `V_TOTAL - 1)
				vcnt <= 'd0;
			else
				vcnt <= vcnt + 1'b1;
		end
	end
end
			
always @(posedge clk_1x or negedge reset_n) begin			//场同步信号发生
	if(!reset_n)
		hs	<=	1'b1;
	else begin
		if((hcnt >= `H_DISP + `H_BP) & (hcnt < `H_DISP + `H_BP + `H_SYNC))
			hs <= `SYNC_POL;
		else
			hs <= ~`SYNC_POL;
	end
end
			
always @(vcnt or reset_n) begin							//行同步信号发生
	if(!reset_n)
		vs	<=	1'b1;
	else begin
		if((vcnt >= `V_DISP + `V_BP) && (vcnt < `V_DISP + `V_BP + `V_SYNC))
			vs	<=	`SYNC_POL;
		else
			vs	<=	~`SYNC_POL;
	end
end
			
always @(posedge clk_1x or negedge reset_n) begin
	if(!reset_n)
		VGA_D <= 'd0;
	else begin
		if (hcnt < `H_DISP & vcnt < `V_DISP && dis_en)	begin	//扫描终止
			VGA_D <= vga_data;
		end
		else begin
			VGA_D <= 'd0;
		end
	end
end
		
endmodule 
