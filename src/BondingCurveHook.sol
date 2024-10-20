// Make this a Hook-based implementation, as opposed to an ERC20
// based solution. This means that the user has flexibility
// with token management prior to using Uniswap v4 w/ this
// custom hook

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {CustomCurveBase} from "./CustomCurveBase.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";

abstract contract BondingCurveHook is CustomCurveBase {
    Currency public immutable tokenForSale;
    Currency public immutable tokenAccepted;
    uint256 public totalPurchased;
    uint256 public immutable numTokensOffered;

    constructor(IPoolManager _poolManager, Currency _tokenForSale, Currency _tokenAccepted, uint256 _numTokensOffered)
        CustomCurveBase(_poolManager)
    {
        require(_numTokensOffered > 0, "Cannot offer 0 tokens");

        tokenForSale = _tokenForSale;
        tokenAccepted = _tokenAccepted;
        numTokensOffered = _numTokensOffered;
    }

    function numTokensRemaining() public view returns (uint256) {
        return numTokensOffered - totalPurchased;
    }

    // Allows front-end to query the price
    function getCurrentPrice() external view virtual returns (uint256);
}
