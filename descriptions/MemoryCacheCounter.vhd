library STD;
use STD.textio.all;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity MemoryCacheCounter is
    Port ( 
           Clk : in std_logic ;
           Reset: in std_logic;
           Counter: out std_logic_vector(1 downto 0)
          );
end MemoryCacheCounter;

architecture Behavioral of MemoryCacheCounter is

signal counter_up: std_logic_vector(1 downto 0);

begin
process(clk, Reset)
  begin
    if (Reset = '1') then
      counter_up <= (others=>'0');
    elsif rising_edge(Clk) then
      counter_up <= counter_up + 1;
    end if;
  end process;
  Counter <= counter_up;
end Behavioral;
