const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

const express = require('express');
const cors = require('cors');
const routes = require('./routes');

const app = express();
const port = Number(process.env.PORT || 3000);

app.use(cors());
app.use(express.json({ limit: '2mb' }));
app.use('/api', routes);

app.use((err, _req, res, _next) => {
  console.error(err);
  const status = err.status || err.statusCode || 500;
  res.status(status).json({
    error: status < 500 ? err.message : 'Internal server error',
  });
});

app.listen(port, () => {
  const aiReady = Boolean(process.env.GEMINI_API_KEY);
  console.log(
    `API listening on http://0.0.0.0:${port} (AI ${aiReady ? 'configured' : 'not configured'})`,
  );
});
