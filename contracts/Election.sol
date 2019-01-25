pragma solidity >=0.4.21 <0.6.0;

import "./ElectionInterface.sol";
import "./Locked.sol";

contract Election is ElectionInterface, Locked {
    uint256 public startValidators;
    uint256 public cycleValidators;
    uint256 public finishValidators;

    uint256 public currValidators;

    uint256 public periodBlock;
    uint256 public blockReward;
    uint256 public bondPeriod;
    uint256 public nextElectionBlockEnd;

    uint256 public head;

    struct pointers {
        uint256 _next;
        uint256 _prev;
    }

    struct elect {
        address _sender;
        bytes32 _hash;
        bool _validator;
    }

    mapping (uint256 => elect) public validatorElect;
    mapping (uint256 => pointers) public list;

    constructor (uint256 _startValidators,uint256 _cycleValidators,uint256 _finishValidators) public {
        startValidators = _startValidators;
        cycleValidators = _cycleValidators;
        finishValidators = _finishValidators;
    }

    function electMe(uint256 _pubKey, uint256 _nonce, bytes32 _hash) public isLocked returns (bool) {
        require(sha256(abi.encodePacked(_pubKey + _nonce + uint256(this))) == _hash);
        require(validatorElect[_pubKey]._validator == false);
        if (validatorElect[_pubKey]._hash != bytes32(0)) {
            require(_hash < validatorElect[_pubKey]._hash);
        }

        _insert(_pubKey, _hash);
        validatorElect[_pubKey]._hash = _hash;
        validatorElect[_pubKey]._sender = msg.sender;
        return true;
    }

    function publishGenesisSigs() public isLocked returns (bool) {
        require(block.number >= nextElectionBlockEnd); // time??
        require(currValidators == 0);
        require(msg.sender == validatorElect[head]._sender);
        
        uint256[] memory validators = new uint256[](startValidators);

        uint256 i;
        while (i < startValidators) {
            require(head != uint256(0));

            validators[i] = head;
            validatorElect[head]._validator = true;

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
            require(head != uint256(0));

            validators[i] = head;
            validatorElect[head]._validator = true;

            head = list[head]._next;
            i++;
        }

        currValidators += cycleValidators;
        if (currValidators >= finishValidators) lock();
        nextElectionBlockEnd += periodBlock; // this way??
        emit NewValidatorsSet((currValidators - startValidators) / cycleValidators, validators);
        return true;
    }

    function _insert(uint256 _pubKey, bytes32 _hash) internal returns (bool) {
        uint256 pointer = head;
        if (pointer == uint256(0)) {
            head = _pubKey;
        } else {
            if (_hash < validatorElect[head]._hash && head != _pubKey) {
                if (list[_pubKey]._next != uint256(0) || list[_pubKey]._prev != uint256(0)) {
                    list[list[_pubKey]._prev]._next = list[_pubKey]._next;
                }

                list[pointer]._prev = _pubKey;
                list[_pubKey]._next = head;
                head = _pubKey;
            } else {
                while (validatorElect[list[pointer]._next]._hash != bytes32(0) && _hash > validatorElect[list[pointer]._next]._hash) {
                    pointer = list[pointer]._next;
                }

                if (list[pointer]._next != _pubKey) {
                    if (list[_pubKey]._next != uint256(0) || list[_pubKey]._prev != uint256(0)) {
                        list[list[_pubKey]._prev]._next = list[_pubKey]._next;
                    }

                    list[_pubKey]._prev = pointer;
                    list[_pubKey]._next = list[pointer]._next;

                    list[list[pointer]._next]._prev = _pubKey;
                    list[pointer]._next = _pubKey;
                }
            }
        }

        return true;
    }
}