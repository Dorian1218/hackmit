// Extract main text content from an article
function getArticleText() {
    let paragraphs = document.querySelectorAll("p");
    let articleText = "";
    paragraphs.forEach(p => articleText += p.innerText + " ");
    return articleText.slice(0, 5000); // Limit to 5000 chars for API efficiency
}

// Send extracted text to API for analysis
async function analyzeArticle() {
    let articleText = getArticleText();
    let response = await fetch("https://your-nextjs-api.com/analyze", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ text: articleText })
    });

    let data = await response.json();
    alert(`Fake News Score: ${data.fakeNewsScore}%\nBias Level: ${data.biasLevel}`);
}

// Automatically analyze page when loaded
window.onload = () => analyzeArticle();
