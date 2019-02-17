module Data.Folders exposing (GetFoldersResponse, getFolders)

import Http
import Json.Decode as D
import Json.Encode as E
import Types exposing (Taco)


decodeFoldersResponse =
    D.list D.string


type alias GetFoldersResponse =
    List String


getFolders : Taco -> (Result Http.Error GetFoldersResponse -> a) -> String -> Cmd a
getFolders taco msg token =
    Http.request
        { method = "GET"
        , url = taco.apiUrl ++ "/api/folders"
        , body = Http.emptyBody
        , expect = Http.expectJson msg decodeFoldersResponse
        , headers =
            [ Http.header "Authorization" <| "Bearer " ++ token
            ]
        , tracker = Nothing
        , timeout = Nothing
        }
