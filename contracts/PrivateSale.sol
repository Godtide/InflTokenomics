pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ICO.sol";

contract PrivateSale is ICO {
    // bytes32 immutable public root = "02546ef9acfa532c0ad0b51e4a8d529ed8dafd0d67db261ee863d109822236b5";

    constructor( bytes32 merkleroot)
    {
        root = merkleroot;
    }


    function buy(bytes32[] calldata proof, uint256 _amountToPurchase) external payable override{
       redeem(proof);
       buy(_amountToPurchase);
    }


    function redeem(address account, bytes32[] calldata proof) 
    external
    {
        require(_verify(_leaf(account, proof), "Invalid merkle proof");
    }

    function _leaf(address account)
    internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(account));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof)
    internal view returns (bool)
    {
        return MerkleProof.verify(proof, root, leaf);
    }
}