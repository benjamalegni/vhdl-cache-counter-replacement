-- ======================
-- ====    Autor Martin Vazquez 
-- ====    Arquitectura de Computadoras 1 - 2024
--
-- ====== Memoria Principal de Datos 
-- =====- escritura y lectura de bloques de 8 palabras (32 bytes)
-- ====== Memoria de Nivel Inferior
-- ======================

library STD;
use STD.textio.all;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.std_logic_textio.all;


entity DataMemoryBlock is
    generic(
        C_ELF_FILENAME    : string := "data";
        C_MEM_SIZE        : integer := 1024
	 );
    Port ( 
           Clk : in std_logic ;						  
           Reset: in std_logic;
           Addr_block : in std_logic_vector(26 downto 0); -- 27 bits (32-5), porque cada bloque es de 8 palabras o 32 bytes
           DataIn : in std_logic_vector(31 downto 0);
           RdStb_block : in std_logic ;
           WrStb_block : in std_logic ;
          
           RdWr_data: out std_logic; -- memoria principal indica a cache que empezo a leer o escribir palabras
           Rdy_block: out std_logic; --se enceuntra disponible para lectura o escritura de bloque
	       DataOut : out std_logic_vector(31 downto 0));
end DataMemoryBlock;

architecture mem_arch of DataMemoryBlock is 
	
    type matriz is array(0 to C_MEM_SIZE-1) of std_logic_vector(7 downto 0);
    signal memo: matriz; -- senal que posee las celdas de la memoria 
    signal aux : std_logic_vector (31 downto 0):= (others=>'0'); -- utilizado para la lectura
    
            
    -- senales que describe los estados de la maquina de estados que consume el tiempo
    type type_state is (init_st, time_st1, time_st2, ReadWrite_st);
    signal curr_st, next_st: type_state;
    
    -- senales que describen los contadores de ciclos para consumo de tiempo
    signal count_time, next_count_time: std_logic_vector(2 downto 0);
    
    -- senal que posee la direccion dentro del bloque cuando se requiere avanzar en la escritura y lectura de bloques
    signal reg_addr_offset, next_addr_offset: std_logic_vector(2 downto 0);

    -- senales de lectura y escritura de la memoria manejadas por la maquina de control que modela consumo de tiempo
    signal rd_memory, wr_memory: std_logic; 
    
    
begin
    -- ==== proceso que modela inicializacion de la memoria y acceso a las celdas
    process (clk)
            variable init_memory : boolean := true;
            variable datum : STD_LOGIC_VECTOR(31 downto 0);
            file bin_file : text is C_ELF_FILENAME;
            variable  current_line : line;
            variable address : integer;
    begin
        
        if init_memory then
        -- esta rama del if se ejecuta por unica vez al principio 
            -- primero iniciamos la memoria con ceros
                for i in 0 to C_MEM_SIZE-1 loop
                    memo(i) <= (others => '0');
                end loop; 
            
            -- luego cargamos el archivo en la misma
                address := 0;
                while (not endfile (bin_file)) loop
                    
                    readline (bin_file, current_line);					
                    
                    hread(current_line, datum);
                    assert address<C_MEM_SIZE 
                        report "Direccion fuera de rango en el fichero de la memoria"
                        severity failure;
                    memo(address) <= datum(31 downto 24);
                    memo(address+1) <= datum(23 downto 16);
                    memo(address+2) <= datum(15 downto 8);
                    memo(address+3) <= datum(7 downto 0);
                    address:= address+4;
            end loop;
            
            -- por ultimo cerramos el archivo y actualizamos el flag de memoria cargada
             file_close (bin_file);
             -- para que no se ejecute mas esta rama del if correspondiente a la inicializacion de la memoria
             init_memory := false; 
        
       elsif (rising_edge(clk)) then
             address := CONV_INTEGER((Addr_block(25 downto 0)&reg_addr_offset&"00"));
             if (wr_memory = '1') then
                memo(address) <= DataIn(31 downto 24);
                memo(address+1) <= DataIn(23 downto 16);
                memo(address+2) <= DataIn(15 downto 8);
                memo(address+3) <= DataIn(7 downto 0);
                
             elsif (rd_memory = '1')then
                aux(31 downto 24) <= memo(address);   
                aux(23 downto 16) <= memo(address+1);
                aux(15 downto 8) <= memo(address+2);
                aux(7 downto 0) <= memo(address+3);
             end if;
             
       end if;
    end process;

