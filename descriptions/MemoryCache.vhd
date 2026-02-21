-- ======================
-- ====    Autor Mart�n V�zquez 
-- ====    arquitectura de Computadoras 1 - 2024
--
-- ====== Memoria cache de datos - Memoria r�pida de Nivel inferior
-- == Memoria con 4 L�neas de 8 palabras de 4 bytes
-- == Escritura/Lectura de  palabra (4 bytes) con el procesador
-- ==  La memoria es de mapeo directo (asociativa de 4 conjuntos de una l�nea ) 
-- ===========
-- Posee dos m�quinas de estados. 
--     Una m�quina es la encargada de transferir (env�o y recepci�n) bloques con la memoria Principal
--     Otra m�quina es principal y se encarga del manejo de cache.  
-- ======================

library STD;
use STD.textio.all;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.std_logic_textio.all;

entity MemoryCache is
    Port ( Clk : in std_logic ;						  
           Reset: in std_logic;
           Counter: in std_logic_vector(1 downto 0);
           
        -- puertos que interact�an con el procesador
	       Addr : in std_logic_vector(31 downto 0);
           DataIn : in std_logic_vector(31 downto 0);
           RdStb : in std_logic ;
           WrStb : in std_logic ;
           D_Rdy: out std_logic; -- se encientra disponible para lectura o escritura de dato
           DataOut : out std_logic_vector(31 downto 0);
           
           
	 -- puertos que interact�an con la memoria principal
	   	   Addr_Block: out std_logic_vector(26 downto 0); 
	   	   -- son 27 bits de bloque, si se consideran bloques de 8 palabras o 32 bytes  y 5 bits paar las 8 palabras
	   	   -- posee la direcci�n de bloque que empezar� a escribir o a leer
	   	    
	   	   RdStb_block : out std_logic; --indica a memoria principal que va a leer bloque para escribirlo en cache
           WrStb_block : out std_logic;-- indica a memoria rpincipal que va escribirle bloque
           RdWr_data: in std_logic; -- la memoria proncipal indica que comenz� a leer o escribir palabras
           Rdy_block: in std_logic; -- indica que memoria principal esta lista para comenzar a transmitir bloques
           DataIn_mem : in std_logic_vector(31 downto 0); 
           DataOut_mem : out std_logic_vector(31 downto 0) );
end MemoryCache;

architecture cache_arch of MemoryCache is 
	
    type matriz_cache is array(0 to 127) of std_logic_vector(7 downto 0);
    signal mem_cache: matriz_cache; -- estructura  que posee las celdas de la memoria 
    signal aux_rd, aux_rd2 : std_logic_vector (31 downto 0):= (others=>'0'); -- utilizado para la lectura
    
    signal reg_valid_line, next_valid_line: std_logic_vector(3 downto 0); -- registro que indica si los bloques de cache fueron cargados alguna vez
    signal reg_dirty_line, next_dirty_line: std_logic_vector (3 downto 0); -- registro que indica si los bloque se cache se escribieron desde el procesador
    
    type matriz_label is array(0 to 3) of std_logic_vector(26 downto 0); -- CAMBIO ahora las etiquetas son de 27 bits
    signal regs_label, next_label: matriz_label; -- registros que poseen las etiquetas correpondiente cada bloque de la memoria cache
    
    
    signal reg_repl_line, next_repl_line: std_logic_vector(1 downto 0); -- registro que indica la l�nea de cache que se reemplazar� en la pr�xima transferencia de bloque desde memoria principal a cache
    signal line_sel_proc : std_logic_vector(1 downto 0); -- linea usada en acceso proc (hit o victima)

    -- se�ales que describe los estados de la m�quina que realiza transferecia de bloques
    type type_state_block is (init_st_block, wait_wrData_block, write_Data_block, write_Data2_block, write_Data3_block, wait_rdData_block, read_Data_block);
    signal curr_st_block, next_st_block: type_state_block;    
    
    -- se�ales que describe los estados de la m�quina principal de manejo de cache
    -- ===================== ESTO SE DEBE DEFINIR POR LOS ALUMNOS/AS
    type type_state_cache is (cache_idle_st, cache_writeback_victim_st, cache_refill_and_resume_st);
    signal curr_st_cache, next_st_cache: type_state_cache;    
    -- =============================================
            
            
    -- se�al que posee la direcci�n dentro del bloque cuando se requiere avanzar en la escritura y lectura de bloques
    signal reg_addr_offset, next_addr_offset: std_logic_vector(2 downto 0);

    -- se�ales que indican a m�quina de estados que que efect�a transferencia de bloques para envio y escritura en cache
    -- son para iniciar el proceso de transferencia
    signal send_block, write_block: std_logic;
    
    -- se�ales de lectura y escritura de la memoria manejadas por m�quina de control principal de cache. 
    -- esto es parra solicitudes del procesador
    signal rd_mem_proc, wr_mem_proc: std_logic; 

    -- se�ales de lectura y escritura de la memoria manejadas por m�quina de control de transferencia de bloques 
    signal rd_mem_block, wr_mem_block: std_logic; 

    -- se�ales que indican que finaliz� de escribir un bloque enviado desde memoria principal
    -- o que termin� de leer un bloque para que lo escriba la memoria principal.
    signal end_rd_block, end_wr_block: std_logic; -- estas se�ales las genera la m�quina de estados que efect�a transferencia de datos 
    
