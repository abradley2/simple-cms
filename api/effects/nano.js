const uuid = require('uuid/v4')
const FOLDERS_DB = 'folders'

const ready = new Promise((resolve) => {
  let nano
  function setup () {
    nano = require('nano')(process.env.COUCH_DB_URL)

    nano.db.list()
      .then((dbs) => {
        if (!dbs.includes(FOLDERS_DB)) {
          return nano.db.create(FOLDERS_DB)
            .then(() => resolve(nano.db.use(FOLDERS_DB)))
        }
        return resolve(nano.db.use(FOLDERS_DB))
      })
  }

  if (process.env.NODE_ENV !== 'test') {
    setup()
    return
  }
  resolve()
})

exports.getFolders = () => () => ready.then((db) => {
  return db.list({ include_docs: true }).then((body) => body.rows.map(row => row.doc))
})

exports.createFolder = (folderName) => () => ready.then((db) => {
  const _id = uuid()

  return db.insert({ _id, folderName, tags: [], files: [] })
})

exports.deleteFolder = (_id) => () => ready.then(db => {
  return db.destroy(_id)
})
