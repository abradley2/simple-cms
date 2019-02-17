module Page.Folders.Main exposing (Model, Msg(..), init, update, view)

import ComponentResult as CR
import Data.Folders exposing (GetFoldersResponse, getFolders)
import Html.Styled as H
import Html.Styled.Attributes as A
import Html.Styled.Events as E
import Http
import RemoteData exposing (RemoteData(..), WebData)
import Types exposing (PageMsg(..), Taco)


type alias Model =
    {}


type Msg
    = NoOp
    | FoldersResponseReceived (Result Http.Error GetFoldersResponse)


type alias PageResult =
    CR.ComponentResult Model Msg PageMsg Never


init : Taco -> PageResult
init taco =
    CR.withModel
        {}
        |> CR.withCmd
            (Maybe.map (getFolders taco FoldersResponseReceived) taco.token
                |> Maybe.withDefault Cmd.none
            )


update : Taco -> Msg -> Model -> PageResult
update taco msg model =
    CR.withModel
        model


view_ : Model -> H.Html Msg
view_ model =
    H.div [] [ H.text "Folders Page" ]


view =
    view_ >> H.toUnstyled
