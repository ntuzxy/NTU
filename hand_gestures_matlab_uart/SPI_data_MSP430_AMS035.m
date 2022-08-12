function [spi_data]=SPI_data_MSP430_AMS035(sel_input, bias_current, sel_output)

Bin_bias=bitget(bias_current,[1:1:6]);
Bin_in=zeros(1,128);
Bin_out=zeros(1,128);
Bin_in(sel_input+1)=1;
Bin_out(sel_output+1)=1;

Bin_all=[Bin_in Bin_bias Bin_out 0 0];
Bin_all_matrix=reshape(Bin_all, 8, 33);
weights=2.^(0:7);
spi_data_tmp=weights*Bin_all_matrix;
spi_data=spi_data_tmp(end:-1:1);