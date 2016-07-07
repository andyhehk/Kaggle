library(data.table)
library(Matrix)
library(Metrics)
library(xgboost)


set.seed(1729) 

train <- fread("../dat/train.csv")
test <- fread("../dat/test.csv")



null_col <- c("Employment_Info_1", "Employment_Info_4", "Employment_Info_6",
 "Insurance_History_5", "Family_Hist_2", "Family_Hist_3", "Family_Hist_4",
 "Family_Hist_5", "Medical_History_1", "Medical_History_10", "Medical_History_15",
 "Medical_History_24", "Medical_History_32")

impute.mean = function(x) {
    replace(x, is.na(x), median(x, na.rm = TRUE))
}

for( col in null_col) {
  set(train, j=col, value=impute.mean(train[[col]]))
  set(test, j=col, value=impute.mean(test[[col]]))
}

train[, Id := NULL]

#train[, c("Id",  "Employment_Info_4", "Employment_Info_6",
# "Insurance_History_5", "Family_Hist_2", "Family_Hist_3", "Family_Hist_4",
# "Family_Hist_5", "Medical_History_1", "Medical_History_10", "Medical_History_15",
# "Medical_History_24", "Medical_History_32") := NULL]

cat_col = c(
"Product_Info_1", "Product_Info_2", "Product_Info_3", "Product_Info_5", "Product_Info_6", 
"Product_Info_7", "Employment_Info_2", "Employment_Info_3", "Employment_Info_5", "InsuredInfo_1", 
"InsuredInfo_2", "InsuredInfo_3", "InsuredInfo_4", "InsuredInfo_5", "InsuredInfo_6", "InsuredInfo_7", 
"Insurance_History_1", "Insurance_History_2", "Insurance_History_3", "Insurance_History_4", 
"Insurance_History_7", "Insurance_History_8", "Insurance_History_9", "Family_Hist_1", 
"Medical_History_2", "Medical_History_3", "Medical_History_4", "Medical_History_5", 
"Medical_History_6", "Medical_History_7", "Medical_History_8", "Medical_History_9", 
"Medical_History_11", "Medical_History_12", "Medical_History_13", "Medical_History_14", 
"Medical_History_16", "Medical_History_17", "Medical_History_18", "Medical_History_19", 
"Medical_History_20", "Medical_History_21", "Medical_History_22", "Medical_History_23", 
"Medical_History_25", "Medical_History_26", "Medical_History_27", "Medical_History_28", 
"Medical_History_29", "Medical_History_30", "Medical_History_31", "Medical_History_33", 
"Medical_History_34", "Medical_History_35", "Medical_History_36", "Medical_History_37", 
"Medical_History_38", "Medical_History_39", "Medical_History_40", "Medical_History_41"
  )

# change categorical columns to be factor type
for( col in cat_col) {
  set(train, j=col, value=as.factor(train[[col]]))
  setnames(train, col, paste(col, "a", sep=""))
  set(test, j=col, value=as.factor(test[[col]]))
  setnames(test, col, paste(col, "a", sep=""))
}
#train[, Medical_History_2a:=NULL]


# Seperate it into training set and validation set
h <- sample(nrow(train),15000)
tra <- train[-h, ]
val <- train[h,]

tra_label <- tra[, Response] - 1
val_label <- val[, Response] - 1

nrow(tra)
length(tra_label)

nrow(val)
length(val_label)

## Change the categorical variable using one-hot encoding
sparse_train <- sparse.model.matrix(Response~.-1, data = tra)
sparse_val <- sparse.model.matrix(Response~.-1, data = val)
sparse_test <- sparse.model.matrix(Id~.-1, data = test)

nrow(sparse_train)
nrow(sparse_val)

KAPPA <- function(preds, dtrain) {
    labels <- getinfo(dtrain, "label")
    return(list(metric = "KAPPA", value = ScoreQuadraticWeightedKappa(labels, preds, 0, 7)))
}

dtrain <- xgb.DMatrix(data = sparse_train, label = tra$Response-1)
dval <- xgb.DMatrix(data = sparse_val, label = val$Response-1)

watchlist <- list(val = dval, train = dtrain)

param <- list(  objective = "multi:softmax",     
                booster = "gbtree",
                eta = 0.01,
                max_depth = 12,
                num_class=8,
                gamma = 1
  )

clf <- xgb.train(   params = param,
                    data = dtrain,
                    nrounds = 30, # 100, 200, 300
                    verbose = 1,
                    watchlist = watchlist
                    #eval_metric = KAPPA
  )

dtest <- xgb.DMatrix(data=sparse_test)

pred1 <- predict(clf, dtest)
submission <- data.frame(Id=test$Id, Risk=pred1+1)
cat("saving the submission file\n")
write.csv(submission, file = "rf1.csv")

#importance <- xgb.importance(feature_names = sparse_train@Dimnames[[2]], model = clf)