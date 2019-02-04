# split test & verification datasets (+ dev)

library(tidyverse)
library(caret)

set.seed(42) # trust no other!

raw_tweets <- read_csv('./data/raw_tweets.csv')

idx <- createDataPartition(raw_tweets$name, p = .8, list = F, times = 1) # 80 / 20 split

train_data <- raw_tweets[idx, ] # train dataset
test_data <- raw_tweets[-idx, ] # verification dataset

dev_pctg <- 50 * length(unique(train_data$name)) / nrow(train_data)

idx_dev <- createDataPartition(train_data$name, p = dev_pctg, list = F, times = 1) 

dev_data <- train_data[idx_dev, ] # dev dataset selected from train data

write_csv(train_data, './data/train_tweets.csv')
write_csv(test_data, './data/test_tweets.csv')
write_csv(dev_data, './data/dev_tweets.csv')