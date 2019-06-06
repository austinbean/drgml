library(randomForest)
library(dplyr)

# scp  "/Users/austinbean/Desktop/drgml/sc_classifier.R" beanaus@hsrdcsub2.pmacs.upenn.edu:/project/Lorch_project2018/bean/


# constant parameter
tree_num = 300
home = FALSE

# forest combining function
source("/project/Lorch_project2018/bean/forest_combiner.R")

train_d = read.csv("/project/Lorch_project2018/bean/sc_nicu_train.csv")
test_d = read.csv("/project/Lorch_project2018/bean/sc_nicu_test.csv")


# maybe this column is just missing and it should be admn_nicu
train_d_ad <- train_d[train_d$admn_nicu == 1, ]
print("DIMENSIONS w/ ADMN_NICU == 1")
print(dim(train_d_ad))
train_d_na <- train_d[train_d$admn_nicu == 0, ]
print("DIMENSIONS w/ ADMN_NICU == 0")
print(dim(train_d_na))
# select half of the admitted patients
train_d2 <- sample_n(train_d_na, floor((nrow(train_d_na)/2)))

# new, smaller dataframe
train_d <- rbind(train_d2, train_d_ad)

# rename
colnames(train_d) <- toupper(colnames(train_d))
colnames(test_d) <- toupper(colnames(test_d))

# add cols:
train_d$ISTRAIN <- rep(1, nrow(train_d))
test_d$ISTRAIN <- rep(0, nrow(test_d))

# rbind - stupid.
complete_d <- rbind(train_d, test_d)

# convert numeric variables to factors
complete_d <- mutate_if(complete_d, is.numeric, as.factor)
# check: is.factor(complete_d$ADMN_NICU)

# dump row number and Record ID
complete_d$PID <- NULL
complete_d$RECORD_ID <- NULL

# recreate new data sets - split bound versions
train_new <- complete_d[complete_d$ISTRAIN==1,]
test_new <- complete_d[complete_d$ISTRAIN==0,]
# drop tag
train_new$ISTRAIN <- NULL
test_new$ISTRAIN<- NULL

# Actual data too long to use Ccall / Fortran w/ RandomForest.  
len1 = dim(train_new)[2]
midpoint_train = floor(dim(train_new)[2]/2)

# allocate a new datafram with a random sample, b/c this one is sorted now.



forest_tst1 <- randomForest(ADMN_NICU~ .,
                            data=train_new[1:midpoint_train,],
                            ntree = tree_num,
                            do.trace=TRUE,
                            importance=TRUE)
forest_tst2 <- randomForest(ADMN_NICU~ .,
                            data=train_new[(midpoint_train+1):len1,],
                            ntree = tree_num,
                            do.trace=TRUE,
                            importance=TRUE)


# library source and then combine.
library(randomForest)

forest_tst <- forest_combine(forest_tst1, forest_tst2)

res <-predict(forest_tst, 
              test_new,
              type="response")

sum(res!=test_new$admn_nicu)/length(res)


imp_vals <- importance(forest_tst)
write.csv(imp_vals, file="/project/Lorch_project2018/bean/var_imp_sc.csv")

