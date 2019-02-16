module Page.Upload.Main exposing (Model, Msg(..), init, update, view)

import ComponentResult as CR
import Html.Styled as H
import Html.Styled.Attributes as A
import Html.Styled.Events as E
import Types exposing (Flags)


type alias Model =
    {}


type ExternalMsg
    = NoOp_


type Msg
    = NoOp


type alias PageResult =
    CR.ComponentResult Model Msg ExternalMsg Never


init : Flags -> PageResult
init flags =
    CR.withModel
        {}


update : Flags -> Msg -> Model -> PageResult
update flags msg model =
    CR.withModel
        model


view_ : Model -> H.Html Msg
view_ model =
    H.div [] [ H.text "upload page" ]


view =
    view_ >> H.toUnstyled
