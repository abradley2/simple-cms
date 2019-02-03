const xs = require('xstream').default

// utility function to always get a response, even if there is an error, then auto-flatten
function selectResponse (source, tag) {
  return source.select(tag)
    .map((response$) => {
      return response$
        .map((response) => ({ response }))
        .replaceError((error) => {
          return xs.of({
            error,
            response: error.response
          })
        })
    })
    .flatten()
}

module.exports = {
  selectResponse
}
