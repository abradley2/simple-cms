module Types exposing (Flags, Taco)


type alias Flags =
    { oauthUrl : String
    , apiUrl : String
    , origin : String
    }


type alias Taco =
    { apiUrl : String
    , token : Maybe String
    }
