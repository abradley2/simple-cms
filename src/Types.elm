module Types exposing (Flags, Folder, PageMsg(..), Taco, Token, stringToToken, tokenToString)


type alias Flags =
    { oauthUrl : String
    , apiUrl : String
    , origin : String
    }


type Token
    = Token String


stringToToken : String -> Token
stringToToken str =
    Token str


tokenToString : Token -> String
tokenToString token =
    case token of
        Token t ->
            t


type alias Taco =
    { apiUrl : String
    , token : Maybe Token
    }


type PageMsg
    = NoOpExternal
    | ShowErrorMsg String


type alias Folder =
    { id : String
    , name : String
    , files : List FolderFile
    , tags : List String
    }


type alias FolderFile =
    { id : String
    , name : String
    }
