library(tidyverse)
library(ruimtehol)
library(udpipe)
library(tokenizers)
library(fastTextR)

src <- bind_rows(list(train = read_csv('./data/train_tweets.csv'),
                      test = read_csv('./data/test_tweets.csv')), 
                 .id = "traintest") %>%
  mutate(doc_id = as.character(id))

# tokenize using the tokenize_tweets + get lemma's with udpipe
x <- tokenize_tweets(x = setNames(src$text, src$doc_id), 
                     lowercase = TRUE, stopwords = NULL, strip_punct = TRUE,
                     strip_url = FALSE)
x <- udpipe("english-ewt", 
            x = sapply(x, FUN=function(x) paste(x, collapse = "\n")), 
            tokenizer = "vertical", tagger = "default", parser = "none", trace = 100)

# Paste everything back together and add if it was train or test dataset and the target
words <- x %>% 
  group_by(doc_id) %>%
  summarize(text = paste(str_to_lower(lemma), collapse = ' ')) %>%
  inner_join(src, by = "doc_id", suffix = c("", ".original"))

##
## Build Fasttext word embedding model
##
train <- subset(words, traintest == "train")
train <- sample(sprintf("__label__%s %s", train$name, train$text))
writeLines(train, con = "keepup.train")

test <- subset(words, traintest == "test")

cntrl <- ft.control(word_vec_size = 75L, learning_rate = 0.05, 
                    min_count = 2L, loss = "softmax",
                    max_len_ngram = 2L, epoch = 50L, verbose = TRUE)
model <- fasttext(input = "keepup.train", method = "supervised", control = cntrl)

embeddings <- get_word_vectors(model, get_words(model))
embedding_similarity(embeddings[c("#rstat", "python"), ], embeddings, top_n = 10)
test$score <- predict(model, newdata = test$text)
test$score <- gsub("__label__", "", test$score)

conf_mtx <- table(test$score, test$name) 

print(paste0('Correctly predicted ',
             sum(diag(conf_mtx)), ' of ',
             sum(conf_mtx), ' tweets, which means ', 
             round(100 * sum(diag(conf_mtx))/sum(conf_mtx), 2), 
             '% of the total.'))
