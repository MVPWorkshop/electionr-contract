require('dotenv').config({ path: '../.env' });

var Election = artifacts.require('./Election.sol');

const {
    START_VALIDATORS,
    END_VALIDATORS,
    CYCLE_VALIDATORS
} = process.env;

module.exports = function (deployer) {
    deployer.deploy(Election,
        +START_VALIDATORS,
        +END_VALIDATORS,
        +CYCLE_VALIDATORS
    );
};
