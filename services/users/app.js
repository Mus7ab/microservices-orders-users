const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.get('/users', (req, res) => {
  res.json({
    service: 'users',
    hostname: require('os').hostname(),
    message: 'Users service is running'
  });
});

app.get('/health', (req, res) => {
  res.status(200).send('OK');
});

app.listen(PORT, () => {
  console.log(`Users service listening on port ${PORT}`);
});
