module Navbar exposing (Model, Msg(..), init, update, view)

import ComponentResult as CR
import Css exposing (..)
import Css.Transitions as T
import Html.Styled as H
import Html.Styled.Attributes as A
import Html.Styled.Events as E
import Styles exposing (baseFontColor, buttonReset, mediumUp)
import Types exposing (Flags, PageMsg(..))


type Msg
    = ToggleNavbar Bool


type alias Model =
    { showNavbar : Bool
    }


type alias NavbarResult =
    CR.ComponentResult Model Msg PageMsg Never


init : Model
init =
    { showNavbar = False
    }


update : Flags -> Msg -> Model -> NavbarResult
update flags msg model =
    case msg of
        ToggleNavbar showNavbar ->
            CR.withModel { model | showNavbar = showNavbar }


linkCss : Css.Style
linkCss =
    Css.batch
        [ lineHeight (px 40)
        , display block
        , height (px 40)
        , padding2 (px 0) (px 14)
        , cursor pointer
        , fontSize (px 16)
        , baseFontColor
        , textDecoration none
        , textAlign center
        , hover
            [ backgroundColor (rgba 0 0 0 0.08)
            ]
        ]


navs : List (H.Html Msg)
navs =
    [ H.a
        [ A.href "/"
        , A.css [ linkCss ]
        , E.onClick <| ToggleNavbar False
        ]
        [ H.text "Home"
        ]
    , H.a
        [ A.href "/folders"
        , A.css [ linkCss ]
        , E.onClick <| ToggleNavbar False
        ]
        [ H.text "Folders"
        ]
    , H.a
        [ A.href "/upload"
        , A.css [ linkCss ]
        , E.onClick <| ToggleNavbar False
        ]
        [ H.text "Upload"
        ]
    ]


navToggle : Model -> H.Html Msg
navToggle model =
    H.span
        [ A.css
            [ linkCss
            ]
        ]
        [ H.button
            [ A.css
                [ buttonReset
                , linkCss
                , padding (px 0)
                , width (pct 100)
                ]
            , E.onClick (ToggleNavbar <| not model.showNavbar)
            ]
            [ H.text "Menu"
            ]
        ]


view_ : Model -> H.Html Msg
view_ model =
    H.div []
        [ -- mediumDown navbar
          H.div
            [ A.css
                [ mediumUp
                    [ display none
                    ]
                , displayFlex
                , flexFlow1 column
                , alignItems stretch
                , position fixed
                , left (px 0)
                , right (px 0)
                , top (px 0)
                , backgroundColor (rgb 255 255 255)
                , zIndex (int 100)
                , T.transition
                    [ T.height 250
                    ]
                , height <|
                    if model.showNavbar then
                        px (List.length navs * 40 + 40 |> toFloat)

                    else
                        px 40
                , overflow hidden
                , boxShadow4 (px 1) (px 2) (px 3) (rgba 0 0 0 0.1)
                ]
            ]
            (navToggle model :: navs)
        , -- mediumUp navbar
          H.div
            [ A.css
                [ position fixed
                , height (px 40)
                , left (px 0)
                , right (px 0)
                , top (px 0)
                , boxShadow4 (px 1) (px 2) (px 3) (rgba 0 0 0 0.1)
                , display none
                , mediumUp
                    [ display initial
                    ]
                ]
            ]
            [ H.div
                [ A.css
                    [ displayFlex
                    , alignItems stretch
                    , justifyContent flexStart
                    , height (px 40)
                    ]
                ]
                navs
            ]
        ]


view =
    view_ >> H.toUnstyled
