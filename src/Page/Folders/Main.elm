module Page.Folders.Main exposing (Model, Msg(..), init, update, view)

import ComponentResult as CR
import Css exposing (..)
import Css.Transitions as Transitions
import Data.Folders exposing (CreateFolderResponse, GetFoldersResponse, createFolder, getFolders)
import Dict
import FormElements.TextInput as TextInput
import Html.Styled as H
import Html.Styled.Attributes as A
import Html.Styled.Events as E
import Http
import Maybe.Extra as M
import Page.Folders.UploadForm as UploadForm
import RemoteData exposing (RemoteData(..), WebData)
import Styles
import Types exposing (Folder, PageMsg(..), Taco, Token)


type alias Model =
    { creatingNewFolder : Bool
    , newFolderName : String
    , newFolderTextInput : TextInput.Model
    , foldersData : WebData GetFoldersResponse
    , folderUploadForms : Dict.Dict String UploadForm.Model
    , expandedFolder : Maybe Folder
    }


type Msg
    = NoOp
    | NewFolderTextInputMsg TextInput.Msg
    | FoldersResponseReceived (Result Http.Error GetFoldersResponse)
    | CreateNewFolderResponseReceived (Result Http.Error CreateFolderResponse)
    | ToggleCreatingNewFolder Bool
    | SubmitCreateFolder Token
    | ExpandFolder (Maybe Folder)
    | UploadFormMsg String UploadForm.Msg


type alias PageResult =
    CR.ComponentResult Model Msg PageMsg Never


init : Taco -> PageResult
init taco =
    CR.withModel
        { creatingNewFolder = False
        , newFolderName = ""
        , newFolderTextInput = Tuple.first <| TextInput.init "new-folder"
        , expandedFolder = Nothing
        , foldersData = Maybe.map (\_ -> Loading) taco.token |> Maybe.withDefault NotAsked
        , folderUploadForms = Dict.empty
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
        UploadFormMsg key uploadFormMsg ->
            Maybe.map
                (\uploadForm ->
                    UploadForm.update uploadFormMsg uploadForm
                        |> CR.mapModel
                            (\newUploadForm ->
                                { model
                                    | folderUploadForms =
                                        Dict.insert key newUploadForm model.folderUploadForms
                                }
                            )
                        |> CR.mapMsg (UploadFormMsg key)
                        |> CR.applyExternalMsg (\extMsg result -> result)
                )
                (Dict.get key model.folderUploadForms)
                |> Maybe.withDefault (CR.withModel model)

        ExpandFolder mFolder ->
            let
                -- reinitialize the expanded upload form
                folderUploadForms =
                    Maybe.map
                        (\folder ->
                            Dict.insert
                                folder.id
                                (UploadForm.init folder)
                                model.folderUploadForms
                        )
                        mFolder
                        |> Maybe.withDefault model.folderUploadForms
            in
            CR.withModel
                { model
                    | expandedFolder = mFolder
                    , folderUploadForms = folderUploadForms
                }

        SubmitCreateFolder token ->
            let
                newModel =
                    { model | creatingNewFolder = False }

                createFolderCmd =
                    createFolder
                        taco
                        CreateNewFolderResponseReceived
                        model.newFolderName
                        token
            in
            CR.withModel newModel
                |> CR.withCmd createFolderCmd

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
                Result.Ok res ->
                    CR.withModel
                        { model
                            | foldersData = Success res
                            , folderUploadForms = Dict.empty
                        }

                Result.Err err ->
                    CR.withModel
                        { model
                            | foldersData = Failure err
                        }

        _ ->
            CR.withModel
                model


folderView : Model -> Folder -> H.Html Msg
folderView model folder =
    let
        expanded =
            Maybe.map (\f -> f.id == folder.id) model.expandedFolder
                |> Maybe.withDefault False

        handleExpand =
            if expanded then
                ExpandFolder Nothing

            else
                ExpandFolder <| Just folder
    in
    H.div
        [ A.css
            [ margin (px 8)
            , boxSizing borderBox
            , borderRadius (px 3)
            , Styles.mediumUp
                [ width (calc (pct 50) minus (px 16))
                ]
            , width (calc (pct 100) minus (px 16))
            , display inlineBlock
            , border3 (px 1) solid Styles.secondary
            ]
        ]
        [ H.div []
            [ H.button
                [ A.css
                    [ Styles.buttonReset
                    , displayFlex
                    , justifyContent spaceBetween
                    , width (pct 100)
                    , padding (px 16)
                    ]
                , E.onClick handleExpand
                ]
                [ H.span []
                    [ H.text folder.name
                    ]
                , H.span
                    []
                    [ H.span
                        [ A.css
                            [ color Styles.primary
                            ]
                        , A.class "fa fa-chevron-down"
                        ]
                        []
                    ]
                ]
            ]
        , H.div
            [ A.css
                [ overflow hidden
                , Transitions.transition
                    [ Transitions.height 300
                    ]
                , batch <|
                    if expanded then
                        [ height (px 150)
                        ]

                    else
                        [ height (px 0)
                        ]
                ]
            ]
            [ Maybe.map
                (UploadForm.view folder >> H.map (UploadFormMsg folder.id))
                (Dict.get folder.id model.folderUploadForms)
                |> Maybe.withDefault (H.text "")
            ]
        ]


folderListView : Model -> List Folder -> List (H.Html Msg)
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


newFolderTextInputProps : Model -> TextInput.Props
newFolderTextInputProps model =
    let
        props =
            TextInput.defaultProps
    in
    { props
        | label = "Folder Name"
        , value = model.newFolderName
        , helperText = Just "(This can be changed later)"
    }


view_ : ( Model, Token ) -> H.Html Msg
view_ ( model, token ) =
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
                [ H.div
                    [ A.css
                        [ displayFlex
                        , justifyContent center
                        , marginTop (px 16)
                        ]
                    ]
                    [ TextInput.view model.newFolderTextInput (newFolderTextInputProps model)
                        |> H.fromUnstyled
                        |> H.map NewFolderTextInputMsg
                    ]
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
                        , A.disabled <| model.newFolderName == ""
                        , E.onClick (SubmitCreateFolder token)
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
                        [ H.div
                            [ A.css
                                [ displayFlex
                                , alignItems flexStart
                                , flexWrap wrap
                                ]
                            ]
                          <|
                            folderListView model folders
                        ]

                    Failure _ ->
                        [ H.div [] [ H.text "failed to load folders" ] ]

                    _ ->
                        [ loadingView ]
                )
            ]
        ]


view =
    view_ >> H.toUnstyled
