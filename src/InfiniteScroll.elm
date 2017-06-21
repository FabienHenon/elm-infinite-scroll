module InfiniteScroll
    exposing
        ( infiniteScroll
        , Model
        , Msg
        , init
        , timeout
        , offset
        , direction
        , Direction(..)
        , update
        , LoadMoreCmd
        , stopLoading
        , startLoading
        , isLoading
        , cmdFromScrollEvent
        )

{-| Infinite scroll allows you to load more content for the user as he scrolls (up or down).

The infinite scroll must be bound to an `Html` element and will execute your own `Cmd` when the user
scrolled to the bottom (or top) of the element.

The `Cmd` can be anything you want from local data fetching or complex requests on remote APIs.
All it has to do is to return a `Cmd msg` and call `stopLoading` once fetching is finished so that
the infinite scroll can continue asking for more content.

# Definitions
@docs LoadMoreCmd, Direction

# Initialization
@docs init, timeout, offset, direction

# Update
@docs update

# Scroll
@docs infiniteScroll, stopLoading, startLoading, isLoading

# Advanced
@docs cmdFromScrollEvent

# Types
@docs Model, Msg
-}

import Html
import Html.Attributes exposing (..)
import Html.Events exposing (on)
import Json.Decode as JD
import Process
import Task
import Time exposing (Time, second)


{-| Definition of the function you must provide to the API. This function will be called
as soon as new content is required

    loadMore : InfiniteScroll.Direction -> Cmd Msg
    loadMore dir =
        Task.perform OnLoadMore <| Task.succeed dir

    InfiniteScroll.init loadMore
-}
type alias LoadMoreCmd msg =
    Direction -> Cmd msg


{-| Scroll direction.
- `Top` means new content will be asked when the user scrolls to the top of the element
- `Bottom` means new content will be asked when the user scrolls to the bottom of the element
-}
type Direction
    = Top
    | Bottom


{-| Model of the infinite scroll module. You need to create a new one using `init` function.
-}
type Model msg
    = Model (ModelInternal msg)


type alias ModelInternal msg =
    { direction : Direction
    , offset : Int
    , loadMoreFunc : LoadMoreCmd msg
    , isLoading : Bool
    , timeout : Time
    , lastRequest : Time
    }


type alias ScrollPos =
    { scrollTop : Int
    , contentHeight : Int
    , containerHeight : Int
    }


{-| Infinite scroll messages you have to give to the `update` function.
-}
type Msg
    = Scroll ScrollPos
    | CurrTime Time
    | Timeout Time ()



-- Init


{-| Creates a new `Model`. This function needs a `LoadMoreCmd` that will be called when new data is required.

    type Msg
        = OnLoadMore InfiniteScroll.Direction

    type alias Model =
        { infiniteScroll : InfiniteScroll.Model Msg }

    loadMore : InfiniteScroll.Direction -> Cmd Msg
    loadMore dir =
        Task.perform OnLoadMore <| Task.succeed dir

    initModel : Model
    initModel =
        { infiniteScroll = InfiniteScroll.init loadMore }
-}
init : LoadMoreCmd msg -> Model msg
init loadMoreFunc =
    Model
        { direction = Bottom
        , offset = 50
        , loadMoreFunc = loadMoreFunc
        , isLoading = False
        , timeout = 5 * second
        , lastRequest = 0
        }


{-| Sets a different timeout value (default is 5 seconds)

When timeout is exceeded `stopLoading` will be automatically called so that infinite scroll can continue asking more content
event when previous request did not finished.

    init loadMore
        |> timeout 10 * second
-}
timeout : Time -> Model msg -> Model msg
timeout timeout (Model model) =
    Model { model | timeout = timeout }


{-| Sets a different offset (default 50).

Offset is the number of pixels from top or bottom (depending on `Direction` value) from which infinite scroll
will detect it needs more content.

For instance with offset set to 50 and direction to `Top`. Once scroll position is 50 pixels or less from the top of the element it will require new content.
The same applies with a direction set to `Bottom` except it will check for the distance with the bottom of the element.

    init loadMore
        |> offset 100
-}
offset : Int -> Model msg -> Model msg
offset offset (Model model) =
    Model { model | offset = offset }


{-| Sets a different direction (default to `Bottom`).

A direction set to `Bottom` will check distance of the scroll bar from the bottom of the element, whereas a direction set to `Top`
will check distance of the scroll bar from the top of the element.

    init loadMore
        |> direction Top
-}
direction : Direction -> Model msg -> Model msg
direction direction (Model model) =
    Model { model | direction = direction }



-- Update


