"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.activate = void 0;
const vscode = require("vscode");
const cwd = ".";
function activate(context) {
    console.log('Congratulations, your extension "smst" is now active!');
    const provider = new ColorsViewProvider(context.extensionUri);
    context.subscriptions.push(vscode.window.registerWebviewViewProvider(ColorsViewProvider.viewType, provider));
    context.subscriptions.push(vscode.commands.registerCommand('calicoColors.addColor', () => {
        provider.addColor();
    }));
    context.subscriptions.push(vscode.commands.registerCommand('calicoColors.clearColors', () => {
        provider.clearColors();
    }));
    context.subscriptions.push(vscode.commands.registerCommand('calicoColors.tidyCode', () => {
        provider.tidyCode();
    }));
    context.subscriptions.push(vscode.commands.registerCommand('calicoColors.createAndSend', () => {
        const terminal = vscode.window.createTerminal('Tidy Term #${NEXT_TERM_ID++}');
        terminal.show();
        terminal.sendText("echo 'Sent text immediately after creating: '");
        const taskProvider = vscode.tasks.registerTaskProvider('rake', {
            provideTasks: () => {
                if(!rakePromise) {
                    rakePromise = getRakeTasks();
                }
                return rakePromise;
            },
            resolveTask(_task: vscode.Task): vscode.Task | undefined{
                const task = _task.definition.task;
                if (task) { // required by rake tasks
                    const definition: RakeTaskDefinition = <any>_task.definition;
                    return new vscode.Task(
                        definition,
                        _task.scope ?? vscode.TaskScope.Workspace,
                        definition.task,
                        'rake', 
                        new vscode.ShellExecution(`rake ${definition.task}`)
                    );
                }
                return undefined;
            }
        }) ;
    }));
}
exports.activate = activate;
class ColorsViewProvider {
    constructor(_extensionUri) {
        this._extensionUri = _extensionUri;
    }
    resolveWebviewView(webviewView, context, _token) {
        this._view = webviewView;
        webviewView.webview.options = {
            // Allow scripts in the webview (main.js)
            enableScripts: true,
            localResourceRoots: [
                this._extensionUri
            ]
        };
        webviewView.webview.html = this._getHtmlForWebview(webviewView.webview);
        webviewView.webview.onDidReceiveMessage(data => {
            var _a, _b;
            switch (data.type) {
                case 'colorSelected':
                    {
                        (_a = vscode.window.activeTextEditor) === null || _a === void 0 ? void 0 : _a.insertSnippet(new vscode.SnippetString(`#${data.value}`));
                        break;
                    }
                case 'tidyCodeMsg':
                    {
                        //vscode.window.activeTextEditor?.insertSnippet(new vscode.SnippetString(`#${data.value}`));
                        //terminalCMD(this);
                        vscode.commands.executeCommand("calicoColors.createAndSend");
                        break;
                    }
                case 'testmsg':
                    {
                        (_b = vscode.window.activeTextEditor) === null || _b === void 0 ? void 0 : _b.insertSnippet(new vscode.SnippetString(`#${data.value}`));
                        break;
                    }
            }
        });
    }
    addColor() {
        var _a, _b;
        if (this._view) {
            (_b = (_a = this._view).show) === null || _b === void 0 ? void 0 : _b.call(_a, true); // `show` is not implemented in 1.49 but is for 1.50 insiders
            this._view.webview.postMessage({ type: 'addColor' });
        }
    }
    clearColors() {
        if (this._view) {
            this._view.webview.postMessage({ type: 'clearColors' });
        }
    }
    tidyCode() {
        if (this._view) {
            this._view.webview.postMessage({ type: 'tidyToMain' });
            //message to send to webview when the command is ran from the command palette 
        }
    }
    _getHtmlForWebview(webview) {
        // Get the local path to main script run in the webview, then convert it to a uri we can use in the webview.
        const scriptUri = webview.asWebviewUri(vscode.Uri.joinPath(this._extensionUri, 'media', 'main.js'));
        // Do the same for the stylesheet.
        const styleResetUri = webview.asWebviewUri(vscode.Uri.joinPath(this._extensionUri, 'media', 'reset.css'));
        const styleVSCodeUri = webview.asWebviewUri(vscode.Uri.joinPath(this._extensionUri, 'media', 'vscode.css'));
        const styleMainUri = webview.asWebviewUri(vscode.Uri.joinPath(this._extensionUri, 'media', 'main.css'));
        // Use a nonce to only allow a specific script to be run.
        const nonce = getNonce();
        return `<!DOCTYPE html>
		<html lang="en">
		<head>
			<meta charset="UTF-8">

			<!--
				Use a content security policy to only allow loading images from https or from our extension directory,
				and only allow scripts that have a specific nonce.
			-->
			<meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src ${webview.cspSource}; script-src 'nonce-${nonce}';">

			<meta name="viewport" content="width=device-width, initial-scale=1.0">

			<link href="${styleResetUri}" rel="stylesheet">
			<link href="${styleVSCodeUri}" rel="stylesheet">
			<link href="${styleMainUri}" rel="stylesheet">
			
			<title>Cat Colors</title>
		</head>
		<body>
			<ul class="color-list">
			</ul>
			<button class="add-color-button">Add Color</button>
			<table>
			  <tr>
			   <td> <label for="ofpid">OFP ID</label> </td>
			   <td> <input type="text" maxlength="4" name="ofpid" value="OFP1" id="ofpid" pattern="[abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890!@#$%^&*()?]"> </td>
			  </tr>
			  <tr>
			   <td width=50> <input type="checkbox" name="choice" value="yes" id="choice-yes"></td>
			   <td><label for="choice-yes">Debug</label></td>
			  </tr>
			  <tr>
			   <td> <input type="checkbox" name="choice" value="no" id="choice-no">	</td>
			   <td> <label for="choice-no">Depend</label> </td>
			  </tr>
			</table>
			<form>

			<label for="build">Build Target:</label>
			<select id="ofp" name="build"><!-- size=3 multiple -->
			  <option value="build[ppc]">ppc</option>
			  <option value="build[sim]" selected>sim</option>
			  <option value="build[both]">both</option>
			</select>
			
			<label for="build[depend]">Depend</label>
			<input type="checkbox" name="choice" value="yes" id="choice-yes" >
			<input type="checkbox" name="choice" value="no" id="choice-no">
			<label for="choice-no">No</label>
			<input type="submit" value="BUILD">
			
			</form>
			
			<button class="add-color-button">TEST COMPILE</button>
			<button class="tidy-code-button">TIDY</button>
			
			<script nonce="${nonce}" src="${scriptUri}"></script>
		</body>
		</html>`;
    }
}
ColorsViewProvider.viewType = 'calicoColors.colorsView';
/*function terminalCMD(context: vscode.ExtensionContext){
    vscode.window.onDidChangeActiveTerminal(e => {
        console.log(`Active terminal changed, name=${e ? e.name : 'undefined'}`);
    });
        
    context.subscriptions.push(vscode.commands.registerCommand('calicoColors.createAndSend',()=>{
        const terminal = vscode.window.createTerminal(`Ext Terminal #${NEXT_TERM_ID++}`);
        terminal.sendText("echo 'Sent text immediately after creating'");
    }));
}*/
function getNonce() {
    let text = '';
    const possible = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    for (let i = 0; i < 32; i++) {
        text += possible.charAt(Math.floor(Math.random() * possible.length));
    }
    return text;
}
//# sourceMappingURL=extension.js.map