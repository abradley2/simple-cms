module Page.Upload.Main exposing (Model, Msg(..), init, update, view)

import ComponentResult as CR
import Html.Styled as H
import Html.Styled.Attributes as A
import Html.Styled.Events as E
import Types exposing (PageMsg(..), Taco)


type alias Model =
    {}


type Msg
    = NoOp


type alias PageResult =
    CR.ComponentResult Model Msg PageMsg Never


init : Taco -> PageResult
init taco =
    CR.withModel
        {}


update : Taco -> Msg -> Model -> PageResult
update taco msg model =
    CR.withModel
        model


view_ : Model -> H.Html Msg
view_ model =
    H.div [] [ H.text "upload page" ]


view =
    view_ >> H.toUnstyled
