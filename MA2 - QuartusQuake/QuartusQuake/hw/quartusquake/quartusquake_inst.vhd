	component quartusquake is
		port (
			clk_clk                          : in    std_logic                     := 'X';             -- clk
			parallel_port_0_ledmatrix_export : inout std_logic_vector(7 downto 0)  := (others => 'X'); -- export
			pio_0_buttons_export             : in    std_logic_vector(3 downto 0)  := (others => 'X'); -- export
			pio_1_leds_export                : out   std_logic_vector(9 downto 0);                     -- export
			pll_0_sdram_clk                  : out   std_logic;                                        -- clk
			reset_reset_n                    : in    std_logic                     := 'X';             -- reset_n
			sdram_controller_0_wire_addr     : out   std_logic_vector(12 downto 0);                    -- addr
			sdram_controller_0_wire_ba       : out   std_logic_vector(1 downto 0);                     -- ba
			sdram_controller_0_wire_cas_n    : out   std_logic;                                        -- cas_n
			sdram_controller_0_wire_cke      : out   std_logic;                                        -- cke
			sdram_controller_0_wire_cs_n     : out   std_logic;                                        -- cs_n
			sdram_controller_0_wire_dq       : inout std_logic_vector(15 downto 0) := (others => 'X'); -- dq
			sdram_controller_0_wire_dqm      : out   std_logic_vector(1 downto 0);                     -- dqm
			sdram_controller_0_wire_ras_n    : out   std_logic;                                        -- ras_n
			sdram_controller_0_wire_we_n     : out   std_logic                                         -- we_n
		);
	end component quartusquake;

	u0 : component quartusquake
		port map (
			clk_clk                          => CONNECTED_TO_clk_clk,                          --                       clk.clk
			parallel_port_0_ledmatrix_export => CONNECTED_TO_parallel_port_0_ledmatrix_export, -- parallel_port_0_ledmatrix.export
			pio_0_buttons_export             => CONNECTED_TO_pio_0_buttons_export,             --             pio_0_buttons.export
			pio_1_leds_export                => CONNECTED_TO_pio_1_leds_export,                --                pio_1_leds.export
			pll_0_sdram_clk                  => CONNECTED_TO_pll_0_sdram_clk,                  --               pll_0_sdram.clk
			reset_reset_n                    => CONNECTED_TO_reset_reset_n,                    --                     reset.reset_n
			sdram_controller_0_wire_addr     => CONNECTED_TO_sdram_controller_0_wire_addr,     --   sdram_controller_0_wire.addr
			sdram_controller_0_wire_ba       => CONNECTED_TO_sdram_controller_0_wire_ba,       --                          .ba
			sdram_controller_0_wire_cas_n    => CONNECTED_TO_sdram_controller_0_wire_cas_n,    --                          .cas_n
			sdram_controller_0_wire_cke      => CONNECTED_TO_sdram_controller_0_wire_cke,      --                          .cke
			sdram_controller_0_wire_cs_n     => CONNECTED_TO_sdram_controller_0_wire_cs_n,     --                          .cs_n
			sdram_controller_0_wire_dq       => CONNECTED_TO_sdram_controller_0_wire_dq,       --                          .dq
			sdram_controller_0_wire_dqm      => CONNECTED_TO_sdram_controller_0_wire_dqm,      --                          .dqm
			sdram_controller_0_wire_ras_n    => CONNECTED_TO_sdram_controller_0_wire_ras_n,    --                          .ras_n
			sdram_controller_0_wire_we_n     => CONNECTED_TO_sdram_controller_0_wire_we_n      --                          .we_n
		);

