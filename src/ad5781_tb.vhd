library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity AD5781_tb is
-- No ports in a testbench entity
end entity AD5781_tb;

architecture Behavioral of AD5781_tb is

    -- Component Declaration for the Unit Under Test (UUT)
    component AD5781
        generic (
            SPI_CLK_DIVIDER : integer := 4;
            axis_DATA_WIDTH : integer := 18
        );
        port (
            clk_i        : in STD_LOGIC;
            resetn_i     : in STD_LOGIC;
            data_i       : in STD_LOGIC_VECTOR(axis_DATA_WIDTH - 1 downto 0);
            sdo_i        : in STD_LOGIC;
            sck_o        : out STD_LOGIC;
            ldacn_o      : out STD_LOGIC;
            syncn_o      : out STD_LOGIC;
            clrn_o       : out STD_LOGIC;
            dac_resetn_o : out STD_LOGIC;
            sdi_o        : out STD_LOGIC
        );
    end component;

    -- Testbench signals
    signal clk_i        : STD_LOGIC := '0';
    signal resetn_i     : STD_LOGIC := '0';
    signal data_i       : STD_LOGIC_VECTOR(17 downto 0) := (others => '0');
    signal sdo_i        : STD_LOGIC := '0';
    signal sck_o        : STD_LOGIC;
    signal ldacn_o      : STD_LOGIC;
    signal syncn_o      : STD_LOGIC;
    signal clrn_o       : STD_LOGIC;
    signal dac_resetn_o : STD_LOGIC;
    signal sdi_o        : STD_LOGIC;

    -- Clock period definition
    constant clk_period : time := 10 ns;

begin

    -- Instantiate the Unit Under Test (UUT)
    uut: AD5781
        generic map (
            SPI_CLK_DIVIDER => 4,
            axis_DATA_WIDTH => 18
        )
        port map (
            clk_i => clk_i,
            resetn_i => resetn_i,
            data_i => data_i,
            sdo_i => sdo_i,
            sck_o => sck_o,
            ldacn_o => ldacn_o,
            syncn_o => syncn_o,
            clrn_o => clrn_o,
            dac_resetn_o => dac_resetn_o,
            sdi_o => sdi_o
        );

    -- Clock generation process
    clk_process : process
    begin
        clk_i <= '0';
        wait for clk_period / 2;
        clk_i <= '1';
        wait for clk_period / 2;
    end process;

    -- Stimulus process
    stim_proc: process
    begin
        -- Hold reset for a while and then release it
        resetn_i <= '0';
        wait for 20 ns;
        resetn_i <= '1';
        
        -- Apply test data
        data_i <= "000000000000000001";
        wait for 1000 ns;

        data_i <= "000000000000000010";
        wait for 1000 ns;

        data_i <= "000000000000000011";
        wait for 1000 ns;

        -- End simulation
        wait;
    end process;

end architecture Behavioral;
