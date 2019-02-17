const xs = require('xstream').default

exports.get = (req, config) => ({ EFFECT, HTTP }) => {

  return {
    RESPONSE: xs.of({
      status: 200,
      body: []
    }),
    HTTP: xs.empty(),
    EFFECT: xs.empty(),
    LOG: xs.empty()
  }
}