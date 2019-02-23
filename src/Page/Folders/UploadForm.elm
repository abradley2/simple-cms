module Page.Folders.UploadForm exposing (ExternalMsg, Model, Msg(..), init, update, view)

import ComponentResult as CR
import Css exposing (..)
import File as File
import FormElements.TextInput as TextInput
import Html.Styled as H
import Html.Styled.Attributes as A
import Html.Styled.Events as E
import RemoteData exposing (RemoteData(..))
import Types exposing (Folder)


type ExternalMsg
    = UploadFormNoop


type Msg
    = FilesRequested
    | FilesLoaded File.File (List File.File)


type alias Model =
    { files : RemoteData String File.File
    }


init : Model
init =
    { files = NotAsked
    }


type alias UploadFormResult =
    CR.ComponentResult Model Msg ExternalMsg Never


update : Msg -> Model -> UploadFormResult
update msg model =
    CR.withModel model


view : Folder -> Model -> H.Html Msg
view folder model =
    H.div []
        [ H.text "upload form"
        ]
