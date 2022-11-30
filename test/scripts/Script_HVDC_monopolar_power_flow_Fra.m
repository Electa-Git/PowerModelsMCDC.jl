clear all
clc

[AC, DC]=runacdcpf('AC_case_Fra_monopolar_HVDC_inf','DC_case_Fra_monopolar_HVDC');


%% DC bus - Retrieving of the PF results 
% Pdc > 0 if going from the DC to the AC converter side

% Bus 1 - Connection DC node 1 and MMC 1
PF.DC_bus1.P_DC_bus1 = DC.busdc(1,4); %dc power bus 1 [MW]
PF.DC_bus1.V_DC_bus1_pu = DC.busdc(1,5); %dc voltage bus 1 [pu]
PF.DC_bus1.V_DC_bus1 = PF.DC_bus1.V_DC_bus1_pu*DC.busdc(1,6); %dc voltage bus 1 [kV]

% Bus 2 - Connection DC node 2 and MMC 2
PF.DC_bus2.P_DC_bus2 = DC.busdc(2,4); %dc power bus 2 [MW]
PF.DC_bus2.V_DC_bus2_pu = DC.busdc(2,5); %dc voltage bus 1 [pu]
PF.DC_bus2.V_DC_bus2 = PF.DC_bus2.V_DC_bus2_pu*DC.busdc(2,6); %dc voltage bus 1 [kV]

%% AC bus - Retrieving of the PF results 

% Bus 1 (PCC1) - Connection MMC 1 and grid 1
PF.AC_bus1.P_AC_bus1 = DC.convdc(1,4); % Active power injected in the AC grid [MW]
PF.AC_bus1.Q_AC_bus1 = DC.convdc(1,5); % Reactive power injected in the AC grid [Mvar]
PF.AC_bus1.V_C1_AC_mag = DC.convdc(1,25); % Voltage magnitude converter terminals [pu]
PF.AC_bus1.V_C1_AC_ang = DC.convdc(1,26); % Voltage angle converter terminals [deg]
PF.AC_bus1.P_C1_AC = DC.convdc(1,27); % Active power at converter terminal [MW]
PF.AC_bus1.Q_C1_AC = DC.convdc(1,28); % Reactive power at converter terminals [Mvar]
PF.AC_bus1.P_C1_loss = DC.convdc(1,29); % Converter losses [MW]
PF.AC_bus1.V_F1_AC_mag = DC.convdc(1,30); % Voltage magnitude at the converter filter [pu]
PF.AC_bus1.V_F1_AC_ang = DC.convdc(1,31); % Voltage angle at the converter filter [deg]
PF.AC_bus1.P_F1_AC = DC.convdc(1,32); % Active power at the filter bus [MW]
PF.AC_bus1.Q_F1_sf_AC = DC.convdc(1,33); % Reactive power through transformer at the filter bus [Mvar]
PF.AC_bus1.Q_F1_cf_AC = DC.convdc(1,34); % Reactive power through reactor at the filter bus [Mvar]

% Bus 2 (PCC2) - Connection MMC 2 and grid 2
PF.AC_bus2.P_AC_bus2 = DC.convdc(2,4); % Active power injected in the AC grid [MW]
PF.AC_bus2.Q_AC_bus2 = DC.convdc(2,5); % Reactive power injected in the AC grid [Mvar]
PF.AC_bus2.V_C2_AC_mag = DC.convdc(2,25); % Voltage magnitude converter terminals [pu]
PF.AC_bus2.V_C2_AC_ang = DC.convdc(2,26); % Voltage angle converter terminals [deg]
PF.AC_bus2.P_C2_AC = DC.convdc(2,27); % Active power at converter terminal [MW]
PF.AC_bus2.Q_C2_AC = DC.convdc(2,28); % Reactive power at converter terminals [Mvar]
PF.AC_bus2.P_C2_loss = DC.convdc(2,29); % Converter losses [MW]
PF.AC_bus2.V_F2_AC_mag = DC.convdc(2,30); % Voltage magnitude at the converter filter [pu]
PF.AC_bus2.V_F2_AC_ang = DC.convdc(2,31); % Voltage angle at the converter filter [deg]
PF.AC_bus2.P_F2_AC = DC.convdc(2,32); % Active power at the filter bus [MW]
PF.AC_bus2.Q_F2_sf_AC = DC.convdc(2,33); % Reactive power through transformer at the filter bus [Mvar]
PF.AC_bus2.Q_F2_cf_AC = DC.convdc(2,34); % Reactive power through reactor at the filter bus [Mvar]

%% Branch - Retrieving of the PF results 
PF.DC_branch.R_DC_pu = DC.branchdc(1,3); % Resistance of the dc cable [pu]
PF.DC_branch.P_DC_branch1 = DC.branchdc(1,10); % Power at end 1 [MW]
PF.DC_branch.P_DC_branch2 = DC.branchdc(1,11); % Power at end 2 [MW]
PF.DC_branch.P_DC_losses = PF.DC_branch.P_DC_branch1 + PF.DC_branch.P_DC_branch2; % Power losses along the branch (cable) [MW]