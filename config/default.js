module.exports = {
  port: process.env.PORT || '8080',
  ghClientId: process.env.GH_CLIENT_ID,
  ghClientSecret: process.env.GH_CLIENT_SECRET,
  secret: process.env.SECRET,
  awsAccessKey: process.env.AWS_ACCESS_KEY,
  awsSecretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
}
