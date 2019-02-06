# reads results from /data/results.csv and saves a nice chart in /img

library(tidyverse)
library(gridExtra)
library(grid)

res <- read_csv('./data/results.csv') 

mpggp <- ggplot(res, aes(x = model, y = correct, label = paste0(correct, ' tweeets out of 1800 right - ', round(correct / total *100, 2), '%'))) +
  geom_col(fill = "darkgoldenrod2", width = 0.7) +
  geom_text(size = 4, position = position_stack(vjust = 0.5), col = "gray45") +
  coord_flip() +
  theme_light() +
  geom_hline(yintercept = 1800, col = "red") +
  theme(axis.text = element_text(size = 12),
        axis.title.y = element_blank(), 
        axis.title.x = element_blank()) +
  scale_y_continuous(breaks = c(0, 500, 1000, 1500, 1800), labels = c(0, 500, 1000, 1500, 1800))

png(filename = "./img/results.png", width = 800, height = 400, res = 100)
grid.arrange(textGrob("Classification Accuracy: Keras vs. StarSpace", 
                      gp = gpar(fontsize = 1.6 * 11, fontface = "bold")), 
             mpggp, 
             heights = c(0.1, 1))
dev.off()