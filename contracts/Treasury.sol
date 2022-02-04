//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ICO.sol";
import { FixedMath } from "./FixedMath.sol";
// import "./PriceConsumer.sol";

/** @title Treasury inherits INFL token
 * @notice INFL follows an ERC20 implementation
 */

contract Treasury is ICO {
    using FixedMath for int256;

    //Max limit of tokens to be minted
    int256 public currentLimit;
    //Midpoint for price function
    int256 public midpoint;
    //Half of max price 
    int256 public maxPrice;
    //Steepness
    int256 public steepness;
    // 18-36 months in seconds



    // // admin address
    // address public admin;

    // modifier isAdmin{
    //     require(msg.sender == admin, "ADMIN: Not allowed!");
    //     _;
    // }

    event BuyINFL(address buyer,  uint256 price);
    event SellINFL(address seller, uint256 price);
    // event ChangeAdmin(address newAdmin);

    constructor(
        int256 _currentLimit,
        int256 _maxPrice,
        int256 _steepness
    ) public  {
        currentLimit = _currentLimit;
        maxPrice = _maxPrice;
        midpoint = currentLimit/2;
        steepness = _steepness;
    }

    /**
     * @dev Get price of next token
     * @param x the position on the curve to check
     * Assuming current bonding curve function of 
     * y = maxPrice/2(( x - midpoint )/sqrt(steepness + (x - midpoint)^2) + 1)
     * In other words, a Sigmoid function
     * Note that we divide back by 10^30 because 10^24 * 10^24 = 10^48 and most ERC20 is in 10^18
     * @return price at the specific position in bonding curve
     */
    function price(uint256 x) public view returns(uint256){
        int256 numerator = int256(x) - midpoint;
        int256 innerSqrt = (steepness + (numerator)**2);
        int256 fixedInner = innerSqrt.toFixed();
        int256 fixedDenominator = fixedInner.sqrt();
        int256 fixedNumerator = numerator.toFixed();
        int256 midVal = fixedNumerator.divide(fixedDenominator) + 1000000000000000000000000;
        int256 fixedFinal = maxPrice.toFixed() * midVal;
        return uint256(fixedFinal / 1000000000000000000000000000000);
    }

    /**
     * @dev Buy INFL 
     * @notice
     * @pricing done in avax
     */
    function buy( uint256 _amountToPurchase) public payable override {
        uint256 currentSupply = totalSupply();
        uint256 estimatedPrice = price(currentSupply + 1);

        require(currentSupply < uint256(currentLimit), "BUY: Max Supply not Reached!");
        uint256 payableinAvax = uint256(computeInitialPriceInAvax(int256(estimatedPrice)));
         uint256 buyable =  _amountToPurchase * payableinAvax;
         uint256 toBurn = (_amountToPurchase * 250) / 1000;
         uint256 receivable = _amountToPurchase - toBurn;
        //  uint256 buyTax = (buyable * 250 ) / 100; 
        //  uint256 toPay = buyable + buyTax;

         require(msg.value > buyable, "not sufficient Avax balance for amount requested");

     // sends ether value to admin address
         (bool sent, ) = owner().call{value: buyable}("");
        require(sent, "Failed to send Avax");

        // burn salestax of 2.5% of token bought
        burn(owner(), toBurn);
  
    //  Send INFLtokens to buyer
       transferFrom(owner(), msg.sender, receivable);
        emit BuyINFL(msg.sender, estimatedPrice);
    }

    /**
     * @dev Sell INFL 
     * @notice burn 10% of sold, 
     * @notice spread 10% of solidity
     */
    function sell(uint256 _amountToSell) public nonReentrant{
        uint256 quotedPrice = price(totalSupply());
        uint256 volume =  balanceOf(msg.sender);
        require(_amountToSell <= volume, "Don't have enough INFL tokens");
        uint256 toBurn = _amountToSell / 10 ;
        uint256 spread = _amountToSell / 10 ;
        uint256 receivable = _amountToSell - toBurn - spread;
        // transfer sold tokens to owner
         _transfer(msg.sender, owner(), receivable);
        // burn 10% to treasury + spread fee 10 %
        _burn(address(this), toBurn + spread);
        uint256 payableinAvax = uint256(computeInitialPriceInAvax(int256(quotedPrice)));
        uint256 collectable = receivable * payableinAvax;
         // sends ether value from contract address to msg.sender address
         (bool sent, ) = msg.sender.call{value: collectable}("");
        require(sent, "Failed to send Avax");

        emit SellINFL(msg.sender, _amountToSell);
    }


      receive () payable external {}
}