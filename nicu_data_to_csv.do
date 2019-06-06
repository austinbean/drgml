* nicu_data_csv
* save to csv...

* scp  "/Users/austinbean/Desktop/drgml/nicu_data_to_csv.do" beanaus@hsrdcsub2.pmacs.upenn.edu:/project/Lorch_project2018/bean/

use /project/Lorch_project2018/bean/nicu_coll_train.dta, clear

*recast byte ind_*

export delimited using /project/Lorch_project2018/bean/nicu_train_csv.csv, replace

use /project/Lorch_project2018/bean/nicu_coll_test.dta, clear

*recast byte ind_*

save export delimited using /project/Lorch_project2018/bean/nicu_test_csv.csv, replace

use /project/Lorch_project2018/bean/nicu_collapsed.dta, clear

*recast byte ind_*

save export delimited using /project/Lorch_project2018/bean/nicu_coll_csv.csv, replace
