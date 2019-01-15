pragma solidity >=0.4.21 <0.6.0;

import "./ElectionInterface.sol";

contract Election is ElectionInterface {
    uint256 public startValidators;
    uint256 public cycleValidators;
    uint256 public finishValidators;

    uint256 public currValidators;

    uint256 public periodBlock;
    uint256 public blockReward;
    uint256 public bondPeriod;
    uint256 public nextElectionBlockEnd;

    address head = address(0);

    struct elect {
        address _next;
        address _prev;
    }

    mapping (address => bytes32) public validatorElectHash;
    mapping (address => elect) public list;

    constructor () public {
    }

    function electMe(bytes32 _pubKey, uint256 _nonce, bytes32 _hash) public returns (bool) {
        require(sha256(abi.encodePacked(_pubKey, _nonce, this))== _hash);
        require(_hash < validatorElectHash[msg.sender]);

        validatorElectHash[msg.sender] = _hash;

        return _insert(msg.sender, _hash);
    }

    function publishSigs() public returns (bool) {
        if (currValidators >= finishValidators) selfdestruct(address(0)); // destroy or lock
        require(block.number >= nextElectionBlockEnd);        
        
        address[] memory validators = new address[](cycleValidators);
        uint256 i;

        if (currValidators == 0) {
            while (i < startValidators) {
                require(list[head]._next != address(0));

                validators[i] = head;

                head = list[head]._next;
                i++;
            }

            currValidators += startValidators;
        } else {
            while (i < cycleValidators) {
                require(list[head]._next != address(0));

                validators[i] = head;

                head = list[head]._next;
                i++;
            }

            currValidators += cycleValidators;
        }

        emit NewValidators(nextElectionBlockEnd, validators);
        nextElectionBlockEnd += periodBlock; // this will not be managed here
        return true;
    }

    function _insert(address _addr, bytes32 _hash) internal returns (bool) {
        address pointer = head;
        if (pointer == address(0)) {
            head = _addr;
        } else {
            while(validatorElectHash[pointer] != bytes32(0) && _hash > validatorElectHash[list[pointer]._next]) {                
                pointer = list[pointer]._next;
            }

            if (list[_addr]._next != address(0) || list[_addr]._prev != address(0)) {
                list[list[_addr]._prev]._next = list[_addr]._next;
            }

            list[_addr]._next = list[pointer]._next;
            list[_addr]._prev = pointer;

            list[list[pointer]._next]._prev = _addr;
            list[pointer]._next = _addr;
        }

        return true;
    }
}