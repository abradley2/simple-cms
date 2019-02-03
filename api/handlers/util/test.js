const delay = require('xstream/extra/delay').default
const xs = require('xstream').default

function testDrivers (sources) {
  return {
    RESPONSE: () => {},
    LOG: () => {},
    HTTP: () => ({
      select: (tag = '*') => sources.HTTP
        .flatten()
        .filter((v) => tag === '*' || (v.category === tag))
        .map((v) => v instanceof Error ? xs.throw(v) : xs.of(v))
        .compose(delay(0))
    }),
    EFFECT: () => ({
      selectValue: (tag) => sources.EFFECT
        .filter((v) => v.tag === tag && !v.error)
        .map((v) => v.value)
        .compose(delay(0)),
      selectError: (tag) => sources.EFFECT
        .filter((v = '*') => v === '*' || (v.tag === tag && !!v.error))
        .map((v) => v.error)
        .compose(delay(0))
    }),
    DOM: () => ({
      select: (field) => ({
        events: (event) => sources.DOM
          .filter((v) => v.field === field && v.event === event)
          .compose(delay(0))
      })
    })
  }
}

module.exports = { testDrivers }
