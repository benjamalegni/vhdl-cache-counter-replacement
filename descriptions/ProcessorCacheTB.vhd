-- ======================
-- ====    Autor Martin Vazquez
-- ====    arquitectura de Computadoras 1 - 2024
--
-- ==== Test bench para validar MemoryCache en forma aislada
-- ==== (cache totalmente asociativa + reemplazo por Counter)
-- ======================

library std;
use std.env.all;

library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity ProcessorCacheTB is
end ProcessorCacheTB;

architecture processorCacheTB_arch of ProcessorCacheTB is

    signal Clk            : std_logic;
    signal Reset          : std_logic;

    -- Interfaz CPU <-> Cache
    signal D_Addr         : std_logic_vector(31 downto 0);
    signal D_RdStb        : std_logic;
    signal D_WrStb        : std_logic;
    signal D_DataOut      : std_logic_vector(31 downto 0);
    signal D_DataIn       : std_logic_vector(31 downto 0);
    signal D_Rdy          : std_logic;
    signal Counter_cache  : std_logic_vector(1 downto 0);

    -- Interfaz Cache <-> Memoria principal de bloques
    signal Addr_block     : std_logic_vector(26 downto 0);
    signal RdStb_block    : std_logic;
    signal WrStb_block    : std_logic;
    signal RdWr_data      : std_logic;
    signal Rdy_block      : std_logic;
    signal DataIn_mem     : std_logic_vector(31 downto 0);
    signal DataOut_mem    : std_logic_vector(31 downto 0);

    -- Monitoreo de transacciones de bloque
    signal rd_txn_count        : integer := 0;
    signal wr_txn_count        : integer := 0;

    constant tper_clk : time := 50 ns;
    constant tdelay   : time := 120 ns;

