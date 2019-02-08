library(tidyverse)
library(ruimtehol)
library(udpipe)
library(tokenizers)
library(glmnet)
library(quanteda)

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

##
## Penalised multinomial regression
##
dtm <- document_term_frequencies(x[, c("doc_id", "lemma")])
dtm <- document_term_matrix(dtm)
testdata  <- dtm[rownames(dtm) %in% src$doc_id[src$traintest == "test"], ]
traindata <- dtm[rownames(dtm) %in% src$doc_id[src$traintest == "train"], ]
traindata <- dtm_remove_lowfreq(traindata, minfreq = 3)
m <- cv.glmnet(x = traindata, y = src$name[match(rownames(traindata), src$doc_id)], 
               family = "multinomial", type.multinomial = "ungrouped", alpha = 1, folds = 10)
plot(m)
prediction <- data.frame(doc_id = rownames(testdata), 
                         name_lambda_1se = predict(m, testdata[, colnames(traindata)], s = m$lambda.1se, type = "class")[, 1],
                         name_lambda_min = predict(m, testdata[, colnames(traindata)], s = m$lambda.min, type = "class")[, 1],
                         stringsAsFactors = FALSE)
prediction <- merge(prediction, src, by = "doc_id", all.x = TRUE, all.y = FALSE)

conf_mtx <- table(prediction$name_lambda_1se, prediction$name) 
print(paste0('Correctly predicted ',
             sum(diag(conf_mtx)), ' of ',
             sum(conf_mtx), ' tweets, which means ', 
             round(100 * sum(diag(conf_mtx))/sum(conf_mtx), 2), 
             '% of the total.'))

##
## Naive Bayes model
##
m <- textmodel_nb(x = as.dfm(traindata), y = src$name[match(rownames(traindata), src$doc_id)], 
             smooth = 1, prior = "uniform", 
             distribution = "multinomial")
prediction <- data.frame(doc_id = rownames(testdata), 
                         name_nb = predict(m, newdata = as.dfm(testdata[, colnames(traindata)]), type = "class"),
                         stringsAsFactors = FALSE)
prediction <- merge(prediction, src, by = "doc_id", all.x = TRUE, all.y = FALSE)

conf_mtx <- table(prediction$name_nb, prediction$name) 
print(paste0('Correctly predicted ',
             sum(diag(conf_mtx)), ' of ',
             sum(conf_mtx), ' tweets, which means ', 
             round(100 * sum(diag(conf_mtx))/sum(conf_mtx), 2), 
             '% of the total.'))
