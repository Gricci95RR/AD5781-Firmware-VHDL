# AD5781 DAC Communication Controller

This repository contains a VHDL implementation of a digital-to-analog converter (DAC) communication controller for the AD5781 DAC using the Serial Peripheral Interface (SPI) protocol. The project includes both the controller implementation and a testbench for verification.

## Overview

The AD5781 DAC controller is designed to communicate with the AD5781 DAC, allowing for precise digital-to-analog signal conversion. The implementation leverages a state machine to handle the SPI communication, ensuring proper data transmission and control signal generation.

## Directory Structure

```
/src
    ├── ad5781.vhd         # VHDL implementation of the AD5781 DAC communication controller
    └── ad5781_tb.vhd      # VHDL testbench for verifying the DAC communication controller
```

## Files Description

- **ad5781.vhd**: This file contains the main VHDL entity `AD5781`, which defines the SPI communication logic for the AD5781 DAC. It includes:
  - A state machine that controls the data transmission process.
  - Control signal generation for `LDAC`, `SYNC`, and other necessary signals.
  - SPI clock management for precise timing during data transmission.

- **ad5781_tb.vhd**: This file provides a testbench for the `AD5781` entity, allowing for simulation and verification of the DAC communication logic. Key features include:
  - A clock generation process to drive the `clk_i` input signal.
  - A stimulus process that applies various data inputs to the DAC and manages the reset signal.
  - Monitoring of output signals to validate the functionality of the DAC controller.

## Usage

To simulate the design, follow these steps:

1. **Setup Simulation Environment**: Use a VHDL simulation tool like ModelSim or Xilinx Vivado.
2. **Compile Source Files**: Compile the `ad5781.vhd` and `ad5781_tb.vhd` files.
3. **Run Simulation**: Simulate the testbench to observe the output signals and validate the behavior of the DAC communication controller.
4. **Analyze Waveforms**: Use the waveform viewer in your simulation tool to inspect the control signals and data transmission.
