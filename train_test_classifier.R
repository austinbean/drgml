library(randomForest)
library(dplyr)
# sink("/project/Lorch_project2018/bean/r_nicu_log.txt")
# this rbinding thing is fucking stupid.
# scp  "/Users/austinbean/Desktop/drgml/train_test_classifier.R" beanaus@hsrdcsub2.pmacs.upenn.edu:/project/Lorch_project2018/bean/

# useful discussion from the creators: https://www.stat.berkeley.edu/~breiman/RandomForests/cc_home.htm

# constant parameter
    tree_num = 3
    home = FALSE

# source the forest-combining function
# https://stackoverflow.com/questions/19170130/combining-random-forests-built-with-different-training-sets-in-r

# HOME
    if (home){
      source("/Users/austinbean/Desktop/drgml/forest_combiner.R")
    }else{
    #REMOTE
    source("/project/Lorch_project2018/bean/forest_combiner.R")
    }


# another attempt:
    if (home) {
    # HOME
    train_d = read.csv("/Users/austinbean/Desktop/drgml/quick_test.csv")
    test_d = read.csv("/Users/austinbean/Desktop/drgml/quick_val.csv")
    } else{
    # REMOTE
    train_d = read.csv("/project/Lorch_project2018/bean/nicu_train_csv.csv")
    test_d = read.csv("/project/Lorch_project2018/bean/nicu_test_csv.csv")
    }

# rename
    colnames(train_d) <- toupper(colnames(train_d))
    colnames(test_d) <- toupper(colnames(test_d))

# subset
    nrows = dim(train_d)[1]
    midp = floor(nrows/2)
    
# subset training sets
    train_1 <- train_d[1:midp, ]
    train_2 <- train_d[(midp+1):nrows, ]

# rbind - stupid.
    train_1$lab1 <-rep(1, nrow(train_1)) 
    train_2$lab1 <-rep(2, nrow(train_2)) 
    test_d$lab1 <-rep(3, nrow(test_d)) 
    
    # row_bind matches on column names
    new_df <- bind_rows(train_1, train_2, test_d)
    
    # convert numeric variables to factors
    new_df <- mutate_if(new_df, is.numeric, as.factor)

    train_1 <- new_df[new_df$lab1 == 1,]
    train_2 <- new_df[new_df$lab1 == 2,]
    test_d <- new_df[new_df$lab1 == 3,]



# dump row number and Record ID
    train_1$PID <- NULL
    train_1$RECORD_ID <- NULL
    train_1$lab1 <- NULL
    
    train_2$PID <- NULL
    train_2$RECORD_ID <- NULL
    train_2$lab1 <- NULL
    
    test_d$PID <- NULL
    test_d$RECORD_ID <- NULL
    test_d$lab1 <- NULL

# estimate random forest.
# actually estimate two of them since the data is too long.
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

# combine the two estimated forests.
    
  library(randomForest)
  forest_tst <- forest_combine(forest_tst1, forest_tst2)
  if (home){
    save(forest_tst, file = "/Users/austinbean/Desktop/drgml/nicu_classifier.RData")
  } else{
    save(forest_tst, file = "/project/Lorch_project2018/bean/nicu_classifier.RData")
  }
  

# apply to test data:
# factor variables have different levels..
# https://stackoverflow.com/questions/17059432/random-forest-package-in-r-shows-error-during-prediction-if-there-are-new-fact
    res <-predict(forest_tst1, 
                  test_d,
                  type="response")
#This does work, which is weird...
    sum(res!=test_d$ADMN_NICU)/length(res)
    
out_res <- (res!=test_d$ADMN_NICU)   
typeof(out_res)    

test_d$predictions <- res    

# Importance Measures
# scp beanaus@hsrdcsub2.pmacs.upenn.edu:/project/Lorch_project2018/bean/var_imp.csv "/Users/austinbean/Desktop/drgml/"
  

imp_vals <- importance(forest_tst)
if (home){
  write.csv(imp_vals, file="/Users/austinbean/Desktop/drgml/var_imp.csv")
} else {
write.csv(imp_vals, file="/project/Lorch_project2018/bean/var_imp.csv")
}

# # Cross-validate:
#   # expect not to work as written since vector of data is too long
#   # not sure where the NAs are coming from but this may exclude them? 
# train_2n <- na.omit(train_new[1:midpoint_train,])
# test_2n <- na.omit(test_new[1:midpoint_train,])
# 
# # really not sure why this does not work...?  
# # maybe this:
# # https://stackoverflow.com/questions/13495041/random-forests-in-r-empty-classes-in-y-and-argument-legth-0
# rfcv(train_2n, test_2n, cv.fold=5, scale="log", step=.5, recursive=FALSE, na.action=na.omit)
# 
# 
# 
# # Plot variable importance...
# 
# mda_vars = order(forest_tst$importance[1:30,3])
# mdg_vars = order(forest_tst$importance[1:30,4])
# 
# varImpPlot(forest_tst, sort=TRUE, n.var=(forest_tst$importance))
# 
# 






#sink()

