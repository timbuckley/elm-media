module Media
    exposing
        ( State
        , audio
        , audioWithEvents
        , video
        , videoWithEvents
        , play
        , pause
        , seek
        , fastSeek
        , load
        , newVideo
        , newAudio
        , PortMsg
        )

{-| ###State

@docs newVideo, newAudio, State

###Audio and Video Elements

@docs audio, video, audioWithEvents, videoWithEvents

###Playback Control

@docs PortMsg, play, pause, seek, fastSeek, load

-}

import Json.Encode as Encode
import Media.State exposing (id)
import Media.Events exposing (..)
import Internal.Types exposing (defaultAudio, defaultVideo)
import Html exposing (Attribute, Html)
import Html.Attributes as Attrs exposing (src, controls, loop, autoplay, preload, poster)


{- Types -}


{-| This is just a convenient alias to prevent you from having to type
Media.State.State. State is an opaque type
-}
type alias State =
    Internal.Types.State



{- HTML Elements -}


{-| Generates an HTMLVideoElement with a state. Works exactly the same
as Elm-lang/HTML's video function, except it requires a State type (which
means it requires an id). It's probably best to generate a default video state in
your init function using the newVideo function, but you can generate one
here with the same function, if you prefer.
-}
video : State -> List (Attribute msg) -> List (Html msg) -> Html msg
video state attrs children =
    Html.video ([ Attrs.id <| id state ] ++ attrs) children


{-| Same as the video function, but for an audio element.

NOTE: audio elements and video playments can each play both audio
and video files. If you give a video file to an audio element, it will only
play the audio track. These audio and video functions only refer to the kind
of HTML element you're using, not the source file.

-}
audio : State -> List (Attribute msg) -> List (Html msg) -> Html msg
audio state attrs children =
    Html.audio ([ Attrs.id <| id state ] ++ attrs) children


{-| Creates a video element with updates for all Media Events. Works just like a standard Html element from
elm-lang/Html, except it required you to specify an id and give it a message
for updating the media state.

The simplest update will look like this:

`type Msg =
UpdateMedia Media.State

update msg model =
case msg of
UpdateMedia state ->
({model | mediaState = state }, Cmd.none )
`
It throws an update event on any of the standard HTMLMediaElement Events,
such as onTimeUpdate, onPlaying, etc.

NOTE: onTimeUpdate does not update every frame on some browsers, and can be
thrown as infrequently as once every 1/4 second. For updates with single-frame precision,
you'll have to figure something out using requestAnimationFrame.

-}
videoWithEvents : State -> (State -> msg) -> List (Attribute msg) -> List (Html msg) -> Html msg
videoWithEvents state tagger attrs children =
    Html.video ([ Attrs.id <| id state ] ++ (allEvents tagger) ++ attrs) children


{-| Same as videoWithEvents, but generates an audio element.

NOTE: video and audio elements can both play any supported file, but
audio elements have no picture element. So if you play a video file in
an audio element, you will hear the audio track, but not see the video track.

-}
audioWithEvents : State -> (State -> msg) -> List (Attribute msg) -> List (Html msg) -> Html msg
audioWithEvents state tagger attrs children =
    Html.video ([ Attrs.id <| id state ] ++ (allEvents tagger) ++ attrs) children


allEvents : (State -> msg) -> List (Attribute msg)
allEvents tagger =
    [ onAbort tagger
    , onCanPlay tagger
    , onCanPlayThrough tagger
    , onDurationChange tagger
    , onEmptied tagger
    , onEnded tagger
    , onError tagger
    , onLoadStart tagger
    , onLoadSuspend tagger
    , onLoadedData tagger
    , onLoadedMetadata tagger
    , onPause tagger
    , onPlaying tagger
    , onProgress tagger
    , onSeeked tagger
    , onSeeking tagger
    , onStalled tagger
    , onTimeUpdate tagger
    , onWaiting tagger
    ]



{- DEFAULT STATES -}


{-| This generates a default video state to put in your init, such as:
type alias Model =
Media.State

init: (Model, Cmd msg)
init =
( newVideo "myVideo", Cmd.none )
`

NOTE: newAudio is for HTMLAudioElements and newVideo is for HTMLVideoElements.
The kind of file you're using doesn't really matter in this context, what matters
is what type the media element is. An audio file will play in a video element &
vice-versa.

-}
newVideo : String -> State
newVideo uniqueId =
    defaultVideo uniqueId


{-| Same as newVideo, but for an audio element.

NOTE: newAudio is for HTMLAudioElements and newVideo is for HTMLVideoElements.
The kind of file you're using doesn't really matter in this context, what matters
is what type the media element is. An audio file will play in a video element &
vice-versa.

-}
newAudio : String -> State
newAudio uniqueId =
    defaultAudio uniqueId



{- HTML Attributes -}
{- FOR PORTS -}


{-| This is the data you'll send through the port you setup.
There should be no need to generate this yourself, the following
control functions will generate for you.
-}
type alias PortMsg =
    { tag : String
    , id : String
    , data : Encode.Value
    }


{-| Begin playback.
-}
play : State -> (PortMsg -> Cmd msg) -> Cmd msg
play state tagger =
    tagger { tag = "Play", id = id state, data = Encode.null }


{-| Pause
-}
pause : State -> (PortMsg -> Cmd msg) -> Cmd msg
pause state tagger =
    tagger { tag = "Pause", id = id state, data = Encode.null }


{-| Change the current position of the playhead to a different time.
-}
seek : State -> Float -> (PortMsg -> Cmd msg) -> Cmd msg
seek state time tagger =
    tagger { tag = "Seek", id = id state, data = Encode.float time }


{-| Same as seek, but changes position to nearest keyframe to specified
time, trading precision for performance
-}
fastSeek : State -> Float -> (PortMsg -> Cmd msg) -> Cmd msg
fastSeek state time tagger =
    tagger { tag = "Seek", id = id state, data = Encode.float time }


{-| Resets the media. Useful if you're changing the media source, for instance.
-}
load : State -> (PortMsg -> Cmd msg) -> Cmd msg
load state tagger =
    tagger { tag = "Load", id = id state, data = Encode.null }
