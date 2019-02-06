# creates bidirectional LSTM network, trains it and saves it in hdf5 format in /models dir

library(tidyverse)
library(udpipe)
library(keras)

# download current udpipe model for English
last_udpipe <- 'english-ewt-ud-2.3-181115.udpipe' # (so far) latest version
if (!file.exists(last_udpipe)) udpipe_download_model(language = "english") # once is enough...
udmodel <- udpipe_load_model(file = last_udpipe) # load the model

tweets <- read_csv('./data/train_tweets.csv') %>% # tweets
  arrange(id)

vocabulary <- read_csv('./data/vocabulary.csv') # prepared in 4.0

words <- udpipe_annotate(udmodel, x = tweets$text, doc_id = tweets$id) %>% 
  as.data.frame() %>%
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


keras_output <- tweets %>%
  mutate(hadley = ifelse(name == 'hadleywickham', 1, 0),
         wes = ifelse(name == 'wesmckinn', 1, 0),
         francois = ifelse(name == 'fchollet', 1, 0),
         kim = ifelse(name == 'KimKardashian', 1, 0),
         kourtney = ifelse(name == 'kourtneykardash', 1, 0),
         khloe = ifelse(name == 'khloekardashian', 1, 0)) %>%
  select(-id, -name, -created, -text) %>%
  as.matrix()

vocab_size <- vocabulary %>% # count the unique ids
  pull(id_slovo) %>% 
  unique() %>%
  length() + 1 # one extra for zero used as padding

# declare keras model
model <- keras_model_sequential() 

model %>% 
  layer_embedding(input_dim = vocab_size, output_dim = 256) %>%
  bidirectional(layer_lstm(units = 128)) %>%
  layer_dropout(rate = .5) %>% 
  layer_dense(units = 64, activation = 'relu') %>%   
  layer_dense(units = 32, activation = 'relu') %>% 
  layer_dense(units = 6, activation = 'softmax') # one output per author

model %>% compile(
  optimizer = "rmsprop",
  loss = "categorical_crossentropy",
  metrics = c("accuracy")
)


# train the model 
history <- model %>% 
  fit( # this will take a while...
    keras_input, keras_output, 
    epochs = 15, batch_size = nrow(keras_input)/10, 
    validation_split = 1/5
  )

print(paste0("Validation accuracy: ", as.character(formatC(100 * last(history$metrics$val_acc), digits = 2, format = "f")), "%"))

model %>% 
  save_model_hdf5("./models/bi-ltsm.h5")
