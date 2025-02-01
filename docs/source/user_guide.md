# User guide

## Building SoC sources

Run the `make hw` command to create a `build/` folder with the VeeR EL2 configuration and AXI interconnect file list in dot-f format.
This command also creates an AXI-based SoC network (`axi_intercon.sv`) source file in the `hw/` folder.

## Building software examples

Run `TEST=software_example_name make build_test` to compile one of the provided software examples.
Right now, the available software examples are:
* `uart` - this example initializes and transfers a "Hello UART" string over UART,
* `i3c` - this example checks I3C register values after reset and initializes the peripheral in device mode.

## Building testbench simulation

Run `make testbench` command to generate the simulation testbench executable using `verilator`.
The program is placed in the `build/obj_dir/Vguineveer_tb` file.
It can be launched with the `+firmware=/path/to/the/software.hex` to run software contained in the `software.hex` file.

~~~{note}
Please note that Guineveer RAM is placed at offset 0x80000000 and firmware is loaded using the \\$readmemh task.
If the hex file was created using objdump -O verilog, it will have addresses starting at 0x80000000 offset, but \\$readmemh expects the  0x0 starting address.
The user is responsible for changing addresses to comply with the \\$readmemh address range.
~~~

## Running example SW using the testbench

Run `TEST=software_example_name make sim` to the launch testbench executable with the provided software.
The log of all register values and their changes throughout the simulation will be written to the  `build/exec.log` file.

## Running example SW using Renode Robot Framework

Run `TEST=software_example_name make renode_test` to launch Renode simulation with the provided software.
It will run software and compare its output with the expected values.

## Running example SW using Renode Robot Framework with cosimulation

Run `make` in the `sw/renode_i3c_cosim` directory to build the cosimulation binary of the I3C device, form the HDL sources.
After building the cosimulation binary and the `i3c` test software, `renode-test` can be used to to run the test available in the `sw/guineveer_i3c_cosim.robot` file.
Refer to the [Testing with Renode](https://renode.readthedocs.io/en/latest/introduction/testing.html) and [Co-simulating with an HDL simulator](https://renode.readthedocs.io/en/latest/advanced/co-simulating-with-an-hdl-simulator.html) chapters in Renode's documentation for a deeper overview of the required dependencies and available options.
