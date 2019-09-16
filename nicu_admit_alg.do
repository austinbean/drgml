
local whereami = "austinbean" 
local file_p = "/Users/`whereami'/Desktop/programs/drgml/"
local data_p = "/Users/`whereami'/Google Drive/Texas PUDF Zipped Backup Files/"

clear

foreach yr of numlist 2004(1)2012{
	foreach qr of numlist 1(1)4{
	di "`yr' `qr'"
	append using "`data_p'`yr'/CD`yr'Q`qr'/birthonly `qr' Q `yr'.dta", force
	replace DISCHARGE = "`yr'Q`qr'" if DISCHARGE == ""
	}

}

// sample 5


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
	* crazy charges:
		* max charge in data is: 179,000,496.  Drop if > 10,000,000 ????
	drop if TOTAL_CHARGES > 10000000                // drops 50 observations 
	* drop some very infrequent hospitals
	gen ctr = 1
	bysort THCIC_ID: egen hosp_count = sum(ctr)
	drop if hosp_count < 10                         // drops 50 observations
	drop if THCIC_ID == 999998 | THCIC_ID == 999999 // do not correspond to actual hospitals 
	
	sort DISCHARGE THCIC_ID 

* hospital specific counts (actual admits -> uses charges)
	bysort DISCHARGE THCIC_ID: egen quarter_admits = sum(ADMN_NICU)

* hospital specific charges - for well babies only (DRG 391):
	bysort DISCHARGE THCIC_ID: egen quarter_avg_charges = mean(TOTAL_CHARGES) if CMS_DRG == 391
	bysort DISCHARGE THCIC_ID: egen qac = max(quarter_avg_charges)
	replace quarter_avg_charges = qac if quarter_avg_charges == .

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
		
		
************************************** ADDS AUTO_ADMITS TO PREDICTION ***********************************
	
	count 
	local tot_count = 3487033
	

* Difference in charges
	gen charges_diff = TOTAL_CHARGES - quarter_avg_charges
	gen np_abs_charge_0 = 0
	gen np_abs_charge_250 = 0
	gen np_abs_charge_500 = 0
	gen np_abs_charge_1000 = 0
	* Replace as 1 if absolute charge diff greater than values given OR guaranteed admit on basis of automatic criteria above
	replace np_abs_charge_0 = 1 if charges_diff >0 | nicu_prediction == 1
	replace np_abs_charge_250 = 1 if charges_diff >250 | nicu_prediction == 1
	replace np_abs_charge_500 = 1 if charges_diff >500 | nicu_prediction == 1
	replace np_abs_charge_1000 = 1 if charges_diff >1000 | nicu_prediction == 1
	* MSE's 
	egen mse_abs_charge_0 = total(abs(ADMN_NICU - np_abs_charge_0))
	replace mse_abs_charge_0 = mse_abs_charge_0/`tot_count'
	egen mse_abs_charge_250 = total(abs(ADMN_NICU - np_abs_charge_250))
	replace mse_abs_charge_250 = mse_abs_charge_250/`tot_count'
	egen mse_abs_charge_500 = total(abs(ADMN_NICU - np_abs_charge_500))
	replace mse_abs_charge_500 = mse_abs_charge_500/`tot_count'
	egen mse_abs_charge_1000 = total(abs(ADMN_NICU - np_abs_charge_1000))
	replace mse_abs_charge_1000 = mse_abs_charge_1000/`tot_count'
	* ROCTAB BELOW


