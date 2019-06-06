* Restore and re-run regressions:

global file_home "/home/beanaus/datacsv/"
global file_dest "/secure/project/Lorch_project2018/bean/"


use "${file_dest}nicu_features.dta"

collapse (sum) ind_*, by(pid) fast
save "${file_dest}nicu_collapsed.dta",replace	

* merge admission
	merge 1:1 pid using "${file_home}nicu_admits.dta"
	drop if _merge != 3
	
* save version with admits:
	save "${file_dest}nicu_collapsed.dta", replace
	save "${file_dest}nicu_collapsed_back.dta"

	
* 10% version
	do "/home/beanaus/dos/nicu_regression_10.do"

* 50% version
	do "/home/beanaus/dos/nicu_regression_50.do"

* 75% version
	do "/home/beanaus/dos/nicu_regression_75.do"
	
* 100% version
	do "/home/beanaus/dos/nicu_regression_100.do"

