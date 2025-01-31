function mpc = case5_2gr_PM.ids()
%case four ac grids connected with a monopolar-bipolar DC grid
% Total 8 ac nodes and 4 generator.
%   Please see 'help caseformat' for details on the case file format.

%   MATPOWER case file data provided by Jef Beerten.
%   MCDC power flow related modification by Chnadra Kant Jat on July 11, 2024

%% MATPOWER Case Format : Version 1
%%-----  Power Flow Data  -----%%
%% system MVA base
mpc.baseMVA = 1000;

%% bus data
%	bus_i	type	  Pd	    Qd    Gs	Bs	area	  Vm     Va	baseKV	zone	Vmax	Vmin
mpc.bus = [
	1       3      5000	   50	  0   0   1       1   	0	    400     1       1.1     0.9;
	2       1      4000	    0	  0   0   1       1     0   	400     1       1.1     0.9;
	3       3     50000	   100	  0   0   2       1     0   	400     1       1.1     0.9;
	4       1       0	    0	  0   0   2       1     0   	400     1       1.1     0.9;
%	5       3      500	   50	  0   0   3       1     0   	400     1       1.1     0.9;
%  6       1        0 	    0	  0   0   3       1   	0	    400     1       1.1     0.9;
%	7       3      100     50 	0   0   4       1     0   	400     1       1.1     0.9;
%	8       1        0	    0	  0   0   4       1     0   	400     1       1.1     0.9;
];

%% generator data
%	bus	 Pg   Qg	Qmax	Qmin	Vg	mBase       status	Pmax	Pmin	pc1 pc2 qlcmin qlcmax qc2min qc2max ramp_agc ramp_10 ramp_30 ramp_q apf
mpc.gen = [
	1	   0    0	  500  -500    1.06	  1000      1    100000    0     0 0 0 0 0 0 0 0 0 0 0;
    2	   40   0	  300  -300    1      1000      1    100000    0     0 0 0 0 0 0 0 0 0 0 0;
    3	   0    0	  500  -500    1.06	  1000      1    100000    0     0 0 0 0 0 0 0 0 0 0 0;
    4	   40   0	  300  -300    1      1000      1      4000    0     0 0 0 0 0 0 0 0 0 0 0;
];

%%% branch data
%%	fbus	tbus	  r	        x	          b	   rateA	rateB	rateC	  ratio	angle	  status angmin angmax
mpc.branch = [
%    1    2    0.01055    0.1055    0.00    1000   1000   1000     0       0       1      -60 60;
%    3    4    0.01055    0.1055    0.00    1000   1000   1000     0       0       1      -60 60;
%    5    6    0.01055    0.1055    0.00    1000   1000   1000     0       0       1      -60 60;
%    7    8    0.01055    0.1055    0.00    1000   1000   1000     0       0       1      -60 60;
    ];


%% dc grid topology
%colunm_names% dcpoles
mpc.dcpol=2;
% numbers of poles (1=monopolar grid, 2=bipolar grid)
%% bus data
%column_names%   busdc_i grid    Pdc     Vdc     basekVdc    Vdcmax  Vdcmin  Cdc
mpc.busdc = [
  1              1       0       1       525         1.0     0.9     0;       %1.0 0.99
  2              1       0       1       525         1.0     0.9     0;
  3              1       0       1       525         1.0     0.9     0;
  4              1       0       1       525         1.0     0.9     0;
  5              1       0       1       525         1.0     0.9     0;       %1.0 0.99
  6              1       0       1       525         1.0     0.9     0;
  7              1       0       1       525         1.0     0.9     0;
  8              1       0       1       525         1.0     0.9     0;
];

