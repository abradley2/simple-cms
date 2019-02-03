module Data.Config exposing (ConfigResponse, getConfig)

import Http
import Json.Decode as D
import Types exposing (Flags)


decodeConfig =
    D.map ConfigResponse (D.at [ "oauthUrl" ] D.string)


type alias ConfigResponse =
    { oauthUrl : String
    }


getConfig : Flags -> (Result Http.Error ConfigResponse -> a) -> Cmd a
getConfig flags msg =
    Http.get
        { url = flags.apiUrl ++ "/api/config"
        , expect = Http.expectJson msg decodeConfig
        }
