// Make this a Hook-based implementation, as opposed to an ERC20
// based solution. This means that the user has flexibility
// with token management prior to using Uniswap v4 w/ this
// custom hook

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {CustomCurveBase} from "./CustomCurveBase.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
// import {UD60x18} from "@prb-math/UD60x18.sol";

abstract contract BondingCurveHook is CustomCurveBase {
    Currency public immutable tokenForSale;
    Currency public immutable tokenAccepted;
    // UD60x18 public totalPurchased;
    // UD60x18 public numTokensOffered;

    constructor(
        IPoolManager _poolManager,
        Currency _tokenForSale,
        Currency _tokenAccepted,
        uint256 _numTokensOffered
        ) CustomCurveBase(_poolManager) {
            tokenForSale = _tokenForSale;
            tokenAccepted = _tokenAccepted;
            _numTokensOffered = _numTokensOffered;
        }
}