begin

    -- ==== proceso que modela acceso a las celdas de la cache ineractuando con procesador o memoria principal
    process (clk)
            variable init_memory_cache: boolean:= true;
            variable address : integer;
    begin
       
       if init_memory_cache then
            -- esta rama del if se ejecuta por �nica vez al principio. Se inicia memoria cache con 0's 
            for i in 0 to 127 loop
                mem_cache(i) <= (others => '0');
            end loop;
            init_memory_cache := false;        
       
       elsif (rising_edge(clk)) then
                
             if (wr_mem_proc = '1' or wr_mem_block = '1') then
                    if (wr_mem_proc='1') then -- si se escribe con direcci�n solicitada desde el procesador
                        address := CONV_INTEGER(line_sel_proc & Addr(4 downto 0)); -- direccion de 7 bits [linea][palabra]
                        -- address := CONV_INTEGER(Addr(6 downto 0));
                        mem_cache(address) <= DataIn(31 downto 24);
                        mem_cache(address+1) <= DataIn(23 downto 16);
                        mem_cache(address+2) <= DataIn(15 downto 8);
                        mem_cache(address+3) <= DataIn(7 downto 0);
                    else -- wr_mem_block='1'
                    -- se escribe con direcci�n solicitada por memoria principal, en transferencias de bloques   
                        address := CONV_INTEGER(reg_repl_line & reg_addr_offset & "00"); -- direccion de 7 bits [linea][offset][00]
                        -- address := CONV_INTEGER( (Addr(6 downto 5)&reg_addr_offset&"00") );
                        mem_cache(address) <= DataIn_mem(31 downto 24);
                        mem_cache(address+1) <= DataIn_mem(23 downto 16);
                        mem_cache(address+2) <= DataIn_mem(15 downto 8);
                        mem_cache(address+3) <= DataIn_mem(7 downto 0);
                    end if;
                
             elsif (rd_mem_proc = '1' or rd_mem_block = '1') then
                    if (rd_mem_proc ='1') then -- si se lee con direcci�n solicitada desde el procesador  
                        address := CONV_INTEGER(line_sel_proc & Addr(4 downto 0)); -- direccion de 7 bits [linea][palabra]
                        -- address := CONV_INTEGER(Addr(6 downto 0));
                        aux_rd(31 downto 24) <= mem_cache(address);   
                        aux_rd(23 downto 16) <= mem_cache(address+1);
                        aux_rd(15 downto 8) <= mem_cache(address+2);
                        aux_rd(7 downto 0) <= mem_cache(address+3);
                    else -- rd_mem_block
                     -- se lee con direcci�n solicitada por memoria principal, en transferencias de bloques
                        address := CONV_INTEGER(reg_repl_line & reg_addr_offset & "00"); -- direccion de 7 bits [linea][offset][00]
                        -- address := CONV_INTEGER( (Addr(6 downto 5)&reg_addr_offset&"00"));
                        aux_rd2(31 downto 24) <= mem_cache(address);   
                        aux_rd2(23 downto 16) <= mem_cache(address+1);
                        aux_rd2(15 downto 8) <= mem_cache(address+2);
                        aux_rd2(7 downto 0) <= mem_cache(address+3);
                    end if;
             end if;
       end if;
    end process;
