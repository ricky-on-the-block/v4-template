// NOTE: This file is kept as provided by Uniswap v4 Example Code
// NOTE: New functionality is in BondingCurveHook.sol and curves/*.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {BaseHook} from "v4-periphery/src/base/hooks/BaseHook.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {Currency, CurrencyLibrary} from "v4-core/src/types/Currency.sol";
import {toBeforeSwapDelta, BeforeSwapDelta} from "v4-core/src/types/BeforeSwapDelta.sol";
import {CurrencySettler} from "v4-core/test/utils/CurrencySettler.sol";
import {SafeCast} from "v4-core/src/libraries/SafeCast.sol";

abstract contract CustomCurveBase is BaseHook {
    using CurrencyLibrary for Currency;
    using CurrencySettler for Currency;
    using SafeCast for uint256;

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

    /// NOTE: In the inheriting contract, define a function to add liquidity...

    /// @notice Returns the amount of output tokens for an exact-input swap
    /// @param amountIn the amount of input tokens
    /// @param input the input token
    /// @param output the output token
    /// @param zeroForOne true if the input token is token0
    /// @return amountIn  in the event that not all input is used, this is returned as the actual amount used
    /// @return amountOut the amount of output tokens
    function getAmountOutFromExactInput(uint256 _amountIn, Currency input, Currency output, bool zeroForOne)
        internal
        virtual
        returns (uint256 amountIn, uint256 amountOut);

    /// @notice Returns the amount of input tokens for an exact-output swap
    /// @param amountOut the amount of output tokens the user expects to receive
    /// @param input the input token
    /// @param output the output token
    /// @param zeroForOne true if the input token is token0
    /// @return amountIn the amount of input tokens required to produce amountOut
    /// @return amountOut in the event that not all output is met, this is returned as the actual amount used
    function getAmountInForExactOutput(uint256 _amountOut, Currency input, Currency output, bool zeroForOne)
        internal
        virtual
        returns (uint256 amountIn, uint256 amountOut);

    /// @dev Facilitate a custom curve via beforeSwap + return delta
    /// @dev input tokens are taken from the PoolManager, creating a debt paid by the swapper
    /// @dev output takens are transferred from the hook to the PoolManager, creating a credit claimed by the swapper
    function beforeSwap(address, PoolKey calldata key, IPoolManager.SwapParams calldata params, bytes calldata)
        external
        override
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        bool exactInput = params.amountSpecified < 0;
        (Currency specified, Currency unspecified) =
            (params.zeroForOne == exactInput) ? (key.currency0, key.currency1) : (key.currency1, key.currency0);

        uint256 specifiedAmount = exactInput ? uint256(-params.amountSpecified) : uint256(params.amountSpecified);
        uint256 unspecifiedAmount;
        BeforeSwapDelta returnDelta;
        if (exactInput) {
            // in exact-input swaps, the specified token is a debt that gets paid down by the swapper
            // the unspecified token is credited to the PoolManager, that is claimed by the swapper
            (unspecifiedAmount, specifiedAmount) =
                getAmountOutFromExactInput(specifiedAmount, specified, unspecified, params.zeroForOne);
            
            specified.take(poolManager, address(this), specifiedAmount, true);
            unspecified.settle(poolManager, address(this), unspecifiedAmount, true);

            returnDelta = toBeforeSwapDelta(specifiedAmount.toInt128(), -unspecifiedAmount.toInt128());
        } else {
            // exactOutput
            // in exact-output swaps, the unspecified token is a debt that gets paid down by the swapper
            // the specified token is credited to the PoolManager, that is claimed by the swapper
            (specifiedAmount, unspecifiedAmount) =
                getAmountInForExactOutput(specifiedAmount, unspecified, specified, params.zeroForOne);
            
            unspecified.take(poolManager, address(this), unspecifiedAmount, true);
            specified.settle(poolManager, address(this), specifiedAmount, true);

            returnDelta = toBeforeSwapDelta(-specifiedAmount.toInt128(), unspecifiedAmount.toInt128());
        }

        return (BaseHook.beforeSwap.selector, returnDelta, 0);
    }

    /// @notice No liquidity will be managed by v4 PoolManager
    function beforeAddLiquidity(address, PoolKey calldata, IPoolManager.ModifyLiquidityParams calldata, bytes calldata)
        external
        pure
        override
        returns (bytes4)
    {
        revert("No v4 liquidity allowed");
    }

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: true, // -- disable v4 liquidity with a revert -- //
            beforeRemoveLiquidity: false,
            afterAddLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: true, // -- Custom Curve Handler --  //
            afterSwap: false,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: true, // -- Enables Custom Curves --  //
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    /// @notice Add liquidity through the hook
    /// @dev Not production-ready, only serves an example of hook-owned liquidity
    function addLiquidity(PoolKey calldata key, uint256 amount0, uint256 amount1) external {
        poolManager.unlock(
            abi.encodeCall(this.handleAddLiquidity, (key.currency0, key.currency1, amount0, amount1, msg.sender))
        );
    }

    /// @dev Handle liquidity addition by taking tokens from the sender and claiming ERC6909 to the hook address
    function handleAddLiquidity(
        Currency currency0,
        Currency currency1,
        uint256 amount0,
        uint256 amount1,
        address sender
    ) external selfOnly returns (bytes memory) {
        currency0.settle(poolManager, sender, amount0, false);
        currency0.take(poolManager, address(this), amount0, true);

        currency1.settle(poolManager, sender, amount1, false);
        currency1.take(poolManager, address(this), amount1, true);

        return abi.encode(amount0, amount1);
    }
}
