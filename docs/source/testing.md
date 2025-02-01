# Testing

## Software tests

Currently two software test samples are available:
* `uart` - example initializes and transmits `Hello UART` over UART
* `i3c` - example verifies the correctness of some basic operations on the `i3c` device, including:
    * verifying if registers contain expected values after reset
    * verifying if read-only registers are not writeable and if read-write registers are writable
    * verifying if status bits change values after an interrupt condition in forced

Building software examples is described in the [User guide](user_guide.md#building-software-examples).

### Running software tests

Software test can be run in multiple ways:
* in Verilator
* in Renode with a behavioral model of the I3C device
* in Renode with a cosimulated model of the I3C device, generated from the original HDL sources.

Running the test software using each of the available methods is described in the [User guide](user_guide.md#running-example-sw-using-the-testbench)
