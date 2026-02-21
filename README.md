### Repositorio: Implementación en VHDL de una memoria cache totalmente asociativa con política de reemplazo pseudoaleatoria basada en un contador.
Características:
- Cache de datos totalmente asociativa (4 líneas, bloque de 8 palabras)
- Reemplazo pseudoaleatorio controlado por contador (2 bits)
- Política write-back + write-allocate
- Validación mediante testbench automatizado con GHDL

## Estructura:
- MemoryCache.vhd — Entity principal de la cache
- MemoryCacheCounter.vhd — Contador pseudoaleatorio
- DataMemoryBlockPrincipal.vhd — Memoria principal simulada
- ProcessorCacheTB.vhd — Testbench de validación

## Ejecución:
```bash
ghdl -a --std=08 -fsynopsys descriptions/*.vhd && \
ghdl -e --std=08 -fsynopsys ProcessorCacheTB && \
ghdl -r --std=08 -fsynopsys ProcessorCacheTB
```
