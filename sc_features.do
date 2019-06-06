* sc_features
* replaces sc_feature_matrix.do 
* scp  "/Users/austinbean/Desktop/drgml/sc_features.do" beanaus@hsrdcsub2.pmacs.upenn.edu:/project/Lorch_project2018/bean/


set matsize 5000

global file_dest "/project/Lorch_project2018/bean/"


use /project/Lorch_project2018/bean/datacsv/datacsv/SC_baby_hosp_records.dta, clear

	gen admn_nicu = 0
	replace admn_nicu = 1 if CHG172 > 0 & CHG172 != .
	replace admn_nicu = 1 if CHG173 > 0 & CHG173 != .
	replace admn_nicu = 1 if CHG174 > 0 & CHG174 != .
	
	rename pdiag SDIAG15
	rename ADM_DIAG SDIAG16
	rename *, lower
	 
	keep baby_id sdiag* admd disd admmth admyear hid_encrypt admn_nicu
	gen pid = _n
	
save /project/Lorch_project2018/bean/datacsv/datacsv/SC_orig_records.dta, replace



keep baby_id sdiag* admd disd admmth admyear hid_encrypt pid
	* admd ? 
	gen nid = string(baby_id) + "_" + string(admd) + "_" + string(disd) + "_" + string(hid_encrypt)
	preserve 
	keep baby_id pid nid
	save /project/Lorch_project2018/bean/sc_baby_id_pid.dta, replace
	restore
	drop admd disd admmth admyear hid_encrypt
* Reshape to have one entry per admission
	reshape long sdiag, i(pid) j(dct)
	drop if sdiag == ""
* Validate ICD-9 
	icd9 check sdiag, generate(inv)
	drop if inv != 0
	drop inv
	
	
	
* drop repeated codes within a person
	sort pid sdiag
	bysort pid sdiag: gen pct_ct = _n
	bysort pid sdiag: egen p_ct = max(pct_ct)
	drop if pct_ct > 1
	drop pct_ct p_ct
	
	
* Must get below 5000 codes, so drop things which appear once only

	sort sdiag
	bysort sdiag: gen ctr = _n
	bysort sdiag: egen totctr = max(ctr)
	drop if ctr == 1 & totctr == 1 
	drop ctr totctr
	
* Make matrix of indicators, combine to one row per person.
	sort sdiag
	gen nsd = subinstr(sdiag, ".", "", .)
	replace sdiag = nsd
	levelsof sdiag, local(icds)
	drop nsd
	
	
* Count unique diagnoses:
	* doesn't work for strings.  F. you.  
preserve
	duplicates drop sdiag, force
    count
restore
	
foreach cd of local icds{
	gen byte ind_`cd' = 0
	replace ind_`cd' = 1 if sdiag == "`cd'"
}

* Save an intermediate output here because that process takes SO long.

	save "${file_dest}sc_nicu_features.dta",replace

* Create one row per record

	collapse (sum) ind_*, by(pid) fast
* recast as byte to save space
	recast byte ind_*
	save "${file_dest}sc_nicu_collapsed.dta",replace
	
* export to CSV
	export delimited "${file_dest}sc_nicu_coll.csv", replace
