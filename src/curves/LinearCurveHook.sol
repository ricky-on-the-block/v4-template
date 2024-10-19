// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.20;

// import {BondingCurveHook} from "@main/BondingCurveHook.sol";
// import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
// import {Currency} from "v4-core/src/types/Currency.sol";
// import {UD60x18, ud, unwrap} from "@prb-math/UD60x18.sol";

// contract LinearCurveHook is BondingCurveHook {
//     UD60x18 public immutable slope;
//     UD60x18 public immutable initialPrice;

//     constructor(
//         IPoolManager _poolManager,
//         Currency _tokenForSale,
//         Currency _tokenAccepted,
//         uint256 _numTokensOffered,
//         uint256 _slope,
//         uint256 _initialPrice
//     ) BondingCurveHook(_poolManager, _tokenForSale, _tokenAccepted, _numTokensOffered) {
//         slope = ud(_slope);
//         initialPrice = ud(_initialPrice);
//     }

// }
