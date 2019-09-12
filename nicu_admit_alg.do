local file_p = "/Users/tuk39938/Desktop/programs/drgml/"
local data_p = "/Users/tuk39938/Google Drive/Texas PUDF Zipped Backup Files/"

clear

foreach yr of numlist 2004(1)2012{
	foreach qr of numlist 1(1)4{
	di "`yr' `qr'"
	append using "`data_p'`yr'/CD`yr'Q`qr'/birthonly `qr' Q `yr'.dta", force
	
	}

}

/*

Automatic NICU admission:
Birth weight < 1500 grams
Gestational age <= 32 weeks
Any transfer
Any death
Any sick DRG, either preterm or term.

Calculate the daily cost difference between each patient and the average cost for the well baby DRG in the specific delivery hospital. 
Then:
If the total number of NICU admissions is available either for the individual hospital or, more likely, the state, then take the the highest cost patients (whether it is absolute difference or average difference from the average well baby delivery hospital) to make up the total number of patients admitted.
If not – then we will use the data below to determine the threshold.  It probably will be somewhere in the 90% percentile for costs.
 
Various options I would like to report the sensitivity and specificity on:

	Specific cost thresholds.  First, absolute differences from the well-baby DRG:  $0, $250, $500

	Second, percent differences:  0%, 25%, 50%, 75%, 100%
	
	Third:  Take the 85th, 90th, and 95th percentile for either absolute or percent difference.

	Same thresholds and percentiles with added “automatic” groups:
First: all preterm births, deaths, and transfers
Then, add the sick DRGs to the automatic groups.
Then:  instead of using specific thresholds, use the total number of admissions in the state, and just take the highest cost patients (for either absolute or percent) to make up the total number of admissions.  Do this without any automatic groups, and then to complete the cohort after including the 2 automatic groups above.

labelsc= ["385/789 Neonates died or transferred", 
          "386/790 Extreme immaturity/respiratory distress", 
		  "387/791 Prematurity w/ Major Problems", 
		  "388/792 Prematurity w/out major problems", 
		  "389/793 Full term neonate w/ major problems", 
		  "390/794 Neonate w/ other significant problems", 
		  "391/795 Normal Newborn"]

*/

* Drop some crazy values
	drop if LENGTH_OF_STAY > 365
	* drop some very infrequent hospitals
	gen ctr = 1
	bysort THCIC_ID: egen hosp_count = sum(ctr)
	drop if hosp_count < 10                         // drops 50 observations
	drop if THCIC_ID == 999998 | THCIC_ID == 999999 // do not correspond to actual hospitals 
	
	sort DISCHARGE THCIC_ID 

* hospital specific counts (actual admits - uses charges)
	bysort DISCHARGE THCIC_ID: egen quarter_admits = sum(ADMN_NICU)

* hospital specific charges:
	bysort DISCHARGE THCIC_ID: egen quarter_avg_charges = mean(TOTAL_CHARGES)

* variable to hold the results of the prediction:
	gen nicu_prediction = 0  
		* birth weight < 1500 grams
	replace nicu_prediction = 1 if VLBW == 1
		* Sick DRGs - all are admits except 391 / Normal newborn.  
	replace nicu_prediction = 1 if CMS_DRG == 385 | CMS_DRG == 386 | CMS_DRG == 387 | CMS_DRG == 388 | CMS_DRG == 389 | CMS_DRG == 390 
		* Deaths
	replace nicu_prediction = 1 if PATIENT_STATUS == 20 
		* Gestational Age
		* NOT AVAILABLE. 
	

* Difference in charges
	gen charges_diff = TOTAL_CHARGES - quarter_avg_charges
	gen np_abs_charge_0 = 0
	gen np_abs_charge_250 = 0
	gen np_abs_charge_500 = 0
	* Replace as 1

* By Charges

* By Percentiles
	bysort DISCHARGE THCIC_ID: egen pct pc

* by length of stay 

* birth weights
