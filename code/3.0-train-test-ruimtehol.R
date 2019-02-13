library(tidyverse)
library(ruimtehol)
library(udpipe)
library(tokenizers)

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
## No changing of hyperparameters 'Vanilla Starspace'
##
src <- subset(words, traintest == "train")

set.seed(42) # trust no other!
model <- embed_tagspace(x = src$text, y = src$name, ngrams = 2, minCount = 2)
plot(model)
src <- subset(words, traintest == "test")

embedding_labels <- as.matrix(model, type = "labels", prefix = FALSE)
embedding_tweets <- predict(model, type = "embedding",
                            newdata = data.frame(doc_id = src$doc_id, text = src$text, stringsAsFactors = FALSE))
prediction <- embedding_similarity(embedding_tweets, embedding_labels, type = "cosine", top_n = 1)
prediction <- mutate(prediction, doc_id = term1)
prediction <- inner_join(prediction, src, by = "doc_id")

conf_mtx <- table(prediction$term2, prediction$name) 

print(paste0('Correctly predicted ',
             sum(diag(conf_mtx)), ' of ',
             sum(conf_mtx), ' tweets, which means ', 
             round(100 * sum(diag(conf_mtx))/sum(conf_mtx), 2), 
             '% of the total.'))

##
## Tune the model a bit to get a nice evolution of the loss
##
src <- subset(words, traintest == "train")

set.seed(42) # trust no other!
model <- embed_tagspace(x = src$text, y = src$name,
                        dim = 75, lr = 0.01, epoch = 20, 
                        loss = "hinge", margin = 0.5, adagrad = FALSE, 
                        similarity = "dot", negSearchLimit = 10, maxNegSamples = 2,
                        ngrams = 2, minCount = 2)
plot(model)

## inspect the model a bit
starspace_knn(model, "__label__hadleywickham", 20)

embedding_words <- as.matrix(model, type = "words")
embedding_words <- embedding_words[!grepl("^@", rownames(embedding_words)), ]
embedding_similarity(starspace_embedding(model, "__label__hadleywickham"),
                     embedding_words, top_n = 20)

## evaluate the model
src <- subset(words, traintest == "test")

embedding_labels <- as.matrix(model, type = "labels", prefix = FALSE)
embedding_tweets <- predict(model, type = "embedding",
                            newdata = data.frame(doc_id = src$doc_id, text = src$text, stringsAsFactors = FALSE))
prediction <- embedding_similarity(embedding_tweets, embedding_labels, type = "cosine", top_n = 1)
prediction <- mutate(prediction, doc_id = term1)
prediction <- inner_join(prediction, src, by = "doc_id")

conf_mtx <- table(prediction$term2, prediction$name) 

print(paste0('Correctly predicted ',
             sum(diag(conf_mtx)), ' of ',
             sum(conf_mtx), ' tweets, which means ', 
             round(100 * sum(diag(conf_mtx))/sum(conf_mtx), 2), 
             '% of the total.'))
