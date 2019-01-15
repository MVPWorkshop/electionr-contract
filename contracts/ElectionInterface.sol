pragma solidity >=0.4.21 <0.6.0;

contract ElectionInterface {
   // Receive lower hash from validator-elect
   function electMe(uint256 _pubKey, uint256 _nonce, uint256 _hash) public returns (bool);

   // Publish the lowest hashes in the election contract
   function publishSigs() public returns (bool);

   event GenesisPublished(address validator /*, string url */);  
   event NewValidators(uint256 cycle, address[] validators);
}