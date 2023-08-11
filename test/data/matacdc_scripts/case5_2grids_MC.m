function mpc = case5_2grids_MC()
%CASE5_2GRIDS_MC
%
%   Network data from ...
%   G.W. Stagg, A.H. El-Abiad, "Computer methods in power system analysis",
%   McGraw-Hill, 1968.
%
%   MATPOWER case file data provided by Jef Beerten.

%% MATPOWER Case Format : Version 2
mpc.version = '2';

%%-----  Power Flow Data  -----%%
%% system MVA base
mpc.baseMVA = 100;

%% AC bus
% bus_i type Pd Qd Gs Bs area   Vm Va baseKV zone Vmax Vmin
mpc.bus = [
      1    3  0  0  0  0    1 1.06  0    345    1  1.1  0.9;
      2    1 20 10  0  0    1 1     0    345    1  1.1  0.9;
      3    1 45 15  0  0    1 1     0    345    1  1.1  0.9;
      4    1 40  5  0  0    1 1     0    345    1  1.1  0.9;
      5    1 60 10  0  0    1 1     0    345    1  1.1  0.9;
      6    3  0  0  0  0    2 1.06  0    345    1  1.1  0.9;
      7    1 20 10  0  0    2 1     0    345    1  1.1  0.9;
      8    1 45 15  0  0    2 1     0    345    1  1.1  0.9;
      9    1 40  5  0  0    2 1     0    345    1  1.1  0.9;
     10    1 60 10  0  0    2 1     0    345    1  1.1  0.9;
     11    3 50 10  0  0    3 1     0    345    1  1.1  0.9;
];

%% generator
% bus Pg Qg Qmax Qmin   Vg mBase status Pmax Pmin
mpc.gen = [
    1  0  0  500 -500 1.06   100      1  250   10;
    2 40  0  300 -300 1      100      1  300   10;
    6  0  0  500 -500 1.06   100      1  250   10;
    7 40  0  300 -300 1      100      1  300   10;
   11 40  0  300 -300 1      100      1  300   10;
];

%% generator cost
% 1 startup shutdown n x1 y1 ... xn yn
% 2 startup shutdown n c(n-1) ... c0
mpc.gencost = [
  2       0        0 2 1   0;
  2       0        0 2 3.5 0;
  2       0        0 2 2.0 0;
  2       0        0 2 5   0;
  2       0        0 2 7   0;
];

%% AC branch
% fbus tbus    r    x    b rateA rateB rateC ratio angle status angmin angmax
mpc.branch = [
     1    2 0.02 0.06 0.06   100   100   100     0     0      1    -60     60;
     1    3 0.08 0.24 0.05   100   100   100     0     0      1    -60     60;
     2    3 0.06 0.18 0.04   100   100   100     0     0      1    -60     60;
     2    4 0.06 0.18 0.04   100   100   100     0     0      1    -60     60;
     2    5 0.04 0.12 0.03   100   100   100     0     0      1    -60     60;
     3    4 0.01 0.03 0.02   100   100   100     0     0      1    -60     60;
     4    5 0.08 0.24 0.05   100   100   100     0     0      1    -60     60;
     6    7 0.02 0.06 0.06   100   100   100     0     0      1    -60     60;
     6    8 0.08 0.24 0.05   100   100   100     0     0      1    -60     60;
     7    8 0.06 0.18 0.04   100   100   100     0     0      1    -60     60;
     7    9 0.06 0.18 0.04   100   100   100     0     0      1    -60     60;
     7   10 0.04 0.12 0.03   100   100   100     0     0      1    -60     60;
     8    9 0.01 0.03 0.02   100   100   100     0     0      1    -60     60;
     9   10 0.08 0.24 0.05   100   100   100     0     0      1    -60     60;
];

%column_names% c_rating_a
mpc.branch_currents = [
                      100;
                      100;
                      100;
                      100;
                      100;
                      100;
                      100;
                      100;
                      100;
                      100;
                      100;
                      100;
                      100;
                      100;
];

%% DC bus
%column_names% busdc_i grid Pdc Vdc basekVdc Vdcmax Vdcmin Cdc
mpc.busdc = [
                     1    1   0   1      345    1.1    0.9   0;
                     2    1   0   1      345    1.1    0.9   0;
                     3    1   0   1      345    1.1    0.9   0;
                     4    1   0   1      345    1.1    0.9   0;
];

%% converter
%column_names% busdc_i busac_i type_dc type_ac P_g Q_g islcc Vtar  rtf xtf transformer tm   bf filter   rc   xc reactor basekVac Vmmax Vmmin Imax status LossA LossB LossCrec LossCinv  droop   Pdcset Vdcset dVdcset Pacmax Pacmin Qacmax Qacmin conv_confi connect_at ground_type ground_z
mpc.convdc = [
                     1       2       2       1 -60 -40     0    1 0.01 0.01          1  1 0.01      1 0.01 0.01       1      345   1.1   0.9  1.1      1 1.103 0.887    2.885    1.885 0.0050 -58.6274 1.0079       0    100   -100     50    -50          2          0           1      0.5;
                     2       7       1       1   0   0     0    1 0.01 0.01          1  1 0.01      1 0.01 0.01       1      345   1.1   0.9  1.1      1 1.103 0.887    2.885    2.885 0.0070  21.9013 1.0000       0    100   -100     50    -50          2          0           0      0.5;
                     3      11       1       1   0   0     0    1 0.01 0.01          1  1 0.01      1 0.01 0.01       1      345   1.1   0.9  1.1      1 1.103 0.887    2.885    2.885 0.0070  21.9013 1.0000       0    100   -100     50    -50          1          2           0      0.5;
];

%% DC branch
%column_names% fbusdc tbusdc     r l c rateA rateB rateC status line_confi return_type return_z connect_at
mpc.branchdc = [
                    1      4 0.052 0 0   100   100   100      1          2           2    0.052          0; % bipolar
                    2      4 0.052 0 0   100   100   100      1          2           2    0.052          0; % bipolar
                    3      4 0.052 0 0    50    50    50      1          1           2    0.052          2; % monopolar
];
