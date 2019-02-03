port module Main exposing (main)

import Browser exposing (Document)
import Browser.Navigation as Navigation
import Data.Config exposing (ConfigResponse, getConfig)
import Data.Token exposing (TokenResponse, getToken)
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Random
import RemoteData exposing (RemoteData(..), WebData)
import Types exposing (Flags)
import UUID
import Url
import Url.Builder as Builder
import Url.Parser as Parser exposing ((</>), (<?>))
import Url.Parser.Query as Q


port loadToken : (Maybe String -> msg) -> Sub msg


port storeToken : String -> Cmd msg


port cleanUrl : () -> Cmd msg


type Msg
    = NoOp
    | ConfigResponseReceived (Result Http.Error ConfigResponse)
    | TokenResponseReceived (Result Http.Error TokenResponse)
    | LoadStoredToken (Maybe String)
    | OnUrlRequest Browser.UrlRequest
    | GeneratedClientId UUID.UUID


type alias Model =
    { flags : Flags
    , key : Navigation.Key
    , url : Url.Url
    , config : WebData ConfigResponse
    , token : WebData (Maybe String) -- TODO: seperate "storedToken" and "token"
    , clientId : Maybe UUID.UUID
    , oauthCode : Maybe String
    , route : Route
    }


type Route
    = HomeRoute (Maybe String)
    | NotFoundRoute


urlToRoute : Url.Url -> Route
urlToRoute url =
    Parser.parse
        (Parser.oneOf
            [ Parser.map HomeRoute (Parser.top <?> Q.string "code")
            ]
        )
        url
        |> Maybe.withDefault NotFoundRoute


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
    in
    ( { flags = flags
      , key = key
      , url = url
      , config = Loading
      , token = Loading
      , clientId = Nothing
      , oauthCode = oauthCode
      , route = route
      }
    , Cmd.batch
        [ -- load any server based configuration variables
          getConfig flags ConfigResponseReceived

        -- uuid for clientId or "state" variable. We can use this for oauth
        , Random.generate GeneratedClientId UUID.generator

        -- clean query params from the url if we have to
        , cleanUrlCmd
        ]
    )


loadedView : Model -> ConfigResponse -> Maybe String -> Html Msg
loadedView model config mToken =
    div []
        [ case mToken of
            Just token ->
                div [] [ text "Welcome back" ]

            Nothing ->
                let
                    oauthUrl =
                        config.oauthUrl ++ "&redirect_uri=" ++ model.flags.origin
                in
                div []
                    [ a [ href oauthUrl ] [ text "please authenticate with Github" ]
                    ]
        ]


view : Model -> Document Msg
view model =
    { title = "hi"
    , body =
        [ nav [ class "navbar" ]
            [ div
                [ class "navbar-menu is-active" ]
                [ div [ class "navbar-start" ]
                    [ a [ href "/", class "navbar-item" ] [ text "Home" ]
                    , a [ href "/", class "navbar-item" ] [ text "Search" ]
                    , a [ href "/", class "navbar-item" ] [ text "Store" ]
                    ]
                ]
            ]
        , div [ class "section" ]
            [ div
                [ class "container"
                ]
                [ RemoteData.map2
                    (loadedView model)
                    model.config
                    model.token
                    |> RemoteData.withDefault (div [] [ text "loading!" ])
                ]
            ]
        ]
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ConfigResponseReceived result ->
            let
                newModel =
                    case result of
                        Result.Ok configResponse ->
                            { model | config = Success configResponse }

                        Result.Err err ->
                            { model | config = Failure err }
            in
            ( newModel, Cmd.none )

        LoadStoredToken result ->
            ( { model | token = Success result }, Cmd.none )

        OnUrlRequest req ->
            case req of
                Browser.External url ->
                    ( model, Navigation.load url )

                Browser.Internal url ->
                    ( model, Cmd.none )

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
        , update = update
        , onUrlChange = \_ -> NoOp
        , onUrlRequest = OnUrlRequest
        , subscriptions = subscriptions
        }
