document.addEventListener('DOMContentLoaded', (event) => {
    fetch('https://pickle_whippets/requestConfig', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    }).then((response) => {
        response.json().then((data) => {
            console.log('Sending config data to NUI', data);
            window.postMessage(data, '*');
        });
    });
});