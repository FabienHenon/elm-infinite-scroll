module Tests exposing (..)

-- import Expect

import Test exposing (..)
import InfiniteScroll as IS


-- import Time exposing (second)


loadMore : IS.Direction -> Cmd msg
loadMore dir =
    Cmd.none


init : IS.Model msg
init =
    IS.init loadMore


all : Test
all =
    describe "elm-infinite-scroll"
        []



--  describe "startLoading"
--     [ test "set isLoading to True" <|
--         \() ->
--             let
--                 model =
--                     { init | isLoading = False }
--             in
--                 Expect.equal (IS.startLoading model).isLoading True
--     ]
-- , describe "stopLoading"
--     [ test "set isLoading to False" <|
--         \() ->
--             let
--                 model =
--                     { init | isLoading = True }
--             in
--                 Expect.equal (IS.stopLoading model).isLoading False
--     ]
-- ]