-- ===========

-- ===========
-- proceso que maneja la informaci�n de etiquetas y flags de los bloques
-- y direcci�n de posici�n dentro del bloque para escritura y lectura
    process (clk, reset)
    begin 
        if (reset='1') then
            reg_valid_line <= (others => '0');
            reg_dirty_line <= (others => '0');
            for i in 0 to 3 loop
                regs_label(i) <= (others=> '0');
            end loop;
            reg_repl_line <= (others => '0'); 
        elsif (falling_edge(clk)) then
            -- luego veo bien si esto es con conv_integer
                reg_valid_line  <= next_valid_line;
                reg_dirty_line <= next_dirty_line;
                for i in 0 to 3 loop
                    regs_label(i) <= next_label(i);
                end loop;
                reg_repl_line <= next_repl_line;
        end if;
    end process;
-- Fin proceso que maneja la informaci�n de etiquetas y flags de los bloques
-- ===========

--  ================ ALUMNOS/AS ==========================
--  === Procesos que modelan m�quina de estados que realiza manejo principal  (o controlador) de la memoria cache
--  =================================== 
    
-- === Proceso que modela registro del estado - NO MODIIFICAR
    process (clk, reset) 
    begin
        if (reset='1') then
            curr_st_cache <= cache_idle_st;
        elsif (falling_edge(clk)) then
            curr_st_cache <= next_st_cache;
        end if;
    end process;


-- =============== PROCESO QUE LOS ALUMNOS/AS DEBEN DESCRIBIR
-- ========= Este proceso realiza las funci�n de pr�ximo estado de la m�quina y las funciones de salida
-- ===================

    state_machine_cache: process (curr_st_cache, reg_valid_line, reg_dirty_line, RdStb, WrStb, Addr,
                                    regs_label(0), regs_label(1), regs_label(2), regs_label(3),
                                    end_wr_block, end_rd_block, Counter, reg_repl_line)
        variable hit       : std_logic;
        variable hit_line  : integer range 0 to 3;
        variable repl_line : integer range 0 to 3; -- se asignara usando el contador
        variable req_tag   : std_logic_vector(26 downto 0);
    begin
    
--     Este proceso se activa por los cambios en las siguientes se�ales (ENTRADAS):
--     * <curr_st_machine> -> el estado corriente en que se encuentra la maquina que controla cache
--     * <Addr> -> direcci�n enviada por el el procesador para efectuar lectura/escritura 
--     * <RdStb>,<WrStb> ->  se�ales de control enviadas por el procesador indicar lectura o escritura
--     * <reg_valid_line> -> registro (son cuatro ffs) que indican si las l�neas donde se ubican los bloques fueron usadas alguna vez
--     * <reg_dirty_line> -> registro (son cuatro ffs) que indican si los bloques que se encuetan en las respectivas l�neas de cache fueron escritos
--     * <regs_label_line(line)> -> (4 l�neas) registros que posee la etiqueta del bloque que se encuentra ubicado en la correspondiente l�nea 
--     * <end_rd_block>, <end_wr_block> -> 
--         Se�ales que provienen del m�dulo (m�quina de estados)que efect�a transferencia de bloques con la memoria principal. 
--         Estas se�ales indican que el m�dulo finaliz� de hacer la transferencia del bloque
--         en el caso de <end_rd_block>, termino de leerlo de cache y envi�rselo a la memoria principal
--         en el caso de <end_wr_block>, que finaliz� de escribir en cache, el bloque que recibe de memoria principal
     
