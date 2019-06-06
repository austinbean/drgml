library(randomForest)
library(dplyr)

# scp  "/Users/austinbean/Desktop/drgml/sc_classifier.R" beanaus@hsrdcsub2.pmacs.upenn.edu:/project/Lorch_project2018/bean/


# constant parameter
tree_num = 300

# forest combining function
source("/project/Lorch_project2018/bean/forest_combiner.R")

train_d = read.csv("/project/Lorch_project2018/bean/sc_nicu_train.csv")
test_d = read.csv("/project/Lorch_project2018/bean/sc_nicu_test.csv")

# what should I do... can't sort and separate out.
# Just take half of each for each thing.


# maybe this column is just missing and it should be admn_nicu
  # select the admitted patients.
      train_d_ad <- train_d[train_d$admn_nicu == 1, ]
    # number of rows
      rows_t1 = dim(train_d_ad)[1]
      midpoint_t1 = floor(rows_t1/2)
    # create two halves of admitted patients
      train_d_ad_1 = train_d_ad[1:midpoint_t1,]
      train_d_ad_2 = train_d_ad[(midpoint_t1+1):rows_t1,]


    # select half the unadmitted patients
      train_d_na <- train_d[train_d$admn_nicu == 0, ]
    # number of rows
      rows_t2 = dim(train_d_na)[1]
      midpoint_t2 = floor(rows_t2/2)
    # two halves of not admitted patients
      train_d_na_1 = train_d_na[1:midpoint_t2,]
      train_d_na_2 = train_d_na[(midpoint_t2+1):rows_t2,]
      
# combine them earlier...
      train_1 <- rbind(train_d_ad_1, train_d_na_1)
      train_2 <- rbind(train_d_ad_2, train_d_na_2)

# add column.  Stupid
      train_1$lab1 <-rep(1, nrow(train_1)) 
      train_2$lab1 <-rep(2, nrow(train_2)) 
      test_d$lab1 <-rep(3, nrow(test_d)) 

# r bind the list of all four of them:
      new_df <- bind_rows(train_1, train_2, test_d)

# reselect out:
      train_1 <- new_df[new_df$lab1 == 1, ]
      train_2 <- new_df[new_df$lab1 == 2, ]
      test_d <- new_df[new_df$lab1 == 3, ]
      
# rename
colnames(train_1) <- toupper(colnames(train_1))
colnames(train_2) <- toupper(colnames(train_2))
colnames(test_d) <- toupper(colnames(test_d))

# convert numeric variables to factors
train_1 <- mutate_if(train_1, is.numeric, as.factor)
train_2 <- mutate_if(train_2, is.numeric, as.factor)
test_d <- mutate_if(test_d, is.numeric, as.factor)

# dump row number and Record ID
train_1$PID <- NULL
train_1$RECORD_ID <- NULL
train_1$LAB1 <- NULL

train_2$PID <- NULL
train_2$RECORD_ID <- NULL
train_2$LAB1 <- NULL

test_d$PID <- NULL
test_d$RECORD_ID <- NULL
test_d$LAB1 <- NULL

forest_tst1 <- randomForest(ADMN_NICU~ .,
                            data=train_1,
                            ntree = tree_num,
                            do.trace=TRUE,
                            importance=TRUE)
forest_tst2 <- randomForest(ADMN_NICU~ .,
                            data=train_2,
                            ntree = tree_num,
                            do.trace=TRUE,
                            importance=TRUE)


# library source and then combine.
library(randomForest)

forest_tst <- forest_combine(forest_tst1, forest_tst2)

res <-predict(forest_tst, 
              test_d,
              type="response")

sum(res!=test_d$ADMN_NICU)/length(res)


imp_vals <- importance(forest_tst)
write.csv(imp_vals, file="/project/Lorch_project2018/bean/var_imp_sc.csv")

