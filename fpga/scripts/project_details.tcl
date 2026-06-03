# Copyright (C) 2025  AGH University of Science and Technology
# MTM UEC2
# Author: Piotr Kaczmarczyk
#
# Description:
# Project detiles required for generate_bitstream.tcl
# Make sure that project_name, top_module and target are correct.
# Provide paths to all the files required for synthesis and implementation.
# Depending on the file type, it should be added in the corresponding section.
# If the project does not use files of some type, leave the corresponding section commented out.

#-----------------------------------------------------#
#                   Project details                   #
#-----------------------------------------------------#
# Project name                                  -- EDIT
set project_name uart_project

# Top module name                               -- EDIT
set top_module top_uart_basys3

# FPGA device
set target xc7a35tcpg236-1

#-----------------------------------------------------#
#                    Design sources                   #
#-----------------------------------------------------#
# Specify .xdc files location                   -- EDIT
set xdc_files {
    constraints/top_uart_basys3.xdc
}

# Specify SystemVerilog design files location   -- EDIT
set sv_files {
    ../rtl/uart_monitor.sv
    ../rtl/uart_display_logic.sv
    ../rtl/top_uart.sv
    rtl/top_uart_basys3.sv
}

# Specify Verilog design files location         -- EDIT
set verilog_files {
    ../rtl/debounce.v
    ../rtl/disp_hex_mux.v
    ../rtl/fifo.v
    ../rtl/flag_buf.v
    ../rtl/mod_m_counter.v
    ../rtl/uart_rx.v
    ../rtl/uart_tx.v
    ../rtl/uart.v
}

# Specify VHDL design files location            -- EDIT
# set vhdl_files {
#    path/to/file.vhd
# }

# Specify files for a memory initialization     -- EDIT
# set mem_files {
#    path/to/file.data
# }
