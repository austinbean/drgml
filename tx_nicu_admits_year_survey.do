* nicu admits / year
/*
given that the inpatient data is surely better than the birth certificate data,
what about the hospital itself?  They submit an answer to the survey - is it 
from birth certificate or is it better?  

This will take data from:
- restricted nicu admissions from dshs: counts of nicu admits, LBW and VLBW by year
- inpatient data: counts of nicu, LBW and VLBW by year
- hospital survey data: counts of nicu admits per year (no birth weight available)

combine and compare...
*/


	* a subset of the restricted data by hospital
clear 
use "/Users/austinbean/Desktop/BirthData2005-2012/CombinedFacCount.dta"
keep facname fid nicu_year lbw_year vlbw_year ncdobyear
duplicates drop fid ncdobyear, force
rename fid FID
rename ncdobyear YEAR
gen from_restricted = 1
save "/Users/austinbean/Desktop/drgml/restr_dat_yearly.dta", replace


	* a subset of the inpatient data by hospital
clear 
use "/Users/austinbean/Desktop/Texas PUDF Zipped Backup Files/combined_data/all_year_nicu_stats.dta"
keep THCIC_ID YEAR TOT_NICU_ADMIT_YR CT_LBW_YR CT_VLBW_YR FID TOTALDELIVERIES
gen from_inpatient = 1
save "/Users/austinbean/Desktop/drgml/inpatient_dat_yearly.dta", replace


clear
quietly do "/Users/austinbean/Google Drive/Annual Surveys of Hospitals/Import 1990 - 2012.do"

* charges available after 2003, so admission only inferrable there.
keep if year > 2003

gen tot_nicu_ads = TransfersInternally_HAS_NICU + TransfersInFromOthers_HAS_NICU
label variable tot_nicu_ads "total internal and transfer nicu admits"


keep fid facility NeoIntensive SoloIntermediate year tot_nicu_ads TotalDeliveries NonzeroBirths_10 YearsNonzeroBirths_10 NonzeroBirths YearsNonzeroBirths TransfersInternally_HAS_NICU TransfersInFromOthers_HAS_NICU

drop if YearsNonzeroBirths_10 == 0

rename fid FID
rename year YEAR

merge 1:1 FID YEAR using "/Users/austinbean/Desktop/Choice Model with Fixed Effects/FIDtoTHCIC_ID.dta"
drop NAME
drop if _merge == 2
drop _merge

* Handles missing THCIC_ID's in a stupid way.
replace THCIC_ID = _n*(-1) if THCIC_ID == .
replace FID = _n*(-1) if FID == .


* merge inpatient data:
merge 1:1 THCIC_ID YEAR using "/Users/austinbean/Desktop/drgml/inpatient_dat_yearly.dta"
drop _merge

* merge restricted
duplicates tag FID YEAR, gen(ddd)
drop if facility == "" & ddd == 1
drop ddd
merge 1:1 FID YEAR using "/Users/austinbean/Desktop/drgml/restr_dat_yearly.dta"
drop _merge

* label some variables:

label variable TOT_NICU_ADMIT_YR "nicu ads, INPATIENT DATA"
label variable CT_LBW_YR "low birth weight, INPATIENT DATA"
label variable CT_VLBW_YR "VLBW, INPATIENT DATA"

label variable nicu_year "nicu ads, Birth Cert Data"
label variable lbw_year "LBW, Birth Cert Data"
label variable vlbw_year "VLBW, Birth Cert Data"

label variable tot_nicu_ads "nicu ads and transfers, Hosp Survey"
label variable TransfersInternally_HAS_NICU "admitted, not via transfer, Hosp Survey"
rename TransfersInFromOthers_HAS_NICU nicu_trans
label variable nicu_trans "admitted via transfer, Hosp Survey"

label variable NeoIntensive "Level III"
label variable SoloIntermediate "Level II, w/out Level III"

label variable NonzeroBirths "Hos. reported >0 births"


* unnecessary vars:
drop NonzeroBirths_10 YearsNonzeroBirths_10
*drop FID THCIC_ID
drop if facility == ""
drop facname
drop THCIC_ID 
drop FID
drop NonzeroBirths YearsNonzeroBirths
drop from_*
drop TOTALDELIVERIES

* which direction is the bias:
/*
gen byte noneq = 0 
replace noneq = 1 if TOT_NICU_ADMIT_YR != tot_nicu_ads
gen byte great = 0 
replace great = 1 if TOT_NICU_ADMIT_YR > tot_nicu_ads 
gen byte less = 0 
replace less = 1 if TOT_NICU_ADMIT_YR < tot_nicu_ads
*/

save /Users/austinbean/Desktop/drgml/nicu_admit_compare.dta, replace
