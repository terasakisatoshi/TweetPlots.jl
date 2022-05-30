# TweetPlots.jl

Share your idea on Twitter using Dash.jl

# How to use:

## Create an application on the Twitter's Developer Platform.

- Create an application on the Twitter's Developer Platform: https://developer.twitter.com/en
- Get CONSUMER_KEY(a.k.a API_KEY), CONSUMER_SECRET (a.k.a API_KEY_SECRET), ACCESS_TOKEN and ACCESS_TOKEN_SECRET from your dashboard of Twitter's Developer Platform.
- Store them above in `.env` file so that you can access these secrets from `ENV`.

```julia
using DotEnv; DotEnv.config();
CONSUMER_KEY = ENV["CONSUMER_KEY"]
CONSUMER_SECRET = ENV["CONSUMER_SECRET"]
ACCESS_TOKEN = ENV["ACCESS_TOKEN"]
ACCESS_TOKEN_SECRET = ENV["ACCESS_TOKEN_SECRET"]
```

## Install `tweepy`

Install `tweepy` via:

```
$ pip3 install tweepy
```

## Run this script

```console
$ julia --project=@. -e 'using Pkg; Pkg.instantiate()'
$ julia --project=@. app.jl
```

You may access the webserver from the browser using http://127.0.0.1:8050.
Then you'll see something like below:


<img width="700" alt="スクリーンショット 2022-05-31 0 15 35" src="https://user-images.githubusercontent.com/16760547/171022500-1b64c14b-360d-4fa5-96c3-4b45ac70f23c.png">

I hope you like it.