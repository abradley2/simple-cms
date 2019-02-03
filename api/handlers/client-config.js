const xs = require('xstream').default
const qs = require('query-string')

const handler = (_, config) => () => {
  const params = qs.stringify({
    client_id: config.ghClientId
  })

  const oauthUrl = `https://github.com/login/oauth/authorize?${params}`

  const response$ = xs.of({
    status: 200,
    contentType: 'application/json',
    body: {
      oauthUrl
    }
  })

  const log$ = xs.merge(
    xs.of({
      method: 'info',
      args: ['Config request received']
    }),
    response$
      .map((res) => ({
        method: 'info',
        args: [`Config request finished with status: ${res.status}`]
      }))
  )

  return {
    RESPONSE: response$,
    LOG: log$
  }
}

module.exports = { handler }
