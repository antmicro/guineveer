# Testing

Guineveer SoC support the following targets:

* HDL simulation
* Renode simulation and cosimulation
* FPGA
* ASIC (in progress)
## Software tests

Currently, three software test samples are available:
* `uart` - example initializes and transmits `Hello UART` over UART
* `i3c` - example verifies the correctness of some basic operations on the `i3c` device, including:
    * verifying if registers contain expected values after reset
    * verifying if read-only registers are not writeable and if read-write registers are writable
    * verifying if status bits change values after an interrupt condition in forced
* `i3c-cocotb` - test application dedicated for use with the Cocotb I3C tests, which cover:
    * waiting for dynamic address assignment and observing the register changes,
    * performing I3C private writes and reads to the device,
    * performing various directed CCC transactions,
    * performing a streaming boot via the recovery I3C target,
    * performing a streaming boot using the AXI bypass functionality.
* `axi-streaming-boot-dualcore` - example tests AXI streaming boot feature of `i3c-core` using two cores
    * core 0 is waiting for payload from `i3c-core` via registers
    * core 1 is sending payload to `i3c-core` via registers
    * payload can be modified and rebuild, source files are located in `tests/sw/axi-streaming-boot-dualcore/core1/payload`
    * payload size is limited in core 0 software, to incrase limit change `MAX_STREAMING_BOOT_SIZE`
    * Needs `dualcore` design

Building software examples is described in the [User guide](user_guide.md#building-software-examples).

### Running software tests

Software test can be run in multiple ways:
* in Verilator
* in Renode with a behavioral model of the I3C device
* in Renode with a cosimulated model of the I3C device, generated from the original HDL sources.

Running the test software using each of the available methods is described in the [User guide](user_guide.md#running-example-sw-using-the-testbench)

## FPGA tests
## Supported FPGA boards
* [Arty A7-100T](https://store.digilentinc.com/arty-a7-artix-7-fpga-development-board/) is an FPGA development board based on the Xilinx Artix-7 FPGA.
