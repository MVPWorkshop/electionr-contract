const abi = require('ethereumjs-abi');

const Web3 = require('web3');
const web3 = new Web3();

const BigNumber = require('bignumber.js');

function calculateHash (pubKey, nonce, contractAddr) {
    const sum = new BigNumber(pubKey).plus(BigNumber(nonce)).plus(BigNumber(web3.utils.hexToNumberString(contractAddr)));
    return '0x' + abi.soliditySHA256(
        [ "uint256" ],
        [ sum.toFixed() ]
    ).toString('hex');
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
