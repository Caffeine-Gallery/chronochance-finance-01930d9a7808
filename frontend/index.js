import { backend } from "declarations/backend";
import { AuthClient } from "@dfinity/auth-client";

let authClient;
let identity;

async function init() {
    authClient = await AuthClient.create();
    if (await authClient.isAuthenticated()) {
        identity = await authClient.getIdentity();
        await handleAuthenticated();
    } else {
        await authenticate();
    }
}

async function authenticate() {
    await authClient.login({
        identityProvider: "https://identity.ic0.app",
        onSuccess: async () => await handleAuthenticated(),
    });
}

async function handleAuthenticated() {
    try {
        await backend.init();
    } catch (e) {
        console.log("Timer already initialized");
    }
    updateBalance();
    updateTransactionHistory();
}

async function updateBalance() {
    showLoading();
    try {
        const balance = await backend.getBalance();
        document.getElementById('balance').textContent = balance.toString();
    } catch (error) {
        console.error('Error fetching balance:', error);
    }
    hideLoading();
}

async function updateTransactionHistory() {
    showLoading();
    try {
        const history = await backend.getTransactionHistory(identity.getPrincipal());
        const tbody = document.getElementById('transactionHistory');
        tbody.innerHTML = '';
        
        history.forEach(([type, amount, timestamp]) => {
            const row = document.createElement('tr');
            row.innerHTML = `
                <td>${type}</td>
                <td>${amount}</td>
                <td>${new Date(Number(timestamp) / 1000000).toLocaleString()}</td>
            `;
            tbody.appendChild(row);
        });
    } catch (error) {
        console.error('Error fetching transaction history:', error);
    }
    hideLoading();
}

document.getElementById('depositBtn').addEventListener('click', async () => {
    const amount = parseInt(document.getElementById('depositAmount').value);
    if (amount > 0) {
        showLoading();
        try {
            await backend.deposit(amount);
            document.getElementById('depositAmount').value = '';
            await updateBalance();
            await updateTransactionHistory();
        } catch (error) {
            console.error('Error depositing:', error);
        }
        hideLoading();
    }
});

document.getElementById('withdrawBtn').addEventListener('click', async () => {
    const amount = parseInt(document.getElementById('withdrawAmount').value);
    if (amount > 0) {
        showLoading();
        try {
            const success = await backend.withdraw(amount);
            if (success) {
                document.getElementById('withdrawAmount').value = '';
                await updateBalance();
                await updateTransactionHistory();
            } else {
                alert('Insufficient balance');
            }
        } catch (error) {
            console.error('Error withdrawing:', error);
        }
        hideLoading();
    }
});

function showLoading() {
    document.getElementById('loadingSpinner').style.display = 'flex';
}

function hideLoading() {
    document.getElementById('loadingSpinner').style.display = 'none';
}

// Initialize the application
init();
