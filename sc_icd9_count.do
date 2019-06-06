use /project/Lorch_project2018/bean/datacsv/datacsv/SC_baby_hosp_records.dta, clear

levelsof admyear, local(allyrs)

foreach yr of local allyrs{

quietly count if admyear == `yr'

di "`yr':    `r(N)'"

}

/*
SC Patient Counts by year:

1996:    51366
1997:    55772
1998:    58193
1999:    59294
2000:    58743
2001:    60377
2002:    58695
2003:    60323
2004:    55733
2005:    61541
2006:    63843
2007:    65872
2008:    65375
2009:    62083
2010:    58387
2011:    57256
2012:    58520
2013:    57893
2014:    57287
2015:    57198
2016:    56424

*/



	* 16 total diag codes, inc primary and admitting
rename pdiag SDIAG15
rename ADM_DIAG SDIAG16

	* 13 total procedure codes, inc primary
rename pproc SPROC13

* DROP THE ICD10s and DATES
drop SPROC10_*
drop SDIAG10_*
drop SPROC*D
drop PDIAG10  
drop ADM_DIAG10  
drop PPROC10  
drop PECODE10  
drop SECODE10
* what's the year var?  
keep SDIAG* SPROC* admyear

gen pid = _n

reshape long SPROC SDIAG, i(pid) j(ctt)

drop if SPROC == "" & SDIAG == ""

* Drop duplicates

foreach var1 of varlist SDIAG SPROC {
	
	duplicates tag pid `var1' if `var1' != "", gen(dup_diag)
	bysort pid `var1': gen ctr1 = _n if dup_diag > 0 & dup_diag != .
	replace `var1' = "" if dup_diag > 0 & ctr1 > 1 & ctr1 != .
	drop ctr1 dup_diag

}

drop if SPROC == "" & SDIAG == ""


* Count the frequencies by year:

foreach var1 of varlist SPROC SDIAG {

	bysort admyear `var1': gen ctr1 = _n
	bysort admyear `var1': egen ct_`var1' = max(ctr1)
	drop ctr1

}


levelsof admyear, local(allyrs)

foreach yr of local allyrs{
	* Diagnoses
	preserve
		keep if admyear == `yr'
		keep ct_SDIAG SDIAG admyear
		duplicates drop SDIAG, force
		drop if SDIAG == ""
		icd9 check SDIAG, gen(inv1)
		drop if inv1 != 0
		icd9 generate descriptions = SDIAG, description
		gsort -ct_SDIAG
		gen rank = _n
		save /project/Lorch_project2018/bean/sc_`yr'_diag_freq.dta, replace
	restore

	* Procedures
	preserve
		keep if admyear == `yr'
		keep ct_SPROC SPROC admyear
		duplicates drop SPROC, force
		drop if SPROC == ""
		icd9p check SPROC, gen(inv1)
		drop if inv1 != 0
		icd9p generate descriptions = SPROC, description
		gsort -ct_SPROC
		gen rank = _n
		save /project/Lorch_project2018/bean/sc_`yr'_proc_freq.dta, replace
	restore
}


* append and collect: 1996 1997 1998 1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016


	* diagnoses:
	
use /project/Lorch_project2018/bean/sc_1996_diag_freq.dta, clear

foreach nm of numlist 1997(1)2016{
	
	append using /project/Lorch_project2018/bean/sc_`nm'_diag_freq.dta
}

save /project/Lorch_project2018/bean/sc_diag_freq_by_year.dta, replace

	* procedures

use /project/Lorch_project2018/bean/sc_1996_proc_freq.dta, clear

foreach nm of numlist 1997(1)2016{
	
	append using /project/Lorch_project2018/bean/sc_`nm'_proc_freq.dta
}

save /project/Lorch_project2018/bean/sc_proc_freq_by_year.dta, replace
