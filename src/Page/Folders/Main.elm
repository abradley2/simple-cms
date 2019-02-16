module Page.Folders.Main exposing (Model, Msg(..), init, update, view)

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


update : Msg -> Model -> PageResult
update msg model =
    CR.withModel
        {}


view : Model -> H.Html Msg
view model =
    H.div [] []
