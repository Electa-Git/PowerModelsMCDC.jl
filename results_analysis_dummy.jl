Annual_Price_diff_uk_dk= (1e-6)*[195361.1995	199063.2011	119290.0093	195573.6492	111917.4162	157144.2191	156500.8126];
Annual_Price_diff_uk_de= (1e-6)*[168637.9375	179989.241	133463.2666	220999.3762	123226.057	175987.7953	172279.7075];
Annual_Price_diff_de_dk= (1e-6)*[58694.79	170280.0285	94827.78798	157796.8345	87566.51277	127185.6681	127401.6074];

	2018

Annual_Price_diff_uk_dk= (1e-6)*[194589.074	179291.4629	102813.2303	170483.0938	99580.73758	136177.3067	136869.4457	];
Annual_Price_diff_uk_de= (1e-6)*[190265.539	150352.325	110590.5573	185434.2146	105238.621	146466.1176	144278.2071	];
Annual_Price_diff_de_dk= (1e-6)*[35714.44	115035.8474	41876.71225	70801.46982	41512.37349	57845.54634	61246.27878	];



Annual_Price_diff_uk_dk= (1e-6)*[101464.205	170753.6497	92636.55276	156115.5383	93496.28579	123728.2312	125868.7845	];
Annual_Price_diff_uk_de= (1e-6)*[105916.341	138191.7267	100839.9868	171002.7116	98614.07993	134262.571	132855.5714	];
Annual_Price_diff_de_dk= (1e-6)*[21928.44	100387.9606	36743.11923	58224.77139	27041.36904	44949.53432	38375.18687	];
	2020
Annual_Price_diff_uk_dk= (1e-6)*[145134.605		328125.4682	202692.0548	338565.5041	189551.7782	271204.5006	270652.9399];
Annual_Price_diff_uk_de= (1e-6)*[97559.384		172850.6052	125803.426	213475.7323	120838.4563	167973.222	166019.4701];
Annual_Price_diff_de_dk= (1e-6)*[56178.75		243524.2618	134878.8431	225102.3502	125920.9419	181850.0353	183474.3375];

