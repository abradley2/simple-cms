const config = require('dotenv').config().parsed
const fs = require('fs')
const path = require('path')
const logger = require('pino')()
const { setup } = require('@cycle/run')
const express = require('express')
const makeEFFECTSDrivers = require('@abradley2/cycle-effects')
const { makeHTTPDriver } = require('@cycle/http')
const ecstatic = require('ecstatic')
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
  '/folders',
  createHandler(require('./handlers/folders').post)
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

server.listen(process.env.PORT, function () {
  logger.info(`Server listening on port ${process.env.PORT}`)
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

function serveIndex (req, res) {
  res.set('Content-Type', 'text/html')
  readIndex
    .then(page => {
      res.status(200).send(page)
    })
    .catch(err => {
      logger.error(err)
      res.status(500).send('error reading index')
    })
}
