module Page.Folders.UploadForm exposing (ExternalMsg, Model, Msg(..), init, update, view)

import ComponentResult as CR
import Css exposing (..)
import File as File
import File.Select as Select
import FormElements.TextInput as TextInput
import Html.Styled as H
import Html.Styled.Attributes as A
import Html.Styled.Events as E
import RemoteData exposing (RemoteData(..))
import Styles
import Types exposing (Folder)


type ExternalMsg
    = UploadFormNoop


type Msg
    = FilesRequested
    | FilesLoaded File.File
    | FileNameInputMsg TextInput.Msg


type alias Model =
    { file : Maybe File.File
    , fileName : String
    , fileNameTextInput : TextInput.Model
    }


init : Folder -> Model
init folder =
    { file = Nothing
    , fileName = ""
    , fileNameTextInput = Tuple.first <| TextInput.init folder.id
    }


type alias UploadFormResult =
    CR.ComponentResult Model Msg ExternalMsg Never


getTextInputProps =
    let
        props =
            TextInput.defaultProps
    in
    { props
        | label = "File Name"
        , errorText = Just "invalid!"
    }


update : Msg -> Model -> UploadFormResult
update msg model =
    case msg of
        FilesRequested ->
            CR.withModel model
                |> CR.withCmd
                    (Select.file
                        [ "image/png", "image/jpeg", "image/jpg", "image/gif" ]
                        FilesLoaded
                    )

        FilesLoaded file ->
            CR.withModel
                { model
                    | file = Just file
                }

        FileNameInputMsg inputMsg ->
            TextInput.update inputMsg model.fileNameTextInput
                |> CR.mapModel
                    (\fileNameTextInput ->
                        { model
                            | fileNameTextInput = fileNameTextInput
                        }
                    )
                |> CR.mapMsg FileNameInputMsg
                |> CR.applyExternalMsg
                    (\extMsg result ->
                        case extMsg of
                            TextInput.ValueChanged value ->
                                result |> CR.mapModel (\m -> { m | fileName = value })
                    )


view : Folder -> Model -> H.Html Msg
view folder model =
    H.div
        [ A.css
            [ padding4 (px 0) (px 16) (px 16) (px 16)
            ]
        ]
        [ H.div
            [ A.css
                [ textAlign left
                ]
            ]
            [ H.button
                [ A.css
                    [ Styles.buttonReset
                    , Styles.defaultButton
                    ]
                , E.onClick FilesRequested
                ]
                [ H.text "Upload File" ]
            ]
        , Maybe.map
            (\file ->
                H.div []
                    [ H.text <| File.name file
                    , H.br [] []
                    , H.text <| String.fromInt (Basics.round ((File.size >> toFloat) file / 1024)) ++ "kb"
                    , H.div []
                        [ TextInput.view model.fileNameTextInput getTextInputProps
                            |> (H.fromUnstyled >> H.map FileNameInputMsg)
                        ]
                    ]
            )
            model.file
            |> Maybe.withDefault (H.text "")
        ]
