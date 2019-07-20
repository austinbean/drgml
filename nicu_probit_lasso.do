* Lasso for NICU admission
	* TX data
	* 10% sample
	
use "/Users/austinbean/Desktop/drgml/nicu_coll_samp10.dta", clear

drop RECORD_ID _merge pid

* set a seed
set seed 1


* Linear 

lasso linear ADMN_NICU ind_*

coefpath, xunits(rlnlambda) xline(.0028439)

cvplot 


* this is slow.


lasso probit ADMN_NICU ind_*, rseed(2)

* post-estimation:

cvplot

coefplot
