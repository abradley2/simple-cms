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
import Types exposing (Flags, PageMsg(..), Taco, Token, stringToToken)
import UUID
import Url
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
    , token : WebData String

    -- delineating token as loaded from browser storage for simplicity sake
    , storedToken : RemoteData String String
    , clientId : Maybe UUID.UUID
    , oauthCode : Maybe String
    , route : Route
    , navbar : Navbar.Model
    , page : Page
    }


getTaco : Model -> Taco
getTaco model =
    { apiUrl = model.flags.apiUrl
    , token = RemoteData.toMaybe model.token |> Maybe.map stringToToken
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


routeToPage : Model -> Route -> ( Model, Cmd Msg )
routeToPage model route =
    case route of
        FoldersRoute ->
            FoldersPage.init (getTaco model)
                |> CR.mapModel (\pageModel -> { model | page = Folders pageModel })
                |> CR.mapMsg FoldersMsg
                |> CR.applyExternalMsg (\ext result -> result)
                |> CR.resolve

        UploadRoute ->
            UploadPage.init (getTaco model)
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
            , token = NotAsked
            , storedToken = Loading
            , clientId = Nothing
            , oauthCode = oauthCode
            , route = route
            , navbar = Navbar.init
            , page = NotFound Nothing
            }

        ( model, pageCmd ) =
            routeToPage initModel route
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


loadedView : Model -> Token -> Html Msg
loadedView model token =
    div []
        [ case model.page of
            Folders foldersPage ->
                FoldersPage.view ( foldersPage, token )
                    |> Html.map FoldersMsg

            Upload uploadPage ->
                UploadPage.view ( uploadPage, token )
                    |> Html.map UploadMsg

            _ ->
                div [] [ text "hello there" ]
        ]


loginView : Model -> Html Msg
loginView model =
    let
        oauthUrl =
            model.flags.oauthUrl ++ "&redirect_uri=" ++ model.flags.origin
    in
    div []
        [ a [ href oauthUrl ] [ text "please authenticate with Github" ]
        ]


view : Model -> Document Msg
view model =
    { title = "Tony's Simple Content Storage"
    , body =
        [ Html.map NavbarMsg (Navbar.view model.navbar)
        , div [ style "margin-top" "48px" ]
            [ case ( model.token, model.storedToken ) of
                ( Success token, _ ) ->
                    loadedView model (stringToToken token)

                ( _, Failure _ ) ->
                    loginView model

                _ ->
                    div [] [ text "loading" ]
            ]
        ]
    }


type alias AppResult =
    CR.ComponentResult Model Msg Never Never


handlePageMsg : PageMsg -> AppResult -> AppResult
handlePageMsg msg result =
    result


updateApplication : Msg -> Model -> ( Model, Cmd Msg )
updateApplication msg model =
    case msg of
        LoadStoredToken result ->
            ( { model
                | storedToken =
                    Maybe.map Success result
                        |> Maybe.withDefault (Failure "not found")

                -- if we found a token on storage, copy it over to the token
                , token =
                    Maybe.map Success result
                        |> Maybe.withDefault NotAsked
              }
            , Maybe.map
                -- refresh if we have a token
                (\_ -> Navigation.replaceUrl model.key <| Url.toString model.url)
                result
                |> Maybe.withDefault Cmd.none
            )

        OnUrlRequest req ->
            case req of
                Browser.External url ->
                    ( model, Navigation.load url )

                Browser.Internal url ->
                    ( model, Navigation.pushUrl model.key <| Url.toString url )

        OnUrlChange url ->
            urlToRoute url
                |> routeToPage model

        TokenResponseReceived result ->
            case result of
                Result.Ok tokenResponse ->
                    ( { model
                        | token = Success tokenResponse.token
                      }
                    , Cmd.batch
                        [ storeToken tokenResponse.token

                        -- refresh if we have a token
                        , Navigation.replaceUrl model.key (Url.toString model.url)
                        ]
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
                |> CR.applyExternalMsg handlePageMsg
                |> CR.resolve

        _ ->
            ( model, Cmd.none )


updatePage : Msg -> Model -> ( Model, Cmd Msg )
updatePage msg model =
    case ( model.page, msg ) of
        ( Folders foldersPage, FoldersMsg foldersMsg ) ->
            FoldersPage.update (getTaco model) foldersMsg foldersPage
                |> CR.mapModel (\page -> { model | page = Folders page })
                |> CR.mapMsg FoldersMsg
                |> CR.applyExternalMsg (\ext result -> result)
                |> CR.resolve

        ( Upload uploadPage, UploadMsg uploadMsg ) ->
            UploadPage.update (getTaco model) uploadMsg uploadPage
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
                        updateApplication msg model
                in
                updatePage msg newModel
                    |> Tuple.mapSecond (\pageCmd -> Cmd.batch [ cmd, pageCmd ])
        , onUrlChange = OnUrlChange
        , onUrlRequest = OnUrlRequest
        , subscriptions = subscriptions
        }
