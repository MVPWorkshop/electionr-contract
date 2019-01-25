pragma solidity >=0.4.21 <0.6.0;

contract Locked {
    bool locked;

    constructor () public {
    }

    modifier isLocked() {
        require(locked == false);
        _;
    }

    function lock() internal returns (bool) {
        locked = true;
    }
}