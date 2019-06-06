* Uses data on CA births to construct a feature matrix like that for TX..
* scp  "/Users/austinbean/Desktop/drgml/ca_feature_matrix.do" beanaus@hsrdcsub2.pmacs.upenn.edu:/project/Lorch_project2018/bean/


	global file_dest "/secure/project/Lorch_project2018/bean/"


use /project/Lorch_project2018/bean/datacsv/ca_transfers.dta, clear
	* 5000 var max on server.
set matsize 5000

* Maybe should redo this with a pid, just for simplicity
	keep id admsrci disstati visnumi dxi* admdti disdti hospidi
	gen pid = _n
* Reshape to have one entry per admission
	reshape long dxi, i(pid) j(dct)
	drop if dxi == ""
* Validate ICD-9 
	icd9 check dxi, generate(inv)
	drop if inv != 0
	drop inv
	
	

* drop codes which only appear only `threshold' times
	local thresh = 10
	sort dxi
	bysort dxi: gen dc_ct = _n
	bysort dxi: egen code_count = max(dc_ct)
	drop dc_ct
	* Save codes which appear once with ICD-9 descriptions
	preserve
		keep if code_count <= `thresh'
		keep dxi code_count
		icd9 generate diag_name = dxi, description
		save "${file_home}ca_singleton_codes.dta", replace
	restore
	drop if code_count <=  `thresh'
	drop code_count
	
	
* drop repeated codes within a person
	sort pid dxi
	bysort pid dxi: gen pct_ct = _n
	bysort pid dxi: egen p_ct = max(pct_ct)
	drop if pct_ct > 1
	drop pct_ct p_ct
	
* Make matrix of indicators, combine to one row per person.
	sort dxi
	levelsof dxi, local(icds)
	
foreach cd of local icds{
	gen byte ind_`cd' = 0
	replace ind_`cd' = 1 if dxi == "`cd'"
}

* Save an intermediate output here because that process takes SO long.

	save "${file_dest}ca_nicu_features.dta",replace

* Create one row per record

	collapse (sum) ind_*, by(pid) fast
* recast as byte to save space
	recast byte ind_*
	save "${file_dest}ca_nicu_collapsed.dta",replace
