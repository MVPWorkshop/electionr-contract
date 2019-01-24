pragma solidity >=0.4.21 <0.6.0;

import "./ElectionInterface.sol";
import "./Locked.sol";

contract Election is ElectionInterface, Locked {
    uint256 public startValidators = 7;
    uint256 public cycleValidators = 7;
    uint256 public finishValidators = 91;

    uint256 public currValidators;

    uint256 public periodBlock;
    uint256 public blockReward;
    uint256 public bondPeriod;
    uint256 public nextElectionBlockEnd;

    address public head;

    struct elect {
        uint256 _pubKey;
        address _next;
        address _prev;
    }

    mapping (address => bytes32) public validatorElectHash;
    mapping (address => elect) public list;

    constructor (uint256 _startValidators,uint256 _cycleValidators,uint256 _finishValidators) public {
        startValidators = _startValidators;
        cycleValidators = _cycleValidators;
        finishValidators = _finishValidators;
    }

    function electMe(uint256 _pubKey, uint256 _nonce, bytes32 _hash) public isLocked returns (bool) {
        require(sha256(abi.encodePacked(_pubKey + _nonce + uint256(this))) == _hash);
        if (validatorElectHash[msg.sender] != bytes32(0)) {
            require(_hash < validatorElectHash[msg.sender]);
        }

        _insert(msg.sender, _pubKey, _hash);
        validatorElectHash[msg.sender] = _hash;
        return true;
    }

    function publishGenesisSigs() public isLocked returns (bool) {
        require(block.number >= nextElectionBlockEnd); // time??
        require(currValidators == 0);
        require(msg.sender == head);
        
        uint256[] memory validators = new uint256[](startValidators);

        uint256 i;
        while (i < startValidators) {
            require(head != address(0));

            validators[i] = list[head]._pubKey;

            head = list[head]._next;
            i++;
        }

        currValidators += startValidators;
        nextElectionBlockEnd = block.number + periodBlock;
        emit GenesisValidatorSet(validators);
        return true;
    }

    function publishSigs() public isLocked returns (bool) {
        require(block.number >= nextElectionBlockEnd);
        require(currValidators != 0);

        uint256[] memory validators = new uint256[](cycleValidators);

        uint256 i;
        while (i < cycleValidators) {
            require(head != 0);

            validators[i] = list[head]._pubKey;

            head = list[head]._next;
            i++;
        }

        currValidators += cycleValidators;
        if (currValidators >= finishValidators) lock();
        nextElectionBlockEnd += periodBlock; // this way??
        emit NewValidatorsSet((currValidators - startValidators) / cycleValidators, validators);
        return true;
    }

    function _insert(address _addr, uint256 _pubKey, bytes32 _hash) internal returns (bool) {
        address pointer = head;
        if (pointer == address(0)) {
            head = _addr;
            list[head]._pubKey = _pubKey;
        } else {
            if (_hash < validatorElectHash[head]) {
                if (head == _addr) {
                    list[_addr]._pubKey = _pubKey;
                } else {
                    if (list[_addr]._next != address(0) || list[_addr]._prev != address(0)) {
                        list[list[_addr]._prev]._next = list[_addr]._next;
                    }

                    list[head]._prev = _addr;

                    list[_addr]._next = head;
                    list[_addr]._pubKey = _pubKey;

                    head = _addr;
                }
            } else {
                while (validatorElectHash[list[pointer]._next] != bytes32(0) && _hash > validatorElectHash[list[pointer]._next]) {// we have u[dated hash
                    pointer = list[pointer]._next;
                }

                if (list[pointer]._next == _addr) {
                    list[_addr]._pubKey = _pubKey;
                } else {
                    if (list[_addr]._next != address(0) || list[_addr]._prev != address(0)) {
                        list[list[_addr]._prev]._next = list[_addr]._next;
                    }

                    list[_addr]._prev = pointer;
                    list[_addr]._next = list[pointer]._next;
                    list[_addr]._pubKey = _pubKey;

                    list[list[pointer]._next]._prev = _addr;
                    list[pointer]._next = _addr;
                }
            }
        }

        return true;
    }
}