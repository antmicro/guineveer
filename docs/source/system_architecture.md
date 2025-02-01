# System architecture

## Block diagram

The following diagram illustrates the key components and interconnections of the Guineveer SoC:

![Guineveer diagram](img/guineveer.png)

The Guineveer System-on-Chip (SoC) employs the VeeR EL2 core which is a 32-bit CPU which supports RISC-V’s integer (I), compressed instruction (C), multiplication and division (M), and instruction-fetch fence, CSR, and subset of bit manipulation instructions (Z) extensions.

The default configuration of the SoC features an AXI system bus which is used to communicate with a couple of peripherals including an SRAM memory module (accessed via an `AXI_to_mem` interface), an `I3C core`, and an `AXI-to-AHB bridge` providing access to an `OpenTitan UART` peripheral. 
The AXI Interconnect was generated using the [pulp generator](https://github.com/pulp-platform/axi/blob/master/scripts/axi_intercon_gen.py).

## Currently used peripherals and components

:::{list-table}
:name: tab-used-peripherials
:header-rows: 1
* - **Peripheral**
  - **Source**
* - VeeR EL2
  - <https://github.com/chipsalliance/Cores-VeeR-EL2>
* - AXI Interconnect
  - <https://github.com/pulp-platform/axi/blob/master/scripts/axi_intercon_gen.py>
* - AXI_AHB bridge
  - <https://github.com/antmicro/Cores-VeeR-EL2/blob/main/design/lib/axi4_to_ahb.sv>
* - AXI_to_mem
  - <https://github.com/pulp-platform/axi/blob/master/src/axi_to_mem.sv>
* - UART OpenTitan
  - <https://github.com/lowRISC/opentitan/tree/master/hw/ip/uart>
* - I3C core
  - <https://github.com/chipsalliance/i3c-core>
:::

## Memory map

The table below summarizes Guineveer memory address map, including start, end and size for the various component types.
::: {csv-table}
    :file: memory_map.csv
    :header-rows: 1
