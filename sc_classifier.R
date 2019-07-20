library(randomForest)
library(dplyr)

# scp  "/Users/austinbean/Desktop/drgml/sc_classifier.R" beanaus@hsrdcsub2.pmacs.upenn.edu:/project/Lorch_project2018/bean/
# scp beanaus@hsrdcsub2.pmacs.upenn.edu:/project/Lorch_project2018/bean/var_imp_sc.csv   "/Users/austinbean/Desktop/drgml/" 
# scp beanaus@hsrdcsub2.pmacs.upenn.edu:/project/Lorch_project2018/bean/sc_test_predict.csv   "/Users/austinbean/Desktop/drgml/" 

# when submitting use bsub < r_sc_class.sh -m pellaeon 

# constant parameter
tree_num = 100
set.seed(26)

# forest combining function
source("/project/Lorch_project2018/bean/forest_combiner.R")

train_d = read.csv("/project/Lorch_project2018/bean/sc_nicu_train.csv")
test_d = read.csv("/project/Lorch_project2018/bean/sc_nicu_test.csv")

# what should I do... can't sort and separate out.
# Just take half of each for each thing.

# combine columns
alld <- bind_rows(train_d, test_d)
alld <- mutate_if(alld, is.numeric, as.factor)


# add column of random values:
alld$r_v <- runif(nrow(alld))
alld$set <- rep(0, nrow(alld))

# select out 60/30/10 split:
for (i in 1:nrow(alld)){
  if (alld[i, "r_v"] <= 0.6) {
    alld[i,"r_v"] = 1
  }
  # check if this is short-circuit and
  else if ((alld[i, "r_v"] > 0.6)&&(alld[i, "r_v"] <= 0.9)){
    alld[i,"r_v"] = 2
  }
  else{
    alld[i, "r_v"] = 3
  }
  if (i%%10000 == 0) {
    print(i)
  }
}

# subset out: 

traind <- alld[alld$r_v == 1,]
vald <- alld[alld$r_v == 2,]
testd <- alld[alld$r_v == 3,]

# rename
colnames(traind) <- toupper(colnames(traind))
colnames(vald) <- toupper(colnames(vald))
colnames(testd) <- toupper(colnames(testd))


# dump row number and Record ID
traind$PID <- NULL
traind$RECORD_ID <- NULL
traind$LAB1 <- NULL
traind$R_V <- NULL
traind$SET <- NULL

vald$PID <- NULL
vald$RECORD_ID <- NULL
vald$LAB1 <- NULL
vald$R_V <- NULL
vald$SET <- NULL

testd$PID <- NULL
testd$RECORD_ID <- NULL
testd$LAB1 <- NULL
testd$R_V <- NULL
testd$SET <- NULL

# split data into two

dim1 = nrow(traind)
train_1 <- traind[1:floor(dim1/2),]
train_2 <- traind[(floor(dim1/2)+1):dim1,]

forest_tst1 <- randomForest(ADMN_NICU~ .,
                            data=train_1,
                            ntree = tree_num,
                            do.trace=TRUE,
                            proximity=FALSE,
                            nodesize=100,
                            importance=TRUE)

forest_tst2 <- randomForest(ADMN_NICU~ .,
                            data=train_2,
                            ntree = tree_num,
                            do.trace=TRUE,
                            proximity=FALSE,
                            nodesize=100,
                            importance=TRUE)


# library source and then combine.
library(randomForest)

forest_tst <- forest_combine(forest_tst1, forest_tst2)

res <-predict(forest_tst, 
              testd,
              type="response")

sum(res!=testd$ADMN_NICU)/length(res)


testd$pred_results <- res
#test_d$num_pred <- as.numeric(levels(res))[res]
write.csv(testd, file="/project/Lorch_project2018/bean/sc_test_predict.csv")


imp_vals <- importance(forest_tst)
write.csv(imp_vals, file="/project/Lorch_project2018/bean/var_imp_sc.csv")

