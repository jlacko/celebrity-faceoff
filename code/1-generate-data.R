# downloads 4 timelines, saves tweets to /data

library(tidyverse)
library(rtweet)

# token is gitignored; and not really necessary (/data is populated)
# more info on homepage of rtweet package: https://rtweet.info/#create-an-app
twitter_token <- readRDS("token.rds")

celebs <- c("hadleywickham", "wesmckinn", "fchollet",  "KimKardashian", "khloekardashian", "kourtneykardash")

scrape <- function(handle) {
  
tweets <- get_timelines(handle, 
                        n = 20000, # or what not...
                        language = 'en',
                        token = twitter_token) %>% 
  mutate(text = str_replace_all(text, "https://t.co/[A-Za-z\\d]+|&amp;", "")) %>% # links add no value
#  mutate(text = str_replace_all(text, "@", "")) %>% # get rid of handles
  filter(!is_retweet) %>% # retweets are not original
  filter(nchar(text) > 20) %>% # enforce minimum length - we need _some_ features to hang on to... 
  select(id = status_id, 
         name = screen_name, 
         created = created_at,
         text, 
         source,
         lajku = favorite_count,
         retweetu = retweet_count)

src <- tweets %>%
  group_by(name) %>%
  arrange(desc(created)) %>%
  filter(row_number() <= 1500) %>%
  select(id, name, created, text)

}

data <- scrape(celebs[1:6])

print(table(data$name))

write_csv(data, './data/raw_tweets.csv')
