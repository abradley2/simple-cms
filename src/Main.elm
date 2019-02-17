port module Main exposing (main)

import Browser exposing (Document)
import Browser.Navigation as Navigation
import ComponentResult as CR
import Data.Token exposing (TokenResponse, getToken)
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Navbar
import Page.Folders.Main as FoldersPage
import Page.Upload.Main as UploadPage
import Random
import RemoteData exposing (RemoteData(..), WebData)
import Types exposing (Flags, Taco)
import UUID
import Url
import Url.Builder as Builder
import Url.Parser as Parser exposing ((</>), (<?>))
import Url.Parser.Query as Q


port loadToken : (Maybe String -> msg) -> Sub msg


port storeToken : String -> Cmd msg


port cleanUrl : () -> Cmd msg


type
    Msg
    -- application level messages
    = NoOp
    | TokenResponseReceived (Result Http.Error TokenResponse)
    | LoadStoredToken (Maybe String)
    | OnUrlRequest Browser.UrlRequest
    | OnUrlChange Url.Url
    | GeneratedClientId UUID.UUID
      -- page messages
    | NavbarMsg Navbar.Msg
    | FoldersMsg FoldersPage.Msg
    | UploadMsg UploadPage.Msg


type Page
    = NotFound (Maybe String)
    | Folders FoldersPage.Model
    | Upload UploadPage.Model


type alias Model =
    { flags : Flags
    , key : Navigation.Key
    , url : Url.Url
    , token : WebData (Maybe String) -- TODO: seperate "storedToken" and "token"
    , clientId : Maybe UUID.UUID
    , oauthCode : Maybe String
    , route : Route
    , navbar : Navbar.Model
    , page : Page
    }


getTaco : Model -> Taco
getTaco model =
    { apiUrl = model.flags.apiUrl
    , token = RemoteData.toMaybe model.token |> Maybe.andThen (\v -> v)
    }


type Route
    = HomeRoute (Maybe String)
    | FoldersRoute
    | UploadRoute
    | NotFoundRoute


urlToRoute : Url.Url -> Route
urlToRoute url =
    Parser.parse
        (Parser.oneOf
            [ Parser.map HomeRoute (Parser.top <?> Q.string "code")
            , Parser.map FoldersRoute (Parser.s "folders")
            , Parser.map UploadRoute (Parser.s "upload")
            ]
        )
        url
        |> Maybe.withDefault NotFoundRoute


routeToPage : Flags -> Model -> Route -> ( Model, Cmd Msg )
routeToPage flags model route =
    case route of
        FoldersRoute ->
            FoldersPage.init flags
                |> CR.mapModel (\pageModel -> { model | page = Folders pageModel })
                |> CR.mapMsg FoldersMsg
                |> CR.applyExternalMsg (\ext result -> result)
                |> CR.resolve

        UploadRoute ->
            UploadPage.init flags
                |> CR.mapModel (\pageModel -> { model | page = Upload pageModel })
                |> CR.mapMsg UploadMsg
                |> CR.applyExternalMsg (\ext result -> result)
                |> CR.resolve

        _ ->
            ( { model
                | page = NotFound Nothing
              }
            , Cmd.none
            )


init : Flags -> Url.Url -> Navigation.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        -- get our initial route
        route =
            urlToRoute url

        -- check if this is an oauth redirect
        oauthCode =
            case route of
                HomeRoute c ->
                    c

                _ ->
                    Nothing

        -- if this is an oauth redirect we should clean the url so a refresh doesn't
        -- trigger re-using a token, which will result in an error
        cleanUrlCmd =
            Maybe.map (\_ -> cleanUrl ()) oauthCode
                |> Maybe.withDefault Cmd.none

        initModel =
            { flags = flags
            , key = key
            , url = url
            , token = Loading
            , clientId = Nothing
            , oauthCode = oauthCode
            , route = route
            , navbar = Navbar.init
            , page = NotFound Nothing
            }

        ( model, pageCmd ) =
            routeToPage flags initModel route
    in
    ( model
    , Cmd.batch
        [ pageCmd

        -- uuid for clientId or "state" variable. We can use this for oauth
        , Random.generate GeneratedClientId UUID.generator

        -- clean query params from the url if we have to
        , cleanUrlCmd
        ]
    )


