const http = require('http');
const req = http.request({
  socketPath: '/var/run/docker.sock',
  path: '/containers/json',
  method: 'GET'
}, (res) => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    try {
      const containers = JSON.parse(data);
      console.log('SUCCESS: Found ' + containers.length + ' containers');
      containers.forEach(c => {
        console.log('  - ' + c.Names[0] + ' (' + c.State + ')');
      });
    } catch(e) {
      console.log('PARSE ERROR:', data.substring(0, 200));
    }
  });
});
req.on('error', e => console.log('CONNECTION ERROR:', e.message));
req.end();
