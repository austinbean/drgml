# TX run forest... 
  # splits the data, runs two forests sequentially, then combines them
# scp  "/Users/austinbean/Desktop/drgml/split_run_forest.R" beanaus@hsrdcsub2.pmacs.upenn.edu:/project/Lorch_project2018/bean/



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
