# TX classifier on more data...
# scp  "/Users/austinbean/Desktop/drgml/TX_nicu_class.R" beanaus@hsrdcsub2.pmacs.upenn.edu:/project/Lorch_project2018/bean/
# bsub < r_tx_class.sh -m pellaeon

# TODO - could split this into three pieces... split data in half, open and train on half, the other, etc.

# another version. 
  library(randomForest)
  library(dplyr)

# Constants
  tree_num = 1
  set.seed(26)
  # forest combining function
  source("/project/Lorch_project2018/bean/forest_combiner.R")
  

# data - 
  # count of rows is 2,734,166
  alld = read.csv("/project/Lorch_project2018/bean/nicu_coll_csv.csv")
  
# set to factor vars:
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

#do summary(alld) here to figure out what is wrong with the indicators?

# subset out: 
  
  traind <- alld[alld$r_v == 1,]
  vald <- alld[alld$r_v == 2,]
  testd <- alld[alld$r_v == 3,]
  
# remove r_v, set
  traind$pid <- NULL
  traind$r_v <- NULL
  traind$set <- NULL
  traind$RECORD_ID <- NULL
  
  vald$pid <- NULL
  vald$r_v <- NULL
  vald$set <- NULL
  vald$RECORD_ID <- NULL
  
  testd$pid <- NULL
  testd$r_v <- NULL
  testd$set <- NULL
  testd$RECORD_ID <- NULL
  
# rename to upper:
  colnames(traind) <- toupper(colnames(traind))
  colnames(vald) <- toupper(colnames(vald))
  colnames(testd) <- toupper(colnames(testd))
  
  
# subset training since it may be too large:
  dim1 = nrow(traind)
  traind1 <- traind[1:floor(dim1/2),]
  traind2 <- traind[(floor(dim1/2)+1):dim1,]
  
# train two forests:
  forest_tst1 <- randomForest(ADMN_NICU~ .,
                              data=traind1,
                              ntree = tree_num,
                              do.trace=TRUE,
                              na.action=na.omit,
                              proximity=FALSE,
                              nodesize=100,
                              importance=TRUE)
  
  forest_tst2 <- randomForest(ADMN_NICU~ .,
                              data=traind2,
                              ntree = tree_num,
                              do.trace=TRUE,
                              na.action=na.omit,
                              proximity=FALSE,
                              nodesize=100,
                              importance=TRUE)
  
# combine them:
  library(randomForest)
  forest_tst <- forest_combine(forest_tst1, forest_tst2)
  
  
# now predict admission in new data from 1999 - 2003:
  tx99 <- read.csv("/project/Lorch_project2018/bean/1999_featurematrix.csv")
  tx00 <- read.csv("/project/Lorch_project2018/bean/2000_featurematrix.csv")
  tx01 <- read.csv("/project/Lorch_project2018/bean/2001_featurematrix.csv")
  tx02 <- read.csv("/project/Lorch_project2018/bean/2002_featurematrix.csv")
  tx03 <- read.csv("/project/Lorch_project2018/bean/2003_featurematrix.csv")

# predict admission...
  # will need to "rbind" all of these stupid things
  # add column.  Stupid
  traind1$lab1 <- rep(0, nrow(traind1))
  tx99$lab1 <-rep(1, nrow(tx99)) 
  tx00$lab1 <-rep(2, nrow(tx00)) 
  tx01$lab1 <-rep(3, nrow(tx01)) 
  tx02$lab1 <-rep(4, nrow(tx02)) 
  tx03$lab1 <-rep(5, nrow(tx03)) 

  # r bind the list of all four of them:
  new_df <- bind_rows(traind1, tx99, tx00, tx01, tx02, tx03)
  
  # resub out
  traind1 <- new_df[new_df$lab1 == 0,]
  tx99 <- new_df[new_df$lab1 == 1,]
  tx00 <- new_df[new_df$lab1 == 2,]
  tx01 <- new_df[new_df$lab1 == 3,]
  tx02 <- new_df[new_df$lab1 == 4,]
  tx03 <- new_df[new_df$lab1 == 5,]
  
# predic admission in previous years...
    # no way that this will work but figure out why...
  res99 <-predict(forest_tst, 
                tx99,
                type="response")
  cbind(res99, n_labs = res99  )
  #res99$num_pred <- as.numeric(levels(res99))[res99]
  write.csv(tx99, file="/project/Lorch_project2018/bean/tx99.csv")
  
  res00 <-predict(forest_tst, 
                  tx00,
                  type="response")
  cbind(res00, pred_results = res00)
  #res00$num_pred <- as.numeric(levels(res00))[res00]
  write.csv(tx00, file="/project/Lorch_project2018/bean/tx00.csv")
  
  res01 <-predict(forest_tst, 
                  tx01,
                  type="response")
  cbind(res01, pred_results = res01)
  #res01$num_pred <- as.numeric(levels(res01))[res01]
  write.csv(tx01, file="/project/Lorch_project2018/bean/tx01.csv")
  
  
  res02 <-predict(forest_tst, 
                  tx02,
                  type="response")
  cbind(res02, pred_results = res02)
  #res02$num_pred <- as.numeric(levels(res02))[res02]
  write.csv(tx02, file="/project/Lorch_project2018/bean/tx02.csv")
  
  
  res03 <-predict(forest_tst, 
                  tx03,
                  type="response")
  cbind(res03, pred_results = res03)
  #res03$num_pred <- as.numeric(levels(res03))[res03]
  write.csv(tx03, file="/project/Lorch_project2018/bean/tx03.csv")
  
  
# write out subsets only
  new99 <- subset(res99, select=c("pid", "res99"))
  write.csv(new99, file="/project/Lorch_project2018/bean/tx99small.csv")
  
  new00 <- subset(res00, select=c("pid", "res00"))
  write.csv(new00, file="/project/Lorch_project2018/bean/tx00small.csv")
  
  new01 <- subset(res01, select=c("pid", "res01"))
  write.csv(new01, file="/project/Lorch_project2018/bean/tx01small.csv")
  
  new02 <- subset(res02, select=c("pid", "res02"))
  write.csv(new02, file="/project/Lorch_project2018/bean/tx02small.csv")
  
  new03 <- subset(res03, select=c("pid", "res03"))
  write.csv(new03, file="/project/Lorch_project2018/bean/tx03small.csv")
  
  