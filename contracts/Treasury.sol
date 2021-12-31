//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Ico.sol";
import { FixedMath } from "./FixedMath.sol";

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



    // DAI contract address
    address public dai;

    // admin address
    address public admin;

    modifier isAdmin{
        require(msg.sender == admin, "ADMIN: Not allowed!");
        _;
    }

    event BuyINFL(address buyer,  uint256 price);
    event SellINFL(address seller, uint256 price);
    event ChangeAdmin(address newAdmin);

    constructor(
        int256 _currentLimit,
        int256 _maxPrice,
        int256 _steepness
    ) public  {
        currentLimit = _currentLimit;
        maxPrice = _maxPrice;
        midpoint = currentLimit/2;
        steepness = _steepness;
        admin = msg.sender;
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
     * @ todo ensure that the pricing is done in dollar to Eth equivalent
     */
    function buy( uint256 _amountToPurchase) public payable override {
        require(cooldownByAddress[msg.sender] < block.number, "BUY: Can't buy if renter!");
        uint256 currentSupply = totalSupply();
        uint256 estimatedPrice = price(currentSupply + 1);

        require(currentSupply < uint256(currentLimit), "BUY: Max Supply Reached!");

         uint256 buyable =  _amountToPurchase * estimatedPrice;
         uint256 toBurn = (_amountToPurchase * 250) / 1000;
         uint256 receivable = _amountToPurchase - toBurn;
        //  uint256 buyTax = (buyable * 250 ) / 100; 
        //  uint256 toPay = buyable + buyTax;

         require(msg.sender.balance > buyable, "not sufficient Eth balance for amount requested");

     // sends ether value to contract address
         (bool sent, )= address(this).call{value: buyable}("");
        require(sent, "Failed to send Ether");

        // burn salestax of 2.5% of token bought
        ICO.burn(address(this), toBurn);
  
    //  Send INFLtokens to buyer
       _transfer(owner(), msg.sender, receivable);
        

        emit BuyINFL(msg.sender, estimatedPrice);
    }

    /**
     * @dev Sell INFL 
     * @notice burn 10% of sold, 
     * @notice spread 10% of solidity
     */
    function sell(uint256 _amountToSell) public{

        uint256 quotedPrice = price(totalSupply());
        uint256 sellable =  _amountToSell * quotedPrice ;
        uint256 volume =  balanceOf(msg.sender);
        require(_amountToSell <= volume, "Don't have enough INFL tokens");
        uint256 toBurn = _amountToSell / 10 ;
        uint256 spread = _amountToSell / 10 ;
        uint256 receivable = _amountToSell - toBurn - spread;
        // transfer sold tokens to owner
         _transfer(msg.sender, owner(), receivable);
        // burn 10% to treasury
        ICO.burn(address(this), toBurn);
        // spread fee 10% to treasury
         ICO.burn(address(this), spread);
        emit SellINFL(msg.sender, _amountToSell);
    }
}