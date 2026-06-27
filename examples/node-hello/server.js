// Minimal HTTP server with no Dockerfile — the Paketo Node.js buildpack detects
// it from package.json and the CNB launcher runs `npm start` on $PORT.
const http = require('http')

const port = process.env.PORT || 8080
http
  .createServer((_req, res) => {
    res.writeHead(200, { 'Content-Type': 'text/plain' })
    res.end('hello from miabi/pack\n')
  })
  .listen(port, () => console.log(`listening on ${port}`))
