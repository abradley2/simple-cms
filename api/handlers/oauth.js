const xs = require('xstream').default
const createValidator = require('is-my-json-valid')
const qs = require('query-string')
const userEffects = require('../effects/user')
const { selectResponse } = require('./util/http')

const tags = {
  GET_ACCESS_TOKEN: 'GET_ACCESS_TOKEN',
  GET_USER: 'GET_USER',
  GET_JWT: 'GET_JWT'
}

const validator = createValidator({
  type: 'object',
  required: true,
  properties: {
    code: {
      type: 'string',
      required: true
    },
    state: {
      type: 'string',
      required: true
    },
    redirectUrl: {
      type: 'string',
      required: true
    }
  }
})

const handler = (req, config) => ({ EFFECT, HTTP }) => {
  const isValid = validator(req.body)

  if (!isValid) {
    return {
      LOG: xs.empty(),
      EFFECT: xs.empty(),
      HTTP: xs.empty(),
      RESPONSE: xs.of({
        status: 400,
        body: validator.errors
      })
    }
  }

  const { code, redirectUrl, state } = req.body

  const tokenRequestParams = qs.stringify({
    client_id: config.ghClientId,
    client_secret: config.ghClientSecret,
    code,
    state,
    redirect_uri: redirectUrl
  })

  const getTokenRequest$ = xs.of({
    category: tags.GET_ACCESS_TOKEN,
    method: 'POST',
    url: `https://github.com/login/oauth/access_token?${tokenRequestParams}`
  })

  const getTokenResponse$ = selectResponse(HTTP, tags.GET_ACCESS_TOKEN)

  const getUserRequest$ = getTokenResponse$
    .filter(({ error }) => !error)
    .map(({ response }) => {
      return {
        category: tags.GET_USER,
        method: 'GET',
        url: 'https://api.github.com/user',
        headers: {
          'Authorization': `token ${response.body.access_token}`
        }
      }
    })

  const getUserResponse$ = selectResponse(HTTP, tags.GET_USER)

  const getJwt$ =
    xs.combine(
      getUserResponse$.filter(({ error }) => !error),
      getTokenResponse$.filter(({ error }) => !error)
    )
      .map(([userResult, tokenResult]) => {
        const userResponse = userResult.response.body
        const tokenResponse = tokenResult.response.body

        return {
          tag: tags.GET_JWT,
          run: userEffects.getUserToken(config, {
            userInfo: userResponse,
            accessToken: tokenResponse.access_token
          })
        }
      })

  const http$ = xs.merge(
    getTokenRequest$,
    getUserRequest$
  )

  const effect$ = getJwt$

  const error$ = xs.merge(
    selectResponse(HTTP)
      .filter(({ error }) => !!error)
      .map(({ error }) => error),
    EFFECT.selectError(tags.GET_USER)
  )

  const response$ = xs.merge(
    error$.map((e) => {
      return {
        status: 500,
        body: {
          message: 'internal server error'
        }
      }
    }),
    EFFECT.selectValue(tags.GET_JWT).map((token) => {
      return {
        status: 200,
        body: { token }
      }
    })
  )

  const log$ = xs.merge(
    error$.map((err) => {
      const args = err.response
        ? [err.status, err.response.body]
        : [err]

      return {
        method: 'error',
        args
      }
    })
  )

  return {
    RESPONSE: response$,
    HTTP: http$,
    EFFECT: effect$,
    LOG: log$
  }
}

module.exports = {
  tags,
  handler
}
