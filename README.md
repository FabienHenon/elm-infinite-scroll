# elm-infinite-scroll [![Build Status](https://travis-ci.org/FabienHenon/elm-infinite-scroll.svg?branch=master)](https://travis-ci.org/FabienHenon/elm-infinite-scroll)

```
elm install FabienHenon/elm-infinite-scroll
```

Infinite scroll allows you to load more content on demand for the user while scrolling.

The infinite scroll must be bound to an `Html` element and will execute your own `Cmd` when the user
scrolled to the bottom (or top) of the element.

The `Cmd` can be anything you want from local data fetching or complex requests on remote APIs.
All it has to do is to return a `Cmd msg` and call `stopLoading` once fetching is finished so that
the infinite scroll can continue asking for more content.

## Getting started

### Types
First you need to add infinite scroll to your messages and your model.

```elm
import InfiniteScroll

type Msg
    = InfiniteScrollMsg InfiniteScroll.Msg

type alias Model =
    { infiniteScroll : InfiniteScroll.Model Msg
    , content : List String
    }
```

### Initialization
Initializes your model.

```elm
initModel : Model
initModel =
    { infiniteScroll = InfiniteScroll.init loadMore
    , content = initialContent
    }
```

`loadMore` is the command that will be called when new content is required (more on see later).
`initialContent` is your own function that initializes your content with a few data (more data will be added as the user scrolls the element)

### View
Then, you need to bind infinite scroll to your `view`, in the element that will contain you long content.

```elm
view : Model -> Html Msg
view model =
    div
        [ style [ ( "height", "300px" ) ]
        , InfiniteScroll.infiniteScroll InfiniteScrollMsg
        ]
        (List.map viewContentItem model.content)
```

`viewContentItem` is your own function responsible for your content rendering.

You call `infiniteScroll` on the element that must be scrolled. This function returns an `Attribute`.

**Your element must have a height explicitly set in order to have the scroll event triggered**

### Load more
You have to define a function that will be called when we need more content. This function must return a `Cmd Msg`.

Here is an example with data retrieved from a remote API:

```elm
type Msg
    -- ... add this message
    | OnDataRetrieved (Result Http.Error String)

loadMore : InfiniteScroll.Direction -> Cmd Msg
loadMore dir =
    Http.getString "https://example.com/retrieve-more"
        |> Http.send OnDataRetrieved
```

### Update
Finally, all we need to do is to implement the update function.

```elm
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        InfiniteScrollMsg msg_ ->
            let
                ( infiniteScroll, cmd ) =
                    InfiniteScroll.update InfiniteScrollMsg msg_ model.infiniteScroll
            in
                ( { model | infiniteScroll = infiniteScroll }, cmd )

        OnDataRetrieved (Err _) ->
            let
                -- Don't forget to handle error
                infiniteScroll =
                    InfiniteScroll.stopLoading model.infiniteScroll
            in
                ( { model | infiniteScroll = infiniteScroll }, Cmd.none )

        OnDataRetrieved (Ok result) ->
            let
                content =
                    addContent result model.content

                infiniteScroll =
                    InfiniteScroll.stopLoading model.infiniteScroll
            in
                ( { model | content = content, infiniteScroll = infiniteScroll }, Cmd.none )
```

In the update you have to handle infinite scroll update. It will return an updated model and a command to execute.

You also have to handle your data fetching, and **don't forget to call `stopLoading`** so that you won't have to wait for timeout before being able to load event more data.

## Examples

To run the examples go to the `examples` directory, install dependencies and run `elm-reactor`:

```
> cd examples/
> elm package install
> elm-reactor
```