--     Este proceso genera las siguiente se�ales (SALIDAS):
--     * <next_st_cache> -> prpximo estado de m�quina de control de cache
--     * <D_Rdy> -> indica al procesador si se encuentra Ready la memoria para leer y escribir palabras (desde el procesador)
--     * <wr_mem_proc> -> se�al de control para escribir en bloque de cache, palabra que proviene del procesador (DataIn)
--     * <rd_mem_proc> -> se�al de control para leer de bloque de cache, palabra que requiere el precesador
--     * <next_valid_line> -> pr�ximo valor del registro (son cuatro ffs) correspondiente a "valid" 
--     * <next_dirty_line> -> pr�ximo valor del registro (son cuatro ffs) correspondiente a "dirty"
--     * <next_label_line(line)> -> (4 l�neas) pr�ximo valor del registro que contiene la etiqueta 
--     * <write_block> -> le indica al m�dulo de transferencia de bloques que debe traer bloque de memoria principal para escribir en cache
--     * <next_dirty_line> -> le indica a m�dulo de transferencia de bloques que debe enviar un bloque a la memoria principal      

      -- lo que habia anteriormente
      --  rd_mem_proc <= '0';
      --  wr_mem_proc <= '0';
      --  send_block <= '0';
      --  write_block <= '0';
      --  next_valid_line <= reg_valid_line;
      --  next_dirty_line <= reg_dirty_line;
      --  for i in 0 to 3 loop
      --       next_label(i) <= regs_label(i);
      --  end loop;
      --  next_st_cache <= curr_st_cache;
      --  D_Rdy <= '1'; 
     
        --      case (curr_st_cache) is
        --              when init_st_cache => ...
        --              when state1 => ...
        --              when state2 => ...
        --              when others => ...
        --       end case; 

    req_tag := Addr(31 downto 5);
    hit := '0';
    hit_line := 0;
    
    for i in 0 to 3 loop
        if (reg_valid_line(i)='1' and regs_label(i)=req_tag and hit='0') then
            hit := '1';
            hit_line := i;
        end if;
    end loop;

    rd_mem_proc <= '0';
    wr_mem_proc <= '0'; send_block <= '0';
    write_block <= '0';
    next_valid_line <= reg_valid_line;
    next_dirty_line <= reg_dirty_line;
    for i in 0 to 3 loop
        next_label(i) <= regs_label(i);
    end loop;
    next_st_cache <= curr_st_cache;
    D_Rdy <= '1';
    line_sel_proc <= reg_repl_line;
    next_repl_line <= reg_repl_line;

    case (curr_st_cache) is
        when cache_idle_st =>
            if (RdStb='1' or WrStb='1') then
                if (hit='1') then
                    line_sel_proc <= CONV_STD_LOGIC_VECTOR(hit_line, 2);
                    if (RdStb='1') then
                        rd_mem_proc <= '1';
                    end if;
                    if (WrStb='1') then
                        wr_mem_proc <= '1';
                        next_dirty_line(hit_line) <= '1';
                    end if;
                else
                    -- if cache miss, se debe evaluar si la l�nea a reemplazar es v�lida y sucio para escribir bloque de cache en memoria principal o no
                    D_Rdy <= '0';
                    next_repl_line <= Counter;
                    line_sel_proc <= Counter;
                    repl_line := CONV_INTEGER(Counter);
                    if (reg_valid_line(repl_line)='1' and reg_dirty_line(repl_line)='1') then
                        send_block <= '1';      -- write-back de victima
                        next_st_cache <= cache_writeback_victim_st;
                    else
                        write_block <= '1';     -- traer bloque nuevo
                        next_st_cache <= cache_refill_and_resume_st;
                    end if;
                end if;
            end if;
        when cache_writeback_victim_st =>
            D_Rdy <= '0';
            -- si termina de escribir bloque de cache en memoria principal, se actualizan registros de la l�nea v�ctima y se trae bloque nuevo a cache
            if (end_rd_block='1') then
                write_block <= '1';
                next_st_cache <= cache_refill_and_resume_st;
            end if;
        when cache_refill_and_resume_st =>
            D_Rdy <= '0';
            write_block <= '1';
            if (end_wr_block='1') then
                repl_line := CONV_INTEGER(reg_repl_line);
                next_valid_line(repl_line) <= '1';
                next_label(repl_line) <= req_tag;
                next_dirty_line(repl_line) <= '0';
                line_sel_proc <= reg_repl_line;
                -- completa operacion pendiente de CPU
                if (WrStb='1') then
                    wr_mem_proc <= '1';
                    -- marco como dirty la l�nea porque se escribi� desde el procesador, aunque el bloque que se trajo de memoria principal no se modific�, se va a modificar con la escritura del procesador
                    next_dirty_line(repl_line) <= '1';
                elsif (RdStb='1') then
                    rd_mem_proc <= '1';
                end if;
                D_Rdy <= '1';
                next_st_cache <= cache_idle_st;
            end if;
        when others =>
            next_st_cache <= cache_idle_st;
    end case;
