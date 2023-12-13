function mpc = BE_energyisland()
%case BE energy island connected with AC and DC lines, also having a dc interconnector with UK
% It consists of 5 converters connected to different terminal of a 3 bus dc system and 5, 2 bus ac systems
%% system MVA base
mpc.baseMVA = 1000;

%   Network data from ... modifed by chandra kant Jat
%   G.W. Stagg, A.H. El-Abiad, "Computer methods in power system analysis",
%   McGraw-Hill, 1968.%
%   MATPOWER case file data provided by Jef Beerten.
%   MCDC power flow related modification by Chnadra Kant Jat on November 14, 2023


%% AC bus data
%column_names%	bus_i	type	Pd	    Qd	    Gs	    Bs  area	Vm    Va	baseKV	zone	Vmax	Vmin
mpc.bus = [
	        1       3       250	    100	    0       0    1       1     0	320     1       1.1     0.9;
	        2       1       0	    0	    0       0    1       1     0	320     1       1.1     0.9;
	        3       3       650	    75	    0       0    2       1     0	320     1       1.1     0.9;
	        4       1       0	    0	    0       0    2       1     0	320     1       1.1     0.9;
	        5       3       600	    100	    0       0    3       1     0	320     1       1.1     0.9;
            6       1       0 	    0	    0       0    3       1     0	320     1       1.1     0.9;
            7       3       250	    75	    0       0    4       1     0	320     1       1.1     0.9;
            8       1       0 	    0	    0       0    4       1     0	320     1       1.1     0.9;
            9       3       200	    75	    0       0    5       1     0	320     1       1.1     0.9;
            10      1       0 	    0	    0       0    5       1     0	320     1       1.1     0.9;
        ];

%% Generator data
 %column_names%	bus  Pg      Qg	    Qmax	Qmin	Vg    mBase    status	  Pmax	  Pmin	pc1 pc2 qlcmin qlcmax qc2min qc2max ramp_agc ramp_10 ramp_30 ramp_q apf
mpc.gen = [
            1	    1000     0	    500      -500    1.06	1000       1       1000     0    0   0      0    0       0       0       0       0       0       0    0;
            3	    100      0	    300      -300    1      1000       1       500     0    0   0      0    0       0       0       0       0       0       0    0;
            5	    100      0	    500      -500    1.06	1000       1       500     0    0   0      0    0       0       0       0       0       0       0    0;
            7	    1000     0	    500      -500    1.06	1000       1       1000     0    0   0      0    0       0       0       0       0       0       0    0;
            9	    100      0	    500      -500    1.06	1000       1       500     0    0   0      0    0       0       0       0       0       0       0    0;
         ];

%% branch data
         %column_names%	fbus	tbus	  r	     x	     b	    rateA    rateB  rateC  ratio angle status angmin angmax
mpc.branch = [
                           1       2       0.00995    0.0995    0      1000    1000   1000     0       0       1   -60     60;
                           3       4       0.00995    0.0995    0      1000    1000   1000     0       0       1   -60     60;
                           5       6       0.00995    0.0995    0      1000    1000   1000     0       0       1   -60     60;
                           7       8       0.00995    0.0995    0      1000    1000   1000     0       0       1   -60     60;
                           9       10      0.00995    0.0995    0      1000    1000   1000     0       0       1   -60     60;
            ];


%% DC grid topology
mpc.dcpol=2;
% numbers of poles (1=monopolar grid, 2=bipolar grid)
%% DC bus data
            %column_names% busdc_i grid    Pdc     Vdc     basekVdc    Vdcmax  Vdcmin  Cdc
mpc.busdc = [
                1       1      0       1       320         1.1     0.9     0;
                2       1      0       1       320         1.1     0.9     0;
	            3       1      0       1       320         1.1     0.9     0;
            ];

%% Converters data
            %column_names%  busdc_i busac_i type_dc type_ac  P_g     Q_g   islcc    Vtar    rtf     xtf  transformer   tm   bf   filter   rc      xc    reactor   basekVac    Vmmax   Vmmin   Imax    status   LossA    LossB  LossCrec LossCinv    droop      Pdcset    Vdcset  dVdcset Pacmax   Pacmin Qacmax Qacmin conv_confi connect_at ground_type ground_z
mpc.convdc = [
                                1       2       2       1     -750      150    0        1     0.001     0.18    1    1   0.01    0   0.0005   0.01875    1       320        1.1     0.9     1.1     1     1.103    0.887   2.885    1.885     0.0050    -58.6274   1.0079      0     1000    -1000   500     -500      1           1         1         0.5 ;
                                2       4       1       1       0       150    0        1     0.001     0.18    1    1   0.01    0   0.0005   0.01875    1       320        1.1     0.9     1.1     1     1.103    0.887   2.885    2.885     0.0070     21.9013   1.0000      0     1000    -1000   500     -500      1           1         0         0.5 ;
	                            3       6       2       1      500      150    0        1     0.001     0.18    1    1   0.01    0   0.0005   0.01875    1       320        1.1     0.9     1.1     1     1.103    0.887   2.885    2.885     0.0070     21.9013   1.0000      0     1000    -1000   500     -500      1           2         0         0.5 ;
                                1       8       1       1     -750      150    0        1     0.001     0.18    1    1   0.01    0   0.0005   0.01875    1       320        1.1     0.9     1.1     1     1.103    0.887   2.885    1.885     0.0050    -58.6274   1.0079      0     1000    -1000   500     -500      1           2         0         0.5 ;
                                2       10      1       1       0       150    0        1     0.001     0.18    1    1   0.01    0   0.0005   0.01875    1       320        1.1     0.9     1.1     1     1.103    0.887   2.885    2.885     0.0070     21.9013   1.0000      0     1000    -1000   500     -500      1           2         0         0.5 ;
            ];

%% DC branches
%column_names%   fbusdc  tbusdc      r      l   c   rateA   rateB   rateC   status line_confi return_type return_z connect_at
mpc.branchdc = [
                    1       2     0.002781   0   0    2000     2000     2000     1        2           2       0.04        0;  %bipolar
	                1       3     0.002781   0   0    1000     1000     1000     1        2           1       0.04        0;  %monopolar
               ];

%% Generator cost data
%	1	startup	shutdown	n	x1	y1	...	xn	yn
%	2	startup	shutdown	n	c(n-1)	...	c0
mpc.gencost = [
	                2	0	0	3	0   1	0;
	                2	0	0	3	0   4	0;
                        2	0	0	3	0   20	0;
	                2	0	0	3       0   1	0;
	                2	0	0	3       0   10	0;
               ];

% adds current ratings to branch matrix
%column_names%	c_rating_a
%mpc.branch_currents = [
%100;100;100;100;100;100;100;100;100;100;100;100;100;100;
%];
