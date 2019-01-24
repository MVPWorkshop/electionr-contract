const abi = require('ethereumjs-abi');

const Web3 = require('web3');
const web3 = new Web3();

const BigNumber = require('bignumber.js');

function getUint256(data) {
    return web3.utils.hexToNumberString('0x' + data.substring(64));
}

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

module.exports = {
    calculateHash,
    compareFn
};
