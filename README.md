# Basketball Shot Simulator

A hardware-accelerated simulator for a basketball shot built on the Digilent Nexys A7-100T FPGA. The project integrates the on-board ADXL362 accelerometer via SPI, kinematic calculation, and VGA graphics to visualize a ball trajectory while driving a two-digit seven-segment shot clock.

## Overview
- Real-time accelerometer sampling over SPI to capture motion.
- Fixed-point kinematics to compute shot trajectory parameters.
- VGA output (640×480 @ 60 Hz) to render the court, hoop, and ball.
- Two-digit seven-segment shot clock with debounced controls and multiplexing.
- Designed for the Nexys A7-100T; portable Verilog with clear module boundaries.

## Features
- Accelerometer: SPI master + filter modules for clean XY readings.
- Kinematics: Computes positions/velocity for trajectory visualization.
- Display: VGA timing, pixel generation, RGB mux, and basketball/hoop sprites.
- Seven-seg: Active-low encoder, anode multiplexing, and parameterized scan rate.
- Control: Debounced buttons for start/reset; 1 Hz tick for countdown.

## Hardware & Tools
- Board: Digilent Nexys A7-100T (Artix-7) with on-board ADXL362.
- Toolchain: Xilinx Vivado (synthesis/implementation, constraints/XDC).
- Clocking: 100 MHz system clock divided for VGA sync, 1 Hz tick, and 7-seg scan.

## Project Structure
- `Prototype/` — Early modules and testbenches for accelerometer, VGA, seven-seg.
- `Shot_Simulator/` — Integrated top-level bringing subsystems together.
- Key modules:
	- `Accelerometer/` + `Accelerometer(XY)/`: SPI master, filters, top wrappers.
	- `VGA/`: `vga_sync.v`, `pixel_Gen.v`, `rgb_Mux.v`, `basketball.v`, `basketballHoop.v`.
	- `seven_segment/`: `sevenseg_mux.v`, `sevenseg_clock_divider.v`, `bcd_counter.v`, `debounce.v`.
	- `kinematic/`: `kinematic.v` for motion math.

## Architecture
- Sensor pipeline: ADXL362 → `spi_master` → `shot_filter(_xy)` → kinematics.
- Rendering pipeline: `vga_sync` → `pixel_Gen` → `rgb_Mux` → VGA.
- Shot clock: `sevenseg_clock_divider` (1 Hz tick + scan) → `bcd_counter` → `sevenseg_mux`.
- Top-level: Wires subsystems, applies constraints (`*.xdc`), and maps I/O.

## Build & Run
1. Open the project in Vivado.
2. Add sources from `Shot_Simulator/` or `Prototype/` as needed.
3. Apply the corresponding `NexysA7-100t.xdc` constraints file.
4. Synthesize → Implement → Generate bitstream.
5. Program the Nexys A7-100T via USB.

## Simulation
- Testbenches provided (e.g., `sevenseg_tb.v`, `VGA/testbench/*`).
- `sevenseg_tb.v` demonstrates a waveform-only countdown and multiplexing.
- Use a 100 MHz clock in simulation; adjust parameters for scan/tick as needed.

## Notable Design Choices
- Active driving of all anode pins to prevent ghosting on unused digits.
- Clear separation of concerns across sensor, compute, display, and UI modules.
- Parameterization of clock divider for portability and readability in sim/hardware.

## Credits
- Hardware: Digilent Nexys A7-100T (ADXL362 accelerometer).
