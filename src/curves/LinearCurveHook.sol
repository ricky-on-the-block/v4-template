// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Console.sol";
import {BondingCurveHook} from "@main/BondingCurveHook.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

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

    function calculateTokensSold(uint256 inputTokenAmount) public view returns (uint256 outputTokenAmount) {
        int256 _numTokensSold = int256(numTokensSold);
        int256 _initialPrice = int256(initialPrice);
        int256 _inputTokenAmount = int256(inputTokenAmount);

        uint256 PRECISION = 1e18;

        // a,b,c of quadratic formula (scaled for precision)
        int256 a = int256(slope);
        int256 b = 2 * _initialPrice;
        int256 c = (-2 * _inputTokenAmount * int256(PRECISION))
            - (a * _numTokensSold * _numTokensSold / int256(PRECISION))
            - (2 * _initialPrice * _numTokensSold / int256(PRECISION));

        // Calculate the discriminant
        int256 discriminant = b * b / int256(PRECISION) - 4 * a * c / int256(PRECISION);
        require(discriminant >= 0, "No real solutions exist");

        // Calculate the square root of the discriminant
        uint256 sqrtDiscriminant = Math.sqrt(uint256(discriminant));

        // Calculate the two possible solutions
        int256 solution1 = (-b + int256(sqrtDiscriminant)) * int256(PRECISION) / (2 * a);
        int256 solution2 = (-b - int256(sqrtDiscriminant)) * int256(PRECISION) / (2 * a);

        // Return the larger solution (assuming we want to maximize tokens sold)
        return uint256(solution1 > solution2 ? solution1 : solution2);
    }

    function calculateIntegral(uint256 x) public view returns (uint256) {
        return ((slope * x * x) / 2) + (initialPrice * x);
    }

    function calcDefiniteIntegral(uint256 x1, uint256 x2) public view returns (uint256) {
        return ((((x2 * x2) - (x1 * x1)) * slope) / 2) + (initialPrice * (x2 - x1));
    }

    function buyFromBondingCurve(uint256 _amountIn) internal view returns (uint256 amountIn, uint256 amountOut) {
        amountOut = calculateTokensSold(_amountIn);

        // check to see if we are near the token sale allocation
        uint256 _numTokensSold = numTokensSold;
        uint256 _numTokensOffered = numTokensOffered;
        uint256 numTokensRemaining = _numTokensOffered - _numTokensOffered;

        // if we can not use all input, we need to calculate how much of the input we can use
        // to do this, we take a definite integral [tokensSold, tokensOffered] mx + b dx
        // TODO: Test definite integral
        if (numTokensRemaining < amountOut) {
            amountOut = numTokensRemaining;
            amountIn = calcDefiniteIntegral(_numTokensSold, _numTokensOffered);
        }
    }

    function getAmountOutFromExactInput(uint256 _amountIn, Currency currency0, Currency currency1, bool zeroForOne)
        internal
        override
        returns (uint256 amountIn, uint256 amountOut)
    {
        require(
            currency0 == tokenForSale && currency1 == tokenAccepted
                || currency1 == tokenForSale && currency0 == tokenAccepted,
            "Unexpected token input"
        );

        // currency0 and currency1 order may be unpredictable. we must handle all permutations
        if (currency0 == tokenForSale) {
            if (zeroForOne) {
                // User is selling to bonding curve
                amountOut = 0;
            } else {
                // User is buying from bonding curve
                (amountIn, amountOut) = buyFromBondingCurve(_amountIn);
                numTokensSold += amountOut; // TODO: test this
            }
        } else {
            if (zeroForOne) {
                // User is buying from bonding curve
                (amountIn, amountOut) = buyFromBondingCurve(_amountIn);
                numTokensSold += amountOut; // TODO: test this
            } else {
                // User is selling to bonding curve
                amountOut = 0;
            }
        }
    }

    function getAmountInForExactOutput(uint256 _amountOut, Currency, Currency, bool)
        internal
        pure
        override
        returns (uint256 amountIn, uint256 amountOut)
    {
        return (0, 0);
    }

    function getCurrentPrice() external view override returns (uint256) {
        return slope * numTokensSold + initialPrice;
    }
}
