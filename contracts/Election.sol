pragma solidity >=0.4.21 <0.6.0;

import "./ElectionInterface.sol";

contract Election is ElectionInterface {
    uint256 public startValidators;
    uint256 public finishValidators;
    uint256 public periodBlock;
    uint256 public blockReward;
    uint256 public bondPeriod;
    uint256 public nextElectionBlockEnd;

    address head = address(0);

    struct elect {
        bytes32 _hash; //maybe unnessesary bacause we have validatorElectHash
        address _next;
        address _prev;
    }

    mapping (address => bytes32) public validatorElectHash;
    mapping (address => elect) public list;

    constructor () public {
    }

    function electMe(uint256 _pubKey, uint256 _nonce, uint256 _hash) public returns (bool) {
        require(sha256(_pubKey + nonce) == _hash);
        require(_hash < validatorElectHash[msg.sender]);

        validatorElectHash[msg.sender] = _hash

        return _insert(msg.sender, _hash);
    }

    function publishSigs() public returns (bool) {
        require(block.number >= nextElectionBlockEnd);
        
        if (head == address(0)) {
            uint256 i = 0;
            while (i < startValidators) {
                head = list[head]._next;
                i++;
            }
            nextElectionBlockEnd += periodBlock;
            // make validators publicly accesable
        } else {
            require(list[head]._next != address(0));
            head = list[head]._next;
            // make validators publicly accesable
        }
        return true;
    }

    function _insert(address _addr, bytes32 _hash) internal returns (bool) {
        address pointer = head;
        if (list[pointer]._hash == bytes32(0)) {
            list[pointer]._hash = _hash;
            list[pointer]._next = _addr;
            list[pointer]._prev = address(0);
        } else {
            while(list[pointer]._hash != address(0) && _hash > list[list[pointer]._next]._hash) {                
                pointer = list[pointer]._next;
            }

            if (list[_addr]._hash != address(0)) {
                list[list[_addr]._prev]._next = list[_addr]._next;
            }

            list[_addr]._next = list[pointer]._next;
            list[_addr]._prev = pointer;
            list[_addr]._hash = _hash;

            list[list[pointer]._next].prev = _addr;
            list[pointer]._next = _addr;
        }

        return true;
    }
}