* Compare the Texas and SC ICD-9 Codes
* scp beanaus@hsrdcsub2.pmacs.upenn.edu:/project/Lorch_project2018/bean/sc_tx_icd_counts.dta /Users/austinbean/Desktop
* see also compare_rates.do
* THIS IS AN OLD VERSION - superseded by compare_rates.do

**********
* SC

do "/project/Lorch_project2018/bean/sc_icd9_count.do
	* scp beanaus@hsrdcsub2.pmacs.upenn.edu:/project/Lorch_project2018/bean/sc_diag_freq_by_year.dta /Users/austinbean/Desktop
	* scp beanaus@hsrdcsub2.pmacs.upenn.edu:/project/Lorch_project2018/bean/sc_proc_freq_by_year.dta /Users/austinbean/Desktop
	



*************
* TX


	* done on own machine.  
	
	
******* Merge them, compare.  
	
	use /project/Lorch_project2018/bean/tx_icd_counts.dta, clear
	
	merge 1:1 sdiag using /project/Lorch_project2018/bean/sc_icd_counts.dta
	
	replace sc_diagcount = 0 if _merge == 1 & sc_diagcount == .
	replace tx_diagcount = 0 if _merge == 2 & tx_diagcount == .
	drop _merge
	
	* Divide by number of patients to get a probability.
	local tx_count = 2734168
	local sc_count = 1240175
	
	gen tx_rate = 1000*(tx_diagcount/`tx_count')
	label variable tx_rate "num infants per 1000 w/ icd9"
	
	gen sc_rate = 1000*(sc_diagcount/`sc_count')
	label variable sc_rate "num infants per 1000 w/ icd9"

	* generate sort variable and non-missing variable:
	gen stx = -tx_diagcount
	gen sctx = -sc_diagcount
	gen non_miss = 1 if tx_diagcount > 0 & sc_diagcount > 0
	sort stx
	drop stx sctx
	
	* validate and describe the ICD-9 codes
	icd9 check sdiag, gen(icheck)
	replace sdiag = "" if icheck != 0
	icd9 generate diag_desc = sdiag, description
	icd9 clean sdiag, dots
	drop icheck
	
	* can test for equality of proportions, but not using prtest.  
		* https://www.itl.nist.gov/div898/software/dataplot/refman2/auxillar/diffprci.htm
	local tx_count = 2734168
	local sc_count = 1240175
	gen comb_prob = (tx_diagcount + sc_diagcount)/(`tx_count' + `sc_count')
	gen prop_test =  ((tx_diagcount/`tx_count') - (sc_diagcount/`sc_count'))/sqrt( (comb_prob*(1-comb_prob))*(1/`tx_count' + 1/`sc_count'))
		* double check
	gen p_value = 2*normal(-abs(prop_test))
	
	
	* Testing differences: 
	count
	local num_hyp = `r(N)'
	local lev = 0.05

	
	* Bonferroni Correction:
	gen test_stat_b = `lev'/`num_hyp'
	gen accept_b = 1 if p_value < test_stat_b
	replace accept_b = 0 if accept_b == .
	label variable accept_b "1 if acc under Bonferroni"
		* this accepts 1330 hypotheses
	
	*Holm-Bonferroni: this will reject all hypotheses above a certain leve
	sort p_value
		* count must happen after sort by p-value
	gen ctr = _n
	gen test_stat_hb = `lev'/(`num_hyp' + 1 - ctr)
	gen accept_hb = 1 if p_value <= test_stat_hb
	replace accept_hb = 0 if accept_hb == .
	label variable accept_hb "1 if acc under Holm-Bonferroni"
		* this accepts the first 1350 hypotheses
		
	* Benjamini-Hochberg (permits arbitrary dependence)
	gen test_stat_bh = (ctr/`num_hyp')*`lev'
	gen accept_bh = 1 if p_value <= test_stat_bh
	replace accept_bh = 0 if accept_bh == .
	label variable accept_bh "1 if acc under Benjamini-Hochberg"
		* this accept 2300 (?)
		
	* Benjamini-Yekuteli (permits arbitrary dependence)
	gen bht = sum(ctr)
	gen test_stat_by = (ctr/(`num_hyp'*bht))*`lev'
	gen accept_by = 1 if p_value <= test_stat_by
	replace accept_by = 0 if accept_by == .
	label variable accept_by "1 if acc under Benjamini-Yekuteli"
		* this accepts 1050

	
	drop ctr bht
	egen sigsum = rowtotal(accept_*)
	* for these variables the tests differ - maybe interesting or maybe not.
	gen sig_dis = 1 if (sigsum != 0) &(sigsum != 4) 
	
save /project/Lorch_project2018/bean/sc_tx_icd_counts.dta, replace
	
