-- ======================
-- ====    Autor Martín Vázquez 
-- ====    arquitectura de Computadoras 1 - 2024
--
-- ==== Test bench del procesador y memoria cache de datos
-- ======================

library ieee;
use ieee.std_logic_1164.all; 
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

	

entity ProcessorCacheTB is
end ProcessorCacheTB;

architecture processorCacheTB_arch  of ProcessorCacheTB is
   
   -- Component declaration of the tested unit
   component Processor
   port(
   	  Clk         : in  std_logic;
	   Reset       : in  std_logic;
      -- Instruction memory
	   I_Addr      : out std_logic_vector(31 downto 0);
	   I_RdStb     : out std_logic;
	   I_WrStb     : out std_logic;
	   I_DataOut   : out std_logic_vector(31 downto 0);
	   I_DataIn    : in  std_logic_vector(31 downto 0);
	  
	-- Data memory
	   D_Rdy     : in std_logic;
	   D_Addr      : out std_logic_vector(31 downto 0);
	   D_RdStb     : out std_logic;
	   D_WrStb   : out std_logic;
	   D_DataOut   : out std_logic_vector(31 downto 0);
	   D_DataIn    : in  std_logic_vector(31 downto 0)
   );
	end component;

	component ProgramMemory
	generic (
	   C_ELF_FILENAME     : string;
      C_MEM_SIZE         : integer
    );
	port (
		Clk                : in std_logic;
		Reset                : in std_logic;  			 
		Addr               : in std_logic_vector(31 downto 0);
		RdStb              : in std_logic;
		WrStb              : in std_logic;
		DataIn             : in std_logic_vector(31 downto 0);
		DataOut            : out std_logic_vector(31 downto 0)
	   );
    end component;

    component MemoryCache 
    Port ( Clk : in std_logic ;						  
           Reset: in std_logic;

	       Addr : in std_logic_vector(31 downto 0);
           DataIn : in std_logic_vector(31 downto 0);
           RdStb : in std_logic ;
           WrStb : in std_logic ;
           D_Rdy: out std_logic; -- se encientra disponible para lectura o escritura de dato
           DataOut : out std_logic_vector(31 downto 0);
           
	   	   Addr_Block: out std_logic_vector(26 downto 0); 
	   	   RdStb_block : out std_logic;
	   	   WrStb_block : out std_logic;
           RdWr_data: in std_logic; 
           Rdy_block: in std_logic; 
           DataIn_mem : in std_logic_vector(31 downto 0); 
           DataOut_mem : out std_logic_vector(31 downto 0) );
    end component;
    
    
    component DataMemoryBlock is
       generic(
           C_ELF_FILENAME    : string := "data";
           C_MEM_SIZE        : integer := 1024
        );
       Port ( 
              Clk : in std_logic ;                          
              Reset: in std_logic;
              Addr_block : in std_logic_vector(26 downto 0); 
              DataIn : in std_logic_vector(31 downto 0);
              RdStb_block : in std_logic ;
              WrStb_block : in std_logic ;
              RdWr_data: out std_logic; 
              Rdy_block: out std_logic; 
              DataOut : out std_logic_vector(31 downto 0));
    end component;
   

	signal Clk         : std_logic;
	signal Reset       : std_logic;
   
   -- Instruction memory
	signal I_Addr      : std_logic_vector(31 downto 0);
	signal I_RdStb     : std_logic;
	signal I_WrStb     : std_logic;
	signal I_DataOut   : std_logic_vector(31 downto 0);
	signal I_DataIn    : std_logic_vector(31 downto 0);
	
	-- Cache Data memory
	signal D_Addr      : std_logic_vector(31 downto 0);
	signal D_RdStb     : std_logic;
	signal D_WrStb     : std_logic;
	signal D_DataOut   : std_logic_vector(31 downto 0);
	signal D_DataIn    : std_logic_vector(31 downto 0);		  
	signal D_Rdy	   : std_logic;

    -- Principal BLock Data memory
    signal Addr_block : std_logic_vector(26 downto 0); 
    signal RdStb_block : std_logic ;
    signal WrStb_block :  std_logic ;
    signal RdWr_data:  std_logic; 
    signal Rdy_block:  std_logic; 
    signal DataIn_mem : std_logic_vector(31 downto 0);
    signal DataOut_mem :  std_logic_vector(31 downto 0);
	
	constant tper_clk  : time := 50 ns;
	constant tdelay    : time := 120 ns; -- antes 150, sino no enta direccion 0

begin
	  
	-- Unit Under Test port map
	UUT : Processor
		port map (
			Clk             => Clk,
			Reset           => Reset,
			-- Instruction memory
	      I_Addr          => I_Addr,
  	      I_RdStb         => I_RdStb,
	      I_WrStb         => I_WrStb,
	      I_DataOut       => I_DataOut,
	      I_DataIn        => I_DataIn,
	      -- Cache Data memory
	      D_Rdy           => D_Rdy,
	      D_Addr          => D_Addr,
  	      D_RdStb         => D_RdStb,
	      D_WrStb         => D_WrStb,
	      D_DataOut       => D_DataOut,
	      D_DataIn        => D_DataIn
		);

	Instruction_Mem : ProgramMemory
	generic map (
	   C_ELF_FILENAME     => "program3",
      C_MEM_SIZE         => 1024
   )
	port map (
		Clk                => Clk,		
		Reset              => Reset,	 
		Addr               => I_Addr,
		RdStb              => I_RdStb,
		WrStb              => I_WrStb,
		DataIn             => I_DataOut,
		DataOut            => I_DataIn
	);
	Cache_Mem : MemoryCache 
    Port map ( Clk => Clk, Reset => Reset,
               Addr => D_Addr, 
               DataIn => D_DataOut,
               RdStb => D_RdStb,
               WrStb => D_WrStb,
               D_Rdy => D_Rdy,
               DataOut => D_DataIn,
               
               Addr_block => Addr_block,
               RdStb_block => RdStb_block,
               WrStb_block => WrStb_block,
               RdWr_data => RdWr_data, 
               Rdy_block => Rdy_block, 
               DataIn_mem => DataIn_mem, 
               DataOut_mem => DataOut_mem);
        
    

	DataBlock_Mem : DataMemoryBlock
	generic map (
	   C_ELF_FILENAME     => "data3",
      C_MEM_SIZE         => 1024
   )	
	port map (Clk => Clk, Reset => Reset,                          
                Addr_block => Addr_block,
                RdStb_block => RdStb_block,
                WrStb_block => WrStb_block,
                RdWr_data => RdWr_data, 
                Rdy_block => Rdy_block, 
                DataIn => DataOut_mem,
                DataOut => DataIn_mem);

	process	
	begin		
	   Clk <= '0';
		wait for tper_clk/2;
		Clk <= '1';
		wait for tper_clk/2; 		
	end process;
	
	process
	begin
		Reset <= '1';
		wait for tdelay;
		Reset <= '0';	   
		wait;
	end process;  	 

end ProcessorCacheTB_arch;

