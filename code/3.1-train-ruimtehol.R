# generate StarSpace model using train (or dev :) data

library(tidyverse)
library(ruimtehol)

set.seed(42) # trust no other!

src <- read_csv('./data/train_tweets.csv') %>% # or what not...
  mutate(text = str_to_lower(text))

model <- embed_tagspace(x = src$text, y = src$name,
                        dim = 75, 
                        lr = 0.01, 
                        epoch = 20, 
                        loss = "hinge", 
                        margin = 0.5, 
                        adagrad = FALSE, 
                        similarity = "dot", 
                        negSearchLimit = 10, 
                        maxNegSamples = 2,
                        ngrams = 2, 
                        minCount = 2
                        )
plot(model)

starspace_save_model(model, file = './models/starspace.rds', method = 'ruimtehol')