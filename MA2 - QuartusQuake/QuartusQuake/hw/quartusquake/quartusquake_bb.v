
module quartusquake (
	clk_clk,
	parallel_port_0_ledmatrix_export,
	pio_0_buttons_export,
	pio_1_leds_export,
	pll_0_sdram_clk,
	reset_reset_n,
	sdram_controller_0_wire_addr,
	sdram_controller_0_wire_ba,
	sdram_controller_0_wire_cas_n,
	sdram_controller_0_wire_cke,
	sdram_controller_0_wire_cs_n,
	sdram_controller_0_wire_dq,
	sdram_controller_0_wire_dqm,
	sdram_controller_0_wire_ras_n,
	sdram_controller_0_wire_we_n);	

	input		clk_clk;
	inout	[7:0]	parallel_port_0_ledmatrix_export;
	input	[3:0]	pio_0_buttons_export;
	output	[9:0]	pio_1_leds_export;
	output		pll_0_sdram_clk;
	input		reset_reset_n;
	output	[12:0]	sdram_controller_0_wire_addr;
	output	[1:0]	sdram_controller_0_wire_ba;
	output		sdram_controller_0_wire_cas_n;
	output		sdram_controller_0_wire_cke;
	output		sdram_controller_0_wire_cs_n;
	inout	[15:0]	sdram_controller_0_wire_dq;
	output	[1:0]	sdram_controller_0_wire_dqm;
	output		sdram_controller_0_wire_ras_n;
	output		sdram_controller_0_wire_we_n;
endmodule
