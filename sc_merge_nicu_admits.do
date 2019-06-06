* runs after sc_features.do
* merges nicu admission data back into the collapsed data.  
* will also select out training and testing samples.  
* scp  "/Users/austinbean/Desktop/drgml/sc_merge_nicu_admits.do" beanaus@hsrdcsub2.pmacs.upenn.edu:/project/Lorch_project2018/bean/


global file_dest "/project/Lorch_project2018/bean/"




* did I call the merging variable pid or bbct?  

* What is the merging file?  
use "/project/Lorch_project2018/bean/datacsv/datacsv/SC_orig_records.dta", clear
keep pid admn_nicu

merge 1:1 pid using "/project/Lorch_project2018/bean/sc_nicu_collapsed.dta", gen(match0)

	* something like 165 records out of 1,200,000 can't be matched.
drop if match0 != 3
drop match0

export delimited "${file_dest}sc_nicu_labeled.csv", replace

	* Subset training and testing data - test on 15%.
set seed 41
gen rlab = runiform()

gen byte tag1 = 0
replace tag1 = 1 if rlab < 0.15

preserve
	keep if tag1 == 1
	drop rlab tag1 
	export delimited "${file_dest}sc_nicu_test.csv", replace
restore
	keep if tag1 == 0
	drop rlab tag1 
	export delimited "${file_dest}sc_nicu_train.csv", replace
	

/*




*/
