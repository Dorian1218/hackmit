chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.action === 'analyze') {
    const pageContent = document.body.innerText;
    checkBias(pageContent, sendResponse);
  }
  return true;
});

async function checkBias(text, sendResponse) {
    const response = await fetch('http://localhost:5000/api/analyze', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ text: text })
    });
    const result = await response.json();
    let formattedText = result.result
        .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
        .replace(/(?<!\*)\*(?!\*)/g, '<br><br>')

    await sendResponse({ result: formattedText});
}