* CA and SC to CSV.
* /project/Lorch_project2018/bean/ 
* scp  "/Users/austinbean/Desktop/drgml/ca_sc_t_csv.do" beanaus@hsrdcsub2.pmacs.upenn.edu:/project/Lorch_project2018/bean/


use /project/Lorch_project2018/bean/ca_nicu_collapsed.dta, clear

export delimited using /project/Lorch_project2018/bean/ca_nicu_coll.csv, replace

use /project/Lorch_project2018/bean/sc_nicu_collapsed.dta, clear

export delimited using /project/Lorch_project2018/bean/sc_nicu_coll.csv, replace 

