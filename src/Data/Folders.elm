module Data.Folders exposing (CreateFolderResponse, GetFoldersResponse, createFolder, getFolders)

import Http
import Json.Decode as D
import Json.Encode as E
import Types exposing (Taco, Token, tokenToString)


decodeFoldersResponse =
    D.list D.string


type alias GetFoldersResponse =
    List String


getFolders : Taco -> (Result Http.Error GetFoldersResponse -> a) -> Token -> Cmd a
getFolders taco msg token =
    Http.request
        { method = "GET"
        , url = taco.apiUrl ++ "/api/folders"
        , body = Http.emptyBody
        , expect = Http.expectJson msg decodeFoldersResponse
        , headers =
            [ Http.header "Authorization" <| "Bearer " ++ tokenToString token
            ]
        , tracker = Nothing
        , timeout = Nothing
        }


type alias CreateFolderResponse =
    { guid : String
    , folderName : String
    }


decodeCreateFolderResponse =
    D.map2 CreateFolderResponse
        (D.at [ "guid" ] D.string)
        (D.at [ "folderName" ] D.string)


createFolder : Taco -> (Result Http.Error CreateFolderResponse -> a) -> String -> Token -> Cmd a
createFolder taco msg folderName token =
    Http.request
        { method = "POST"
        , url = taco.apiUrl ++ "/api/folders"
        , body =
            Http.jsonBody <|
                E.object
                    [ ( "name", E.string folderName )
                    ]
        , expect = Http.expectJson msg decodeCreateFolderResponse
        , headers =
            [ Http.header "Authorization" <| "Bearer " ++ tokenToString token
            ]
        , tracker = Nothing
        , timeout = Nothing
        }
