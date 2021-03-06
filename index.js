import { Elm } from './src/Main.elm'
import localforage from 'localforage'

const forage = localforage.createInstance({ name: 'smol_cms' })

const apiUrl = process.env.NODE_ENV === 'development'
  ? 'http://localhost:9966'
  : ''

console.log(process.env.GH_CLIENT_ID)
const flags = {
  apiUrl,
  origin: window.location.origin,
  oauthUrl: `https://github.com/login/oauth/authorize?client_id=${process.env.GH_CLIENT_ID}`
}

const app = Elm.Main.init({
  flags,
  node: document.getElementById('app')
})

forage.getItem('token', (_, data) => {
  app.ports.loadToken.send(data)
})

app.ports.cleanUrl.subscribe(() => {
  window.history.replaceState(null, document.title, window.location.pathname)
})

app.ports.storeToken.subscribe((token) => {
  forage.setItem('token', token)
})
