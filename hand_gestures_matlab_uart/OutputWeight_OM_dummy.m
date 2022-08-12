tmp=(1:60)';
N_outN=4;
OutputWeights_OM=tmp(:,ones(1,N_outN));

save('OutputWeights_MSP_OM_dummy.mat','OutputWeights_OM');
