document.addEventListener('DOMContentLoaded', (event) => {
    setTimeout(() => {
        window.postMessage({
            type: 'setConfig',
            locale: {
                grab_object: "Grab Object",
                lower_hand: "Lower Hand",
                rotate_hand: "Rotate Hand",
                key_spacebar: "Spacebar",
                key_left_click: "LMB",
                key_right_click: "RMB",
                stove_status: "Stove Status",
                cook_progress: "Cook Progress",
                online: "Online",
                offline: "Offline",
                temperature: "Temperature",
            },
            gasProcess: {
                ProgressPerTick: 5,
                Temperature: 10,
            }
        }, '*');
        setTimeout(() => {
            window.postMessage({
                type: "showControls",
                controls: [
                    {key: "Spacebar", action: "Grab Object"},
                    {key: "LeftClick", action: "Lower Hand"},
                    {key: "RightClick", action: "Rotate Hand"},
                ]
            }, '*');
        }, 100);
    }, 100);
});