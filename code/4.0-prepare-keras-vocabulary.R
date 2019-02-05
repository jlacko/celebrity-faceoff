# prepare vocabulary for keras modeling

library(tidyverse)
library(udpipe)

# download current udpipe model for English
last_udpipe <- 'english-ewt-ud-2.3-181115.udpipe' # (so far) last version
if (!file.exists(last_udpipe)) udpipe_download_model(language = "english") # once is enoug...
udmodel <- udpipe_load_model(file = last_udpipe) # load the model

src <- readr::read_csv('./data/train_tweets.csv')

vocabulary <- udpipe_annotate(udmodel, x = src$text, doc_id = src$id) %>%
  as.data.frame() %>%
  count(lemma) %>%
  ungroup() %>%
  arrange(desc(n)) %>%
  filter(n>=3) %>% # menší frekvence není vypovídající...
  mutate(id_slovo = row_number()) %>%
  select(lemma, id_slovo)

write_csv(vocabulary, './data/vocabulary.csv') # pro budoucí použití...