loadedView : Model -> Maybe String -> Html Msg
loadedView model mToken =
    div []
        [ case mToken of
            Just token ->
                case model.page of
                    Folders foldersPage ->
                        FoldersPage.view foldersPage
                            |> Html.map FoldersMsg

                    Upload uploadPage ->
                        UploadPage.view uploadPage
                            |> Html.map UploadMsg

                    _ ->
                        div [] [ text "hello there" ]

            Nothing ->
                let
                    oauthUrl =
                        model.flags.oauthUrl ++ "&redirect_uri=" ++ model.flags.origin
                in
                div []
                    [ a [ href oauthUrl ] [ text "please authenticate with Github" ]
                    ]
        ]


view : Model -> Document Msg
view model =
    { title = "hi"
    , body =
        [ Html.map NavbarMsg (Navbar.view model.navbar)
        , div [ class "has-navbar-fixed-top" ]
            [ div [ class "section" ]
                [ div
                    [ class "container"
                    ]
                    [ RemoteData.map (loadedView model)
                        model.token
                        |> RemoteData.withDefault (div [] [ text "loading!" ])
                    ]
                ]
            ]
        ]
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LoadStoredToken result ->
            ( { model | token = Success result }, Cmd.none )

        OnUrlRequest req ->
            case req of
                Browser.External url ->
                    ( model, Navigation.load url )

                Browser.Internal url ->
                    ( model, Navigation.pushUrl model.key <| Url.toString url )

        OnUrlChange url ->
            urlToRoute url
                |> routeToPage model.flags model

        TokenResponseReceived result ->
            case result of
                Result.Ok tokenResponse ->
                    ( { model
                        | token = Success <| Just tokenResponse.token
                      }
                    , storeToken tokenResponse.token
                    )

                Result.Err err ->
                    ( { model
                        | token = Failure err
                      }
                    , Cmd.none
                    )

        GeneratedClientId clientId ->
            let
                getTokenCmd =
                    Maybe.map
                        (\code ->
                            getToken model.flags
                                { code = code, state = clientId }
                                TokenResponseReceived
                        )
                        model.oauthCode
                        |> Maybe.withDefault Cmd.none
            in
            ( { model | clientId = Just clientId }, getTokenCmd )

        NavbarMsg navbarMsg ->
            Navbar.update model.flags navbarMsg model.navbar
                |> CR.mapModel (\navbar -> { model | navbar = navbar })
                |> CR.mapMsg NavbarMsg
                |> CR.applyExternalMsg (\ext result -> result)
                |> CR.resolve

        _ ->
            ( model, Cmd.none )


updatePage : Msg -> Model -> ( Model, Cmd Msg )
updatePage msg model =
    case ( model.page, msg ) of
        ( Folders foldersPage, FoldersMsg foldersMsg ) ->
            FoldersPage.update model.flags foldersMsg foldersPage
                |> CR.mapModel (\page -> { model | page = Folders page })
                |> CR.mapMsg FoldersMsg
                |> CR.applyExternalMsg (\ext result -> result)
                |> CR.resolve

        ( Upload uploadPage, UploadMsg uploadMsg ) ->
            UploadPage.update model.flags uploadMsg uploadPage
                |> CR.mapModel (\page -> { model | page = Upload page })
                |> CR.mapMsg UploadMsg
                |> CR.applyExternalMsg (\ext result -> result)
                |> CR.resolve

        _ ->
            ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Maybe.map (\_ -> Sub.none) model.oauthCode
            |> Maybe.withDefault (loadToken LoadStoredToken)
        ]


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update =
            \msg model ->
                let
                    ( newModel, cmd ) =
                        update msg model
                in
                updatePage msg newModel
                    |> Tuple.mapSecond (\pageCmd -> Cmd.batch [ cmd, pageCmd ])
        , onUrlChange = OnUrlChange
        , onUrlRequest = OnUrlRequest
        , subscriptions = subscriptions
        }
