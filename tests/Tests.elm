module Tests exposing (..)

import Expect
import Test exposing (..)
import InfiniteScroll as IS
import Time exposing (second)


loadMore : IS.Direction -> Cmd msg
loadMore dir =
    Cmd.none


init : IS.Model msg
init =
    IS.init loadMore


all : Test
all =
    describe "elm-infinite-scroll"
        [ describe "init"
            [ test "default direction is Bottom" <|
                \() ->
                    Expect.equal init.direction IS.Bottom
            , test "default offset is 50" <|
                \() ->
                    Expect.equal init.offset 50
            , test "default timeout is 5 second" <|
                \() ->
                    Expect.equal init.timeout (5 * second)
            , test "not loading" <|
                \() ->
                    Expect.equal init.isLoading False
            ]
        , describe "timeout"
            [ test "change timeout value" <|
                \() ->
                    Expect.equal (init |> IS.timeout (10 * second)).timeout (10 * second)
            ]
        , describe "offset"
            [ test "change offset value" <|
                \() ->
                    Expect.equal (init |> IS.offset 100).offset 100
            ]
        , describe "direction"
            [ test "change direction to Top" <|
                \() ->
                    Expect.equal (init |> IS.direction IS.Top).direction IS.Top
            , test "change direction to Bottom" <|
                \() ->
                    Expect.equal (init |> IS.direction IS.Bottom).direction IS.Bottom
            ]
        , describe "startLoading"
            [ test "set isLoading to True" <|
                \() ->
                    let
                        model =
                            { init | isLoading = False }
                    in
                        Expect.equal (IS.startLoading model).isLoading True
            ]
        , describe "stopLoading"
            [ test "set isLoading to False" <|
                \() ->
                    let
                        model =
                            { init | isLoading = True }
                    in
                        Expect.equal (IS.stopLoading model).isLoading False
            ]
        ]
