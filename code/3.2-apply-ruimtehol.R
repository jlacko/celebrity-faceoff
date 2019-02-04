# apply StarSpace model on test data

library(tidyverse)
library(ruimtehol)

set.seed(42) # trust no other!

src <- read_csv('./data/test_tweets.csv') # or what not...

model <- starspace_load_model('./model/starspace.rds', method = 'ruimtehol')

prediction <- predict(model, newdata = src$text, type = 'generic') %>%
  unlist(recursive = T) %>%
  enframe() %>%
  filter(name == 'prediction.label1') %>% # the most likely tag
  pull(value)

conf_mtx <- table(prediction, src$name) 

print(paste0('Correctly predicted ',
             sum(diag(conf_mtx)), ' of ',
             sum(conf_mtx), ' tweets, which means ', 
             round(100 * sum(diag(conf_mtx))/sum(conf_mtx), 2), 
             '% of the total.'))