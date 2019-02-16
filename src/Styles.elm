module Styles exposing (baseFontColor, buttonReset, mediumUp)

import Css exposing (..)
import Css.Media


baseFontColor =
    color (rgba 0 0 0 0.86)


buttonReset =
    Css.batch
        [ backgroundColor inherit
        , border (px 0)
        , padding (px 0)
        , margin (px 0)
        , cursor pointer
        , Css.hover
            []
        , Css.focus
            [ outline none
            ]
        ]


mediumUp =
    Css.Media.withMediaQuery
        [ "screen and (min-width: 768px)"
        ]
