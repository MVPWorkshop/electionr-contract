pragma solidity >=0.4.21 <0.6.0;

contract ElectionInterface {
   // Receive lower hash from validator-elect
   function electMe(uint256 _pubKey, uint256 _nonce, bytes32 _hash) public returns (bool);

   // Publish the lowest hashes in the election contract
   function publishSigs() public returns (bool);

   // Publish the lowest hashes in the election contract
   function publishGenesisSigs() public returns (bool);

   // Inserting elect in sorted list
   function _insert(uint256 _pubKey, bytes32 _hash) internal returns (bool);
 
   event GenesisValidatorSet(uint256[] validators);
   event NewValidatorsSet(uint256 cycle, uint256[] validators);
}