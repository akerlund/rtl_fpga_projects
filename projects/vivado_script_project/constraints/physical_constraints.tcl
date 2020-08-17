## LEDs
set_property -dict { PACKAGE_PIN R14 IOSTANDARD LVCMOS33 } [get_ports { led_0 }]; #IO_L6N_T0_VREF_34 Sch=LED0
set_property -dict { PACKAGE_PIN P14 IOSTANDARD LVCMOS33 } [get_ports { led_1 }]; #IO_L6P_T0_34 Sch=LED1
set_property -dict { PACKAGE_PIN N16 IOSTANDARD LVCMOS33 } [get_ports { led_2 }]; #IO_L21N_T3_DQS_AD14N_35 Sch=LED2
set_property -dict { PACKAGE_PIN M14 IOSTANDARD LVCMOS33 } [get_ports { led_3 }]; #IO_L23P_T3_35 Sch=LED3

## Buttons
set_property -dict { PACKAGE_PIN D19 IOSTANDARD LVCMOS33 } [get_ports { btn_0 }]; #IO_L4P_T0_35 Sch=BTN0
set_property -dict { PACKAGE_PIN D20 IOSTANDARD LVCMOS33 } [get_ports { btn_1 }]; #IO_L4N_T0_35 Sch=BTN1
set_property -dict { PACKAGE_PIN L20 IOSTANDARD LVCMOS33 } [get_ports { btn_2 }]; #IO_L9N_T1_DQS_AD3N_35 Sch=BTN2
set_property -dict { PACKAGE_PIN L19 IOSTANDARD LVCMOS33 } [get_ports { btn_3 }]; #IO_L9P_T1_DQS_AD3P_35 Sch=BTN3

## Pmod Header JA
set_property -dict { PACKAGE_PIN Y18 IOSTANDARD LVCMOS33 } [get_ports { cs_tx_mclk  }]; #IO_L17P_T2_34 Sch=JA1_P
set_property -dict { PACKAGE_PIN Y19 IOSTANDARD LVCMOS33 } [get_ports { cs_tx_lrck  }]; #IO_L17N_T2_34 Sch=JA1_N
set_property -dict { PACKAGE_PIN Y16 IOSTANDARD LVCMOS33 } [get_ports { cs_tx_sclk  }]; #IO_L7P_T1_34 Sch=JA2_P
set_property -dict { PACKAGE_PIN Y17 IOSTANDARD LVCMOS33 } [get_ports { cs_tx_sdout }]; #IO_L7N_T1_34 Sch=JA2_N
set_property -dict { PACKAGE_PIN U18 IOSTANDARD LVCMOS33 } [get_ports { cs_rx_mclk  }]; #IO_L12P_T1_MRCC_34 Sch=JA3_P
set_property -dict { PACKAGE_PIN U19 IOSTANDARD LVCMOS33 } [get_ports { cs_rx_lrck  }]; #IO_L12N_T1_MRCC_34 Sch=JA3_N
set_property -dict { PACKAGE_PIN W18 IOSTANDARD LVCMOS33 } [get_ports { cs_rx_sclk  }]; #IO_L22P_T3_34 Sch=JA4_P
set_property -dict { PACKAGE_PIN W19 IOSTANDARD LVCMOS33 } [get_ports { cs_rx_sdin  }]; #IO_L22N_T3_34 Sch=JA4_N

## Switches
set_property -dict { PACKAGE_PIN M20 IOSTANDARD LVCMOS33 } [get_ports { sw_0 }]; #IO_L7N_T1_AD2N_35 Sch=SW0
set_property -dict { PACKAGE_PIN M19 IOSTANDARD LVCMOS33 } [get_ports { sw_1 }]; #IO_L7P_T1_AD2P_35 Sch=SW1