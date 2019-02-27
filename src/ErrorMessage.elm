module ErrorMessage exposing (view)

import Css exposing (..)
import Html.Styled as H
import Html.Styled.Attributes as A
import Html.Styled.Events as E
import Styles


view_ : a -> String -> H.Html a
view_ toggleClose message =
    H.div
        [ A.css
            [ position absolute
            , top (px 48)
            , right (px 16)
            , boxShadow4 (px 1) (px 2) (px 3) (rgba 0 0 0 0.1)
            , backgroundColor Styles.white
            , padding2 (px 8) (px 16)
            , color Styles.secondary
            , borderRadius (px 3)
            , border3 (px 1) solid Styles.secondary
            , displayFlex
            , zIndex (int 10000)
            , alignItems center
            ]
        ]
        [ H.i
            [ A.class "fa fa-exclamation-triangle"
            , A.css
                [ fontSize (px 20)
                , paddingRight (px 16)
                ]
            ]
            []
        , H.span [] [ H.text message ]
        , H.button
            [ A.css
                [ Styles.buttonReset
                , color Styles.secondary
                ]
            , E.onClick toggleClose
            ]
            [ H.i
                [ A.class "fa fa-window-close"
                , A.css
                    [ fontSize (px 24)
                    ]
                ]
                []
            ]
        ]


view message =
    view_ message >> H.toUnstyled
