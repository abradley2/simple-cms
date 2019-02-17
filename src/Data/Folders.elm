module Data.Folders exposing (GetFoldersResponse, getFolders)

import Http
import Json.Decode as D
import Json.Encode as E
import Types exposing (Flags)


decodeFoldersResponse =
    D.list D.string


type alias GetFoldersResponse =
    List String


getFolders : Flags -> String -> (Result Http.Error GetFoldersResponse -> a) -> Cmd a
getFolders flags token msg =
    Http.request
        { method = "GET"
        , url = flags.apiUrl ++ "/folders"
        , body = Http.emptyBody
        , expect = Http.expectJson msg decodeFoldersResponse
        , headers =
            [ Http.header "Authorization" <| "Bearer " ++ token
            ]
        , tracker = Nothing
        , timeout = Nothing
        }
