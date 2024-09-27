library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-------------------------------------------------------
--! @entity AD5781
--! @brief SPI communication for AD5362 DAC. Control Logic Entity.
--
--! @generic
--!   @param SPI_CLK_DIVIDER Integer value to adjust SPI clock speed (default: 4).
--!   @param axis_DATA_WIDTH Integer value that determines the number of bits in the data bus used for communicating with the DAC (16 bits for AD5362).
--!
--! @port
--!   @name clk_i Clock input signal.
--!   @name resetn_i Reset input signal (active low).
--!   @name data_i Input data signal to be send to DAC and converted (18 bits).
--!   @name sdo_i Serial Data Out - from dac (SDO) input signal.
--!   @name sck_o Serial Clock (SCK) output signal.
--!   @name ldacn_o Signal used as an output to control the LDAC (Load DAC) pin (active low). 
--!   @name syncn_o Signal used for synchronization and control of the DAC read operation (active low).
--!   @name clrn_o Signal used for clearing the DAC read operation (active low).
--!   @name dac_resetn_o this signal has the function is to reset the DAC (active low).
--!   @name sdi_o Serial Data In - to dac (SDI) output signal.
-------------------------------------------------------
entity AD5781 is
  generic (
    SPI_CLK_DIVIDER : integer := 4; -- Adjust this value for desired SPI clock speed.
    axis_DATA_WIDTH : integer := 18 -- Adjust this value for desired axis data width.
  );
  Port (
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
end entity AD5781;

architecture Behavioral of AD5781 is
	-- Define modes as constants
	constant MODE_WRITE_DAC_REGISTER : std_logic := '0';
	constant Register_Address  : std_logic_vector(2 downto 0) := "001";
	constant DC  : std_logic_vector(1 downto 0) := "00";
	-- Definition of shift register len as constant (2 mode bits + 6 address bits + 16 data bits = 24 bits)
	constant shift_reg_NB_BITS  : integer := 24;
	-- Signals declarations
    signal state           : STD_LOGIC_VECTOR(2 downto 0);
    signal shift_reg       : STD_LOGIC_VECTOR(shift_reg_NB_BITS - 1 downto 0);
    -- Generate SPI clock (SCK) with appropriate frequency
    signal counter     : natural := 0;
    signal clk_divided : STD_LOGIC := '0';
    signal counter_data_bits : std_logic_vector(4 downto 0) := "00000";
    signal data_in_previous    : STD_LOGIC_VECTOR(axis_DATA_WIDTH - 1 downto 0) := (others => '0');
    signal data_initialization : STD_LOGIC_VECTOR(shift_reg_NB_BITS - 1 downto 0) := "001000000000000000010010";
begin
    
    -------------------------------------------------------
    --! @brief SPI master state machine.
    --! This process represents an SPI (Serial Peripheral Interface) master state entity work.AD5781 
    --! responsible for transmitting data to a slave device using the SPI protocol.
    --! @note Synchronous DAC Update Implemented
    --! In this mode, LDAC is held low while data is being clocked into
    --! the input shift register. The DAC output is updated on the rising
    --! edge of SYNC.
    --! @param clk_i     Input clock signal.
    --! @param resetn_i  Input reset signal (active low).
    -------------------------------------------------------
    process (clk_i, resetn_i)
      --variable counter_sr : natural range 0 to (axis_DATA_WIDTH - 1) := 0; -- Initialize the counter_sr to check if the data_i signal has been sent to the slave with sdi_o
    begin
        if resetn_i = '0' then
            state <= "000"; -- Reset to the initial state
            shift_reg <= (others => '0'); -- Reset shift register
            --counter_sr := 0; -- Reset counter_sr
            counter_data_bits <= (others => '0');
            ldacn_o <= '1';
            syncn_o <= '1';
            clrn_o  <= '0';
            dac_resetn_o <= '0';
        else
            if rising_edge(clk_i) then
                clrn_o  <= '1';
                dac_resetn_o <= '1';
                case state is
                    when "000" => -- Init state
                        ldacn_o <= '1';
                        if (data_in_previous /= data_i) then
                            shift_reg <= data_initialization; -- Load: 1 mode bits + 3 reg address bits + 18 data (concatenated into the shift register) + 2 don't care
                            data_in_previous <= data_i;
                            counter_data_bits <= (others => '0');
                            state <= "001"; -- Move to the next state
                        end if;
                    when "001" =>
                        state <= "010"; -- Move to the next state
                    when "010" => -- Shift out MSB of data (send data state)
                        counter_data_bits <= counter_data_bits + '1';
                        if (counter_data_bits = (shift_reg_NB_BITS)) then  -- All data bits have been sent
                            syncn_o <= '1';
                            state <= "011";
                        else
                            sdi_o <= shift_reg(shift_reg_NB_BITS - 1); -- Set SDI signal
                            syncn_o <= '0';
                            shift_reg <= shift_reg(shift_reg_NB_BITS - 2 downto 0) & '0'; -- Shift data left
                            state <= "010"; -- Stay in the same state
                        end if;
                    when "011" => -- Finish shifting data
                        ldacn_o <= '0';
                        state <= "100"; -- Return to idle state
                    when "100" => -- Idle state
                        shift_reg <= MODE_WRITE_DAC_REGISTER & Register_Address & data_i & DC; -- Load: 1 mode bits + 3 reg address bits + 18 data (concatenated into the shift register) + 2 don't care
                        ldacn_o <= '1';
                        counter_data_bits <= (others => '0');
                        state <= "101"; -- Move to the next state
                    when "101" => -- Synchronize to the rising edge of SCK
                        state <= "110";
                    when "110" => -- Shift out MSB of data (send data state)
                        counter_data_bits <= counter_data_bits + '1';
                        if (counter_data_bits = (shift_reg_NB_BITS)) then  -- All data bits have been sent
                            syncn_o <= '1';
                            state <= "111";
                        else
                            sdi_o <= shift_reg(shift_reg_NB_BITS - 1); -- Set SDI signal
                            syncn_o <= '0';
                            shift_reg <= shift_reg(shift_reg_NB_BITS - 2 downto 0) & '0'; -- Shift data left
                            state <= "110"; -- Stay in the same state
                        end if;
                    when "111" => -- Finish shifting data
                        ldacn_o <= '0';
                        state <= "000"; -- Return to idle state
                    when others =>
                        -- Add error handling or other states as needed
                        state <= "000"; -- Return to idle state
                end case;
            end if;
        end if;
    end process;
    
    -------------------------------------------------------
    --! @brief Generate SPI clock (SCK) with appropriate frequency.
    --! @param clk_i     Input clock signal.
    -------------------------------------------------------
    sck_o <= clk_i;  -- Set the Serial Clock (SCK) output signal

end architecture Behavioral;