--  ======================
--  ======================


--  ======================
--  === Procesos que modelan maquina de estados utilizada para generar los 13 ciclos de reloj)
--  === involucrados en la lectura y escritura de bloques de 8 palabras de la memoria principal coreespondiente a memoria de Datos

--      ciclo 1 -> procesa direccion de fila en en el bus de direcciones
--      ciclo 2 -> procesa activacion RAS# (Row Access Strobe)
--      ciclo 3 -> procesa direccion de columna en el bus de direcciones
--      ciclo 4 -> procesa activacion CAS# (Column Access Strobe)
--      ciclo 5 -> lstencia de busqueda de palabra
--      ciclos 6-13 -> ciclos de transmision por bus de datos

    -- Modela registro de estado, contador de tiempo usado en la maquina de estados
    -- y el offset para direccionar palabra dentro del bloque
    -- curr_time y reg_addr_offset puedo fucionarlo en curr_time, pero por razones didacticas los trabajamos separados
    process (clk, reset) 
    begin
        if (reset='1') then
            curr_st <= init_st;
            count_time <= (others => '0');
            reg_addr_offset <= (others=> '0');
        elsif (falling_edge(clk)) then
            count_time <= next_count_time;
            reg_addr_offset <= next_addr_offset;
            curr_st <= next_st;
        end if;
    end process;
    
    
    -- funcion de transicion de estados y salidas de la maquina
    state_machine: process (curr_st, RdStb_block, WrStb_block, reg_addr_offset, count_time)
    begin
    
       Rdy_block <= '1';
       next_count_time <= count_time;
       next_addr_offset <= reg_addr_offset;
       next_st <= curr_st;
       rd_memory <= '0';
       wr_memory <= '0';
    
       -- senales que indican a cache que la memoria princial empezo a leer o a escribir
       RdWr_data <= '0';
       
       case (curr_st) is
       
            when init_st =>
            -- cuando se activa WrStb_block o RdStb_block se procesa direccion de fila 
            -- en el bus de direcciones ciclo 1
                                                       
                            if (RdStb_block='1'or WrStb_block='1') then
                                Rdy_block <= '0';
                                next_count_time <= count_time + 1;
                                next_st <= time_st1;
                            end if;
           
           when time_st1 => -- ciclos 2-4
            -- activacion RAS# 
            -- direccion de columna en el bus de direcciones
            --  activacion CAS# 
            
                            Rdy_block <= '0';
                            next_count_time <= count_time + 1;
                            next_st <= time_st1;
                            if (count_time="011") then
                                next_count_time <= (others => '0');
                                next_st <= time_st2;
                            end if; 
           
           
           when time_st2 => -- ciclo 5
           -- latencia de busqueda de palabra
           
                            Rdy_block <= '0';
                            next_addr_offset <= (others => '0');
                            if (RdStb_block='1') then
                                next_st <= ReadWrite_st;
                            else -- es porque WrStb_block es '1'
                                next_st <= ReadWrite_st;
                                RdWr_data <= '1'; --adelanta un ciclo para indicarle a cache que debe leer  en el siguiente escribe 
                            end if;
       
           when ReadWrite_st => -- ciclos 6 a 13 
           -- lectura/escritura del bloque
                            
                            Rdy_block <= '0';
                            next_addr_offset <= reg_addr_offset + 1;
                            rd_memory <= RdStb_block;
                            wr_memory <= WrStb_block;
                            RdWr_data <= '1';
                            if (reg_addr_offset="111") then
                                next_addr_offset <= (others => '0');
                                Rdy_block <= '1';
                                next_st <= init_st;
                            end if;
           
           when others =>
                            Rdy_block <= '1';
                            next_count_time <= (others => '0');
                            next_addr_offset <= (others => '0');
                            next_st <= init_st;
                            rd_memory <= '0';
                            wr_memory <= '0';
                            RdWr_data <= '0';
                            
        end case;
    end process;

   
    DataOut <= aux;	 


end mem_arch;

