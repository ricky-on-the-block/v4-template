// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Console.sol";
import {BondingCurveHook} from "@main/BondingCurveHook.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import { SD59x18, sd, convert } from "@prb/math/src/SD59x18.sol";

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

    // original impl returns: 4372135954999792963595
    // prb-math returns: 4373253849269222075384
    function calculateTokensSold(uint256 inputTokenAmount) public view returns (uint256 outputTokenAmount) {
        SD59x18 test = sd(int256(numTokensSold));
        SD59x18 _numTokensSold = sd(int256(numTokensSold));
        SD59x18 _initialPrice = sd(int256(initialPrice));
        SD59x18 _inputTokenAmount = sd(int256(inputTokenAmount));

        // a,b,c of quadratic formula (scaled for precision)
        SD59x18 a = sd(int256(slope));
        SD59x18 b = convert(2).mul(_initialPrice);
        SD59x18 c = convert(-2).mul(_inputTokenAmount).sub(
            a.mul(_numTokensSold).mul(_numTokensSold)).sub(
                convert(2).mul(_initialPrice).mul(_numTokensSold));

        // Calculate the discriminant
        SD59x18 discriminant = b.mul(b).sub(convert(4).mul(a).mul(c));
        require(discriminant.gte(convert(0)), "No real solutions exist");

        // Calculate the square root of the discriminant
        SD59x18 sqrtDiscriminant = discriminant.sqrt();

        // Calculate the two possible solutions
        SD59x18 solution1 = (b.mul(convert(-1)).add(sqrtDiscriminant)).div(convert(2).mul(a)); //(-b + int256(sqrtDiscriminant)) / (2 * a);
        SD59x18 solution2 = (b.mul(convert(-1)).sub(sqrtDiscriminant)).div(convert(2).mul(a)); //(-b - int256(sqrtDiscriminant)) / (2 * a);

        // Return the larger solution (assuming we want to maximize tokens sold)
        return uint256(SD59x18.unwrap(solution1 > solution2 ? solution1 : solution2));
        //return uint256(solution1 > solution2 ? solution1 : solution2);
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
