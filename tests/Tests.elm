module Tests exposing (..)

import Expect
import Test exposing (..)
import InfiniteScroll as IS


loadMore : IS.Direction -> Cmd msg
loadMore dir =
    Cmd.none


init : IS.Model msg
init =
    IS.init loadMore


all : Test
all =
    describe "elm-infinite-scroll"
        [ describe "startLoading"
            [ test "set isLoading to True" <|
                \() ->
                    let
                        model =
                            init |> IS.stopLoading
                    in
                        Expect.equal (IS.startLoading model |> IS.isLoading) True
            ]
        , describe "stopLoading"
            [ test "set isLoading to False" <|
                \() ->
                    let
                        model =
                            init |> IS.startLoading
                    in
                        Expect.equal (IS.stopLoading model |> IS.isLoading) False
            ]
        ]
