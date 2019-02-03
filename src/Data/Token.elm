module Data.Token exposing (TokenResponse, getToken)

import Http
import Json.Decode as D
import Json.Encode as E
import Types exposing (Flags)
import UUID


type alias TokenResponse =
    { token : String
    }


decodeTokenResponse =
    D.map TokenResponse
        (D.at [ "token" ] D.string)


type alias GetTokenArgs =
    { state : UUID.UUID
    , code : String
    }


getToken : Flags -> GetTokenArgs -> (Result Http.Error TokenResponse -> a) -> Cmd a
getToken flags args msg =
    Http.post
        { url = flags.apiUrl ++ "/api/oauth"
        , expect = Http.expectJson msg decodeTokenResponse
        , body =
            Http.jsonBody
                (E.object
                    [ ( "code", E.string args.code )
                    , ( "state", E.string <| UUID.toString args.state )
                    , ( "redirectUrl", E.string flags.origin )
                    ]
                )
        }
