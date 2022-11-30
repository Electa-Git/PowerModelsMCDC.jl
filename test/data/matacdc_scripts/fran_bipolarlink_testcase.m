function mpc = case_fran.ids()
%% Francesco G. Puricelli April 2022 - KUL
% HVDC monopolar connection.
% DC grid:
% Busdc 1: PQ MMC -> MMC controlling active and reactive power at its
% terminals
% Busdc 2: VdcQ MMC -> MMC controlling dc voltage and reactive power at its
% terminals
% AC grid:
% file to be used together with the DC case: "DC_case_Fra_monopolar_HVDC.m"
%% system MVA base
mpc.baseMVA = 1000;

%% bus data
%	bus_i	type	Pd      Qd	Gs	Bs	area	Vm      Va	baseKV	zone	Vmax	Vmin
mpc.bus = [
	1       2       0     0	0   0   1       1       0	400     1       1.1     0.9;
	2       1       100     0	0   0   1       1       0	400     1       1.1     0.9;
    3       2       0     0	0   0   1       1       0	400     1       1.1     0.9;
	4       1       100     0	0   0   1       1       0	400     1       1.1     0.9;
    5       2       0     0	0   0   1       1       0	400     1       1.1     0.9;
	6       1       100     0	0   0   1       1       0	400     1       1.1     0.9;
    7       2       0     0	0   0   1       1       0	400     1       1.1     0.9;
	8       1       100     0	0   0   1       1       0	400     1       1.1     0.9;
];


%% generator data
%	bus	Pg      Qg	Qmax	Qmin	Vg	mBase       status	Pmax	Pmin	pc1 pc2 qlcmin qlcmax qc2min qc2max ramp_agc ramp_10 ramp_30 ramp_q apf
mpc.gen = [
	1	0       0	500      -500    1.06	100       1       250     10 0 0 0 0 0 0 0 0 0 0 0;
    3	0       0	300      -300    1      100       1       250     10 0 0 0 0 0 0 0 0 0 0 0;
    5	0       0	500      -500    1.06	100       1       250     10 0 0 0 0 0 0 0 0 0 0 0;
    7	0       0	300      -300    1      100       1       250     10 0 0 0 0 0 0 0 0 0 0 0;
];

%% branch data
%	fbus	tbus	r	x	b	rateA	rateB	rateC	ratio	angle
%	status angmin angmax
mpc.branch = [
    1   2   0.01055    0.1055    0    1000   1000   1000     0       0       1 -60 60;
    3   4   0.01055    0.1055    0    1000   1000   1000     0       0       1 -60 60;
    5   6   0.01055    0.1055    0    1000   1000   1000     0       0       1 -60 60;
    7   8   0.01055    0.1055    0    1000   1000   1000     0       0       1 -60 60;
    ];


%% Francesco G. Puricelli April 2022 - KUL
% HVDC monopolar connection.
% Busdc 1: PQ MMC -> MMC controlling active and reactive power at its
% terminals
% Busdc 2: VdcQ MMC -> MMC controlling dc voltage and reactive power at its
% terminals
% file to be used together with the AC case: "AC_case_Fra_monopolar_HVDC_inf.m"

%% system MVA base
% baseMVAac = 1060;
% baseMVAdc = 1060;

%% dc grid topology
 mpc.pol=1;  % numbers of poles (1=monopolar grid, 2=bipolar grid)


%% bus data
%column_names%   busdc_i grid    Pdc     Vdc     basekVdc    Vdcmax  Vdcmin  Cdc
mpc.busdc = [
  1              1       0       1       640         1.1     0.9     0;
  2              1       0       1       640         1.1     0.9     0;


];

%% converters -> contains all converter station data -> loss data, impedance values, status...
% busdc_i-type_dc-type_ac - P_g   - Q_g - Vtar - rtf  - xtf -  bf  -  rc   -  xc  -basekVac -  Vmmax   Vmmin   Imax    status   LossA LossB  LossCrec LossCinv

%% converters
%column_names%   busdc_i busac_i type_dc type_ac P_g   Q_g   islcc Vtar    rtf xtf  transformer tm   bf filter    rc      xc  reactor   basekVac    Vmmax   Vmmin   Imax    status   LossA LossB  LossCrec LossCinv  droop      Pdcset    Vdcset  dVdcset Pacmax Pacmin Qacmax Qacmin conv_confi ground_type ground_z connect_at
mpc.convdc = [
        1       2  2 1       -60    -40    0 1           0.001  0.18 1 1 0.01 1 0.01   0.01 1  345         1.1     0.9     1.1     1       1.103 0.887  2.885    1.885      0.0050    -58.6274   1.0079   0 100 -100 50 -50 1 1 0.5 1;
        1       4  1 1       -60    -40    0 1           0.001  0.18 1 1 0.01 1 0.01   0.01 1  345         1.1     0.9     1.1     1       1.103 0.887  2.885    2.885      0.0070     21.9013   1.0000   0 100 -100 50 -50 1 0 0.5 2;
        2       6  1 1       -60    -40    0 1           0.001  0.18 1 1 0.01 1 0.01   0.01 1  345         1.1     0.9     1.1     1       1.103 0.887  2.885    1.885      0.0050    -58.6274   1.0079   0 100 -100 50 -50 1 0 0.5 1;
        2       8  1 1       -60    -40    0 1           0.001  0.18 1 1 0.01 1 0.01   0.01 1  345         1.1     0.9     1.1     1       1.103 0.887  2.885    2.885      0.0070     21.9013   1.0000   0 100 -100 50 -50 1 0 0.5 2;
    ];

%column_names%   fbusdc  tbusdc  r      l        c   rateA   rateB   rateC   status line_confi return_type return_z connect_at
mpc.branchdc = [
  1       2       0.001384   0   0    1000     1000     1000     1  2 2 0.04 0;  %bipolar
];


%% generator cost data
%	1	startup	shutdown	n	x1	y1	...	xn	yn
%	2	startup	shutdown	n	c(n-1)	...	c0
mpc.gencost = [
	2	0	0	3	0  1	0;
	2	0	0	3	0  10	0;
  2	0	0	3	00  100	0;
	2	0	0	3	000  1000	0;

 ];
