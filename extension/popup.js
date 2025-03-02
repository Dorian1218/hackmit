document.getElementById('analyzeButton').addEventListener('click', () => {
  chrome.tabs.query({ active: true, currentWindow: true }, (tabs) => {
    chrome.tabs.sendMessage(tabs[0].id, { action: 'analyze' }, (response) => {
      if (response && response.result) {
        document.getElementById('result').innerHTML = response?.result;
      } else {
        document.getElementById('result').innerHTML = 'No result received or error occurred';
      }
    });
  });
});
