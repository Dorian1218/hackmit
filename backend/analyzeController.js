const axios = require("axios")
const GEMINI_API_URL = 'https://gemini.googleapis.com/v1/analyze';
const API_KEY = 'AIzaSyDPdHzqj9t-QU6wBXLtETggAG9-GgxOsLU';  // Use your Gemini API key

// Function to analyze text using Gemini
async function analyzeWithGemini(text) {
  try {
    const response = await axios.post(GEMINI_API_URL, {
      headers: {
        'Authorization': `Bearer ${API_KEY}`,
        'Content-Type': 'application/json',
      },
      data: {
        text: text,  // Article text
      }
    });

    // Example structure of response, adjust according to actual Gemini response format
    const result = response.data;

    return {
      fakeNewsScore: result.fake_news_score,
      biasLevel: result.bias_level,
      factCheckResults: result.fact_check_results
    };
  } catch (error) {
    console.error('Error analyzing with Gemini:', error);
    return { error: 'Unable to analyze the text at the moment.' };
  }
}

module.exports = { analyzeWithGemini };
