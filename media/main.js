//@ts-check

// This script will be run within the webview itself
// It cannot access the main VS Code APIs directly.
(function () {
    const vscode = acquireVsCodeApi();

    const oldState = vscode.getState() || { colors: [] };

    /** @type {Array<{ value: string }>} */
    let colors = oldState.colors;

    updateColorList(colors);
    
    const form = document.getElementById('form');

    // const log = document.getElementById('log')
    form.addEventListener('submit', logSubmit);

    document.querySelector('.add-color-button').addEventListener('click', () => {
        addColor();
    });
    document.querySelector('.tidy-code-button').addEventListener('click', () => {
        tidyCode();
    });
    
    // Handle messages sent from the extension to the webview
    window.addEventListener('message', event => {
        const message = event.data; // The json data that the extension sent
        switch (message.type) {
            case 'addColor':
                {
                    addColor();
                    break;
                }
            case 'clearColors':
                {
                    colors = [];
                    updateColorList(colors);
                    break;
                }
            case 'tidyToMain': // this works with Ctrl+Shift+P type 'tidy code'. and 'tidymsg received' is printed in console
                {
                    console.log("tidymsg received from extension");
                    break;
                }

        }
    });

    function logSubmit(event) {
        console.log(`Form Submitted! Time stamp: ${event.timeStamp}`);
        event.preventDefault();
    }
    
    /**
     * @param {Array<{ value: string }>} colors
     */
    function updateColorList(colors) {
        const ul = document.querySelector('.color-list');
        ul.textContent = '';
        for (const color of colors) {
            const li = document.createElement('li');
            li.className = 'color-entry';

            const colorPreview = document.createElement('div');
            colorPreview.className = 'color-preview';
            colorPreview.style.backgroundColor = `#${color.value}`;
            colorPreview.addEventListener('click', () => {
                onColorClicked(color.value);
            });
            colorPreview.addEventListener('click', () => {
                onColorClicked(color.value);
            });
            li.appendChild(colorPreview);

            const input = document.createElement('input');
            input.className = 'color-input';
            input.type = 'text';
            input.value = color.value;
            input.addEventListener('change', (e) => {
                const value = e.target.value;
                if (!value) {
                    // Treat empty value as delete
                    colors.splice(colors.indexOf(color), 1);
                } else {
                    color.value = value;
                }
                updateColorList(colors);
            });
            li.appendChild(input);

            ul.appendChild(li);
        }

        // Update the saved state
        vscode.setState({ colors: colors });
    }

    /** 
     * @param {string} color 
     */
    function onColorClicked(color) {
        vscode.postMessage({ type: 'colorSelected', value: color });
    }

    /**
     * @returns string
     */
    function getNewCalicoColor() {
        const colors = ['020202', 'f1eeee', 'a85b20', 'daab70', 'efcb99'];
        return colors[Math.floor(Math.random() * colors.length)];
    }

    function addColor() {
        colors.push({ value: getNewCalicoColor() });
        updateColorList(colors);
    }
    
    function tidyCode() {
        let ofpid_text = document.getElementById('ofpid').value;
        console.log("tidyCode function called send message to extension");
        vscode.postMessage({ type: 'tidyCodeMsg', value: ofpid_text, term: document.getElementById('newTerm').checked});
    }

    function test() {
         vscode.postMessage({ type: 'testmsg', value: 5 });
    }
}());