* By Charges

	* CHARGES PERCENT DIFFERENCE 
		* Predictors:
		gen np_pdiff_25 = 0
		gen np_pdiff_50 = 0
		gen np_pdiff_75 = 0
		gen np_pdiff_100 = 0
		* Replace as 1 if Total Charges greater than +% of the hospital-quarter mean OR guaranteed admits on basis of automatic criteria 
		replace np_pdiff_25 = 1 if TOTAL_CHARGES > 1.25*quarter_avg_charges | nicu_prediction == 1
		replace np_pdiff_50 = 1 if TOTAL_CHARGES > 1.50*quarter_avg_charges | nicu_prediction == 1
		replace np_pdiff_75 = 1 if TOTAL_CHARGES > 1.75*quarter_avg_charges | nicu_prediction == 1
		replace np_pdiff_100 = 1 if TOTAL_CHARGES > 2.00*quarter_avg_charges | nicu_prediction == 1
		* MSE's 
		egen mse_np_pdiff_25 = sum(abs(ADMN_NICU - np_pdiff_25))
		replace mse_np_pdiff_25 = mse_np_pdiff_25/`tot_count'
		egen mse_np_pdiff_50 = sum(abs(ADMN_NICU - np_pdiff_50))
		replace mse_np_pdiff_50 = mse_np_pdiff_50/`tot_count'
		egen mse_np_pdiff_75 = sum(abs(ADMN_NICU - np_pdiff_75))
		replace mse_np_pdiff_75 = mse_np_pdiff_75/`tot_count'
		egen mse_np_pdiff_100 = sum(abs(ADMN_NICU - np_pdiff_100))
		replace mse_np_pdiff_100 = mse_np_pdiff_100/`tot_count'
		* ROCTAB BELOW

	* PERCENTILE OF TOTAL_CHARGES 
		bysort DISCHARGE THCIC_ID: egen ptile_abcharges_diff_85 = pctile(quarter_avg_charges), p(85)
		bysort DISCHARGE THCIC_ID: egen ptile_abcharges_diff_90 = pctile(quarter_avg_charges), p(90)
		bysort DISCHARGE THCIC_ID: egen ptile_abcharges_diff_95 = pctile(quarter_avg_charges), p(95)
		* Predictors:
		gen np_abdiff_85 = 0
		gen np_abdiff_90 = 0
		gen np_abdiff_95 = 0
		* Replace as 1 if Total Charges greater than X%-ile of the hospital-quarter mean OR guaranteed admits on basis of automatic criteria 
		replace np_abdiff_85 = 1 if TOTAL_CHARGES > ptile_abcharges_diff_85 | nicu_prediction == 1
		replace np_abdiff_90 = 1 if TOTAL_CHARGES > ptile_abcharges_diff_90 | nicu_prediction == 1
		replace np_abdiff_95 = 1 if TOTAL_CHARGES > ptile_abcharges_diff_95 | nicu_prediction == 1
		* MSE's
		egen mse_np_abdiff_85 = sum(abs(ADMN_NICU-np_abdiff_85))
		replace mse_np_abdiff_85 = mse_np_abdiff_85/`tot_count'
		egen mse_np_abdiff_90 = sum(abs(ADMN_NICU-np_abdiff_90))
		replace mse_np_abdiff_90 = mse_np_abdiff_90/`tot_count'
		egen mse_np_abdiff_95 = sum(abs(ADMN_NICU-np_abdiff_95))
		replace mse_np_abdiff_95 = mse_np_abdiff_95/`tot_count'
	
	
	* PERCENTILE OF DIFFERENCE WITH RESPECT TO TOTAL_CHARGES 
		bysort DISCHARGE THCIC_ID: egen ptile_charges_diff_85 = pctile(charges_diff), p(85)
		bysort DISCHARGE THCIC_ID: egen ptile_charges_diff_90 = pctile(charges_diff), p(90)
		bysort DISCHARGE THCIC_ID: egen ptile_charges_diff_95 = pctile(charges_diff), p(95)
		* Predictors:
		gen np_ptcdiff_85 = 0
		gen np_ptcdiff_90 = 0
		gen np_ptcdiff_95 = 0
		* Replace as 1 if Total Charges greater than X%-ile of the hospital-quarter mean OR guaranteed admits on basis of automatic criteria 
		replace np_ptcdiff_85 = 1 if charges_diff > ptile_charges_diff_85 | nicu_prediction == 1
		replace np_ptcdiff_90 = 1 if charges_diff > ptile_charges_diff_90 | nicu_prediction == 1
		replace np_ptcdiff_95 = 1 if charges_diff > ptile_charges_diff_95 | nicu_prediction == 1
		* MSE
		egen mse_np_ptcdiff_85 = sum(abs(ADMN_NICU - np_ptcdiff_85))
		replace mse_np_ptcdiff_85 = mse_np_ptcdiff_85/`tot_count'
		egen mse_np_ptcdiff_90 = sum(abs(ADMN_NICU - np_ptcdiff_90))
		replace mse_np_ptcdiff_90 = mse_np_ptcdiff_90/`tot_count'
		egen mse_np_ptcdiff_95 = sum(abs(ADMN_NICU - np_ptcdiff_95))
		replace mse_np_ptcdiff_95 = mse_np_ptcdiff_95/`tot_count'


