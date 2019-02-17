module Types exposing (Flags, PageMsg(..), Taco)


type alias Flags =
    { oauthUrl : String
    , apiUrl : String
    , origin : String
    }


type alias Taco =
    { apiUrl : String
    , token : Maybe String
    }


type PageMsg
    = NoOpExternal
