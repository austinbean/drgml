* sc connect.
/*
Just merge the baby ID and pid for the sc feature matrices.
in sc_feature_matrix the baby_id and pid are matched and saved prior to the 
collapsing of the data and construction of the feature matrix.  
*/


	* 
/*
SC_baby_hosp_records.dta contains four variables: CHG170, CHG172, CHG173 CHG174.  [NOTE NON SEQUENTIAL - no chg170]
By the numbers, CHG170 is well baby, whereas 172 - 174 are nicu admits.
These are nicu admit variables.  They are recorded as floats, for the charges item.
Identifying items are:
BABY_ID - unique ID per baby, but not per admit
admd - admitting DATE (note: not admday, which is day of week)
disd - discharge date.
HID_ENCRYPT - hospital ID.

Probably this is sufficient.  


The SC_birthcert.dta file contains a baby ID.  There are 1,038,105 rows and 1,036,945 unique baby ids
This can be merged 1:M into SC_baby_hosp_records.  
There are 1,088,273 baby IDs.
What I need from this file are birth dates only.
If I even care...  I'm not sure I do.

*/




use /project/Lorch_project2018/bean/sc_baby_id_pid.dta, clear


* How nid is created:
* 	gen nid = string(baby_id) + "_" + string(admd) + "_" + string(disd) + "_" + string(hid_encrypt) + "_" + string(bbct)
* from sc_feature_matrix.do

split nid, p("_")

rename nid1 baby_id_copy
rename nid2 admit_date
rename nid3 disc_date
rename nid4 hospital_id
rename nid5 babycounter


merge 1:1 pid using /project/Lorch_project2018/bean/sc_nicu_collapsed.dta

* don't understand who is missing and why...

* lis baby_id nid pid baby_id_copy admit_date disc_date hospital_id babycounter _merge 

drop if _merge != 3

rename baby_id BABY_ID
drop _merge


	* IS IT POSSIBLE TO MERGE ON PID?  THAT IS UNIQUE
save /project/Lorch_project2018/bean/sc_nicu_collapsed_id.dta, replace

clear

use /project/Lorch_project2018/bean/datacsv/datacsv/SC_birthcert.dta, clear

keep BABY_ID AC_NICU_ADMISSION

save /project/Lorch_project2018/bean/sc_nicu_admits.dta, replace

use /project/Lorch_project2018/bean/sc_nicu_collapsed.dta, clear
