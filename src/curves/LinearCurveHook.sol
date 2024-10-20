// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Console.sol";
import {BondingCurveHook} from "@main/BondingCurveHook.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
import {UD60x18, ud, unwrap, powu} from "@prb-math/UD60x18.sol";

contract LinearCurveHook is BondingCurveHook {
    UD60x18 public immutable slope;
    UD60x18 public immutable initialPrice;

    constructor(
        IPoolManager _poolManager,
        Currency _tokenForSale,
        Currency _tokenAccepted,
        uint256 _numTokensOffered,
        uint256 _slope,
        uint256 _initialPrice
    ) BondingCurveHook(_poolManager, _tokenForSale, _tokenAccepted, _numTokensOffered) {
        slope = ud(_slope);
        initialPrice = ud(_initialPrice);
    }

    function calculateIntegral(uint256 _x) public view returns (uint256) {
        // Integral of mx + b is (m/2)x^2 + bx
        console.log(_x);
        console.log(UD60x18.unwrap(slope));
        uint256 _slope = UD60x18.unwrap(slope);
        uint256 _initialPrice = UD60x18.unwrap(initialPrice);
        // UD60x18 x = ud(_x);
        //console.log(x);
        // return UD60x18.unwrap(slope.mul(powu(x, 2)).div(ud(2)).add(initialPrice.mul(x)));
        // return (m.mul(x).mul(x).div(2).add(b.mul(x))).mul(PRECISION);
        
        return ((_slope * _x * _x) / 2) + (_initialPrice * _x);
    }

    function buyFromBondingCurve(uint256 amountIn) internal view returns (uint256 amountOut) {
        //UD60X18 currentIntegral = 
        return 0;
    }

    function getAmountOutFromExactInput(uint256 amountIn, Currency currency0, Currency currency1, bool zeroForOne)
        internal
        view
        override
        returns (uint256 amountOut)
    {
        require(
            currency0 == tokenForSale && currency1 == tokenAccepted ||
            currency1 == tokenForSale && currency0 == tokenAccepted,
            "Unexpected token input");

        if (currency0 == tokenForSale) {
            if (zeroForOne) {
                // User is selling to bonding curve

            }
            else {
                // User is buying from bonding curve
                amountOut = buyFromBondingCurve(amountIn);
            }
        }
        else {
            if (zeroForOne) {
                // User is buying from bonding curve
                amountOut = buyFromBondingCurve(amountIn);
            }
            else {
                // User is selling to bonding curve
            }
        }

        // amountOut can be either token, ex: USDC or MEME
        amountOut = 0;
    }

    function getAmountInForExactOutput(uint256 amountOut, Currency, Currency, bool)
        internal
        pure
        override
        returns (uint256 amountIn)
    {
        // in constant-sum curve, tokens trade exactly 1:1
        amountIn = amountOut;
    }

    function getCurrentPrice() external view override returns (UD60x18) {
        return slope.mul(numTokensRemaining()).add(initialPrice);
    }
}
