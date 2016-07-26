const http = require('http');
const port = 3000;
const server = http.createServer((req, res) => {
  console.log(`Got request: ${req.method}, ${req.url}`)
  if (req.url == '/test1' && req.method == 'GET') {
      res.statusCode = 200;
      res.setHeader('Content-Type', 'text/plain');
      res.end('Hello World\n');
  } else if (req.url == '/post1' && req.method == 'POST') {
      var body = '';
      req.on('data', function(data) {
          body += data;
      })
      req.on('end', function() {
          //console.log(`length=${ body.length }, ${body}`)
          res.statusCode = 200;
          res.setHeader('Content-Type', 'text/plain');
          res.end(body);
      })
  } else {
      res.statusCode = 404;
      res.setHeader('Content-Type', 'text/plain');
      res.end('Not Found\n');
  }
});

server.listen(port, function() {
    console.log(`Server running at http://localhost:${port}/`);
})