begin

    CounterGen : entity work.MemoryCacheCounter
    port map (
        Clk     => Clk,
        Reset   => Reset,
        Counter => Counter_cache
    );

    Cache_Mem : entity work.MemoryCache
    port map (
        Clk         => Clk,
        Reset       => Reset,
        Counter     => Counter_cache,
        Addr        => D_Addr,
        DataIn      => D_DataOut,
        RdStb       => D_RdStb,
        WrStb       => D_WrStb,
        D_Rdy       => D_Rdy,
        DataOut     => D_DataIn,
        Addr_Block  => Addr_block,
        RdStb_block => RdStb_block,
        WrStb_block => WrStb_block,
        RdWr_data   => RdWr_data,
        Rdy_block   => Rdy_block,
        DataIn_mem  => DataIn_mem,
        DataOut_mem => DataOut_mem
    );

    DataBlock_Mem : entity work.DataMemoryBlock
    generic map (
        C_ELF_FILENAME => "data/data3",
        C_MEM_SIZE     => 1024
    )
    port map (
        Clk         => Clk,
        Reset       => Reset,
        Addr_block  => Addr_block,
        RdStb_block => RdStb_block,
        WrStb_block => WrStb_block,
        RdWr_data   => RdWr_data,
        Rdy_block   => Rdy_block,
        DataIn      => DataOut_mem,
        DataOut     => DataIn_mem
    );

    -- Reloj
    process
    begin
        Clk <= '0';
        wait for tper_clk / 2;
        Clk <= '1';
        wait for tper_clk / 2;
    end process;

    -- Reset
    process
    begin
        Reset <= '1';
        wait for tdelay;
        Reset <= '0';
        wait;
    end process;

    -- Monitorea inicios de transaccion (flanco 0->1 de RdStb_block/WrStb_block)
    monitor_block_if : process (Clk)
        variable prev_rd : std_logic := '0';
        variable prev_wr : std_logic := '0';
    begin
        if rising_edge(Clk) then
            if (prev_rd = '0' and RdStb_block = '1') then
                rd_txn_count <= rd_txn_count + 1;
            end if;

            if (prev_wr = '0' and WrStb_block = '1') then
                wr_txn_count <= wr_txn_count + 1;
            end if;

            prev_rd := RdStb_block;
            prev_wr := WrStb_block;
        end if;
    end process;

    -- Estimulos directos sobre la cache
    stimulus : process
        procedure wait_counter(constant val : std_logic_vector(1 downto 0)) is
        begin
            for i in 0 to 128 loop
                if Counter_cache = val then
                    return;
                end if;
                wait until rising_edge(Clk);
            end loop;
            assert false
                report "Timeout esperando valor de Counter"
                severity failure;
        end procedure;

        procedure cpu_read(
            constant addr : std_logic_vector(31 downto 0);
            variable data : out std_logic_vector(31 downto 0)
        ) is
        begin
            D_Addr   <= addr;
            D_RdStb  <= '1';
            D_WrStb  <= '0';

            wait until rising_edge(Clk);
            for i in 0 to 512 loop
                exit when D_Rdy = '1';
                wait until rising_edge(Clk);
            end loop;
            assert D_Rdy = '1'
                report "Timeout esperando D_Rdy=1 durante cpu_read"
                severity failure;

            wait until rising_edge(Clk);
            data := D_DataIn;
            D_RdStb <= '0';
        end procedure;

        constant ADDR_A     : std_logic_vector(31 downto 0) := x"00000000"; -- bloque 0
        constant ADDR_B     : std_logic_vector(31 downto 0) := x"00000020"; -- bloque 1
        constant ADDR_C     : std_logic_vector(31 downto 0) := x"00000040"; -- bloque 2
        constant ADDR_D     : std_logic_vector(31 downto 0) := x"00000060"; -- bloque 3
        constant ADDR_E     : std_logic_vector(31 downto 0) := x"00000080"; -- bloque 4

        variable rd_before : integer;
        variable wr_before : integer;
        variable read_data : std_logic_vector(31 downto 0);
    begin
        -- valores iniciales de interfaz CPU
        D_Addr             <= (others => '0');
        D_DataOut          <= (others => '0');
        D_RdStb            <= '0';
        D_WrStb            <= '0';

        wait until Reset = '0';
        wait until rising_edge(Clk);

        -- Llenado controlado de las 4 lineas usando Counter
        wait_counter("00");
        report "TB: MISS controlado en A con Counter=00" severity note;
        rd_before := rd_txn_count;
        cpu_read(ADDR_A, read_data);
        assert rd_txn_count > rd_before
            report "Fallo: lectura de A debio producir miss y refill"
            severity failure;

        wait_counter("01");
        report "TB: MISS controlado en B con Counter=01" severity note;
        rd_before := rd_txn_count;
        cpu_read(ADDR_B, read_data);
        assert rd_txn_count > rd_before
            report "Fallo: lectura de B debio producir miss y refill"
            severity failure;

        wait_counter("10");
        report "TB: MISS controlado en C con Counter=10" severity note;
        rd_before := rd_txn_count;
        cpu_read(ADDR_C, read_data);
        assert rd_txn_count > rd_before
            report "Fallo: lectura de C debio producir miss y refill"
            severity failure;

        wait_counter("11");
        report "TB: MISS controlado en D con Counter=11" severity note;
        rd_before := rd_txn_count;
        cpu_read(ADDR_D, read_data);
        assert rd_txn_count > rd_before
            report "Fallo: lectura de D debio producir miss y refill"
            severity failure;

        -- Hits esperados luego del llenado
        rd_before := rd_txn_count;
        wr_before := wr_txn_count;
        cpu_read(ADDR_A, read_data);
        assert rd_txn_count = rd_before and wr_txn_count = wr_before
            report "Fallo: lectura de A debio ser hit"
            severity failure;

        rd_before := rd_txn_count;
        wr_before := wr_txn_count;
        cpu_read(ADDR_B, read_data);
        assert rd_txn_count = rd_before and wr_txn_count = wr_before
            report "Fallo: lectura de B debio ser hit"
            severity failure;

        rd_before := rd_txn_count;
        wr_before := wr_txn_count;
        cpu_read(ADDR_C, read_data);
        assert rd_txn_count = rd_before and wr_txn_count = wr_before
            report "Fallo: lectura de C debio ser hit"
            severity failure;

        rd_before := rd_txn_count;
        wr_before := wr_txn_count;
        cpu_read(ADDR_D, read_data);
        assert rd_txn_count = rd_before and wr_txn_count = wr_before
            report "Fallo: lectura de D debio ser hit"
            severity failure;

        -- Reemplazo pseudoaleatorio controlado por Counter.
        -- Al pedir E con Counter=01 se reemplaza la linea usada por B (sin write-back porque todo esta clean)
        wait_counter("01");
        report "TB: MISS en E con Counter=01 (debe reemplazar B)" severity note;
        rd_before := rd_txn_count;
        wr_before := wr_txn_count;
        cpu_read(ADDR_E, read_data);
        assert rd_txn_count > rd_before and wr_txn_count = wr_before
            report "Fallo: miss clean de E debio hacer solo refill (sin write-back)"
            severity failure;

        -- A, C y D deben seguir en cache (hit)
        rd_before := rd_txn_count;
        cpu_read(ADDR_A, read_data);
        assert rd_txn_count = rd_before
            report "Fallo: A debio seguir como hit"
            severity failure;

        rd_before := rd_txn_count;
        cpu_read(ADDR_C, read_data);
        assert rd_txn_count = rd_before
            report "Fallo: C debio seguir como hit"
            severity failure;

        rd_before := rd_txn_count;
        cpu_read(ADDR_D, read_data);
        assert rd_txn_count = rd_before
            report "Fallo: D debio seguir como hit"
            severity failure;

        -- B fue expulsado, debe ser miss
        rd_before := rd_txn_count;
        cpu_read(ADDR_B, read_data);
        assert rd_txn_count > rd_before
            report "Fallo: B debio ser miss luego del reemplazo"
            severity failure;

        report "TB PASS: cache asociativa y reemplazo por Counter verificados" severity note;
        stop;
        wait;
    end process;

end processorCacheTB_arch;
