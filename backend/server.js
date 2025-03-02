
const express = require('express');
const axios = require('axios');
const cors = require('cors');
require('dotenv').config();

const app = express();
const port = 5000;


app.use(express.json());
app.use(cors());


async function checkFakeNews(content) {
  // const response = await axios.post('https://api.gemini.com/analyze', {
  //   text: content,
  //   api_key: "AIzaSyDPdHzqj9t-QU6wBXLtETggAG9-GgxOsLU"
  // });
  // return response.data;
  return content;
}


app.post('/api/analyze', async (req, res) => {
  try {
    const { text } = req.body;
    console.log(text)
    // const result = await checkFakeNews(text);
    // res.json(result);
    // console.log(result)
  } catch (error) {
    res.status(500).json({ error: 'Error analyzing the news article' });
  }
});

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});
