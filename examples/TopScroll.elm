module TopScroll exposing (main)

import Browser
import Html exposing (Html, div, p, text)
import Html.Attributes exposing (style)
import Http
import InfiniteScroll as IS
import Json.Decode as JD


type Msg
    = InfiniteScrollMsg IS.Msg
    | OnDataRetrieved (Result Http.Error (List String))


type alias Model =
    { infScroll : IS.Model Msg
    , content : List String
    }


main : Program () Model Msg
main =
    Browser.document
        { init = always init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


initModel : Model
initModel =
    { infScroll = IS.init loadMore |> IS.offset 200 |> IS.direction IS.Top
    , content = []
    }


init : ( Model, Cmd Msg )
init =
    let
        model =
            initModel
    in
    ( { model | infScroll = IS.startLoading model.infScroll }, loadContent )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        InfiniteScrollMsg msg_ ->
            let
                ( infScroll, cmd ) =
                    IS.update InfiniteScrollMsg msg_ model.infScroll
            in
            ( { model | infScroll = infScroll }, cmd )

        OnDataRetrieved (Err _) ->
            let
                infScroll =
                    IS.stopLoading model.infScroll
            in
            ( { model | infScroll = infScroll }, Cmd.none )

        OnDataRetrieved (Ok result) ->
            let
                content =
                    List.concat [ result, model.content ]

                infScroll =
                    IS.stopLoading model.infScroll
            in
            ( { model | content = content, infScroll = infScroll }, Cmd.none )


stringsDecoder : JD.Decoder (List String)
stringsDecoder =
    JD.list JD.string


loadContent : Cmd Msg
loadContent =
    Http.get "https://baconipsum.com/api/?type=all-meat&paras=10" stringsDecoder
        |> Http.send OnDataRetrieved


loadMore : IS.Direction -> Cmd Msg
loadMore dir =
    loadContent


view : Model -> Browser.Document Msg
view model =
    { title = "Top Scroll Example"
    , body =
        [ div
            [ style "height" "500px"
            , style "width" "500px"
            , style "overflow" "auto"
            , style "border" "1px solid #000"
            , style "margin" "auto"
            , IS.infiniteScroll InfiniteScrollMsg
            ]
            (loader model ++ List.map viewContentItem model.content)
        ]
    }


viewContentItem : String -> Html Msg
viewContentItem item =
    p [] [ text item ]


loader : Model -> List (Html Msg)
loader { infScroll } =
    if IS.isLoading infScroll then
        [ div
            [ style "color" "red"
            , style "font-weight" "bold"
            , style "text-align" "center"
            ]
            [ text "Loading ..." ]
        ]

    else
        []


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none
