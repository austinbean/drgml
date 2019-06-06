* NICU / ICD-9 Indicators.
	* scp beanaus@hsrdcsub2.pmacs.upenn.edu:/project/Lorch_project2018/bean/nicu_collased_1pct.dta "/Users/austinbean/Desktop/"
	* NB: the file that this generates is ENORMOUS, > 40 Gb.


* Global Filepaths
	*global file_home "/Users/austinbean/Desktop/drgml/"
	*global file_dest "/Users/austinbean/Desktop/drgml/"
	
	global file_home "/home/beanaus/datacsv/"
	global file_dest "/secure/project/Lorch_project2018/bean/"
	
* For the regression at the bottom:
	set matsize 5000


use "${file_home}nicu_subset.dta", clear

gen pid = _n

* Preserve the original record ID and ADMN_NICU variable, which gets lost in collapse below
	preserve
	
	keep pid RECORD_ID ADMN_NICU
	
	save "${file_home}nicu_admits.dta", replace
	
	restore

* Rename and reshape:
	rename ADMITTING_DIAGNOSIS OTH_DIAG_CODE_25
	
	rename PRINC_DIAG_CODE OTH_DIAG_CODE_26
	* From wide to long:
	reshape long OTH_DIAG_CODE_, i(pid) j(ctt)
	drop if OTH_DIAG_CODE_ == ""
	bysort pid: gen dct = _n
	drop ct
	rename OTH_DIAG_CODE DIAG_CODES

* Validate ICD-9 Codes and drop those that don't work
	icd9 check DIAG_CODES, generate(inv)
	drop if inv != 0
	drop inv
	
	
* drop codes which only appear only `threshold' times
	local thresh = 10
	sort DIAG_CODES
	bysort DIAG_CODES: gen dc_ct = _n
	bysort DIAG_CODES: egen code_count = max(dc_ct)
	drop dc_ct
	* Save codes which appear once with ICD-9 descriptions
	preserve
	keep if code_count <= `thresh'
	keep DIAG_CODES code_count
	icd9 generate diag_name = DIAG_CODES, description
	save "${file_home}nicu_singleton_codes.dta", replace
	restore
	drop if code_count <=  `thresh'
	drop code_count
	
* drop those only associated with one outcome:
	sort DIAG_CODES ADMN_NICU
	bysort DIAG_CODES ADMN_NICU: gen na_ct = _n
	bysort DIAG_CODES ADMN_NICU: egen code_count = max(na_ct)
	drop na_ct
	unique code_count, by(DIAG_CODES) gen(ad_ct)
	bysort DIAG_CODES: egen outcomes = max(ad_ct)
	* Save codes which are associated with one outcome (i.e., either with only admissions or only non-admissions)
	preserve
	keep if outcomes == 1
	keep DIAG_CODES
	duplicates drop DIAG_CODES, force
	icd9 generate diag_name = DIAG_CODES, description
	save "${file_home}nicu_single_outcome_codes.dta", replace
	restore 
	drop if outcomes == 1
	drop code_count outcomes ad_ct

* drop people with no codes
	* not clear that there can be such people but just in case.
	sort pid
	bysort pid: gen cdct = _n
	bysort pid: egen cd_ct = max(cdct)
	drop cdct
	* In fact no people are dropped here
	drop if cd_ct == 0
	drop cd_ct
	
* drop repeated codes within a person
	sort pid DIAG_CODES
	bysort pid DIAG_CODES: gen pct_ct = _n
	bysort pid DIAG_CODES: egen p_ct = max(pct_ct)
	drop if pct_ct > 1
	drop pct_ct p_ct
	
* Make matrix of indicators, combine to one row per person.
	sort DIAG_CODES
	levelsof DIAG_CODES, local(icds)
	
foreach cd of local icds{
	gen byte ind_`cd' = 0
	replace ind_`cd' = 1 if DIAG_CODES == "`cd'"
}

* Save an intermediate output here because that process takes SO long.

	save "${file_dest}nicu_features.dta",replace

* Create one row per record

	collapse (sum) ind_*, by(pid) fast
	save "${file_dest}nicu_collapsed.dta",replace

* Add the ADMN_NICU and RECORD_ID vars back in
	merge 1:1 pid using "${file_home}nicu_admits.dta"
	drop if _merge != 3
	
* save version with predicted prob
	save "${file_dest}nicu_collapsed.dta", replace



