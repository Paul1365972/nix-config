# Email sample

A reply to an engineer who asked about Paul's project, his circuits and his experience with PCIe FPGAs.
The text is as sent; only the names are changed.

```
Dear Dr Smith,

First of all, thank you for the quick response.

The open-source project I am writing my thesis about is MCHPRS, a software simulator for "redstone", the digital logic system of Minecraft.
Redstone contains some basic components like OR gates and inverters, it's Turing complete, and many players have created impressive builds, from Tetris and Minecraft simulated in Minecraft itself to a small transformer-based language model.
MCHPRS enables players to accelerate the simulation of redstone, from vanilla 10 Hz up to 50 kHz - 10 MHz depending on the build.
My main contribution is a new FPGA-based backend that fixes many of the restrictions that the current software-based approach produces.
At the moment players optimize for the number of changes a build produces, which leads to degenerate designs and makes pipelined builds strictly worse performance-wise.
As this is a common entry point into computer architecture for many students and should thus promote interesting, realistic designs, our goal is aligning the incentives more with real-world hardware design.

Our project's current workflow is: a player builds something on our Minecraft server, then it's converted into a graph, optimized, converted into Verilog, synthesized and placed and routed with the open-source openXC7 toolchain (Yosys, nextpnr-xilinx) and loaded onto the board with openFPGALoader, then a real-time connection is kept open such that the player can interact with and control the simulation on the FPGA in real time.

The circuits we are currently benchmarking are synthetic tests to ensure correct semantics, and a player-built 8-bit CPU running an example Fibonacci program.
On the Basys 3 it takes about 7,000 LUTs and runs at 160 MHz with one simulation step per clock, about 90 times faster than MCHPRS's software simulator while the CPU is executing.
However, we would also like to benchmark bigger, more interesting builds, such as two redstone computers running a Mandelbrot renderer.
They are about 14 and 80 times the size of the CPU, so we estimate roughly 100k and 600k LUTs, which need an Alveo-class card.

I have no experience yet with PCIe-based FPGAs, however my supervisor and our department have the expertise to support me there.
My only work with FPGAs has been over the course of the thesis with the Basys 3, including the board design and its UART host interface.
The FPGA runs the simulation on its own and only exchanges inputs, state and control commands with the host, which is little data.
For the Alveo cards I would use the PCIe infrastructure you recommend for the cluster, for example an RTL kernel through XRT, instead of writing my own.

I've attached the slides from my current progress presentation, which show the circuits and the FPGA design in more detail.
Code: https://github.com/Paul1365972/MCHPRS/tree/thesis/main

Best regards,
Paul
```
