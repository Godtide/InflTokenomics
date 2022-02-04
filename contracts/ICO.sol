// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import from node_modules @openzeppelin/contracts 
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./PriceConsumer.sol";

/** 
  *@title Initial Coin Offerring(ICO) contract
*/
contract ICO is ERC20, Ownable, ReentrancyGuard,  PriceConsumerV3 {

  int oracleMultipler = 10**8;


    event Buy(address buyer,  uint256 price);
    event Sell(address seller, uint256 price);
    // event ChangeAdmin(address newAdmin);


      


    constructor() ERC20("InfluencerEconomy", "INFL") {
      // admin = msg.sender;
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
    function burn(address account, uint256 amount) public returns (bool success) {
      require(balanceOf(msg.sender) > amount, " you cannot burn the amount not available in your acct");
      require(account != address(0) && amount != uint256(0), "ERC20: function burn invalid input");
      _burn(account, amount);
      return true;
    }

    /** 
      * @dev function to buy token with ether
    */
    function buy(uint256 _amountToPurchase) public payable virtual nonReentrant 
    // returns (bool sucess) 
    {
        // real pricePerToken = 5/ 10 ** 2
       uint256 pricePerToken = uint256(computeInitialPriceInAvax(5));
       uint256 amount = pricePerToken * _amountToPurchase;
      require(msg.sender.balance >= amount && amount != 0 ether, "ICO: function buy invalid input");
      _transfer(owner(), msg.sender, amount);

      emit Buy(msg.sender,  _amountToPurchase);

      // return true;
    }

    /** 
      * @param amount (type uint256) amount of ether
      * @dev function use to withdraw ether from contract
    */
    function withdraw(uint256 amount) public onlyOwner nonReentrant returns (bool success) {
      require(amount <= address(this).balance, "ICO: function withdraw invalid input");
      payable(msg.sender).transfer(amount);
      return true;
    }



    function computeInitialPriceInAvax(int _usdAmount) public view returns (int priceInNAvax) {
      return  (_usdAmount * 10**9 / (getLatestPrice() / oracleMultipler) / 10 ** 2) ;
     }

     function approveTreasurySpend (address _treasury) public onlyOwner {
      _approve(msg.sender, _treasury, 180000000 *(10**uint256(decimals())));
     }

}