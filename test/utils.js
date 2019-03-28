const Web3 = require('web3');

const {
    ENV
} = process.env;
const config = require('../truffle-config').networks[ENV];

const web3 = new Web3('http://' + config.host + config.port);

const BigNumber = require('bignumber.js');

function calculateHash (pubKey, nonce, contractAddr) {
    return web3.utils.soliditySha3(pubKey, nonce, contractAddr).toString('hex');
}

function compareFn (a, b) {
    return a.hash > b.hash;
}

function calculateLowerHash (hash, pubKey, nonce, contractAddr) {
    let newHash = calculateHash(pubKey, nonce, contractAddr);
    let newNonce = 0;

    while (hash <= newHash) {
        newNonce++;
        newHash = calculateHash(pubKey, newNonce, contractAddr);
    }

    return {
        nonce: newNonce,
        hash: newHash
    }
}

function checkIfEqual(head, publicKey) {
    return head.toString() === new BigNumber(publicKey).toFixed()
}

module.exports = {
    calculateHash,
    compareFn,
    checkIfEqual,
    calculateLowerHash
};
