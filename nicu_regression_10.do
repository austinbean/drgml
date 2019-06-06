* Try a logistic regression with that ludicrous dataset.


	global file_home "/home/beanaus/datacsv/"
	global file_dest "/secure/project/Lorch_project2018/bean/"
* Increase Matrix size since there are 3000 variables
	set matsize 5000

* Fraction to sample
	local frac = 10
	
* Load and merge data
	use "${file_dest}nicu_collapsed.dta", clear
	
* PRESERVE
	preserve 
	
* Load previous results:
	estimates use "${file_dest}logit_mod_samp_25"
	matrix a1 = e(b)


* Whole Data set has trouble converging, try on a sample:
	set seed 25
	sample `frac'

* Estimation
	logit ADMN_NICU ind_*, difficult from(a1)
 
 * Save the results		
	estimates save "${file_dest}logit_mod_samp_`frac'", replace

* RESTORE
	restore

* Predict Probability
	predict pr1_`frac'

* save version with predicted prob
	save "${file_dest}nicu_collapsed.dta", replace
	
* ROC curve
	lroc , saving("${file_home}nicu_model_roc_`frac'.gph", replace)
	
* Sensitivity
	lsens, saving("${file_home}nicu_model_sens_`frac'.gph", replace)


