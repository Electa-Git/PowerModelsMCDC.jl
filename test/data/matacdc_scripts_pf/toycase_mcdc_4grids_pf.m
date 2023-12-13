function mpc = case5_2gr_PM.ids()
%case four ac grids connected with a monopolar-bipolar DC grid
% Total 8 ac nodes and 4 generator.
%   Please see 'help caseformat' for details on the case file format.
%
%   case file can be used together with dc case files "case5_stagg_....m"
%
%   MATPOWER case file data provided by Jef Beerten.
%   MCDC power flow related modification by Chnadra Kant Jat on November 14, 2023

%% MATPOWER Case Format : Version 1
%%-----  Power Flow Data  -----%%
%% system MVA base
mpc.baseMVA = 1000;

%% bus data
%	bus_i	type	Pd	Qd	Gs	Bs	area	Vm      Va	baseKV	zone	Vmax	Vmin
mpc.bus = [
	1       3       20	  100	  0   0   1       1     	0	345     1       1.1     0.9;
	2       1       0	  0	  0   0   1       1       0	345     1       1.1     0.9;
	3       3       30	  100	  0   0   2       1       0	345     1       1.1     0.9;
	4       1       0	  0	  0   0   2       1       0	345     1       1.1     0.9;
	5       3       40	  75	  0   0   3       1       0	345     1       1.1     0.9;
  6       1       0 	0	  0   0   3       1     	0	345     1       1.1     0.9;
	7       3       10  20 	0   0   4       1       0	345     1       1.1     0.9;
	8       1       0	  0	  0   0   4       1       0	345     1       1.1     0.9;
  9       3       40	  80	  0   0   5       1       0	345     1       1.1     0.9;
	10      1      0   0	  0 	0   5       1       0	345     1       1.1     0.9;
];

%% generator data
%	bus	Pg      Qg	Qmax	Qmin	Vg	mBase       status	Pmax	Pmin	pc1 pc2 qlcmin qlcmax qc2min qc2max ramp_agc ramp_10 ramp_30 ramp_q apf
mpc.gen = [
	1	0       0	500      -500    1.06	  1000       1       500     0 0 0 0 0 0 0 0 0 0 0 0;
  3	40      0	300      -300    1      1000       1       500     0 0 0 0 0 0 0 0 0 0 0 0;
  5	0       0	500      -500    1.06	  1000       1       500     0 0 0 0 0 0 0 0 0 0 0 0;
  7	40      0	300      -300    1      1000       1       500     0 0 0 0 0 0 0 0 0 0 0 0;
  9	40      0	300      -300    1      1000       1       200     0 0 0 0 0 0 0 0 0 0 0 0;
];

%% branch data
%	fbus	tbus	r	x	b	rateA	rateB	rateC	ratio	angle
%	status angmin angmax
mpc.branch = [
    1  2   0.02    0.06    0.06    1000   1000   1000     0       0       1 -60 60;
    3  4   0.08    0.24    0.05    1000   1000   1000     0       0       1 -60 60;
    5  6   0.06    0.18    0.04    1000   1000   1000     0       0       1 -60 60;
    7  8   0.01    0.03    0.02    1000   1000   1000     0       0       1 -60 60;
    9  10   0.01    0.03    0.02    1000   1000   1000     0       0       1 -60 60;
];


%% dc grid topology
%colunm_names% dcpoles
mpc.dcpol=2;
% numbers of poles (1=monopolar grid, 2=bipolar grid)
%% bus data
%column_names%   busdc_i grid    Pdc     Vdc     basekVdc    Vdcmax  Vdcmin  Cdc
mpc.busdc = [
  1              1       0       1       345         1.1     0.9     0;
  2              1       0       1       345         1.1     0.9     0;
	3              1       0       1       345         1.1     0.9     0;
	4              1       0       1       345         1.1     0.9     0;
];

%% converters
%column_names%   busdc_i busac_i type_dc type_ac P_g   Q_g   islcc Vtar    rtf xtf  transformer tm   bf filter    rc      xc  reactor   basekVac    Vmmax   Vmmin   Imax    status   LossA LossB  LossCrec LossCinv  droop      Pdcset    Vdcset  dVdcset Pacmax Pacmin Qacmax Qacmin conv_confi connect_at ground_type ground_z
mpc.convdc = [
    1       2   2       1       -60    -40    0 1     0.01  0.18 1 1 0.01 0 0.0005   0.01875 1  345         1.1     0.9     1.1     1       1.103 0.887  2.885    1.885      0.0050    -58.6274   1.0079   0 1000 -1000 500 -500 1 1 1 0.5 ;
    2       4   1       1       0       0     0 1     0.01  0.18 1 1 0.01 0 0.0005   0.01875 1  345         1.1     0.9     1.1     1       1.103 0.887  2.885    2.885      0.0070     21.9013   1.0000   0 1000 -1000 500 -500 1 1 0 0.5 ;
		3       6   2       1       0       0     0 1     0.01  0.18 1 1 0.01 0 0.0005   0.01875 1  345         1.1     0.9     1.1     1       1.103 0.887  2.885    2.885      0.0070     21.9013   1.0000   0 1000 -1000 500 -500 1 2 0 0.5 ;
    1       8   1       1       0        0    0 1     0.01  0.18 1 1 0.01 0 0.0005   0.01875 1  345         1.1     0.9     1.1     1       1.103 0.887  2.885    1.885      0.0050    -58.6274   1.0079   0 1000 -1000 500 -500 1 2 0 0.5 ;
    2       4   1       1       0       0     0 1     0.01  0.18 1 1 0.01 0 0.0005   0.01875 1  345         1.1     0.9     1.1     1       1.103 0.887  2.885    2.885      0.0070     21.9013   1.0000   0 1000 -1000 500 -500 1 2 0 0.5 ;
];

%% branches
%column_names%   fbusdc  tbusdc  r      l        c   rateA   rateB   rateC   status line_confi return_type return_z connect_at
mpc.branchdc = [
  1       4       0.052   0   0    100     100     100     1  2 2 0.04 0;  %bipolar
	2       4       0.052   0   0    100     100     100     1  2 2 0.04 0;  %bipolar
	3       4       0.052   0   0     50      50      50     1  1 2 0.04 2;  %monopolar
 ];

%% generator cost data
%	1	startup	shutdown	n	x1	y1	...	xn	yn
%	2	startup	shutdown	n	c(n-1)	...	c0
mpc.gencost = [
	2	0	0	3	0  1	0;
	2	0	0	3	0  4	0;
  2	0	0	3	0  10	0;
	2	0	0	3 0	 2	0;
	2	0	0	3 0	 20	0;
];

% adds current ratings to branch matrix
%column_names%	c_rating_a
%mpc.branch_currents = [
%100;100;100;100;100;100;100;100;100;100;100;100;100;100;
%];
