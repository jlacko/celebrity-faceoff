# loads the hdf5 format keras model & applies it to the test data

library(tidyverse)
library(udpipe)
library(keras)

# download current udpipe model for English
last_udpipe <- 'english-ewt-ud-2.3-181115.udpipe' # (so far) latest version
if (!file.exists(last_udpipe)) udpipe_download_model(language = "english") # once is enough...
udmodel <- udpipe_load_model(file = last_udpipe) # load the model

tweets <- read_csv('./data/test_tweets.csv') %>% # tweets
  arrange(id)

vocabulary <- read_csv('./data/vocabulary.csv') # prepared in 4.0

words <- udpipe_annotate(udmodel, x = tweets$text, doc_id = tweets$id, trace = 250) %>% 
  as.data.frame() %>%
  mutate(lemma = ifelse(is.na(lemma), token, lemma)) %>%
  select(id = doc_id, token, lemma, upos, sentence_id) %>%
  mutate(id = as.numeric(id))

# 150 zeroes for each tweet id for padding
vata <- expand.grid(id = unique(tweets$id),
                    word_num = 1:150,
                    id_slovo = 0)

word_matrix <- words %>% # words
  # filtering join! words not in vocabulary are discarded
  inner_join(vocabulary, by = c('lemma' = 'lemma')) %>% 
  select(id, lemma, id_slovo) %>%
  group_by(id) %>%
  mutate(word_num = row_number()) %>% # 
  ungroup() %>%
  select(id, word_num, id_slovo) %>% # relevant columns
  rbind(vata) %>% # bind the 150 zeroes per tweet
  group_by(id, word_num) %>%
  mutate(id_slovo = max(id_slovo)) %>% # will include duplicites
  ungroup() %>%
  unique() %>% # remove duplicites
  spread(word_num, id_slovo) # spread to matrix format

keras_input <- tweets %>%
  select(id) %>%
  inner_join(word_matrix, by = c('id' = 'id')) %>%
  arrange(id) %>%
  select(-id) %>%
  as.matrix() 

# read the model
model <- load_model_hdf5("./models/2x-ltsm.h5")

# apply the model
pred <- model %>% 
  predict_proba(keras_input)

# interpret results
res <- tweets %>%
  select(id) %>%
  cbind(pred %>% as.data.frame()) %>%
  gather(column, value, -id) %>%
  group_by(id) %>%
  mutate(rnk = rank(value)) %>%
  arrange(id) %>%
  filter(rnk == 6) %>%
  mutate(name = case_when(column == 'V1' ~ 'hadleywickham',
                          column == 'V2' ~ 'wesmckinn',
                          column == 'V3' ~ 'fchollet',
                          column == 'V4' ~ 'KimKardashian',
                          column == 'V5' ~ 'kourtneykardash',
                          column == 'V6' ~ 'khloekardashian',
                          T ~ 'unknown'))

conf_mtx <- table(tweets$name, res$name)

print(paste0('Correctly predicted ',
             sum(diag(conf_mtx)), ' of ',
             sum(conf_mtx), ' tweets, which means ', 
             round(100 * sum(diag(conf_mtx))/sum(conf_mtx), 2), 
             '% of the total.'))