***********************************  NOW DON'T ADD AUTO_ADMITS *****************************************


* Difference in charges
	gen np_abs_charge_wo_0 = 0
	gen np_abs_charge_wo_250 = 0
	gen np_abs_charge_wo_500 = 0
	gen np_abs_charge_wo_1000 = 0
	* Replace as 1 if absolute charge diff greater than values given OR guaranteed admit on basis of automatic criteria above
	replace np_abs_charge_wo_0 = 1 if charges_diff >0 
	replace np_abs_charge_wo_250 = 1 if charges_diff >250 
	replace np_abs_charge_wo_500 = 1 if charges_diff >500 
	replace np_abs_charge_wo_1000 = 1 if charges_diff >1000 
	* MSE
	egen mse_wo_np_abs_charge_0 = sum(abs(ADMN_NICU-np_abs_charge_wo_0))
	replace mse_wo_np_abs_charge_0 = mse_wo_np_abs_charge_0/`tot_count'
	egen mse_wo_np_abs_charge_250 = sum(abs(ADMN_NICU-np_abs_charge_wo_250))
	replace mse_wo_np_abs_charge_250 = mse_wo_np_abs_charge_250/`tot_count'
	egen mse_wo_np_abs_charge_500 = sum(abs(ADMN_NICU-np_abs_charge_wo_500))
	replace mse_wo_np_abs_charge_500 = mse_wo_np_abs_charge_500/`tot_count'
	egen mse_wo_np_abs_charge_1000 = sum(abs(ADMN_NICU-np_abs_charge_wo_1000))
	replace mse_wo_np_abs_charge_1000 = mse_wo_np_abs_charge_1000/`tot_count'



