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
        uint256 _oprAddr;
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

    function electMe(uint256 _conPubKey, uint256 _oprAddr, uint256 _nonce, bytes32 _hash) public isLocked returns (bool) {
        require(keccak256(abi.encodePacked(_conPubKey, _nonce, this)) == _hash);
        require(validatorElect[_conPubKey]._validator == false);
        if (validatorElect[_conPubKey]._hash != bytes32(0)) {
            require(_hash < validatorElect[_conPubKey]._hash);
        }

        _insert(_conPubKey, _hash);
        validatorElect[_conPubKey]._hash = _hash;
        validatorElect[_conPubKey]._sender = msg.sender;
        validatorElect[_conPubKey]._oprAddr = _oprAddr;
        return true;
    }

    function publishGenesisSigs() public isLocked returns (bool) {
        require(block.number >= nextElectionBlockEnd); // time??
        require(currValidators == 0);
        require(msg.sender == validatorElect[head]._sender);

        uint256[] memory conPubKey = new uint256[](startValidators);
        uint256[] memory oprAddr = new uint256[](startValidators);

        uint256 i;
        while (i < startValidators) {
            require(head != uint256(0));

            conPubKey[i] = head;
            oprAddr[i] = validatorElect[head]._oprAddr;
            validatorElect[head]._validator = true;

            head = list[head]._next;
            i++;
        }

        currValidators += startValidators;
        nextElectionBlockEnd = block.number + periodBlock;
        emit GenesisValidatorSet(conPubKey, oprAddr);
        return true;
    }

    function publishSigs() public isLocked returns (bool) {
        require(block.number >= nextElectionBlockEnd);
        require(currValidators != 0);

        uint256[] memory oprAddr = new uint256[](cycleValidators);
        uint256[] memory conPubKey = new uint256[](cycleValidators);

        uint256 i;
        while (i < cycleValidators) {
            require(head != uint256(0));

            conPubKey[i] = head;
            oprAddr[i] = validatorElect[head]._oprAddr;
            validatorElect[head]._validator = true;

            head = list[head]._next;
            i++;
        }

        currValidators += cycleValidators;
        if (currValidators >= finishValidators) lock();
        nextElectionBlockEnd += periodBlock; // this way??
        emit NewValidatorsSet((currValidators - startValidators) / cycleValidators, conPubKey, oprAddr);
        return true;
    }

    function _insert(uint256 _conPubKey, bytes32 _hash) internal returns (bool) {
        uint256 pointer = head;
        if (pointer == uint256(0)) {
            head = _conPubKey;
        } else if (pointer != _conPubKey) {
            if (_hash < validatorElect[head]._hash) {
                if (list[_conPubKey]._next != uint256(0) || list[_conPubKey]._prev != uint256(0)) {
                    list[list[_conPubKey]._prev]._next = list[_conPubKey]._next;
                }

                list[pointer]._prev = _conPubKey;
                list[_conPubKey]._next = pointer;
                head = _conPubKey;
            } else {
                while (validatorElect[list[pointer]._next]._hash != bytes32(0) && _hash > validatorElect[list[pointer]._next]._hash) {
                    pointer = list[pointer]._next;
                }

                if (list[pointer]._next != _conPubKey) {
                    if (list[_conPubKey]._next != uint256(0) || list[_conPubKey]._prev != uint256(0)) {
                        list[list[_conPubKey]._prev]._next = list[_conPubKey]._next;
                    }

                    list[_conPubKey]._prev = pointer;
                    list[_conPubKey]._next = list[pointer]._next;

                    list[list[pointer]._next]._prev = _conPubKey;
                    list[pointer]._next = _conPubKey;
                }
            }
        }

        return true;
    }
}