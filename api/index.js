require('dotenv').config()
const fs = require('fs')
const path = require('path')
const logger = require('pino')()
const { setup } = require('@cycle/run')
const config = require('config')
const express = require('express')
const makeEFFECTSDrivers = require('@abradley2/cycle-effects')
const { makeHTTPDriver } = require('@cycle/http')
const ecstatic = require('ecstatic')
const createValidator = require('is-my-json-valid')
const qs = require('query-string')
const uuid = require('uuid')
const bodyParser = require('body-parser')
const cors = require('cors')
const server = express()

const api = express.Router()

if (process.env.NODE_ENV === 'development') server.use(cors())

api.use(bodyParser.json())

server.use('/api', api)

api.get(
  '/folders',
  createHandler(require('./handlers/folders').get)
)

api.post(
  '/oauth',
  createHandler(require('./handlers/oauth').handler)
)

server.use((req, res, next) => {
  if (req.path.includes('.')) {
    return next()
  }
  serveIndex(req, res)
})

server.use(ecstatic({
  root: path.join(__dirname, '../dist')
}))

const configValidation = createValidator(
  require('../config/config-schema'),
  { verbose: true }
)

configValidation(config)

if (configValidation.errors && configValidation.errors.length) {
  const error = new Error('Failed to launch, config invalid')
  logger.error(error)
  logger.info(JSON.stringify(configValidation.errors, null, 2))
  process.exit()
}

const port = config.get('port')
server.listen(port, function () {
  logger.info(`Server listening on port ${port}`)
})

function createHandler (handler) {
  return (req, res) => {
    const requestId = uuid.v4()
    const requestLogger = logger.child({ requestId })

    const drivers = {
      EFFECT: makeEFFECTSDrivers(),
      HTTP: makeHTTPDriver()
    }

    const { run, sinks } = setup(handler(req, config), drivers)
    const dispose = run()

    sinks.LOG
      .subscribe({
        next ({ method, args }) {
          requestLogger[method](...args)
        }
      })

    sinks.RESPONSE.take(1)
      .subscribe({
        next (v) {
          res.set('Content-Type', v.contentType || 'application/json')
          res.status(v.status).send(v.body)
        },
        error (err) {
          logger.error(err)
          res.status(500).send('Internal Server error')
        },
        complete () {
          dispose()
        }
      })
  }
}

const readIndex = new Promise((resolve, reject) => {
  fs.readFile(path.join(__dirname, '../dist/index.html'), 'utf8', (err, data) => {
    if (err) return reject(err)
    return resolve(data)
  })
})

function serveIndex(req, res) {
  res.set('Content-Type', 'text/html')
  readIndex
    .then(page =>  {
      res.status(200).send(page)
    })
    .catch(err => {
      logger.error(err)
      res.status(500).send('error reading index')
    })
}