* By Charges

	* CHARGES PERCENT DIFFERENCE 
		* Predictors:
		gen np_pdiff_25_wo = 0
		gen np_pdiff_50_wo = 0
		gen np_pdiff_75_wo = 0
		gen np_pdiff_100_wo = 0
		* Replace as 1 if Total Charges greater than +% of the hospital-quarter mean OR guaranteed admits on basis of automatic criteria 
		replace np_pdiff_25_wo = 1 if TOTAL_CHARGES > 1.25*quarter_avg_charges 
		replace np_pdiff_50_wo = 1 if TOTAL_CHARGES > 1.50*quarter_avg_charges 
		replace np_pdiff_75_wo = 1 if TOTAL_CHARGES > 1.75*quarter_avg_charges 
		replace np_pdiff_100_wo = 1 if TOTAL_CHARGES > 2.00*quarter_avg_charges 
		* MSEs
		egen mse_np_pdiff_25_wo = sum(abs(ADMN_NICU - np_pdiff_25_wo))
		replace mse_np_pdiff_25_wo = mse_np_pdiff_25_wo/`tot_count'
		egen mse_np_pdiff_50_wo = sum(abs(ADMN_NICU - np_pdiff_50_wo))
		replace mse_np_pdiff_50_wo = mse_np_pdiff_50_wo/`tot_count'
		egen mse_np_pdiff_75_wo = sum(abs(ADMN_NICU - np_pdiff_75_wo))
		replace mse_np_pdiff_75_wo = mse_np_pdiff_75_wo/`tot_count'
		egen mse_np_pdiff_100_wo = sum(abs(ADMN_NICU - np_pdiff_100_wo))
		replace mse_np_pdiff_100_wo = mse_np_pdiff_100_wo/`tot_count'

	* PERCENTILE OF TOTAL_CHARGES 
		* Predictors:
		gen np_abdiff_85_wo = 0
		gen np_abdiff_90_wo = 0
		gen np_abdiff_95_wo = 0
		* Replace as 1 if Total Charges greater than X%-ile of the hospital-quarter mean OR guaranteed admits on basis of automatic criteria 
		replace np_abdiff_85_wo = 1 if TOTAL_CHARGES > ptile_abcharges_diff_85 
		replace np_abdiff_90_wo = 1 if TOTAL_CHARGES > ptile_abcharges_diff_90 
		replace np_abdiff_95_wo = 1 if TOTAL_CHARGES > ptile_abcharges_diff_95 
		* MSEs 
		egen mse_np_abdiff_85_wo = sum(abs(ADMN_NICU - np_abdiff_85_wo))
		replace mse_np_abdiff_85_wo = mse_np_abdiff_85_wo/`tot_count'
		egen mse_np_abdiff_90_wo = sum(abs(ADMN_NICU - np_abdiff_90_wo))
		replace mse_np_abdiff_90_wo = mse_np_abdiff_90_wo/`tot_count'
		egen mse_np_abdiff_95_wo = sum(abs(ADMN_NICU - np_abdiff_95_wo))
		replace mse_np_abdiff_95_wo = mse_np_abdiff_95_wo/`tot_count'
	
	
	* PERCENTILE OF DIFFERENCE WITH RESPECT TO TOTAL_CHARGES 
		* Predictors:
		gen np_ptcdiff_85_wo = 0
		gen np_ptcdiff_90_wo = 0
		gen np_ptcdiff_95_wo = 0
		* Replace as 1 if Total Charges greater than X%-ile of the hospital-quarter mean OR guaranteed admits on basis of automatic criteria 
		replace np_ptcdiff_85_wo = 1 if TOTAL_CHARGES > ptile_charges_diff_85 
		replace np_ptcdiff_90_wo = 1 if TOTAL_CHARGES > ptile_charges_diff_90 
		replace np_ptcdiff_95_wo = 1 if TOTAL_CHARGES > ptile_charges_diff_95 
		* MSEs
		egen mse_np_ptcdiff_85_wo = sum(abs(ADMN_NICU - np_ptcdiff_85_wo))
		replace mse_np_ptcdiff_85_wo = mse_np_ptcdiff_85_wo/`tot_count'
		egen mse_np_ptcdiff_90_wo = sum(abs(ADMN_NICU - np_ptcdiff_90_wo))
		replace mse_np_ptcdiff_90_wo = mse_np_ptcdiff_90_wo/`tot_count'
		egen mse_np_ptcdiff_95_wo = sum(abs(ADMN_NICU - np_ptcdiff_95_wo))
		replace mse_np_ptcdiff_95_wo = mse_np_ptcdiff_95_wo/`tot_count'



********************** LOGGED PREDICTIONS *********************

log using "`data_p'log files/admit_algo.smcl", replace

	* Predictions based on absolute charges difference:
