const defPort = "8080";

const joinEndpoint = "join/";
const chatEndpoint = "chat/";

const serverIpField = document.getElementById('server-ip-input');
const usernameField = document.getElementById('username-input');

const serverIpError = document.getElementById('server-ip-error');
const usernameError = document.getElementById('username-error');

const connectBtn = document.getElementById('connect-btn');
const clearBtn = document.getElementById('clear-btn');
const disconnectBtn = document.getElementById('disconnect-btn');

const chatContainer = document.getElementById('div-chat-container');

const chatInput = document.getElementById('chat-send-input');
const chatBtn = document.getElementById('chat-send-btn');

const overlay = document.getElementById('image-overlay');
const containerBlur = document.getElementById('container-blur');

let nameOfUser = "";

let clientToken = "";
let getServerIp = "";

let lastMessageId = 0;

let allowMessageSend = false;
let isConnected = false;

let requestPerformer;

function checkInputs() {
    if(isConnected){
        changeUI(false);
        return;
    }
    let allCorrect = true;

    const serverIp = serverIpField.value.trim();
    const username = usernameField.value.trim();

    console.log(serverIp);

    if (serverIp === "") {
        allCorrect = false;
        serverIpError.innerHTML = "Server IP can't be empty";
    } else {
        serverIpError.innerHTML = "&nbsp;";
    }

    if (username === "") {
        allCorrect = false;
        usernameError.innerHTML = "Username can't be empty";
    } else {
        allCorrect = allCorrect & true;
        usernameError.innerHTML = "&nbsp;";
    }
    const endpoint = `http://${serverIp}:${defPort}/`
    if (allCorrect) {
        checkConnection(endpoint, username);
    }
}

function changeUI(connected) {
    if (connected) {
        isConnected = true;
        connectBtn.innerHTML = "Disconnect";
        connectBtn.classList.add("red");
        overlay.style.display = "none";
        containerBlur.classList.remove("blur");
    }else{
        clearInterval(requestPerformer);
        isConnected = false;
        lastMessageId = 0;
        connectBtn.innerHTML = "Connect";
        connectBtn.classList.remove("red");
        overlay.style.display = "initial";
        chatContainer.innerHTML="";
        containerBlur.classList.add("blur");
    }
}

async function checkConnection(serverIp, username) {
    const endpoint = serverIp + joinEndpoint + username + "/";
    try {
        const response = await fetch(endpoint);
        if (response.ok) {
            const resText = await response.text();
            if (resText === "") {
                usernameError.innerHTML = "Username already exists";
            } else {
                clientToken = resText;
                getServerIp = serverIp + chatEndpoint + clientToken;
                nameOfUser = username;
                changeUI(true);
                requestPerformer = setInterval(performGetRequest, 1000);
            }
        }
    } catch (error) {
        console.log(error);
        serverIpError.innerHTML = "Unable to connect to server";
    }
}

async function performGetRequest() {
    try {
        const response = await fetch(getServerIp + "/" + lastMessageId);
        if (response.ok) {
            const jsonResponse = await response.json();
            jsonResponse.forEach(element => {
                lastMessageId = element.Id;
                if (element.Name != nameOfUser) {
                    addToChat(element.Name, element.Message);
                }
            });
        }
    } catch (error) {
        console.log(error);
    }

}

async function performPostRequest(message) {
    addToChat(nameOfUser, message);
    try {
        let data = JSON.stringify({
            Id: 0,
            Name: nameOfUser,
            Message: message,
        });
        await fetch(getServerIp, {
            method: 'POST',
            body: data,
        });
    } catch (error) {
        console.log(error);
    }


}

function addToChat(name, message) {
    let messageDiv = document.createElement("div");
    let messageContainer = document.createElement("div");
    let messageHead = document.createElement("div");
    let messageBody = document.createElement("div");

    messageDiv.classList.add("message");
    messageContainer.classList.add("message-child");
    messageHead.classList.add("message-head");
    messageBody.classList.add("message-text");

    messageHead.innerHTML = `<span>${name}</span>`;
    messageBody.innerHTML = `<span>${message}</span>`;

    if (name === nameOfUser) {
        messageDiv.classList.add("right");
        messageContainer.classList.add("my-message");

    } else if (name === "Server") {
        messageContainer.classList.add("server-message");
        messageContainer.appendChild(messageHead);

    } else {
        messageContainer.classList.add("user-message");
        messageContainer.appendChild(messageHead);
    }
    messageContainer.appendChild(messageBody);
    messageDiv.appendChild(messageContainer);
    chatContainer.prepend(messageDiv);
}

function sendMessage() {
    if (allowMessageSend) {
        let message = chatInput.value.trim();
        performPostRequest(message);
        chatInput.value = "";
        chatBtn.classList.remove("btn-activate");
    }
}
connectBtn.addEventListener('click', checkInputs);
clearBtn.addEventListener('click', () => {
    serverIpField.value = "";
    usernameField.value = "";
});

chatInput.addEventListener('keyup', (val) => {
    if (val.key === "Enter") {
        sendMessage();
    }
    if (chatInput.value.trim() === "") {
        chatBtn.classList.remove("btn-activate")
    } else {
        chatBtn.classList.add("btn-activate")
        allowMessageSend = true;
    }
});

chatBtn.addEventListener('click', sendMessage);