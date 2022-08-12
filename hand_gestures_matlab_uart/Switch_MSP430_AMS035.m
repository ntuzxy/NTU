function [switch_data]=Switch_MSP430_AMS035(RES, SDL, CA, CB, ext_ctrl, active, mode)

switch_data=[RES*4+CA SDL*32+CB*8+ext_ctrl*4+active*2+mode];