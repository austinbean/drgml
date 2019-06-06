* recast and save...
* this is stupid... 
* scp  "/Users/austinbean/Desktop/drgml/nicu_data_recast.do" beanaus@hsrdcsub2.pmacs.upenn.edu:/project/Lorch_project2018/bean/

use /project/Lorch_project2018/bean/nicu_coll_train.dta, clear

recast byte ind_*

save nicu_train_2.dta, replace

use /project/Lorch_project2018/bean/nicu_coll_test.dta, clear

recast byte ind_*

save nicu_test_2.dta, replace

use /project/Lorch_project2018/bean/nicu_collapsed.dta, clear

recast byte ind_*

save nicu_coll_c.dta, replace