%% converters
%column_names%   busdc_i busac_i type_dc type_ac P_g   Q_g   islcc Vtar    rtf xtf  transformer tm   bf filter       rc      xc  reactor   basekVac    Vmmax   Vmmin   Imax    status   LossA LossB  LossCrec LossCinv  droop      Pdcset    Vdcset  dVdcset droop_ac     Vacset  Pacmax Pacmin Qacmax Qacmin conv_confi connect_at ground_type ground_z
mpc.convdc = [
                    1       1       2     1      -742        106.0     0    1        0.0041  0.02915   0     1        0.01  0      0.0005   0.01875 0      262.5      1.1     0.9     1.1     1     0   0           0   0         0.1    -58.6274     1.0    0      0.0500    1.0     2000 -2000   1000 -1000         1 1 0 0.5 ;
                    2       2       1     3      742         159       0    1        0.0041  0.02915   0     1        0.01  0      0.0005   0.01875 0      262.5      1.1     0.9     1.1     1     0   0           0   0         0.1     21.9013     1.0    0      0.0500    1.0     2000 -2000   1000 -1000         1 1 0 0.5 ;
	                3       3       2     1      -424        53        0    1        0.0041  0.02915   0     1        0.01  0      0.0005   0.01875 0      262.5      1.1     0.9     1.1     1     0   0           0   0         0.1     21.9013    -1.0    0      0.0500    1.0     2000 -2000   1000 -1000         1 1  0 0.5 ;
                    4       4       1     1      -530       -212       0    1        0.0041  0.02915   0     1        0.01  0      0.0005   0.01875 0      262.5      1.1     0.9     1.1     1     0   0           0   0         0.1    -58.6274    -1.0    0      0.0500    1.0     2000 -2000   1000 -1000         1 1  1 0.5 ;
					5       1       2     1      -742        106.0     0    1        0.0041  0.02915   0     1        0.01  0      0.0005   0.01875 0      262.5      1.1     0.9     1.1     1     0   0           0   0         0.1    -58.6274     1.0    0      0.0500    1.0     2000 -2000   1000 -1000         1 2 0 0.5 ;
                    6       2       1     3      742         159       0    1        0.0041  0.02915   0     1        0.01  0      0.0005   0.01875 0      262.5      1.1     0.9     1.1     1     0   0           0   0         0.1     21.9013     1.0    0      0.0500    1.0     2000 -2000   1000 -1000         1 2 0 0.5 ;
	                7       3       2     1      -424        53        0    1        0.0041  0.02915   0     1        0.01  0      0.0005   0.01875 0      262.5      1.1     0.9     1.1     1     0   0           0   0         0.1     21.9013    -1.0    0      0.0500    1.0     2000 -2000   1000 -1000         1 2  0 0.5 ;
                    8       4       1     1      -530       -212       0    1        0.0041  0.02915   0     1        0.01  0      0.0005   0.01875 0      262.5      1.1     0.9     1.1     1     0   0           0   0         0.1    -58.6274    -1.0    0      0.0500    1.0     2000 -2000   1000 -1000         1 2  1 0.5 ;
];
 
%% branches
%column_names%   fbusdc  tbusdc  r      l        c   rateA   rateB   rateC   status line_confi connect_at return_type return_z 
mpc.branchdc = [
               	  1       2       0.01155   0   0    1000     1000     1000     1           1      1             2    0.01155 ;  %bipolar
	              1       3       0.01155   0   0    1000     1000     1000     1           1      1             2    0.01155 ;  %bipolar
	              2       3       0.01155   0   0    1000     1000     1000     1           1      1             2    0.01155 ;  %bipolar
	              1       4       0.01155   0   0    1000     1000     1000     1           1      1             2    0.01155 ;  %bipolar
	              3       4       0.01155   0   0    1000     1000     1000     1           1      1             2    0.01155 ;  %bipolar
				  5       6       0.01155   0   0    1000     1000     1000     1           1      2             2    0.01155 ;  %bipolar
	              5       7       0.01155   0   0    1000     1000     1000     1           1      2             2    0.01155 ;  %bipolar
	              6       7       0.01155   0   0    1000     1000     1000     1           1      2             2    0.01155 ;  %bipolar
	              5       8       0.01155   0   0    1000     1000     1000     1           1      2             2    0.01155 ;  %bipolar
	              7       8       0.01155   0   0    1000     1000     1000     1           1      2             2    0.01155 ;  %bipolar
 ];

%% generator cost data
%	1	startup	shutdown	n	x1	y1	...	xn	yn
%	2	startup	shutdown	n	c(n-1)	...	c0
mpc.gencost = [
	2	0	0	3	0  1	0;
	2	0	0	3	0  1	0;
  	2	0	0	3	0  1	0;
	2	0	0	3 	0  0	0;
];

% adds current ratings to branch matrix
%column_names%	c_rating_a
%mpc.branch_currents = [
%100;100;100;100;100;100;100;100;100;100;100;100;100;100;
%];


