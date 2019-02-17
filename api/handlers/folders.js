const dbEffects = require('../effects/nano')
const xs = require('xstream').default

const tags = {
  CREATE_FOLDER: 'CREATE_FOLDER',
  GET_FOLDERS: 'GET_FOLDERS'
}

exports.get = (req, config) => ({ EFFECT, HTTP }) => {
  const effect$ = xs.of({
    run: dbEffects.getFolders(),
    tag: tags.GET_FOLDERS
  })

  const log$ = xs.merge(
    EFFECT.selectError(tags.GET_FOLDERS)
      .map((error) => ({
        method: 'error',
        args: [error, 'error getting folders from db']
      }))
  )

  const response$ = xs.merge(
    EFFECT.select(tags.GET_FOLDERS)
      .map(({ error, value }) => {
        if (error) {
          return {
            status: 500,
            body: {
              message: error.message
            }
          }
        }
        return {
          status: 200,
          body: value
        }
      })
  )

  return {
    RESPONSE: response$,
    HTTP: xs.empty(),
    EFFECT: effect$,
    LOG: log$
  }
}

exports.post = (req, config) => ({ EFFECT, HTTP }) => {
  const effect$ = xs.of({
    tag: tags.CREATE_FOLDER,
    run: dbEffects.createFolder(req.body.name)
  })

  const response$ = EFFECT
    .select(tags.CREATE_FOLDER)
    .map(({ value, error }) => {
      if (error) {
        return {
          status: 500,
          body: {
            message: error.message
          }
        }
      }
      return {
        status: 200,
        body: {
          guid: value.id,
          name: req.body.name
        }
      }
    })

  const log$ = xs.merge(
    xs.of({
      method: 'info',
      args: ['creating folder: ' + req.body.name]
    }),
    EFFECT.selectError(tags.CREATE_FOLDER)
      .map((error) => {
        return {
          method: 'error',
          args: [error]
        }
      })
  )

  return {
    RESPONSE: response$,
    HTTP: xs.empty(),
    EFFECT: effect$,
    LOG: log$
  }
}