end process;


           
-- ===========FIN DE PROCESO QUE LOS ALUMNOS/AS DEBEN DESCRIBIR
--  =====================

--  ======================
--  === Procesos que modelan m�quina de estados que transfiere bloques con la memoria principal
--  ==== 
--  === LATENCIA
--  Cuando trae bloque desde memoria principal para escribirlo en cache son 15 ciclos 
--        5 ciclos iniciales que tarda la memoria principal (dir fila+RAS+dir columna+CAS+busqueda palabra)
--        8 ciclos de lectura y transferencia de palabra del bloque desde memoria principal a CACHE
--        1 ciclo porque escribe en el siguiene ciclo respecto a la �ltima lectura, son memorias con lecturas sincr�nicas
--        1 ciclo adicional porqeu maquina de estados de cache (solicitud de procesador) requiere �ltima palabra del bloque y lo est� escribiendo  

--  Cuando lee bloque desde CACHE y lo transfiere a memoria principal son 13 ciclos 
--        5 ciclos iniciales que tarda la memoria principal (dir fila+RAS+dir columna+CAS+busqueda palabra)
--        8 ciclos de lectura y transferencia de palabra del bloque desde memoria CACHE a Principal

    process (clk, reset) 
    begin
        if (reset='1') then
            curr_st_block <= init_st_block;
            reg_addr_offset <= (others => '0');
        elsif (falling_edge(clk)) then
            reg_addr_offset <= next_addr_offset;
            curr_st_block <= next_st_block;
        end if;
    end process;
    
  
    
    state_machine_block: process (curr_st_block, send_block, write_block, RdWr_data, Rdy_block, reg_addr_offset, 
                                    Addr, reg_repl_line, regs_label(0), regs_label(1), regs_label(2), regs_label(3))
        variable repl_line:integer range 0 to 3;
    begin
      -- Cambio addr_line por repl_line (replacement line)
      -- addr_line := CONV_INTEGER(addr(6 downto 5)); -- posee nro de l�nea en la cache
       
      repl_line := CONV_INTEGER(reg_repl_line);

       -- se�ales de control que indican lo que se va a hacer con la memoria principal: leer o escribir un bloque     
       RdStb_block <= '0'; 
       WrStb_block <= '0'; 
       
       -- la direcci�n de bloque de escritura de la memoria principal, se obtiene de los 26 bits m�s significativos de la direcci�n de la palabra
       -- esto es por defecto. En el caso que se requiera escribir bloque de cache en bloque de memoria principal, se tomar� de los label
       Addr_Block <= Addr(31 downto 5);       
       
       wr_mem_block <= '0';
       rd_mem_block <= '0';
       next_addr_offset <= reg_addr_offset;
       next_st_block <= curr_st_block;
       end_rd_block <= '0'; 
       end_wr_block <= '0';
                       
       case (curr_st_block) is
            when init_st_block =>
            -- la m�quina se activa cuando send_block o write_block provenientes de m�quina de estado principal que maneja cache
                            
                            next_addr_offset <= (others =>'0');                            
                            if (write_block='1') then
                            -- cuando se desea escribir bloque a cache desde memoria principal
                            -- Se lee el bloque de memoria principal
                                RdStb_block <= '1';
                                next_st_block <= wait_wrData_block;
                            elsif (send_block='1') then    
                            -- cuando se desea enviar bloque a memoria principal
                                WrStb_block <= '1';

                                -- direcci�n de bloque que debo escribir en memoria principal.
                                Addr_Block <= regs_label(repl_line); 

                                next_st_block <= wait_rdData_block;
                            end if;
                            
           when wait_wrData_block =>
            -- en este estado se espera hasta que la memoria principal indica que este ciclo va a leer dato (el primero),
            -- para que cache ya pueda escribir primer dato
                            RdStb_block <= '1';
                            if (RdWr_data='1') then
                                next_st_block <= write_Data_block;
                            end if;
                            
           when write_Data_block =>
           -- en este escribe en memoria cache hasta que la memoria principal indica que est� disponible Rdy_block, 
           -- es decir que cuando Rdy_block es uno, en este ciclo termina de transferir �ltima palabra del bloque
           -- por consiguiente ac� en cache, reg_addr_offset es igual a 6 (mientras que en memoria principal vale 7)
                            
                            RdStb_block <= '1';
                            wr_mem_block <= '1';
                            next_addr_offset <= reg_addr_offset+1;
                            if (Rdy_block = '1') then  -- reg_addr_block = 6
                                    next_st_block <= write_Data2_block;
                            end if; 

           when write_Data2_block => 
           -- para escribir el �ltimo dato
                            RdStb_block <= '0';
                            wr_mem_block <= '1';
                            next_addr_offset <= (others=> '0');
                            next_st_block <= write_Data3_block;
                            
           when write_Data3_block => 
           -- para indicarle a m�quina de estados principal de cache, que finaliz� de escribir el �ltimo dato
           -- Este estado adicional surge porque si desde procesador quisiera leer la �ltima palabra del bloque,
           -- al ser lectura sincr�nica, debo esperar al sigiuiente ciclo a �ltima escritura de cache para leerla 
                            end_wr_block <= '1';
                            next_st_block <= init_st_block;
                             
           when wait_rdData_block => 
           -- en este estado lee de memoria cache posici�n 0, hasta que memoria principal indica 
           -- que esta disponible RdWr_data para empezar a ecribir bloque 
           
                             WrStb_block <= '1';

                             -- direcci�n de bloque que debo escribir en memoria principal.
                             Addr_Block <= regs_label(repl_line); 

                             rd_mem_block <= '1';
                             if (RdWr_data='1') then
                                 next_addr_offset <= reg_addr_offset +1;
                                 next_st_block <= read_Data_block;                           
                             end if;
  
            when read_Data_block => 
            -- en este estado se espera hasta que la memoria principal indica que escribi� la �ltima palabra 
            -- del bloque Rdy_block, 
            -- en este estado se lee en serie las palabras de cache
                             
                             WrStb_block <= '1';

                             -- direcci�n de bloque que debo escribir en memoria principal.
                             Addr_Block <= regs_label(repl_line); 

                             rd_mem_block <= '1';
                             next_addr_offset <= reg_addr_offset +1;
                             if (Rdy_block = '1') then
                                end_rd_block <= '1';
                                next_addr_offset <= (others =>'0');
                                next_st_block <= init_st_block;                           
                             end if;       

           when others => 
                    RdStb_block <= '0'; 
                    WrStb_block <= '0'; 
                    wr_mem_block <= '0';
                    rd_mem_block <= '0';
                    Addr_Block <= Addr(31 downto 5);
                    next_addr_offset <= reg_addr_offset;
                    next_st_block <= curr_st_block;
                    end_rd_block <= '0'; 
                    end_wr_block <= '0';
           
        end case;
    end process;

  
    DataOut <= aux_rd;	 
    DataOut_mem <= aux_rd2;	 

end cache_arch;
