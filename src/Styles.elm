module Styles exposing (baseFontColor, buttonReset, container, defaultButton, mediumUp, primary, secondary, white)

import Css exposing (..)
import Css.Media


white =
    hex "#fff"


primary =
    hex "#60b5cd"


secondary =
    hex "#646e83"


baseFontColor =
    color (hex "#4a4a4a")


buttonReset =
    Css.batch
        [ backgroundColor inherit
        , border (px 0)
        , padding2 (px 8) (px 16)
        , margin (px 0)
        , cursor pointer
        , fontSize (px 16)
        , Css.hover
            []
        , Css.focus
            [ outline none
            ]
        ]


defaultButton =
    Css.batch
        [ borderRadius (px 3)
        , backgroundColor primary
        , color white
        ]


container =
    Css.batch
        [ maxWidth (px 768)
        , margin auto
        , padding (px 8)
        ]


mediumUp =
    Css.Media.withMediaQuery
        [ "screen and (min-width: 768px)"
        ]


largeUp =
    Css.Media.withMediaQuery
        [ "screen and (min-width: 992px)"
        ]
