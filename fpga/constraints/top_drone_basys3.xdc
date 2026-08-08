## This file is a general .xdc for the Basys3 rev B board
## To use it in a project:
## - uncomment the lines corresponding to used pins
## - rename the used ports (in each line, after get_ports) according to the top level signal names in the project

## Clock signal
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports clk]

## Switches
set_property PACKAGE_PIN V17 [get_ports {sw[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[0]}]
set_property PACKAGE_PIN V16 [get_ports {sw[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[1]}]
set_property PACKAGE_PIN W16 [get_ports {sw[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[2]}]
set_property PACKAGE_PIN W17 [get_ports {sw[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[3]}]
set_property PACKAGE_PIN W15 [get_ports {sw[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[4]}]
set_property PACKAGE_PIN V15 [get_ports {sw[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[5]}]
set_property PACKAGE_PIN W14 [get_ports {sw[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[6]}]
set_property PACKAGE_PIN W13 [get_ports {sw[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[7]}]
set_property PACKAGE_PIN V2 [get_ports {sw[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[8]}]
set_property PACKAGE_PIN T3 [get_ports {sw[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[9]}]
set_property PACKAGE_PIN T2 [get_ports {sw[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[10]}]
set_property PACKAGE_PIN R3 [get_ports {sw[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[11]}]
set_property PACKAGE_PIN W2 [get_ports {sw[12]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[12]}]
set_property PACKAGE_PIN U1 [get_ports {sw[13]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[13]}]
set_property PACKAGE_PIN T1 [get_ports {sw[14]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[14]}]
set_property PACKAGE_PIN R2 [get_ports {sw[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[15]}]


## LEDs
set_property PACKAGE_PIN U16 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]
set_property PACKAGE_PIN E19 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]
set_property PACKAGE_PIN U19 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]
set_property PACKAGE_PIN V19 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]
set_property PACKAGE_PIN W18 [get_ports {led[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[4]}]
set_property PACKAGE_PIN U15 [get_ports {led[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[5]}]
set_property PACKAGE_PIN U14 [get_ports {led[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[6]}]
set_property PACKAGE_PIN V14 [get_ports {led[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[7]}]
set_property PACKAGE_PIN V13 [get_ports {led[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[8]}]
set_property PACKAGE_PIN V3 [get_ports {led[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[9]}]
set_property PACKAGE_PIN W3 [get_ports {led[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[10]}]
set_property PACKAGE_PIN U3 [get_ports {led[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[11]}]
set_property PACKAGE_PIN P3 [get_ports {led[12]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[12]}]
set_property PACKAGE_PIN N3 [get_ports {led[13]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[13]}]
set_property PACKAGE_PIN P1 [get_ports {led[14]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[14]}]
set_property PACKAGE_PIN L1 [get_ports {led[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[15]}]


##7 segment display
set_property PACKAGE_PIN W7 [get_ports {sseg[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sseg[0]}]
set_property PACKAGE_PIN W6 [get_ports {sseg[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sseg[1]}]
set_property PACKAGE_PIN U8 [get_ports {sseg[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sseg[2]}]
set_property PACKAGE_PIN V8 [get_ports {sseg[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sseg[3]}]
set_property PACKAGE_PIN U5 [get_ports {sseg[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sseg[4]}]
set_property PACKAGE_PIN V5 [get_ports {sseg[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sseg[5]}]
set_property PACKAGE_PIN U7 [get_ports {sseg[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sseg[6]}]
set_property PACKAGE_PIN V7 [get_ports {sseg[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sseg[7]}]
#
# set_property PACKAGE_PIN V7 [get_ports dp]
# 	set_property IOSTANDARD LVCMOS33 [get_ports dp]

set_property PACKAGE_PIN U2 [get_ports {an[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[0]}]
set_property PACKAGE_PIN U4 [get_ports {an[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[1]}]
set_property PACKAGE_PIN V4 [get_ports {an[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[2]}]
set_property PACKAGE_PIN W4 [get_ports {an[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[3]}]


##Buttons
set_property PACKAGE_PIN U18 [get_ports btnC]
set_property IOSTANDARD LVCMOS33 [get_ports btnC]
set_property PACKAGE_PIN T18 [get_ports btnU]
set_property IOSTANDARD LVCMOS33 [get_ports btnU]
set_property PACKAGE_PIN W19 [get_ports btnL]
set_property IOSTANDARD LVCMOS33 [get_ports btnL]
set_property PACKAGE_PIN T17 [get_ports btnR]
set_property IOSTANDARD LVCMOS33 [get_ports btnR]
set_property PACKAGE_PIN U17 [get_ports btnD]
set_property IOSTANDARD LVCMOS33 [get_ports btnD]



##Pmod Header JA
##Sch name = JA1
#set_property PACKAGE_PIN J1 [get_ports {JA1}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JA1}]
##Sch name = JA2
#set_property PACKAGE_PIN L2 [get_ports {JA2}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JA2}]
##Sch name = JA3
#set_property PACKAGE_PIN J2 [get_ports {JA[2]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JA[2]}]
##Sch name = JA4
#set_property PACKAGE_PIN G2 [get_ports {JA[3]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JA[3]}]
##Sch name = JA7
#set_property PACKAGE_PIN H1 [get_ports {JA[4]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JA[4]}]
##Sch name = JA8
#set_property PACKAGE_PIN K2 [get_ports {JA[5]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JA[5]}]
##Sch name = JA9
#set_property PACKAGE_PIN H2 [get_ports {JA[6]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JA[6]}]
##Sch name = JA10
#set_property PACKAGE_PIN G3 [get_ports {JA[7]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JA[7]}]



##Pmod Header JB
##Sch name = JB1
#set_property PACKAGE_PIN A14 [get_ports {JB[0]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JB[0]}]
##Sch name = JB2
#set_property PACKAGE_PIN A16 [get_ports {JB[1]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JB[1]}]
##Sch name = JB3
#set_property PACKAGE_PIN B15 [get_ports {JB[2]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JB[2]}]
##Sch name = JB4
#set_property PACKAGE_PIN B16 [get_ports {JB[3]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JB[3]}]
##Sch name = JB7
#set_property PACKAGE_PIN A15 [get_ports {JB[4]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JB[4]}]
##Sch name = JB8
#set_property PACKAGE_PIN A17 [get_ports {JB[5]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JB[5]}]
##Sch name = JB9
#set_property PACKAGE_PIN C15 [get_ports {JB[6]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JB[6]}]
##Sch name = JB10
set_property PACKAGE_PIN C16 [get_ports JB10]
set_property IOSTANDARD LVCMOS33 [get_ports JB10]



##Pmod Header JC
##Sch name = JC1 zmienione z JC[0]
set_property PACKAGE_PIN K17 [get_ports {JC[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {JC[1]}]
##Sch name = JC2 zmienione z JC[1]
set_property PACKAGE_PIN M18 [get_ports JC_input]
set_property IOSTANDARD LVCMOS33 [get_ports JC_input]
##Sch name = JC3
set_property PACKAGE_PIN N17 [get_ports {JC[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {JC[2]}]
##Sch name = JC4
set_property PACKAGE_PIN P18 [get_ports {JC[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {JC[3]}]
##Sch name = JC7
set_property PACKAGE_PIN L17 [get_ports {JC[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {JC[4]}]
##Sch name = JC8
set_property PACKAGE_PIN M19 [get_ports {JC[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {JC[5]}]
##Sch name = JC9
set_property PACKAGE_PIN P17 [get_ports {JC[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {JC[6]}]
##Sch name = JC10
set_property PACKAGE_PIN R18 [get_ports {JC[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {JC[7]}]


##Pmod Header JXADC
##Sch name = XA1_P
#set_property PACKAGE_PIN J3 [get_ports {JXADC[0]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JXADC[0]}]
##Sch name = XA2_P
#set_property PACKAGE_PIN L3 [get_ports {JXADC[1]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JXADC[1]}]
##Sch name = XA3_P
#set_property PACKAGE_PIN M2 [get_ports {JXADC[2]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JXADC[2]}]
##Sch name = XA4_P
#set_property PACKAGE_PIN N2 [get_ports {JXADC[3]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JXADC[3]}]
##Sch name = XA1_N
#set_property PACKAGE_PIN K3 [get_ports {JXADC[4]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JXADC[4]}]
##Sch name = XA2_N
#set_property PACKAGE_PIN M3 [get_ports {JXADC[5]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JXADC[5]}]
##Sch name = XA3_N
#set_property PACKAGE_PIN M1 [get_ports {JXADC[6]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JXADC[6]}]
##Sch name = XA4_N
#set_property PACKAGE_PIN N1 [get_ports {JXADC[7]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JXADC[7]}]



##VGA Connector
# set_property PACKAGE_PIN G19 [get_ports {vgaRed[0]}]
# 	set_property IOSTANDARD LVCMOS33 [get_ports {vgaRed[0]}]
# set_property PACKAGE_PIN H19 [get_ports {vgaRed[1]}]
# 	set_property IOSTANDARD LVCMOS33 [get_ports {vgaRed[1]}]
# set_property PACKAGE_PIN J19 [get_ports {vgaRed[2]}]
# 	set_property IOSTANDARD LVCMOS33 [get_ports {vgaRed[2]}]
# set_property PACKAGE_PIN N19 [get_ports {vgaRed[3]}]
# 	set_property IOSTANDARD LVCMOS33 [get_ports {vgaRed[3]}]
# set_property PACKAGE_PIN N18 [get_ports {vgaBlue[0]}]
# 	set_property IOSTANDARD LVCMOS33 [get_ports {vgaBlue[0]}]
# set_property PACKAGE_PIN L18 [get_ports {vgaBlue[1]}]
# 	set_property IOSTANDARD LVCMOS33 [get_ports {vgaBlue[1]}]
# set_property PACKAGE_PIN K18 [get_ports {vgaBlue[2]}]
# 	set_property IOSTANDARD LVCMOS33 [get_ports {vgaBlue[2]}]
# set_property PACKAGE_PIN J18 [get_ports {vgaBlue[3]}]
# 	set_property IOSTANDARD LVCMOS33 [get_ports {vgaBlue[3]}]
# set_property PACKAGE_PIN J17 [get_ports {vgaGreen[0]}]
# 	set_property IOSTANDARD LVCMOS33 [get_ports {vgaGreen[0]}]
# set_property PACKAGE_PIN H17 [get_ports {vgaGreen[1]}]
# 	set_property IOSTANDARD LVCMOS33 [get_ports {vgaGreen[1]}]
# set_property PACKAGE_PIN G17 [get_ports {vgaGreen[2]}]
# 	set_property IOSTANDARD LVCMOS33 [get_ports {vgaGreen[2]}]
# set_property PACKAGE_PIN D17 [get_ports {vgaGreen[3]}]
# 	set_property IOSTANDARD LVCMOS33 [get_ports {vgaGreen[3]}]
# set_property PACKAGE_PIN P19 [get_ports Hsync]
# 	set_property IOSTANDARD LVCMOS33 [get_ports Hsync]
# set_property PACKAGE_PIN R19 [get_ports Vsync]
# 	set_property IOSTANDARD LVCMOS33 [get_ports Vsync]


##USB-RS232 Interface
#set_property PACKAGE_PIN B18 [get_ports RsRx]
#set_property IOSTANDARD LVCMOS33 [get_ports RsRx]
#set_property PACKAGE_PIN A18 [get_ports RsTx]
#set_property IOSTANDARD LVCMOS33 [get_ports RsTx]


##USB HID (PS/2)
#set_property PACKAGE_PIN C17 [get_ports PS2Clk]
#set_property IOSTANDARD LVCMOS33 [get_ports PS2Clk]
#set_property PULLUP true [get_ports PS2Clk]
#set_property PACKAGE_PIN B17 [get_ports PS2Data]
#set_property IOSTANDARD LVCMOS33 [get_ports PS2Data]
#set_property PULLUP true [get_ports PS2Data]


##Quad SPI Flash
##Note that CCLK_0 cannot be placed in 7 series devices. You can access it using the
##STARTUPE2 primitive.
#set_property PACKAGE_PIN D18 [get_ports {QspiDB[0]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {QspiDB[0]}]
#set_property PACKAGE_PIN D19 [get_ports {QspiDB[1]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {QspiDB[1]}]
#set_property PACKAGE_PIN G18 [get_ports {QspiDB[2]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {QspiDB[2]}]
#set_property PACKAGE_PIN F18 [get_ports {QspiDB[3]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {QspiDB[3]}]
#set_property PACKAGE_PIN K19 [get_ports QspiCSn]
#set_property IOSTANDARD LVCMOS33 [get_ports QspiCSn]


## Configuration options, can be used for all designs
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]



create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 2048 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list pclk]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 2 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {u_top_drone/gyro/gyro_state[0]} {u_top_drone/gyro/gyro_state[1]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 2 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {page_cnt[0]} {page_cnt[1]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 56 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {u_top_drone/spi_controller/out[0]} {u_top_drone/spi_controller/out[1]} {u_top_drone/spi_controller/out[2]} {u_top_drone/spi_controller/out[3]} {u_top_drone/spi_controller/out[4]} {u_top_drone/spi_controller/out[5]} {u_top_drone/spi_controller/out[6]} {u_top_drone/spi_controller/out[7]} {u_top_drone/spi_controller/out[8]} {u_top_drone/spi_controller/out[9]} {u_top_drone/spi_controller/out[10]} {u_top_drone/spi_controller/out[11]} {u_top_drone/spi_controller/out[12]} {u_top_drone/spi_controller/out[13]} {u_top_drone/spi_controller/out[14]} {u_top_drone/spi_controller/out[15]} {u_top_drone/spi_controller/out[16]} {u_top_drone/spi_controller/out[17]} {u_top_drone/spi_controller/out[18]} {u_top_drone/spi_controller/out[19]} {u_top_drone/spi_controller/out[20]} {u_top_drone/spi_controller/out[21]} {u_top_drone/spi_controller/out[22]} {u_top_drone/spi_controller/out[23]} {u_top_drone/spi_controller/out[24]} {u_top_drone/spi_controller/out[25]} {u_top_drone/spi_controller/out[26]} {u_top_drone/spi_controller/out[27]} {u_top_drone/spi_controller/out[28]} {u_top_drone/spi_controller/out[29]} {u_top_drone/spi_controller/out[30]} {u_top_drone/spi_controller/out[31]} {u_top_drone/spi_controller/out[32]} {u_top_drone/spi_controller/out[33]} {u_top_drone/spi_controller/out[34]} {u_top_drone/spi_controller/out[35]} {u_top_drone/spi_controller/out[36]} {u_top_drone/spi_controller/out[37]} {u_top_drone/spi_controller/out[38]} {u_top_drone/spi_controller/out[39]} {u_top_drone/spi_controller/out[40]} {u_top_drone/spi_controller/out[41]} {u_top_drone/spi_controller/out[42]} {u_top_drone/spi_controller/out[43]} {u_top_drone/spi_controller/out[44]} {u_top_drone/spi_controller/out[45]} {u_top_drone/spi_controller/out[46]} {u_top_drone/spi_controller/out[47]} {u_top_drone/spi_controller/out[48]} {u_top_drone/spi_controller/out[49]} {u_top_drone/spi_controller/out[50]} {u_top_drone/spi_controller/out[51]} {u_top_drone/spi_controller/out[52]} {u_top_drone/spi_controller/out[53]} {u_top_drone/spi_controller/out[54]} {u_top_drone/spi_controller/out[55]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 16 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {led_OBUF[0]} {led_OBUF[1]} {led_OBUF[2]} {led_OBUF[3]} {led_OBUF[4]} {led_OBUF[5]} {led_OBUF[6]} {led_OBUF[7]} {led_OBUF[8]} {led_OBUF[9]} {led_OBUF[10]} {led_OBUF[11]} {led_OBUF[12]} {led_OBUF[13]} {led_OBUF[14]} {led_OBUF[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 4 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {JC_OBUF[1]} {JC_OBUF[2]} {JC_OBUF[3]} {JC_OBUF[5]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 56 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list {u_top_drone/odczytwartosc[0]} {u_top_drone/odczytwartosc[1]} {u_top_drone/odczytwartosc[2]} {u_top_drone/odczytwartosc[3]} {u_top_drone/odczytwartosc[4]} {u_top_drone/odczytwartosc[5]} {u_top_drone/odczytwartosc[6]} {u_top_drone/odczytwartosc[7]} {u_top_drone/odczytwartosc[8]} {u_top_drone/odczytwartosc[9]} {u_top_drone/odczytwartosc[10]} {u_top_drone/odczytwartosc[11]} {u_top_drone/odczytwartosc[12]} {u_top_drone/odczytwartosc[13]} {u_top_drone/odczytwartosc[14]} {u_top_drone/odczytwartosc[15]} {u_top_drone/odczytwartosc[16]} {u_top_drone/odczytwartosc[17]} {u_top_drone/odczytwartosc[18]} {u_top_drone/odczytwartosc[19]} {u_top_drone/odczytwartosc[20]} {u_top_drone/odczytwartosc[21]} {u_top_drone/odczytwartosc[22]} {u_top_drone/odczytwartosc[23]} {u_top_drone/odczytwartosc[24]} {u_top_drone/odczytwartosc[25]} {u_top_drone/odczytwartosc[26]} {u_top_drone/odczytwartosc[27]} {u_top_drone/odczytwartosc[28]} {u_top_drone/odczytwartosc[29]} {u_top_drone/odczytwartosc[30]} {u_top_drone/odczytwartosc[31]} {u_top_drone/odczytwartosc[32]} {u_top_drone/odczytwartosc[33]} {u_top_drone/odczytwartosc[34]} {u_top_drone/odczytwartosc[35]} {u_top_drone/odczytwartosc[36]} {u_top_drone/odczytwartosc[37]} {u_top_drone/odczytwartosc[38]} {u_top_drone/odczytwartosc[39]} {u_top_drone/odczytwartosc[40]} {u_top_drone/odczytwartosc[41]} {u_top_drone/odczytwartosc[42]} {u_top_drone/odczytwartosc[43]} {u_top_drone/odczytwartosc[44]} {u_top_drone/odczytwartosc[45]} {u_top_drone/odczytwartosc[46]} {u_top_drone/odczytwartosc[47]} {u_top_drone/odczytwartosc[48]} {u_top_drone/odczytwartosc[49]} {u_top_drone/odczytwartosc[50]} {u_top_drone/odczytwartosc[51]} {u_top_drone/odczytwartosc[52]} {u_top_drone/odczytwartosc[53]} {u_top_drone/odczytwartosc[54]} {u_top_drone/odczytwartosc[55]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 56 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list {u_top_drone/spi_odebrane[0]} {u_top_drone/spi_odebrane[1]} {u_top_drone/spi_odebrane[2]} {u_top_drone/spi_odebrane[3]} {u_top_drone/spi_odebrane[4]} {u_top_drone/spi_odebrane[5]} {u_top_drone/spi_odebrane[6]} {u_top_drone/spi_odebrane[7]} {u_top_drone/spi_odebrane[8]} {u_top_drone/spi_odebrane[9]} {u_top_drone/spi_odebrane[10]} {u_top_drone/spi_odebrane[11]} {u_top_drone/spi_odebrane[12]} {u_top_drone/spi_odebrane[13]} {u_top_drone/spi_odebrane[14]} {u_top_drone/spi_odebrane[15]} {u_top_drone/spi_odebrane[16]} {u_top_drone/spi_odebrane[17]} {u_top_drone/spi_odebrane[18]} {u_top_drone/spi_odebrane[19]} {u_top_drone/spi_odebrane[20]} {u_top_drone/spi_odebrane[21]} {u_top_drone/spi_odebrane[22]} {u_top_drone/spi_odebrane[23]} {u_top_drone/spi_odebrane[24]} {u_top_drone/spi_odebrane[25]} {u_top_drone/spi_odebrane[26]} {u_top_drone/spi_odebrane[27]} {u_top_drone/spi_odebrane[28]} {u_top_drone/spi_odebrane[29]} {u_top_drone/spi_odebrane[30]} {u_top_drone/spi_odebrane[31]} {u_top_drone/spi_odebrane[32]} {u_top_drone/spi_odebrane[33]} {u_top_drone/spi_odebrane[34]} {u_top_drone/spi_odebrane[35]} {u_top_drone/spi_odebrane[36]} {u_top_drone/spi_odebrane[37]} {u_top_drone/spi_odebrane[38]} {u_top_drone/spi_odebrane[39]} {u_top_drone/spi_odebrane[40]} {u_top_drone/spi_odebrane[41]} {u_top_drone/spi_odebrane[42]} {u_top_drone/spi_odebrane[43]} {u_top_drone/spi_odebrane[44]} {u_top_drone/spi_odebrane[45]} {u_top_drone/spi_odebrane[46]} {u_top_drone/spi_odebrane[47]} {u_top_drone/spi_odebrane[48]} {u_top_drone/spi_odebrane[49]} {u_top_drone/spi_odebrane[50]} {u_top_drone/spi_odebrane[51]} {u_top_drone/spi_odebrane[52]} {u_top_drone/spi_odebrane[53]} {u_top_drone/spi_odebrane[54]} {u_top_drone/spi_odebrane[55]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 1 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list u_top_drone/gyro_read_done]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 1 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list spi_done]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets pclk]
