// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// import from node_modules @openzeppelin/contracts v4.0
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./EthUsd.sol";

/** 
  *@title Initial Coin Offerring(ICO) contract
*/
contract ICO is ERC20, Ownable, ReentrancyGuard,  PriceConsumerV3 {

    constructor() ERC20("InfluencerEconomy", "INFL") {
      mint(msg.sender,  200000000 *(10**uint256(decimals())));
    }
    
    /**
      * @param account (type address) address of recipient
      * @param amount (type uint256) amount of token
      * @dev function use to mint token
    */
    function mint(address account, uint256 amount) public onlyOwner returns (bool sucess) {
      require(account != address(0) && amount != uint256(0), "ERC20: function mint invalid input");
      _mint(account, amount);
      return true;
    }

    /** 
      * @param account (type address) address of recipient
      * @param amount (type uint256) amount of token
      * @dev function use to burn token
    */
    function burn(address account, uint256 amount) public onlyOwner returns (bool success) {
      require(account != address(0) && amount != uint256(0), "ERC20: function burn invalid input");
      _burn(account, amount);
      return true;
    }

    /** 
      * @dev function to buy token with ether
    */
    function buy(uint256 _amountToPurchase) public payable nonReentrant returns (bool sucess) {
        // real pricePerToken = 5/ 10 ** 2
       uint256 pricePerToken = computeInitialPriceInEth(5);
       uint256 amount = pricePerToken * _amountToPurchase;
      require(msg.sender.balance >= amount && amount != 0 ether, "ICO: function buy invalid input");
      _transfer(owner(), _msgSender(), amount);
      return true;
    }

    /** 
      * @param amount (type uint256) amount of ether
      * @dev function use to withdraw ether from contract
    */
    function withdraw(uint256 amount) public onlyOwner returns (bool success) {
      require(amount <= address(this).balance, "ICO: function withdraw invalid input");
      payable(_msgSender()).transfer(amount);
      return true;
    }



    function computeInitialPriceInEth(uint256 _usdAmount) public view returns (uint priceInEth) {
     return  _usdAmount/uint256(this.getLatestPrice())/ (10 ** 2) * 10**uint256(decimals());
    }
}