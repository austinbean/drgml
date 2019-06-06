* preserve test sample on nicu_feature_matrix on server.
/*

in 
/project/Lorch_project2018/bean
do 
bsub < classifier.sh
which calls
server_nicu_classifier.sh
Maybe split this into 4 pieces?  
*/

local thresh = 0.75

use /project/Lorch_project2018/bean/nicu_collapsed.dta, clear
drop _merge
gen tr = runiform() 
gen kp = 1 if tr <= `thresh'
replace kp = 0 if tr > `thresh'

preserve
keep if kp == 1
drop kp tr pr1_10
recast byte ind_*
save /project/Lorch_project2018/bean/nicu_coll_train.dta, replace

restore


preserve
keep if kp == 0
recast byte ind_*
save /project/Lorch_project2018/bean/nicu_coll_test.dta, replace