// "********************************************************************************************************"
// "Predictions when absolute charge is $0, $250, $500 or $1000 greater than facility-quarter specific mean"
// "Adds all automatic admits"
// "Cutpoints: 0 -> <mean, 1 -> $0-250 greater, 2 -> $0-500 greater, 3 -> $0-1000 greater, 4-> >$1000 greater"
	quietly egen tpred = rowtotal(np_abs_charge_0 np_abs_charge_250 np_abs_charge_500 np_abs_charge_1000) 
	roctab ADMN_NICU tpred, detail table graph plotopts(title("Total Charge is $0, $250," "$500, $1000 Greater" "than Hospital-Quarter Mean") graphregion(color(white)) note("Including Automatically Admitted Patients: <1500 g, Sick DRG, All Deaths"))
	graph save "`data_p'graphs/admit_alg/senspec_abs_charge_aa.gph", replace
	graph export "`data_p'graphs/admit_alg/senspec_abs_charge_aa.png", replace
	di "Mean-squared error for the same predictions"
	summarize mse_abs_charge_0
	summarize mse_abs_charge_250
	summarize mse_abs_charge_500 
	summarize mse_abs_charge_1000

	
	* % greater than X% facility-quarter specific mean
// "*********************************************************************************************************************"
// "Predictions when absolute charge is 25%, 50%, 75% or 100% greater than facility-quarter specific mean"
// "Adds all automatic admits"
// "Cutpoints: 0 -> <25%+ avg charge, 1 -> >0-25% avg chg, 2 -> 0-50% avg chg, 3 -> 0-75% avg chg, 4-> 0-100%+ avg chg"
	quietly egen tpctpred = rowtotal(np_pdiff_25 np_pdiff_50 np_pdiff_75 np_pdiff_100)
	roctab ADMN_NICU tpctpred, detail table graph plotopts(title("Total Charge is 25%, 50%,"  "75%, 100% Greater" "than Hosp.-Quarter Mean") graphregion(color(white)) note("Including Automatically Admitted Patients: <1500 g, Sick DRG, All Deaths"))
	graph save "`data_p'graphs/admit_alg/senspec_pct_charge_aa.gph", replace
	graph export "`data_p'graphs/admit_alg/senspec_pct_charge_aa.png", replace
	di "Mean-squared error for the same predictions"
	summarize mse_np_pdiff_25 
	summarize mse_np_pdiff_50 
	summarize mse_np_pdiff_75 
	summarize mse_np_pdiff_100

	
	* Percentiles of the facility-specific mean diff
// "*********************************************************************************************************************"
// "Predictions when  patient charge  is greater than 85th 90th and 95th %-iles of the facility-quarter specific mean"
// "Adds all automatic admits"
// "Cutpoints: 0 -> <85th%ile diff charge, 1 -> 85th-89th%ile diff chg, 2 -> 90th-94th%ile diff chg, 3 -> >95th%ile diff chg"
	quietly egen abpreddiff = rowtotal(np_abdiff_85 np_abdiff_90 np_abdiff_95)
	roctab ADMN_NICU abpreddiff, detail table graph plotopts(title("Total Charge is at or Greater" "than 85th, 90th, 95th"  "%ile of Hosp.-Quarter Mean") graphregion(color(white)) note("Including Automatically Admitted Patients: <1500 g, Sick DRG, All Deaths") )
	graph save "`data_p'graphs/admit_alg/senspec_pctile_charge_aa.gph", replace
	graph export "`data_p'graphs/admit_alg/senspec_pctile_charge_aa.png", replace
	di "Mean-squared error for the same predictions"
	summarize mse_np_abdiff_85 
	summarize mse_np_abdiff_90 
	summarize mse_np_abdiff_95


	* 
// "*********************************************************************************************************************"
// "Predictions when  (patient charge - facility-quarter mean) is greater than 85th 90th and 95th %-iles of that difference"
// "Adds all automatic admits"
// "Cutpoints: 0 -> <85th%ile diff charge, 1 -> 85th-89th%ile diff chg, 2 -> 90th-94th%ile diff chg, 3 -> >95th%ile diff chg"
	quietly egen pctdiffpred = rowtotal(np_ptcdiff_85 np_ptcdiff_90 np_ptcdiff_95)
	roctab ADMN_NICU pctdiffpred, detail table graph plotopts(title("Patient Charge - Fac-Quart."  "Mean is at or Greater" "than 85th, 90th, 95th %ile of Patient"  "Charge - Hospital-Quarter Mean") graphregion(color(white)) note("Including Automatically Admitted Patients: <1500 g, Sick DRG, All Deaths") )
	graph save "`data_p'graphs/admit_alg/senspec_pcdiff_charge_aa.gph", replace
	graph export "`data_p'graphs/admit_alg/senspec_pcdiff_charge_aa.png", replace
	di "Mean-squared error for the same predictions"
	summarize mse_np_ptcdiff_85 
	summarize mse_np_ptcdiff_90 
	summarize mse_np_ptcdiff_95


	*******************************************************

	* 
