# Introduction

Guineveer is a reference SoC disgn based on the Veer EL2 RISC-V core that uses AXI interconnect to connect two CPUs with UART, I3C and memory.
Topwrap is used as a generator for the top module, which enables convenient SoC designing and configuration changes.

This documentation is divided into the following chapters:
* {doc}`system_architecture` describes key components and interconnects in the SoC
* {doc}`testing` describes design simulation and testing with Renode and Verilator
* {doc}`user_guide` provides build instructions and describes basic usage