{-| The update function must be called in your own update function. It will return an updated `Model` and commands to execute.

    type Msg =
        InfiniteScrollMsg InfiniteScroll.Msg

    type alias Model =
        { infiniteScroll : InfiniteScroll.Model Msg }

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            InfiniteScrollMsg msg_ ->
                let
                    ( infiniteScroll, cmd ) =
                        InfiniteScroll.update InfiniteScrollMsg msg_ model.infiniteScroll
                in
                    ( { model | infiniteScroll = infiniteScroll }, cmd )
-}
update : (Msg -> msg) -> Msg -> Model msg -> ( Model msg, Cmd msg )
update mapper msg (Model model) =
    case msg of
        Scroll pos ->
            if shouldLoadMore model pos then
                ( startLoading (Model model)
                , Cmd.map mapper <| Task.perform CurrTime <| Time.now
                )
            else
                ( Model model, Cmd.map mapper Cmd.none )

        CurrTime time ->
            ( Model { model | lastRequest = time }
            , Cmd.batch
                [ model.loadMoreFunc model.direction
                , Cmd.map mapper <| Task.perform (Timeout time) <| Process.sleep model.timeout
                ]
            )

        Timeout time _ ->
            if time == model.lastRequest then
                ( stopLoading (Model model), Cmd.map mapper Cmd.none )
            else
                ( Model model, Cmd.map mapper Cmd.none )


shouldLoadMore : ModelInternal msg -> ScrollPos -> Bool
shouldLoadMore { direction, offset, isLoading } { scrollTop, contentHeight, containerHeight } =
    if isLoading then
        False
    else
        case direction of
            Top ->
                scrollTop <= offset

            Bottom ->
                let
                    excessHeight =
                        contentHeight - containerHeight
                in
                    scrollTop >= (excessHeight - offset)


{-| **Only use this function if you handle `on "scroll"` event yourself**
_(for instance if another package is also using the scroll event on the same node)_

The function returns a `Cmd msg` that will perform the model update normally done with `infiniteScroll`.
You have to pass it a `Json.Decode.Value` directly coming from `on "scroll"` event

    type Msg
        = InfiniteScrollMsg InfiniteScroll.Msg
        | OnScroll JsonDecoder.Value

    view : Model -> Html Msg
    view model =
        div [ on "scroll" (JsonDecoder.map OnScroll JsonDecoder.value) ] [ -- content -- ]

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            -- ... --

            InfiniteScrollMsg msg_ ->
                let
                    ( infScroll, cmd ) =
                        InfiniteScroll.update InfiniteScrollMsg msg_ model.infScroll
                in
                    ( { model | infScroll = infScroll }, cmd )

            OnScroll value ->
                ( model, InfiniteScroll.cmdFromScrollEvent InfiniteScrollMsg value )
-}
cmdFromScrollEvent : (Msg -> msg) -> JD.Value -> Cmd msg
cmdFromScrollEvent mapper value =
    case JD.decodeValue (JD.map Scroll decodeScrollPos) value of
        Ok msg ->
            Task.perform mapper <| Task.succeed msg

        Err _ ->
            Cmd.none



-- Infinite scroll


{-| Function used to bind the infinite scroll on an element.

**The element's height must be explicitly set, otherwise scroll event won't be triggered**

    type Msg
        = InfiniteScrollMsg InfiniteScroll.Msg

    view : Model -> Html Msg
    view _ =
        let
            styles =
                [ ( "height", "300px" ) ]
        in
            div [ infiniteScroll InfiniteScrollMsg, Attributes.style styles ]
                [ -- Here will be my long list -- ]
-}
infiniteScroll : (Msg -> msg) -> Html.Attribute msg
infiniteScroll mapper =
    Html.Attributes.map mapper <| on "scroll" (JD.map Scroll decodeScrollPos)


{-| Starts loading more data. You should never have to use this function has it is automatically called
when new content is required and your `loadMore` command is executed.
-}
startLoading : Model msg -> Model msg
startLoading (Model model) =
    Model { model | isLoading = True }


{-| Checks if the infinite scroll is currently in a loading state.

Which means it won't ask for more data even if the user scrolls
-}
isLoading : Model msg -> Bool
isLoading (Model { isLoading }) =
    isLoading


{-| Stops loading. You should call this function when you have finished fetching new data. This tells infinite scroll that it
can continue asking you more content.

If you forget to call this function or if your data fetching is too long, you will be asked to retrieve more content after timeout has expired.
-}
stopLoading : Model msg -> Model msg
stopLoading (Model model) =
    Model { model | isLoading = False }



-- Decoder


decodeScrollPos : JD.Decoder ScrollPos
decodeScrollPos =
    JD.map3 ScrollPos
        (JD.at [ "target", "scrollTop" ] JD.int)
        (JD.at [ "target", "scrollHeight" ] JD.int)
        (JD.map2 Basics.max offsetHeight clientHeight)


scrollHeight : JD.Decoder Int
scrollHeight =
    JD.at [ "target", "scrollHeight" ] JD.int


offsetHeight : JD.Decoder Int
offsetHeight =
    JD.at [ "target", "offsetHeight" ] JD.int


clientHeight : JD.Decoder Int
clientHeight =
    JD.at [ "target", "clientHeight" ] JD.int