Annual_Price_diff_uk_dk= (1e-6)*[
Annual_Price_diff_uk_de= (1e-6)*[
Annual_Price_diff_de_dk= (1e-6)*[




    [9.1210 10.3722 14.0825 8.8588;
    8.9074 10.6598 14.8298 8.6750;
   10.1148 12.6177 18.8053 9.7609];

   [29/03/2021, 12:29:12] Jay Dave: m = JuMP.Model(JuMP.with_optimizer(“C:/Users/mayar.madboly/Downloads/couenne-win64.exe”, print_level =0))
   [29/03/2021, 12:29:46] Jay Dave: https://github.com/coin-or/Couenne <https://github.com/coin-or/Couenne>
   [29/03/2021, 12:35:07] Jay Dave: juniper = JuMP.with_optimizer(Juniper.Optimizer, mip_solver=cbc_solver, nl_solver = ipopt)
   [29/03/2021, 12:35:21] Jay Dave: ipopt = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-4, print_level=1)

       cbc_solver = JuMP.with_optimizer(Cbc.Optimizer)


	   /Users/cjat/Downloads/couenne-osx/couenne
-----------------

#######ACgrid side#######
generation
"4, 0.1"
"1, 1.4288307278849228"
"5, 0.1"
"2, 0.9135664979608048"
"3, 1.4288126917129407"
AC Bus Va and Vm
"4, -0.09024397646745408, 1.0598932052594834"
"1, 7.045735287856155e-17, 1.0999999917627485"
"2, -0.04980712445338442, 1.080978028583292"
"6, 0.049813122325943204, 1.0999999912499796"
"11, -0.0031484788261422797, 1.0926897162600477"
"5, -0.10424470759187503, 1.0534359886829614"
"7, -2.8124861992296647e-5, 1.0811090570328594"
"8, -0.03479873716521496, 1.0609051972459709"
"10, -0.05445092166735454, 1.0535630687059292"
"9, -0.040449263801025266, 1.0600015976358916"
"3, -0.08459407881579677, 1.0608037109091746"
AC branch flows
"4, 0.2711316992349958, -0.26726881916364714"
"1, 0.9999932260245792, -0.9834381022729021"
"12, 0.543350526615469, -0.5330216899501541"
"2, 0.42883750186034364, -0.4164852807609917"
"6, 0.20040906351274443, -0.2000418702613083"
"11, 0.27113802304670465, -0.26727527946674323"
"13, 0.20039573892026907, -0.20002851997711682"
"5, 0.5433458381959996, -0.5330150039989874"
"14, 0.06730379944386, -0.06697831004984589"
"7, 0.06731068942495538, -0.0669849960010127"
"8, 0.9999991381233829, -0.9834468554080398"
"10, 0.2369210539307972, -0.233929856072917"
"9, 0.42881355358955775, -0.4164658828473521"
"3, 0.23691466343247675, -0.23392378275175277"
###DC grid side###
DC bus Vm
"4, [1.0953677091046004, -1.0900115789085736, 3.6303606433902076e-12]"
"1, [1.0999994202923846, -1.0999999311449213, -2.7756958995901875e-11]"
"2, [1.090735997916816, -1.0900930477776194, 2.378968837560748e-14]"
"3, [1.000000000382289, -1.0698719366977865, -1.430102298089872e-15]"

[1.0999994202923846, -1.0999999311449213, -2.7756958995901875e-11;
1.090735997916816, -1.0900930477776194, 2.378968837560748e-14;
1.000000000382289, -1.0698719366977865, -1.430102298089872e-15;
1.0953677091046004, -1.0900115789085736, 3.6303606433902076e-12]


.....conv....
.....pgrid....
"1, [0.20803343879275626, 0.43757896057747875]"
"2, [-0.18243307759935706, 0.014470324023708635]"
"3, [-0.4000000079963923]"

[0.20803343879275626, 0.43757896057747875;
-0.18243307759935706, 0.014470324023708635;
-0.4000000079963923]

.....pdc....
"1, [-0.19595690852017092, -0.4225841066243769, 4.288953595798852e-12]"
"2, [0.19430669709502452, -0.003415717221429271, -2.875020629485003e-15]"
"3, [0.41436226954721517, -3.692531802376227e-16]"

[-0.19595690852017092, -0.4225841066243769, 4.288953595798852e-12;
0.19430669709502452, -0.003415717221429271, -2.875020629485003e-15;
0.41436226954721517, -3.692531802376227e-16]
.....pdcg....
"1, [-4.9451548251827166e-12, 1.0663752888189738e-11]"
"2, [-3.837705128716087e-15, -4.951678644562941e-16]"
"3, [-1.5287267786188478e-15]"
.....pdcg_shunt....
"1, -1.4296511982455503e-12"
"2, -0.0"
"3, -0.0"
.....iconv_dc....
"1, [-0.17814273799170097, 0.3841673937056861, -0.20602465571398706]"
"2, [0.17814273799170857, 0.0031334180402283903, -0.18127615603193706]"
"3, [-0.38730081174590403, 0.38730081174590403]"

[-0.17814273799170097, 0.3841673937056861, -0.20602465571398706;
0.17814273799170857, 0.0031334180402283903, -0.18127615603193706;
-0.38730081174590403, 0.38730081174590403]

.....iconv_dcg_shunt....
"1, -2.7756958972004866e-11"
"2, -0.0"
"3, -0.0"
.....conv ground status....
"1, 0.5"
"0, 0.5"
"0, 0.5"
.....DC branch flows....
"1, [0.19595690852017209, 0.42258410662437573, -1.4296511981721948e-12], [-0.1951318028075978, -0.4187469073783238, 5.735196567363604e-23]"
"2, [-0.19430669709502385, 0.0034157172214285764, 1.437510311607569e-15], [0.1951318028075987, -0.00341546194540517, -1.586054112551318e-23]"
"3, [-0.41436226954721617, 1.8462659001340662e-16], [0.4221623693237281, -1.596784167613137e-23]"
.....DC branch losses....
"1, [0.0008251057125742978, 0.0038371992460519144, -1.4296511981148428e-12]"
"2, [0.0008251057125748529, 2.552760234066087e-7, 1.437510295747028e-15]"
"3, [0.007800099776511915, 1.8462657404556494e-16]"
termination status of the pf is:LOCALLY_SOLVED


------------------------

### ACDC results ..  DC grid side###
DC bus Vm
"4, 1.0856628398096324"
"1, 1.0999999360203276"
"2, 1.0813414998570707"
"3, 1.0756470835514989"
.....conv....
.....pgrid....
"1, 0.6253271818754805"
"2, -0.16796126681430334"
"3, -0.4000000080068404"
.....pdc....
"1, -0.6065694197877737"
"2, 0.17972477791136182"
"3, 0.41436226956246247"
generation
"4, 0.1"
"1, 1.4288285295864727"
"5, 0.1"
"2, 0.8932821204235433"
"3, 1.4288153863564423"

"4, 0.1"
"1, 1.4288307278849228"
"5, 0.1"
"2, 0.9135664979608048"
"3, 1.4288126917129407"


"7, -3.1156523285366776e-18, 0.1, -0.1, 0.009970675303040896, 943.9394432953333,0.2967897383807562"
"4, -3.0264866731347477e-18, 0.0789429802054378, -0.1, 0.01545652983185149, 941.2866419635523,0.28606904795556404"
"9, -1.3159975699462854e-17, 0.1, -0.1, 0.00217983663958233, 946.5263560903718,0.3117638290277713"
"10, 7.282439963291094e-18, 0.1, -0.1, -0.001315789678083964, 947.8465984050985,0.3184791761573046"
"2, 1.3005884900615102e-17, 0.04010183250871904, -0.1, 0.0087417710325942, 940.5405186648043,0.29876052424164"
"3, -7.567400590220126e-19, 0.06084395458959025, -0.1, 0.012821778325519064, 940.7966932631995,0.2910169894423897"
"5, 9.292593949057537e-18, 0.09473730886786481, -0.1, 0.0169592475028089, 941.9526218946588,0.2832841192531295"
"8, 5.2763620319319685e-19, 0.1, -0.1, 0.005932203863260695, 945.2087939790687,0.30455425899358096"
"6, 3.6201554229957167e-19, 0.1, -0.1, 0.014329269301400193, 942.8050597399075,0.28839631790103526"
"1, -7.803503383276221e-16, 0.01720841090606418, -0.1, 0.003235936250490254, 940.497800341845,0.3093678598183616"

"1, [1.1, -1.1, 1.617983824364545e-16], [1.1, -1.1, 2.1051772621374507e-16]"
"2, [1.0897680001470686, -1.0949680014965402, 0.1], [1.0897679898945145, -1.0949679904593157, 0.10000001086156314]"
"3, [1.0000000005, -1.0844840049442794, -0.1], [1.0, -1.0844839937629247, -0.10000001149306198]"


function chandra(a,b)
	c=a+b
	return chandra(a,b,c)
end

function chandra(x,y,z)
 d=x+y+z
 return d
end

chandra(3,4)

chandra(1,2,3)

age = 12
if age < 10
    println("$age")
end


((0_p[(7, 2, 12)] + 0_p[(6, 2, 9)] + 0_p[(5, 2, 3)]) + 0) - ((+0_pg[2] - 0) - 0 * 0_vm[2] ^ 2.0) = 0
((0_p[(24, 11, 13)] + 0_p[(23, 11, 12)] + 0_p[(21, 11, 10)]) + 0) - ((0 - +1.355) - 0 * 0_vm[11] ^ 2.0) = 0
((0_p[(68, 39, 43)] + 0_p[(67, 39, 40)] + 0_p[(49, 39, 29)]) + 0) - ((0 - +3.145) - 0 * 0_vm[39] ^ 2.0) = 0
((0_p[(78, 46, 48)] + 0_p[(75, 46, 45)]) + 0) - ((0 - +3.07) - 0 * 0_vm[46] ^ 2.0) = 0
((0_p[(42, 25, 43)] + 0_p[(39, 25, 22)] + 0_p[(36, 25, 21)]) + 0) - ((+0_pg[8] - 0) - 0 * 0_vm[25] ^ 2.0) = 0
((0_p[(87, 55, 57)] + 0_p[(84, 55, 63)]) + 0) - ((0 - +1.515) - 0 * 0_vm[55] ^ 2.0) = 0
((0_p[(70, 42, 43)] + 0_p[(71, 42, 49)] + 0_p[(69, 42, 41)]) + 0) - ((0 - +4.295) - 0 * 0_vm[42] ^ 2.0) = 0
((0_p[(49, 29, 39)] + 0_p[(50, 29, 44)] + 0_p[(63, 29, 35)]) + 0) - ((+0_pg[9] - 0) - 0 * 0_vm[29] ^ 2.0) = 0
((0_p[(88, 58, 61)] + 0_p[(92, 58, 60)] + 0_p[(90, 58, 57)] + 0_p[(91, 58, 56)]) + 0) - ((0 - +1.62) - 0 * 0_vm[58] ^ 2.0) = 0
((0_p[(101, 66, 64)] + 0_p[(100, 66, 54)] + 0_p[(99, 66, 65)] + 0_p[(93, 66, 62)]) + 0) - ((+0_pg[19] - 0) - 0 * 0_vm[66] ^ 2.0) = 0
((0_p[(97, 59, 60)] + 0_p[(89, 59, 56)] + 0_p[(81, 59, 47)]) + 0) - ((+0_pg[16] - 0) - 0 * 0_vm[59] ^ 2.0) = 0
((0_p[(20, 8, 9)] + 0_p[(3, 8, 1)] + 0_p[(16, 8, 5)]) + 0) - ((0 - +1.435) - 0 * 0_vm[8] ^ 2.0) = 0
((0_p[(90, 57, 58)] + 0_p[(87, 57, 55)] + 0_p[(98, 57, 63)]) + 0) - ((0 - 0) - 0 * 0_vm[57] ^ 2.0) = 0
((0_p[(35, 20, 21)] + 0_p[(33, 20, 19)] + 0_p[(40, 20, 18)]) + 0) - ((0 - +0.89) - 0 * 0_vm[20] ^ 2.0) = 0
((0_p[(52, 31, 27)] + 0_p[(44, 31, 26)] + 0_p[(51, 31, 30)]) + 0) - ((0 - +4.225) - 0 * 0_vm[31] ^ 2.0) = 0
((0_p[(28, 14, 18)] + 0_p[(27, 14, 15)] + 0_p[(4, 14, 1)] + 0_p[(12, 14, 4)]) + 0) - ((0 - +0.995) - 0 * 0_vm[14] ^ 2.0) = 0
((0_p[(95, 52, 64)] + 0_p[(83, 52, 54)] + 0_p[(82, 52, 53)]) + 0) - ((0 - +1.545) - 0 * 0_vm[52] ^ 2.0) = 0
((0_p[(32, 18, 24)] + 0_p[(40, 18, 20)] + 0_p[(30, 18, 16)] + 0_p[(28, 18, 14)]) + 0) - ((+0_pg[7] - 0) - 0 * 0_vm[18] ^ 2.0) = 0
((0_p[(58, 33, 34)] + 0_p[(57, 33, 51)] + 0_p[(60, 33, 35)]) + 0) - ((+0_pg[10] - 0) - 0 * 0_vm[33] ^ 2.0) = 0
((0_p[(44, 26, 31)] + 0_p[(45, 26, 40)] + 0_p[(43, 26, 27)] + 0_p[(53, 26, 30)]) + 0) - ((0 - +1.975) - 0 * 0_vm[26] ^ 2.0) = 0
((0_p[(60, 35, 33)] + 0_p[(61, 35, 36)] + 0_p[(62, 35, 47)] + 0_p[(47, 35, 28)] + 0_p[(63, 35, 29)]) + 0) - ((0 - +2.3) - 0 * 0_vm[35] ^ 2.0) = 0
((0_p[(99, 65, 66)] + 0_p[(86, 65, 54)]) + 0) - ((0 - +1.575) - 0 * 0_vm[65] ^ 2.0) = 0
((0_p[(31, 17, 24)] + 0_p[(29, 17, 16)]) + 0) - ((0 - +1.375) - 0 * 0_vm[17] ^ 2.0) = 0
((0_p[(95, 64, 52)] + 0_p[(101, 64, 66)]) + 0) - ((+0_pg[18] - 0) - 0 * 0_vm[64] ^ 2.0) = 0
((0_p[(71, 49, 42)] + 0_p[(72, 49, 43)] + 0_p[(41, 49, 24)]) + 0) - ((0 - 0) - 0 * 0_vm[49] ^ 2.0) = 0
((0_p[(74, 44, 48)] + 0_p[(73, 44, 45)] + 0_p[(50, 44, 29)] + 0_p[(56, 44, 43)]) + 0) - ((0 - +2.37) - 0 * 0_vm[44] ^ 2.0) = 0
((0_p[(66, 37, 38)] + 0_p[(64, 37, 36)] + 0_p[(48, 37, 28)]) + 0) - ((0 - +2.255) - 0 * 0_vm[37] ^ 2.0) = 0
((0_p[(13, 4, 19)] + 0_p[(12, 4, 14)] + 0_p[(8, 4, 3)]) + 0) - ((+0_pg[3] - 0) - 0 * 0_vm[4] ^ 2.0) = 0
((0_p[(75, 45, 46)] + 0_p[(76, 45, 50)] + 0_p[(73, 45, 44)]) + 0) - ((0 - +3.34) - 0 * 0_vm[45] ^ 2.0) = 0
((0_p[(26, 13, 53)] + 0_p[(25, 13, 12)] + 0_p[(24, 13, 11)]) + 0) - ((+0_pg[6] - 0) - 0 * 0_vm[13] ^ 2.0) = 0
(0 + 0) - ((+0_pg[20] - 0) - 0 * 0_vm[67] ^ 2.0) = 0
((0_p[(2, 1, 7)] + 0_p[(4, 1, 14)] + 0_p[(1, 1, 5)] + 0_p[(3, 1, 8)]) + 0) - ((+0_pg[1] - 0) - 0 * 0_vm[1] ^ 2.0) = 0
((0_p[(102, 30, 32)] + 0_p[(51, 30, 31)] + 0_p[(53, 30, 26)]) + 0) - ((0 - +1.33) - 0 * 0_vm[30] ^ 2.0) = 0
((0_p[(86, 54, 65)] + 0_p[(83, 54, 52)] + 0_p[(100, 54, 66)]) + 0) - ((0 - 0) - 0 * 0_vm[54] ^ 2.0) = 0
((0_p[(77, 47, 48)] + 0_p[(80, 47, 51)] + 0_p[(79, 47, 50)] + 0_p[(81, 47, 59)] + 0_p[(62, 47, 35)]) + 0) - ((0 - +0.405) - 0 * 0_vm[47] ^ 2.0) = 0
((0_p[(54, 32, 40)] + 0_p[(102, 32, 30)]) + 0) - ((0 - +1.66) - 0 * 0_vm[32] ^ 2.0) = 0
((0_p[(79, 50, 47)] + 0_p[(76, 50, 45)]) + 0) - ((+0_pg[14] - 0) - 0 * 0_vm[50] ^ 2.0) = 0
((0_p[(55, 40, 41)] + 0_p[(45, 40, 26)] + 0_p[(67, 40, 39)] + 0_p[(54, 40, 32)]) + +((0_pconv_tf_fr_2[1] + 0_pconv_tf_fr_2[2]))) - ((0 - 0) - 0 * 0_vm[40] ^ 2.0) = 0
((0_p[(72, 43, 49)] + 0_p[(56, 43, 44)] + 0_p[(68, 43, 39)] + 0_p[(42, 43, 25)] + 0_p[(70, 43, 42)]) + 0) - ((+0_pg[13] - 0) - 0 * 0_vm[43] ^ 2.0) = 0
((0_p[(11, 9, 3)] + 0_p[(20, 9, 8)] + 0_p[(6, 9, 2)]) + 0) - ((0 - +0.93) - 0 * 0_vm[9] ^ 2.0) = 0
((0_p[(18, 7, 15)] + 0_p[(19, 7, 16)] + 0_p[(2, 7, 1)] + 0_p[(17, 7, 6)] + 0_p[(15, 7, 5)]) + +((0_pconv_tf_fr_1[1] + 0_pconv_tf_fr_1[2]))) - ((0 - 0) - 0 * 0_vm[7] ^ 2.0) = 0
((0_p[(92, 60, 58)] + 0_p[(97, 60, 59)]) + 0) - ((0 - +0.575) - 0 * 0_vm[60] ^ 2.0) = 0
((0_p[(59, 34, 51)] + 0_p[(58, 34, 33)]) + 0) - ((0 - +2.7) - 0 * 0_vm[34] ^ 2.0) = 0
((0_p[(11, 3, 9)] + 0_p[(8, 3, 4)] + 0_p[(9, 3, 10)] + 0_p[(10, 3, 12)] + 0_p[(5, 3, 2)]) + 0) - ((0 - 0) - 0 * 0_vm[3] ^ 2.0) = 0
((0_p[(94, 61, 62)] + 0_p[(88, 61, 58)]) + 0) - ((0 - +0.935) - 0 * 0_vm[61] ^ 2.0) = 0
((0_p[(66, 38, 37)] + 0_p[(65, 38, 36)]) + 0) - ((0 - +0.75) - 0 * 0_vm[38] ^ 2.0) = 0
((0_p[(65, 36, 38)] + 0_p[(64, 36, 37)] + 0_p[(61, 36, 35)]) + 0) - ((+0_pg[11] - 0) - 0 * 0_vm[36] ^ 2.0) = 0
((0_p[(74, 48, 44)] + 0_p[(78, 48, 46)] + 0_p[(77, 48, 47)]) + 0) - ((0 - 0) - 0 * 0_vm[48] ^ 2.0) = 0
((0_p[(25, 12, 13)] + 0_p[(7, 12, 2)] + 0_p[(10, 12, 3)] + 0_p[(23, 12, 11)]) + 0) - ((0 - +0.855) - 0 * 0_vm[12] ^ 2.0) = 0
((0_p[(29, 16, 17)] + 0_p[(30, 16, 18)] + 0_p[(19, 16, 7)]) + 0) - ((0 - +0.19) - 0 * 0_vm[16] ^ 2.0) = 0
((0_p[(96, 62, 63)] + 0_p[(93, 62, 66)] + 0_p[(94, 62, 61)]) + 0) - ((0 - +1.595) - 0 * 0_vm[62] ^ 2.0) = 0
((0_p[(37, 21, 22)] + 0_p[(38, 21, 23)] + 0_p[(36, 21, 25)] + 0_p[(35, 21, 20)]) + 0) - ((0 - 0) - 0 * 0_vm[21] ^ 2.0) = 0
((0_p[(21, 10, 11)] + 0_p[(22, 10, 22)] + 0_p[(9, 10, 3)]) + 0) - ((+0_pg[5] - 0) - 0 * 0_vm[10] ^ 2.0) = 0
((0_p[(33, 19, 20)] + 0_p[(34, 19, 23)] + 0_p[(13, 19, 4)]) + 0) - ((0 - +0.825) - 0 * 0_vm[19] ^ 2.0) = 0
((0_p[(59, 51, 34)] + 0_p[(57, 51, 33)] + 0_p[(80, 51, 47)]) + 0) - ((0 - +2.15) - 0 * 0_vm[51] ^ 2.0) = 0
((0_p[(39, 22, 25)] + 0_p[(85, 22, 56)] + 0_p[(37, 22, 21)] + 0_p[(22, 22, 10)]) + 0) - ((0 - +0.15) - 0 * 0_vm[22] ^ 2.0) = 0
((0_p[(17, 6, 7)] + 0_p[(14, 6, 5)]) + 0) - ((0 - +0.955) - 0 * 0_vm[6] ^ 2.0) = 0
((0_p[(41, 24, 49)] + 0_p[(31, 24, 17)] + 0_p[(32, 24, 18)]) + 0) - ((0 - +0.16) - 0 * 0_vm[24] ^ 2.0) = 0
((0_p[(26, 53, 13)] + 0_p[(82, 53, 52)]) + 0) - ((0 - +0.5) - 0 * 0_vm[53] ^ 2.0) = 0
((0_p[(47, 28, 35)] + 0_p[(48, 28, 37)] + 0_p[(46, 28, 27)]) + 0) - ((0 - +3.325) - 0 * 0_vm[28] ^ 2.0) = 0
((0_p[(14, 5, 6)] + 0_p[(16, 5, 8)] + 0_p[(15, 5, 7)] + 0_p[(1, 5, 1)]) + 0) - ((+0_pg[4] - 0) - 0 * 0_vm[5] ^ 2.0) = 0
((0_p[(34, 23, 19)] + 0_p[(38, 23, 21)]) + 0) - ((0 - 0) - 0 * 0_vm[23] ^ 2.0) = 0
((0_p[(84, 63, 55)] + 0_p[(98, 63, 57)] + 0_p[(96, 63, 62)]) + 0) - ((+0_pg[17] - 0) - 0 * 0_vm[63] ^ 2.0) = 0
((0_p[(46, 27, 28)] + 0_p[(52, 27, 31)] + 0_p[(43, 27, 26)]) + 0) - ((0 - 0) - 0 * 0_vm[27] ^ 2.0) = 0
((0_p[(89, 56, 59)] + 0_p[(91, 56, 58)] + 0_p[(85, 56, 22)]) + 0) - ((+0_pg[15] - 0) - 0 * 0_vm[56] ^ 2.0) = 0
((0_p[(55, 41, 40)] + 0_p[(69, 41, 42)]) + 0) - ((+0_pg[12] - 0) - 0 * 0_vm[41] ^ 2.0) = 0
((0_p[(18, 15, 7)] + 0_p[(27, 15, 14)]) + 0) - ((0 - +0.565) - 0 * 0_vm[15] ^ 2.0) = 0
0_iconv_dc_2[1] + 0_idcgrid_(1, 2, 1)[1] = 0.0
0_iconv_dc_2[2] + 0_idcgrid_(1, 2, 1)[2] = 0.0
0_iconv_dc_2[3] + 0_idcgrid_(1, 2, 1)[3] = 0.0
0_iconv_dc_1[1] + 0_idcgrid_(1, 1, 2)[1] = 0.0
0_iconv_dc_1[2] + 0_idcgrid_(1, 1, 2)[2] = 0.0
0_iconv_dc_1[3] + 0_idcgrid_(1, 1, 2)[3] = 0.0
(0_pconv_ac_2[1] + 0_pconv_dc_2[1] + 0_pconv_dcg_2[1]) - (0.0 + 0.0 * 0_iconv_ac_2[1] + 0.0 * 0_iconv_ac_2[1] ^ 2.0) = 0
(0_pconv_ac_2[2] + 0_pconv_dc_2[2] + 0_pconv_dcg_2[2]) - (0.0 + 0.0 * 0_iconv_ac_2[2] + 0.0 * 0_iconv_ac_2[2] ^ 2.0) = 0
0_pconv_dc_2[3] - 0_pconv_dcg_2[1] - 0_pconv_dcg_2[2] = 0.0
(0_pconv_ac_2[1] ^ 2.0 + 0_qconv_ac_2[1] ^ 2.0) - 0_vmc_2[1] ^ 2.0 * 0_iconv_ac_2[1] ^ 2.0 = 0
(0_pconv_ac_2[2] ^ 2.0 + 0_qconv_ac_2[2] ^ 2.0) - 0_vmc_2[2] ^ 2.0 * 0_iconv_ac_2[2] ^ 2.0 = 0
0_pconv_dc_2[1] - 0_iconv_dc_2[1] * 0_vdcm_2[1] = 0
0_pconv_dc_2[2] - 0_iconv_dc_2[2] * 0_vdcm_2[2] = 0
0_pconv_dc_2[3] - 0_iconv_dc_2[3] * 0_vdcm_2[3] = 0
(0_pconv_ac_1[1] + 0_pconv_dc_1[1] + 0_pconv_dcg_1[1]) - (0.0 + 0.0 * 0_iconv_ac_1[1] + 0.0 * 0_iconv_ac_1[1] ^ 2.0) = 0
(0_pconv_ac_1[2] + 0_pconv_dc_1[2] + 0_pconv_dcg_1[2]) - (0.0 + 0.0 * 0_iconv_ac_1[2] + 0.0 * 0_iconv_ac_1[2] ^ 2.0) = 0
0_pconv_dc_1[3] - 0_pconv_dcg_1[1] - 0_pconv_dcg_1[2] = 0.0
(0_pconv_ac_1[1] ^ 2.0 + 0_qconv_ac_1[1] ^ 2.0) - 0_vmc_1[1] ^ 2.0 * 0_iconv_ac_1[1] ^ 2.0 = 0
(0_pconv_ac_1[2] ^ 2.0 + 0_qconv_ac_1[2] ^ 2.0) - 0_vmc_1[2] ^ 2.0 * 0_iconv_ac_1[2] ^ 2.0 = 0
0_pconv_dc_1[1] - 0_iconv_dc_1[1] * 0_vdcm_1[1] = 0
0_pconv_dc_1[2] - 0_iconv_dc_1[2] * 0_vdcm_1[2] = 0
0_pconv_dc_1[3] - 0_iconv_dc_1[3] * 0_vdcm_1[3] = 0


.....pgrid....
"8, -11.97790071752083"
"4, 1.8504483046536964"
"1, 7.322183978755917"
"5, -6.549683743532226"
"2, -8.719449536305168"
"7, 0.697060997879222"
"6, 1.42996951950278"
"9, 8.0"
"3, 8.244187678652349"
"8, -12.078108720797136"
"4, 1.821543134459767"
"1, 7.380756899326412"
"5, -6.60925305302381"
"2, -8.728711474513734"
"7, 0.6670508763714517"
"6, 1.4180534066947192"
"9, 8.0"
"3, 8.416147973342328"
.....pgrid....
"8, -11.97790071752083"
"4, 1.8504483046536964"
"1, 7.322183978755917"
"5, -6.549683743532226"
"2, -8.719449536305168"
"7, 0.697060997879222"
"6, 1.42996951950278"
"9, 8.0"
"3, 8.244187678652349"


line==> "2"

k="1"
"(11, 3, 9), d=1"
"(11, 3, 9), 1"
0_idcgrid_(2, 3, 4)[1] - 833.3333333333334 * (0_vdcm_3[1] - 0_vdcm_4[1]) = 0
0_idcgrid_(2, 4, 3)[1] - 833.3333333333334 * (0_vdcm_4[1] - 0_vdcm_3[1]) = 0
"(2, 3, 4), 1"
"(2, 3, 4), 1"
0_idcgrid_(2, 3, 4)[1] - 833.3333333333334 * (0_vdcm_3[1] - 0_vdcm_4[1]) = 0
0_idcgrid_(2, 4, 3)[1] - 833.3333333333334 * (0_vdcm_4[1] - 0_vdcm_3[1]) = 0
"(5, 3, 1), 1"
"(5, 3, 1), 1"
0_idcgrid_(2, 3, 4)[1] - 833.3333333333334 * (0_vdcm_3[1] - 0_vdcm_4[1]) = 0
0_idcgrid_(2, 4, 3)[1] - 833.3333333333334 * (0_vdcm_4[1] - 0_vdcm_3[1]) = 0
"2"
"(11, 3, 9), 2"
"(11, 3, 9), 2"
0_idcgrid_(2, 3, 4)[2] - 19.23076923076923 * (0_vdcm_3[2] - 0_vdcm_4[2]) = 0
0_idcgrid_(2, 4, 3)[2] - 19.23076923076923 * (0_vdcm_4[2] - 0_vdcm_3[2]) = 0
"(5, 3, 1), 2"
"(5, 3, 1), 2"
0_idcgrid_(2, 3, 4)[2] - 19.23076923076923 * (0_vdcm_3[2] - 0_vdcm_4[2]) = 0
0_idcgrid_(2, 4, 3)[2] - 19.23076923076923 * (0_vdcm_4[2] - 0_vdcm_3[2]) = 0
"3"
"(11, 3, 9), 3"