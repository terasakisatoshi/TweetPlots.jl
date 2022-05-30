#=
# Share your idea on Twitter!

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
$ julia app.jl
```

=#

using Base64

using Dash
using IOCapture
using Plots
using PyCall
using DotEnv

DotEnv.config() # read credential from .env

tweepy = pyimport("tweepy")
@pydef mutable struct TweetEngine
    function __init__(self)
        CONSUMER_KEY = ENV["CONSUMER_KEY"]
        CONSUMER_SECRET = ENV["CONSUMER_SECRET"]
        ACCESS_TOKEN = ENV["ACCESS_TOKEN"]
        ACCESS_TOKEN_SECRET = ENV["ACCESS_TOKEN_SECRET"]

        self.client = tweepy.Client(
            consumer_key=CONSUMER_KEY,
            consumer_secret=CONSUMER_SECRET,
            access_token=ACCESS_TOKEN,
            access_token_secret=ACCESS_TOKEN_SECRET,
        )
        auth = tweepy.OAuth1UserHandler(CONSUMER_KEY, CONSUMER_SECRET)
        auth.set_access_token(ACCESS_TOKEN, ACCESS_TOKEN_SECRET)
        self.api = tweepy.API(auth)
    end
end

engine = TweetEngine()

app = dash(
    external_stylesheets=["https://codepen.io/chriddyp/pen/bWLwgP.css"],
    prevent_initial_callbacks=true,
)



function encodefile(file::AbstractString)
    io = IOBuffer()
    write(io, "data:image/png;base64,")
    enc = file |> read |> base64encode
    write(io, enc)
    src = String(take!(io))
    close(io)
    src
end

encode(::Any) = nothing

function encode(p::Plots.Plot)
    savefig(p, "save.png")
    return encodefile("save.png")
end

function encode(anim::Plots.Animation)
    gif(anim, "save.gif")
    return encodefile("save.gif")
end

encode(g::Plots.AnimatedGif) = encodefile(g.filename)

initialsourcecode = """
# input alt_text here
using Plots
plot(cos)
plot!(sin)
"""

initialtweet = """
#JuliaLang

Let's share your idea on Twitter!
See ALT text to see how the attached image/gif is created.
"""

app.layout = html_div() do
    html_h1("Share your idea on Twitter"),
    dcc_textarea(
        id="text-sourcecode",
        placeholder="write visualization code here",
        value=initialsourcecode,
        rows="15",
        style=Dict(
            :width => "80%",
            :height => "50%",
        ),
    ),
    html_br(),
    html_button(
        "Plot!",
        id="button-plot",),
    html_br(),
    html_img(id="img-canvas", src=encode(abspath("save.png"))),
    html_h3("Tweet"),
    dcc_textarea(
        id="text-tweet",
        placeholder="tweet message with your image",
        value=initialtweet,
        rows="5",
        style=Dict(
            :width => "50%",
            :height => "50%",
        ),
    ),
    html_br(),
    html_button(
        "Tweet!", id="button-tweet",
    ),
    html_div(id="div-dummy")
end

function sandbox()
    m = Module(gensym())
    # eval(expr) is available in the REPL (i.e. Main) so we emulate that for the sandbox
    Core.eval(m, :(eval(x) = Core.eval($m, x)))
    # modules created with Module() does not have include defined
    # abspath is needed since this will call `include_relative`
    Core.eval(m, :(include(x) = Base.include($m, abspath(x))))
    # load InteractiveUtils
    Core.eval(m, :(using InteractiveUtils))
    return m
end
sb = sandbox()

callback!(
    app,
    Output("img-canvas", "src"),
    Input("button-plot", "n_clicks"),
    [State("text-sourcecode", "value")]
) do n_clicks, sourcecode

    ret = IOCapture.capture(rethrow=Union{}) do
        include_string(sb, sourcecode)
    end

    if ret.error
        msg = """
        $(sprint(showerror, ret.value))
        with the following code block
        ```julia
        $sourcecode
        ```
        """
        @warn "$msg"
        return nothing
    else
        @info "ret" ret.output ret.value
        return encode(ret.value)
    end
end

callback!(
    app,
    Output("div-dummy", "children"),
    Input("button-tweet", "n_clicks"),
    [State("text-tweet", "value"), State("text-sourcecode", "value"), State("img-canvas", "src")]
) do n_clicks, tweetmsg, sourcecode, img_or_gif
    try
        str = img_or_gif[length("data:image/png;base64,"):end]
        data = base64decode(str)
        uploadfilename = "tmp.png"
        write(uploadfilename, data)
        @info "Upload image"
        mediaID = engine.api.simple_upload(uploadfilename)
        @info "Insert alt_text"
        engine.api.create_media_metadata(mediaID.media_id, alt_text=sourcecode)
        @info "It's time to tweet"
        r = engine.client.create_tweet(
            text=tweetmsg,
            media_ids=[mediaID.media_id],
        )
        @info "Succeeded!" r
        @info "Clean up"
        rm(uploadfilename, force=true)
    catch e
        @warn "$e"
        @warn "Tweet failed"
        return nothing
    end
end

run_server(app, debug=true)