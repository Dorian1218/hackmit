const url = ('https://example.com/?name=John&age=25');
Fetch ('https://example.com/?name=John&age=25');
then (response => response.text)
newsarticle = document.body.innerText;
analyzeContent(newsarticle, sendResponse);
async function analyzeContent(content, sendResponse) {
    try {
        const response = await fetch('http://localhost:5000/api/analyze', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({text: content})
        });
        const result = await response.json();
        highlightBias(result);
        sendResponse({result: 'Bias: $(result.bias), Fake News: $(result.fake)'});
    }
    catch (error) {
        sendResponse({result: 'Error analyzing content'});
    }
    }
