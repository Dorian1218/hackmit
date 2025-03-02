const google = require("@google/generative-ai");
const express = require('express');
const axios = require('axios');
const cors = require('cors');
require('dotenv').config();

const app = express();
const port = 5000;


app.use(express.json());
app.use(cors());


app.post('/api/analyze', async (req, res) => {
  try {
    const { text } = req.body;
    const genAI = new google.GoogleGenerativeAI("AIzaSyDPdHzqj9t-QU6wBXLtETggAG9-GgxOsLU");
    const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });
        
    const prompt = "Take the following text and check if for potential bias: " + text;
        
    const result = await model.generateContent(prompt);
    res.json({result: result.response.text()});
  } catch (error) {
    res.status(500).json({ error: 'Error analyzing the news article' });
  }
});

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});
