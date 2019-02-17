module Page.Folders.Main exposing (Model, Msg(..), init, update, view)

import ComponentResult as CR
import Css exposing (..)
import Css.Transitions as Transitions
import Data.Folders exposing (GetFoldersResponse, getFolders)
import FormElements.TextInput as TextInput
import Html.Styled as H
import Html.Styled.Attributes as A
import Html.Styled.Events as E
import Http
import Maybe.Extra as M
import RemoteData exposing (RemoteData(..), WebData)
import Styles as Styles
import Types exposing (PageMsg(..), Taco)


type alias Model =
    { creatingNewFolder : Bool
    , newFolderName : String
    , newFolderTextInput : TextInput.Model
    , foldersData : WebData GetFoldersResponse
    }


type Msg
    = NoOp
    | NewFolderTextInputMsg TextInput.Msg
    | FoldersResponseReceived (Result Http.Error GetFoldersResponse)
    | ToggleCreatingNewFolder Bool


type alias PageResult =
    CR.ComponentResult Model Msg PageMsg Never


init : Taco -> PageResult
init taco =
    CR.withModel
        { creatingNewFolder = False
        , newFolderName = ""
        , newFolderTextInput = Tuple.first <| TextInput.init "new-folder"
        , foldersData = Maybe.map (\_ -> Loading) taco.token |> Maybe.withDefault NotAsked
        }
        |> CR.withCmd
            (Maybe.map (getFolders taco FoldersResponseReceived) taco.token
                |> Maybe.withDefault Cmd.none
            )


initNewFolderNameInput : ( TextInput.Model, Cmd Msg )
initNewFolderNameInput =
    let
        ( nameTextInput, textInputCmd ) =
            TextInput.init "new-folder"
    in
    ( nameTextInput
    , Cmd.map NewFolderTextInputMsg textInputCmd
    )


update : Taco -> Msg -> Model -> PageResult
update taco msg model =
    case msg of
        ToggleCreatingNewFolder isCreating ->
            if isCreating then
                let
                    ( input, cmd ) =
                        initNewFolderNameInput
                in
                CR.withModel
                    { model
                        | creatingNewFolder = True
                        , newFolderName = ""
                    }
                    |> CR.withCmd cmd

            else
                CR.withModel { model | creatingNewFolder = False }

        NewFolderTextInputMsg textInputMsg ->
            TextInput.update textInputMsg model.newFolderTextInput
                |> CR.mapModel (\m -> { model | newFolderTextInput = m })
                |> CR.mapMsg NewFolderTextInputMsg
                |> CR.applyExternalMsg
                    (\ext result ->
                        case ext of
                            TextInput.ValueChanged value ->
                                result |> CR.mapModel (\m -> { m | newFolderName = value })
                    )

        FoldersResponseReceived result ->
            case result of
                Result.Ok folders ->
                    CR.withModel
                        { model
                            | foldersData = Success folders
                        }

                Result.Err err ->
                    CR.withModel
                        { model
                            | foldersData = Failure err
                        }

        _ ->
            CR.withModel
                model


folderView : Model -> String -> H.Html Msg
folderView model folderName =
    H.div [] []


folderListView : Model -> List String -> List (H.Html Msg)
folderListView model folders =
    let
        len =
            List.length folders
    in
    if len /= 0 then
        List.map (folderView model) folders

    else
        [ H.div [] [ H.text "No folders yet" ] ]


loadingView : H.Html Msg
loadingView =
    H.div [] [ H.text "loading folders" ]


view_ : Model -> H.Html Msg
view_ model =
    H.div
        [ A.css
            [ Styles.container ]
        ]
        [ H.div
            [ A.css
                [ position relative
                ]
            ]
            [ H.div
                [ A.css
                    [ position absolute
                    , backgroundColor Styles.white
                    , left (px 0)
                    , right (px 0)
                    , top (px 0)
                    , overflow hidden
                    , if model.creatingNewFolder then
                        Css.batch
                            [ height (px 150)
                            , boxShadow4 (px 1) (px 2) (px 3) (rgba 0 0 0 0.16)
                            ]

                      else
                        Css.batch
                            [ height (px 0)
                            , boxShadow none
                            ]
                    , Transitions.transition
                        [ Transitions.height 250
                        ]
                    ]
                ]
                [ H.div [] []
                , H.div
                    [ A.css
                        [ width (px 200)
                        , displayFlex
                        , justifyContent spaceBetween
                        , margin2 (px 16) auto
                        ]
                    ]
                    [ H.button
                        [ A.css
                            [ Styles.buttonReset
                            ]
                        , E.onClick (ToggleCreatingNewFolder False)
                        ]
                        [ H.text "Cancel"
                        ]
                    , H.button
                        [ A.css
                            [ Styles.buttonReset
                            , Styles.defaultButton
                            ]
                        , E.onClick (ToggleCreatingNewFolder False)
                        ]
                        [ H.text "Submit"
                        ]
                    ]
                ]
            , H.div
                [ A.css
                    [ displayFlex
                    , justifyContent center
                    ]
                ]
                [ H.button
                    [ A.css
                        [ Styles.buttonReset
                        , Styles.defaultButton
                        ]
                    , E.onClick (ToggleCreatingNewFolder True)
                    ]
                    [ H.text "Create New Folder"
                    ]
                ]
            ]

        -- folders list
        , H.div []
            [ H.div []
                (case model.foldersData of
                    Success folders ->
                        folderListView model folders

                    Failure _ ->
                        [ H.div [] [ H.text "failed to load folders" ] ]

                    _ ->
                        [ loadingView ]
                )
            ]
        ]


view =
    view_ >> H.toUnstyled
