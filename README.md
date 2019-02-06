# Celebrity Faceoff: a Text Classification Challenge

Benchmarking text classification with Keras and Ruimtehol packages on celebrity twitter data.

<p align="center">
  <img src="https://github.com/jlacko/celebrity-faceoff/blob/master/img/mugshots.jpg?raw=true" alt="arent't they lovely?"/>
</p>

The underlying dataset is 9,000 tweets, collected on 2019-02-02 via [`rtweet`](https://github.com/mkearney/rtweet). It consists of 1,500 tweets each from  

* [Hadley Wickham](https://twitter.com/hadleywickham), 
* [Wes McKinney](https://twitter.com/wesmckinn),  
* [François Chollet](https://twitter.com/fchollet), 
* [Kim Kardashian](https://twitter.com/KimKardashian), 
* [Kourtney Kardashian](https://twitter.com/kourtneykardash),  
* [Khloe Kardashian](https://twitter.com/khloekardashian)

From each account 1,200 (80%) are be included in training dataset and 300 (20%) in verification set.

At the first glance a fancy Keras model performs better than StarSpace. 

<p align="center">
  <img src="https://github.com/jlacko/celebrity-faceoff/blob/master/img/results.png?raw=true" alt="classification results"/>
</p>

I do not feel though that such a simple percentage comparison gives the models justice, as the StarSpace set up in a breeze and took about a minute to train. The effort and resources necessary to come up with the Keras result were much, much higher.

So my provisional verdict on [`ruimtehol`] / StarSpace is that it gives an *adequate* result at the fraction of the effort & resources required to set up a fancy solution.

