// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {BondingCurveHook} from "@main/BondingCurveHook.sol";
// import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
import {CurrencySettler} from "v4-core/test/utils/CurrencySettler.sol";

contract ConstSumCurveHook is BondingCurveHook {
    using CurrencySettler for Currency;

    constructor(IPoolManager _poolManager, Currency _tokenForSale, Currency _tokenAccepted, uint256 _numTokensOffered)
        BondingCurveHook(_poolManager, _tokenForSale, _tokenAccepted, _numTokensOffered)
    {}

    function getAmountOutFromExactInput(uint256 _amountIn, Currency, Currency, bool)
        internal
        pure
        override
        returns (uint256 amountIn, uint256 amountOut)
    {
        // in constant-sum curve, tokens trade exactly 1:1
        return (_amountIn, _amountIn);
    }

    function getAmountInForExactOutput(uint256 _amountOut, Currency, Currency, bool)
        internal
        pure
        override
        returns (uint256 amountIn, uint256 amountOut)
    {
        // in constant-sum curve, tokens trade exactly 1:1
        return (_amountOut, _amountOut);
    }

    function getCurrentPrice() external pure override returns (uint256) {
        return 1;
    }
}