// "*********************************************************************************************************************"
// "Predictions when charge is $0, $250, $500, $1000 greater than the facility-quarter specific mean"
// "Does not add automatic admits"
// "Cutpoints: 0 -> <mean, 1 -> $0-250 greater, 2 -> $0-500 greater, 3 -> $0-1000 greater, 4-> >$1000 greater"
	quietly egen na_abpreddiff =  rowtotal(np_abs_charge_wo_0 np_abs_charge_wo_250 np_abs_charge_wo_500 np_abs_charge_wo_1000)
	roctab ADMN_NICU na_abpreddiff, detail table graph plotopts(title("Total Charge is $0, $250," "$500, $1000 Greater" "than Hospital-Quarter Mean") graphregion(color(white)) note("Excluding Automatically Admitted Patients"))
	graph save "`data_p'graphs/admit_alg/senspec_abs_charge_naa.gph", replace
	graph export "`data_p'graphs/admit_alg/senspec_abs_charge_naa.png", replace
	di "Mean-squared error for the same predictions"
	summarize mse_wo_np_abs_charge_0 
	summarize mse_wo_np_abs_charge_250 
	summarize mse_wo_np_abs_charge_500 
	summarize mse_wo_np_abs_charge_1000 

	
	* 
// "*********************************************************************************************************************"
// "Predictions when  patient charge  is 25%, 50%, 75%, 100% greater than the facility-quarter specific mean"
// "Does not add automatic admits"
// "Cutpoints: 0 -> <25%+ avg charge, 1 -> >0-25% avg chg, 2 -> 0-50% avg chg, 3 -> 0-75% avg chg, 4-> 0-100%+ avg chg"
	quietly egen na_tpctpred = rowtotal(np_pdiff_25_wo np_pdiff_50_wo np_pdiff_75_wo np_pdiff_100_wo)
	roctab ADMN_NICU na_tpctpred, detail table graph plotopts(title("Total Charge is 25%, 50%,"  "75%, 100% Greater" "than Hosp.-Quarter Mean") graphregion(color(white)) note("Excluding Automatically Admitted Patients"))
	graph save "`data_p'graphs/admit_alg/senspec_pct_charge_naa.gph", replace
	graph export "`data_p'graphs/admit_alg/senspec_pct_charge_naa.png", replace
	di "Mean-squared error for the same predictions"
	summarize mse_np_pdiff_25_wo 
	summarize mse_np_pdiff_50_wo 
	summarize mse_np_pdiff_75_wo 
	summarize mse_np_pdiff_100_wo 

	
	* 
// "*********************************************************************************************************************"
// "Predictions when  patient charge is greater than 85th 90th and 95th %-iles of the facility-quarter specific mean"
// "Does not add automatic admits"
// "Cutpoints: 0 -> <85th%ile diff charge, 1 -> 85th-89th%ile diff chg, 2 -> 90th-94th%ile diff chg, 3 -> >95th%ile diff chg"
	quietly  egen na_abpdiff = rowtotal( np_abdiff_85_wo np_abdiff_90_wo np_abdiff_95_wo)
	roctab ADMN_NICU na_abpdiff, detail table graph plotopts(title("Total Charge is at or Greater" "than 85th, 90th, 95th"  "%ile of Hosp.-Quarter Mean") graphregion(color(white)) note("Excluding Automatically Admitted Patients") )
	graph save "`data_p'graphs/admit_alg/senspec_pctile_charge_naa.gph", replace
	graph export "`data_p'graphs/admit_alg/senspec_pctile_charge_naa.png", replace
	di "Mean-squared error for the same predictions"
	summarize mse_np_abdiff_85_wo 
	summarize mse_np_abdiff_90_wo 
	summarize mse_np_abdiff_95_wo 

	
	
	* 
