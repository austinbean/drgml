


* IGNORE - superseded by sc_features.do


















* sc_feature_matrix
*  scp  "/Users/austinbean/Desktop/drgml/sc_feature_matrix.do" beanaus@hsrdcsub2.pmacs.upenn.edu:/project/Lorch_project2018/bean/

/*

Ok - this is not being done right.   
1.  Merge SC_baby_hosp_records.dta with SC_birthcert.dta to track which patients have nicu admission.
2.  Then do all of this other nonsense.  

What's the merge variable?

*/

global file_dest "/project/Lorch_project2018/bean/datacsv/datacsv"


use /project/Lorch_project2018/bean/datacsv/datacsv/SC_birthcert.dta, clear
sort BABY_ID
unique BABY_ID
duplicates tag BABY_ID, gen(ddd)
tab ddd
	* 1,036,945 - baby ID's
	* 1,038,105 - rows in data
use /project/Lorch_project2018/bean/datacsv/datacsv/SC_baby_hosp_records.dta, clear
sort BABY_ID
unique BABY_ID
duplicates tag BABY_ID, gen(ddd)
tab ddd
	* 1,088,273
	* 1,240,175
	
	
* The hospital ID will have this information.  Does the BC contain the whole record of transfers?  	
	

set matsize 5000

rename pdiag SDIAG15
rename ADM_DIAG SDIAG16

rename *, lower
	bysort baby_id admd disd: gen bbct = _n
save /project/Lorch_project2018/bean/datacsv/datacsv/SC_orig_records.dta, replace

* Maybe should redo this with a pid, just for simplicity
	* this is going to be wrong since there's a baby ID which is repeated for transfers.  but we have a Pid which is unique.  
	* going to keep the date, hospital ID and baby_id.  Hopefully that's unique.
	keep baby_id sdiag* admd disd admmth admyear hid_encrypt
	* admd ? 
	gen nid = string(baby_id) + "_" + string(admd) + "_" + string(disd) + "_" + string(hid_encrypt) + "_" + string(bbct)
	gen pid = _n
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
	
* Make matrix of indicators, combine to one row per person.
	sort sdiag
	levelsof sdiag, local(icds)
	
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
