module Elements.Button exposing (view)

import Css exposing (..)
import Html.Styled as H
import Html.Styled.Attributes as A
import Styles exposing (buttonReset)


view : List (H.Attribute a) -> List Css.Style -> List (H.Html a) -> H.Html a
view attributes style children =
    H.button
        ([ A.css
            [ buttonReset
            , Css.batch style
            ]
         ]
            ++ attributes
        )
        children
