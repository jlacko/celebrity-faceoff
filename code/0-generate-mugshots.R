# combine images using magick

library(tidyverse)
library(magick)


hadley <- image_read('./img/hadley.jpg')
wes <- image_read('./img/wes.jpg')
francois <- image_read('./img/francois.jpg')
kim <- image_read('./img/kim.jpg')
kourtney <- image_read('./img/kourtney.jpg')
khloe <- image_read('./img/khloe.jpg')

guys <- image_append(c(hadley, wes, francois))
gals <- image_append(c(kim, kourtney, khloe))

img <- image_append(c(guys, gals), stack = T) %>%
  image_scale('x400') # size 400px × 600px feels about right

image_write(img, path = './img/mugshots.jpg', format = 'jpg')