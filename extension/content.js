chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.action === 'analyze') {
    const pageContent = document.body.innerText;
    analyzeContent(pageContent, sendResponse);
  }
});

async function analyzeContent(content, sendResponse) {
  try {
    const response = await fetch('http://localhost:5000/api/analyze', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ text: content })
    });
    const result = await response.json();
    highlightBias(result);
    sendResponse({ result: `Bias: ${result.bias}, Fake News: ${result.fake}` });
  } catch (error) {
    sendResponse({ result: 'Error analyzing content' });
  }
}

function highlightBias(result) {
  if (result.bias) {
    document.body.innerHTML = document.body.innerHTML.replace(
      /(\b[^\s]+\b)/g, 
      `<span style="background-color: yellow;">$1</span>`
    );
  }
}
