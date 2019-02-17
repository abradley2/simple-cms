const jwt = require('jsonwebtoken')

const getUserToken = (config, claims) => () => {
  const token = jwt.sign(claims, config.SECRET, { expiresIn: '6h' })

  return Promise.resolve(token)
}

module.exports = {
  getUserToken
}
