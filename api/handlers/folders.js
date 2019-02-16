const xs = require('xstream').default

const handler = (req, config) => ({ EFFECT, HTTP }) => {

  return {
    RESPONSE: xs.of({
      state: 200,
      body: []
    }),
    HTTP: xs.empty(),
    EFFECT: xs.empty(),
    LOG: log$
  }
}