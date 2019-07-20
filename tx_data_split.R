# just split the texas data into two...
# scp  "/Users/austinbean/Desktop/drgml/tx_data_split.R" beanaus@hsrdcsub2.pmacs.upenn.edu:/project/Lorch_project2018/bean/

alld = read.csv("/project/Lorch_project2018/bean/nicu_coll_csv.csv")

# add column of random values:
alld$r_v <- runif(nrow(alld))
alld$set <- rep(0, nrow(alld))


# select out 50/50 split:
for (i in 1:nrow(alld)){
  if (alld[i, "r_v"] <= 0.5) {
    alld[i,"r_v"] = 1
  }
  else{
    alld[i, "r_v"] = 2
  }
  if (i%%10000 == 0) {
    print(i)
  }
}

# subset out

d1 <- alld[alld$r_v == 1,]
d2 <- alld[alld$r_v == 2,]

# drop column
d1$r_v <- NULL
d2$r_v <- NULL

# save  

write.csv(d1, file="/project/Lorch_project2018/bean/tx_d1.csv")
write.csv(d2, file="/project/Lorch_project2018/bean/tx_d2.csv")