// "*********************************************************************************************************************"
// "Predictions when  patient charge is greater than 85th 90th and 95th %-iles of the facility-quarter specific mean"
// "Does not add automatic admits"
// "Cutpoints: 0 -> <85th%ile diff charge, 1 -> 85th-89th%ile diff chg, 2 -> 90th-94th%ile diff chg, 3 -> >95th%ile diff chg"
	quietly egen na_pctdiffpred = rowtotal(np_ptcdiff_85_wo np_ptcdiff_90_wo np_ptcdiff_95_wo)
	roctab ADMN_NICU na_pctdiffpred, detail table graph plotopts(title("Patient Charge - Fac-Quart."  "Mean is at or Greater" "than 85th, 90th, 95th %ile of Patient"  "Charge - Hospital-Quarter Mean") graphregion(color(white)) note("Excluding Automatically Admitted Patients") )
	graph save "`data_p'graphs/admit_alg/senspec_pcdiff_charge_naa.gph", replace
	graph export "`data_p'graphs/admit_alg/senspec_pcdiff_charge_naa.png", replace
	di "Mean-squared error for the same predictions"
	summarize mse_np_ptcdiff_85_wo 
	summarize mse_np_ptcdiff_90_wo 
	summarize mse_np_ptcdiff_95_wo 



	
log close 

translate "`data_p'log files/admit_algo.smcl" "`data_p'log files/admit_algo.pdf", replace

* Graph combine: 
	graph combine "`data_p'graphs/admit_alg/senspec_abs_charge_aa.gph" "`data_p'graphs/admit_alg/senspec_abs_charge_naa.gph", xcommon ycommon title("Combined Dollar Threshold")
	graph export "`data_p'graphs/admit_alg/combined_abs_charg.png", replace
	
	graph combine "`data_p'graphs/admit_alg/senspec_pct_charge_aa.gph" "`data_p'graphs/admit_alg/senspec_pct_charge_naa.gph", xcommon ycommon title("Combined Percentage Over Hosp-Quart Mean")
	graph export "`data_p'graphs/admit_alg/combined_percent_charg.png", replace

	graph combine "`data_p'graphs/admit_alg/senspec_pctile_charge_aa.gph" "`data_p'graphs/admit_alg/senspec_pctile_charge_naa.gph", xcommon ycommon title("Combined Percentile Threshold")
	graph export "`data_p'graphs/admit_alg/combined_percentile.png", replace
	
	graph combine "`data_p'graphs/admit_alg/senspec_pcdiff_charge_aa.gph" "`data_p'graphs/admit_alg/senspec_pcdiff_charge_naa.gph", xcommon ycommon title("Combined Percentile of Difference")
	graph export "`data_p'graphs/admit_alg/combined_percentile_diff.png", replace



	

// keep mse*
// keep if _n == 1
// gen ID = 1

// rename mse_np_pdiff_*_wo mse_np_pdiff_wo_* 
// rename mse_np_abdiff_*_wo mse_np_abdiff_wo_*
// rename mse_np_ptcdiff_*_wo mse_np_ptcdiff_wo_*

//  * NOTE NEEDS RENUMBERING 

// reshape long mse_abs_charge_ mse_np_pdiff_ mse_np_abdiff_ mse_np_ptcdiff_ mse_wo_np_abs_charge_ mse_np_pdiff_wo_ mse_np_abdiff_wo_ mse_np_ptcdiff_wo_ , i(ID) j(ctr)
