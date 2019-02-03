const test = require('tape')
const defer = require('lodash.defer')
const config = require('config')
const { setup } = require('@cycle/run')
const xs = require('xstream').default
const { tags, handler } = require('./oauth.js')
const { testDrivers } = require('./util/test')

test('it should return a github auth token', (t) => {
  t.timeoutAfter(50)
  t.plan(1)

  const TOKEN = Symbol('token')

  const req = {
    body: {
      code: 'code',
      state: 'state',
      redirectUrl: 'http://fake.com'
    }
  }

  const drivers = testDrivers({
    HTTP: xs.fromArray([
      xs.of({
        category: tags.GET_ACCESS_TOKEN,
        body: {
          access_token: 'access_token'
        }
      }),
      xs.of({
        category: tags.GET_USER,
        body: {
          id: 12345
        }
      })
    ]),
    EFFECT: xs.fromArray([
      {
        tag: tags.GET_JWT,
        error: null,
        value: TOKEN
      }
    ])
  })

  const { sinks, run } = setup(handler(req, config), drivers)

  defer(run())

  sinks.RESPONSE
    .take(1)
    .subscribe({
      next (res) {
        t.equals(res.body.token, TOKEN)
      }
    })
})

test('endpoint should return 400 for an invalid request', (t) => {
  t.plan(1)
  t.timeoutAfter(50)

  const req = {
    body: {}
  }

  const drivers = testDrivers({})

  const { sinks, run } = setup(handler(req, config), drivers)

  defer(run())

  sinks.RESPONSE
    .take(1)
    .subscribe({
      next (res) {
        t.equals(res.status, 400)
      }
    })
})

test('endpoint should return 500 if github user request fails', (t) => {
  t.plan(1)
  t.timeoutAfter(50)

  const req = {
    body: {
      code: 'code',
      state: 'state',
      redirectUrl: 'http://fake.com'
    }
  }

  const userError = Object.assign(new Error('failed to get user'), {
    category: tags.GET_USER
  })

  const drivers = testDrivers({
    HTTP: xs.fromArray([
      xs.of({
        category: tags.GET_ACCESS_TOKEN,
        body: {
          access_token: 'access_token'
        }
      }),
      xs.of(userError)
    ]),
    EFFECT: xs.empty()
  })

  const { sinks, run } = setup(handler(req, config), drivers)

  defer(run())

  sinks.RESPONSE
    .take(1)
    .subscribe({
      next (res) {
        t.equals(res.status, 500)
      }
    })
})

test('endpoint should return 500 if access token request fails', (t) => {
  t.plan(1)
  t.timeoutAfter(50)

  const req = {
    body: {
      code: 'code',
      state: 'state',
      redirectUrl: 'http://fake.com'
    }
  }

  const accessTokenError = Object.assign(new Error(), {
    category: tags.GET_ACCESS_TOKEN
  })

  const drivers = testDrivers({
    HTTP: xs.fromArray([
      xs.of(accessTokenError),
      xs.throw(new Error('should not make any requests after failed access token request'))
    ]),
    EFFECT: xs.empty()
  })

  const { sinks, run } = setup(handler(req, config), drivers)

  defer(run())

  sinks.RESPONSE
    .take(1)
    .subscribe({
      next (res) {
        t.equals(res.status, 500)
      }
    })
})
