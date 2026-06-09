# Project Overview

This is an FPGA hardware design project written primarily in **SystemVerilog/Verilog**. It targets a Xilinx Basys3 FPGA and utilizes the **Xilinx Vivado** toolchain for synthesis, implementation, and simulation. The project represents a drone control system components based on the `top_drone` design.

The directory structure separates technology-independent RTL code from FPGA-specific wrappers and provides automated bash and Tcl scripts to streamline the development workflow.

## Directory Structure

*   **`env.sh`**: Environment setup script. Initializes necessary variables (like `VIVADO_DIR` and `PATH`), sets up the local git repo (required by other scripts), and copies necessary IP simulation files.
*   **`rtl/`**: Contains core, technology-independent, synthesizable Verilog/SystemVerilog source files (e.g., `top_drone.sv`, `pwm.v`, UART modules).
*   **`fpga/`**: Contains files strictly related to the target FPGA (Basys3).
    *   `constraints/`: XDC constraints files defining pinouts and timing.
    *   `rtl/`: FPGA-specific top modules that wrap the main RTL top and include FPGA primitives (like clock synthesizers or buffers).
    *   `scripts/`: Tcl scripts used by Vivado for building the project.
*   **`sim/`**: Contains simulation testbenches. Tests are organized into subdirectories (e.g., `sim/pwm/`, `sim/top_drone/`).
    *   Each test directory must contain a `<test_name>.prj` file (listing module paths) and a `<test_name>_tb.sv` testbench file.
    *   `common/`: Contains files shared across multiple tests (like `glbl.v`).
*   **`tools/`**: Contains bash scripts for running common tasks (simulation, bitstream generation, programming, cleaning).
*   **`results/`**: (Generated) Output directory where the final `.bit` file and `warning_summary.log` are placed after a build.

## Building and Running

**Important:** All commands must be executed from the root directory of the project.

### 1. Environment Initialization
You must source the environment script at the start of every new terminal session:
```bash
. env.sh
```

### 2. Simulation
Simulations are executed using the Xilinx Simulator (xsim/xelab) via the `run_simulation.sh` script:
*   List available tests: `run_simulation.sh -l`
*   Run a specific test text mode: `run_simulation.sh -t <test_name>`
*   Run a specific test in GUI mode: `run_simulation.sh -gt <test_name>`
*   Run all tests: `run_simulation.sh -a`

### 3. Bitstream Generation
To synthesize, implement, and generate the bitstream (`.bit` file):
```bash
generate_bitstream.sh
```
The final bitstream and log summaries will be placed in the `results/` directory.

### 4. Programming the FPGA
To program the connected Basys3 board:
```bash
program_fpga.sh
```
*(Requires exactly one `.bit` file to be present in the `results/` directory).*

### 5. Cleaning Up
To remove all untracked and build-generated temporary files:
```bash
clean.sh
```
*Note: This script uses `git clean` and deletes files mentioned in `.gitignore`.*

## Development Conventions

*   **File and Module Naming**: A file should contain exactly one module, and the filename must be identical to the module name (e.g., module `pwm` goes in `pwm.v` or `pwm.sv`).
*   **Top-Level Modules**: Functional top-level modules (like `rtl/top_*.sv`) should be purely **structural**. They should only contain module instantiations and wire connections; no procedural logic (`always` blocks) should be present.
*   **Simulation Structure**: 
    *   Testbenches must be placed in a directory inside `sim/` named after the test.
    *   A `.prj` file must define relative paths to all sources needed for the test, with packages listed before modules.
    *   If testing modules with IP cores, `verilog work ../common/glbl.v` must be included in the `.prj` file.
*   **Assertions**: Testbenches should use SystemVerilog assertions that return `$error` when a condition is not met. The test runner (`run_simulation.sh -a`) relies on parsing the log for the word "error" to determine if a test `PASSED` or `FAILED`.
*   **Linting**: If working within the specific laboratory environment (Cadence HAL), use `hal_mtm_rtl.sh` or `hal_mtm_tb.sh` to statically analyze your code prior to synthesis/simulation.