* features 1999 - 2003
* server version is server_tx_features_99_03.do

/*
 
 There is no way to infer NICU admission from charges, but it is inferrable 
 potentially from ICD-9s
 Generate a feature matrix of ICD-9's to do that classification using the 1999 -
 2003 data.  
 Classify using the RF trained on 2004 - 2012.

 - Takes an extremely long time.  Better to run on server.
*/

set matsize 5000

	* Select out ICD-9's
	
global chr_path "/Users/austinbean/Desktop/Texas PUDF Zipped Backup Files/"
global inp_path "/Users/austinbean/Desktop/Texas PUDF Zipped Backup Files/"



* List of variables to use:
	* 99 variables work for 99 - 03
	* this list duplicated below in main loop
local vnms99 = "ADMITTING_DIAG PRINC_DIAG_CODE OTH_DIAG_CODE_1 OTH_DIAG_CODE_2 OTH_DIAG_CODE_3 OTH_DIAG_CODE_4 OTH_DIAG_CODE_5 OTH_DIAG_CODE_6 OTH_DIAG_CODE_7 OTH_DIAG_CODE_8 PRINC_SURG_PROC_CODE OTH_SURG_PROC_CODE_1 OTH_SURG_PROC_CODE_2 OTH_SURG_PROC_CODE_3 OTH_SURG_PROC_CODE_4 OTH_SURG_PROC_CODE_5 PRINC_ICD9_CODE OTH_ICD9_CODE_1 OTH_ICD9_CODE_2 OTH_ICD9_CODE_3 OTH_ICD9_CODE_4 OTH_ICD9_CODE_5"


* Recast variables to string

	foreach yr of numlist 1999 2000 2001 2002 2003{
	
		foreach qr of numlist 1 2 3 4{
		use "${chr_path}`yr'/CD`yr'Q`qr'/birthonly `qr' Q `yr'.dta", clear
		
			foreach var1 of local vnms99{
				tostring `var1', replace
			}
			
		save "${chr_path}`yr'/CD`yr'Q`qr'/birthonly `qr' Q `yr'.dta", replace
		}
	}

* Append all quarters and generate feature matrix

foreach yr of numlist 1999 2000 2001 2002 2003{
	

	use "${chr_path}`yr'/CD`yr'Q1/birthonly 1 Q `yr'.dta", clear
		* Force option fine because variables of interest all converted to string
	append using "${chr_path}`yr'/CD`yr'Q2/birthonly 2 Q `yr'.dta", force
	
	append using "${chr_path}`yr'/CD`yr'Q3/birthonly 3 Q `yr'.dta", force
	
	append using "${chr_path}`yr'/CD`yr'Q4/birthonly 4 Q `yr'.dta", force
	
	* Keep pregnancy related (drops 0)
	keep if CMS_DRG == 385 | CMS_DRG == 386 | CMS_DRG ==  387 | CMS_DRG == 388 | CMS_DRG == 389 | CMS_DRG == 390 | CMS_DRG == 391
	
	local vnms99 = "ADMITTING_DIAG PRINC_DIAG_CODE OTH_DIAG_CODE_1 OTH_DIAG_CODE_2 OTH_DIAG_CODE_3 OTH_DIAG_CODE_4 OTH_DIAG_CODE_5 OTH_DIAG_CODE_6 OTH_DIAG_CODE_7 OTH_DIAG_CODE_8 PRINC_SURG_PROC_CODE OTH_SURG_PROC_CODE_1 OTH_SURG_PROC_CODE_2 OTH_SURG_PROC_CODE_3 OTH_SURG_PROC_CODE_4 OTH_SURG_PROC_CODE_5 PRINC_ICD9_CODE OTH_ICD9_CODE_1 OTH_ICD9_CODE_2 OTH_ICD9_CODE_3 OTH_ICD9_CODE_4 OTH_ICD9_CODE_5"
	
	keep `vnms99'
	
	* generate an ID number per person, then rename ICD-9 diag codes
	drop *_SURG_PROC_*
	
	gen pid = _n
	rename ADMITTING_DIAG OTH_DIAG_CODE_9
	rename PRINC_DIAG_CODE OTH_DIAG_CODE_10
	
	*rename diag codes to make numbering consistent for reshape	
	rename PRINC_ICD9_CODE OTH_DIAG_CODE_11 
	rename OTH_ICD9_CODE_1 OTH_DIAG_CODE_12
	rename OTH_ICD9_CODE_2 OTH_DIAG_CODE_13
	rename OTH_ICD9_CODE_3 OTH_DIAG_CODE_14
	rename OTH_ICD9_CODE_4 OTH_DIAG_CODE_15
	rename OTH_ICD9_CODE_5 OTH_DIAG_CODE_16
	
	reshape long OTH_DIAG_CODE_ , i(pid) j(ctt)
	replace OTH_DIAG_CODE_ = "" if OTH_DIAG_CODE == "."
	
	
	* Check for duplicates within person.  
	
	duplicates tag pid OTH_DIAG_CODE_ if OTH_DIAG_CODE_ != "", gen(dup_diag)
	bysort pid OTH_DIAG_CODE_: gen ctr1 = _n if dup_diag > 0 & dup_diag != .
	replace OTH_DIAG_CODE_ = "" if ctr1 > 1 & dup_diag > 0 & ctr1 != .
	drop ctr1 dup_diag
	
	* drop missing/blank diag coes	
	drop if OTH_DIAG_CODE_ == "" 
	
	
	* Validate ICD-9 Codes and drop those that don't work
	icd9 check OTH_DIAG_CODE_, generate(inv)
	drop if inv != 0
	drop inv
	
* FOR TESTING - DELETE!
	sample 1
	*duplicates drop OTH_DIAG_CODE_, force
	*count
	
	* List all ICD-9 codes
	gen nsd = subinstr(OTH_DIAG_CODE_, ".", "", .)
	replace OTH_DIAG_CODE_ = nsd
	drop nsd
	levelsof OTH_DIAG_CODE_, local(icds)
	
	* Generate features - indicator for presence of icd-9
	foreach cd of local icds{
		gen byte ind_`cd' = 0
		replace ind_`cd' = 1 if OTH_DIAG_CODE_ == "`cd'"
	}
	
	* One row per person
	collapse (sum) ind_*, by(pid) fast
	
	* Reset all to byte
	recast byte ind_*
	
	* Save feature matrix
	export delimited "${chr_path}`yr'/`yr'_featurematrix.csv", replace
	
	}
