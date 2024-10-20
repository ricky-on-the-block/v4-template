// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Console.sol";
import {BondingCurveHook} from "@main/BondingCurveHook.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {Currency} from "v4-core/src/types/Currency.sol";

contract LinearCurveHook is BondingCurveHook {
    uint256 public immutable slope;
    uint256 public immutable initialPrice;

    constructor(
        IPoolManager _poolManager,
        Currency _tokenForSale,
        Currency _tokenAccepted,
        uint256 _numTokensOffered,
        uint256 _slope,
        uint256 _initialPrice
    ) BondingCurveHook(_poolManager, _tokenForSale, _tokenAccepted, _numTokensOffered) {
        slope = _slope;
        initialPrice = _initialPrice;
    }

    function calculateIntegral(uint256 x) public view returns (uint256) {
        return ((slope * x * x) / 2) + (initialPrice * x);
    }

    function buyFromBondingCurve(uint256 amountIn) internal view returns (uint256 amountOut) {
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

    function getCurrentPrice() external view override returns (uint256) {
        return slope * numTokensRemaining() + initialPrice;
    }
}
