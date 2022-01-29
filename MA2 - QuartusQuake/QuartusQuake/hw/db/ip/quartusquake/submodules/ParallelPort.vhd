library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ParallelPort is
   port (
        -- Avalon interfaces signals
        Clk        : in  std_logic;
        nReset     : in  std_logic;
        Address    : in  std_logic_vector (2 DOWNTO 0);
        ChipSelect : in  std_logic;
        Read       : in  std_logic;
        Write      : in  std_logic;
        ReadData   : out std_logic_vector (7 DOWNTO 0);
        WriteData  : in  std_logic_vector (7 DOWNTO 0);
        -- Parallel Port external interface
        ParPort    : inout std_logic_vector (7 DOWNTO 0)
    );
end ParallelPort;

architecture comp of ParallelPort is
    signal iRegDir : std_logic_vector (7 DOWNTO 0);
    signal iRegPort: std_logic_vector (7 DOWNTO 0);
    signal iRegPin : std_logic_vector (7 DOWNTO 0);
begin
    -- ParallelPort output value
    pPort: process(iRegDir, iRegPort)
    begin
        for i in 0 to 7 loop
            if iRegDir(i) = '1' then
                ParPort(i) <= iRegPort(i);
            else
                ParPort(i) <= 'Z';
            end if;
        end loop;
    end process pPort;

    -- ParallelPort input value
    iRegPin <= ParPort;

    -- Process Write to registers
    pRegWr: process(Clk, nReset)
    begin
        if nReset = '0' then
            iRegDir <= (others => '0');
        elsif rising_edge(Clk) then
            if ChipSelect = '1' and Write = '1' then
                -- Write cycle
                case Address(2 downto 0) is
                    when "000" => iRegDir <= WriteData ;
                    when "010" => iRegPort <= WriteData;
                    when "011" => iRegPort <= iRegPort OR WriteData;
                    when "100" => iRegPort <= iRegPort AND NOT WriteData;
                    when others => null;
                end case;
            end if;
        end if;
    end process pRegWr;

    -- Read Process to registers
    pRegRd: process(Clk)
    begin
        if rising_edge(Clk) then
            ReadData <= (others => '0');
            if ChipSelect = '1' and Read = '1' then
                -- Read cycle
                case Address(2 downto 0) is
                    when "000" => ReadData <= iRegDir ;
                    when "001" => ReadData <= iRegPin;
                    when "010" => ReadData <= iRegPort;
                    when others => null;
                end case;
            end if;
        end if;
    end process pRegRd;
end comp;
