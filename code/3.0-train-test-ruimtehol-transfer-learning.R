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
            tokenizer = "vertical", tagger = "default", parser = "none", trace = 1000)

# Paste everything back together and add if it was train or test dataset and the target
words <- x %>% 
  group_by(doc_id) %>%
  summarize(text = paste(str_to_lower(lemma), collapse = ' ')) %>%
  inner_join(src, by = "doc_id", suffix = c("", ".original"))

##
## Collect Pretrained word embeddings based on R package fasttextM (https://github.com/statsmaths/fasttextM) - fastText_multilingual
##   - Note: need to have embeddings of labels and the words, missing data is not allowed
##   - Note: it is important that the label embeddings should be at the end
##
library(fasttextM)
#ft_download_model("en", mb = 500)
ft_load_model("en")
terms <- na.exclude(unique(str_to_lower(x$lemma)))
pretrained_word_embeddings <- ft_embed(words = terms, lang = "en")

set.seed(42) # trust no other!
emb_mean <- mean(pretrained_word_embeddings, na.rm=TRUE)
emb_sd   <- sd(pretrained_word_embeddings, na.rm=TRUE)
pretrained_label_embeddings <- do.call(rbind, lapply(sprintf("__label__%s", unique(src$name)), FUN=function(x){
  matrix(rnorm(ncol(pretrained_word_embeddings), emb_mean, sd = emb_sd), nrow = 1, ncol = ncol(pretrained_word_embeddings), dimnames = list(x))
}))
pretrained_word_embeddings <- apply(pretrained_word_embeddings, FUN=function(x){
  if(anyNA(x)){
    x <- rnorm(ncol(pretrained_word_embeddings), emb_mean, sd = emb_sd)
  }
  x
}, MARGIN=1)
pretrained_word_embeddings <- t(pretrained_word_embeddings)
rownames(pretrained_word_embeddings) <- terms
pretrained_embeddings <- rbind(pretrained_word_embeddings, pretrained_label_embeddings)

##
## Build Starspace model
##
src <- subset(words, traintest == "train")

set.seed(42) # trust no other!
model <- embed_tagspace(x = src$text, y = src$name, 
                        embeddings = pretrained_embeddings, 
                        lr = 0.01, epoch = 20, 
                        loss = "hinge", margin = 2, adagrad = TRUE, 
                        similarity = "dot", negSearchLimit = 10, maxNegSamples = 2,
                        ngrams = 2, minCount = 2)
plot(model)

## evaluation
src <- subset(words, traintest == "test")

embedding_labels <- as.matrix(model, type = "labels", prefix = FALSE)
embedding_tweets <- predict(model, type = "embedding",
                            newdata = data.frame(doc_id = src$doc_id, text = src$text, stringsAsFactors = FALSE))
prediction <- embedding_similarity(embedding_tweets, embedding_labels, type = "dot", top_n = 1)
prediction <- mutate(prediction, doc_id = term1)
prediction <- inner_join(prediction, src, by = "doc_id")

conf_mtx <- table(prediction$term2, prediction$name) 

print(paste0('Correctly predicted ',
             sum(diag(conf_mtx)), ' of ',
             sum(conf_mtx), ' tweets, which means ', 
             round(100 * sum(diag(conf_mtx))/sum(conf_mtx), 2), 
             '% of the total.'))


##
## Stacking the embeddings of the Fasttest tuned embeddings and just plain embeddings with Starspace
##
allembeddings <- list()
allembeddings$fasttext <- as.matrix(model)

src <- subset(words, traintest == "train")
set.seed(42) # trust no other!
model <- embed_tagspace(x = src$text, y = src$name,
                        dim = 75, lr = 0.01, epoch = 20, 
                        loss = "hinge", margin = 0.5, adagrad = FALSE, 
                        similarity = "dot", negSearchLimit = 10, maxNegSamples = 2,
                        ngrams = 2, minCount = 2)
plot(model)
allembeddings$starspace <- as.matrix(model)

combinedembeddings <- intersect(rownames(allembeddings$fasttext), rownames(allembeddings$starspace))
combinedembeddings <- cbind(allembeddings$fasttext[combinedembeddings, ], allembeddings$starspace[combinedembeddings, ])

set.seed(42) # trust no other!
model <- embed_tagspace(x = src$text, y = src$name, 
                        embeddings = combinedembeddings, 
                        lr = 0.01, epoch = 50, 
                        loss = "hinge", margin = 1, adagrad = TRUE, 
                        similarity = "dot", negSearchLimit = 10, maxNegSamples = 2,
                        ngrams = 2, minCount = 2)
plot(model)

## evaluation
src <- subset(words, traintest == "test")

embedding_labels <- as.matrix(model, type = "labels", prefix = FALSE)
embedding_tweets <- predict(model, type = "embedding",
                            newdata = data.frame(doc_id = src$doc_id, text = src$text, stringsAsFactors = FALSE))
prediction <- embedding_similarity(embedding_tweets, embedding_labels, type = "dot", top_n = 1)
prediction <- mutate(prediction, doc_id = term1)
prediction <- inner_join(prediction, src, by = "doc_id")

conf_mtx <- table(prediction$term2, prediction$name) 

print(paste0('Correctly predicted ',
             sum(diag(conf_mtx)), ' of ',
             sum(conf_mtx), ' tweets, which means ', 
             round(100 * sum(diag(conf_mtx))/sum(conf_mtx), 2), 
             '% of the total.'))
