// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {LinearCurveHook} from "@main/curves/LinearCurveHook.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {Deployers} from "v4-core/test/utils/Deployers.sol";

contract LinearCurveHookTest is Test, Deployers {
    LinearCurveHook public hook;

    function setUp() public {
        // creates the pool manager, utility routers, and test tokens
        deployFreshManagerAndRouters();
        deployMintAndApprove2Currencies();
    }

    function testCalculateIntegral() public {
        uint256 slope = 3;          // m in y=mx+b
        uint256 initialPrice = 5;   // b in y=mx+b

        // Deploy the hook to an address with the correct flags
        address flags = address(
            uint160(Hooks.BEFORE_ADD_LIQUIDITY_FLAG | Hooks.BEFORE_SWAP_FLAG | Hooks.BEFORE_SWAP_RETURNS_DELTA_FLAG)
                ^ (0x4444 << 144) // Namespace the hook to avoid collisions
        );
        bytes memory constructorArgs = 
            abi.encode(
                manager,
                currency1,
                currency0,
                1_000_000,
                slope,
                initialPrice); // Add all the necessary constructor arguments from the hook
        deployCodeTo("LinearCurveHook.sol:LinearCurveHook", constructorArgs, flags);
        hook = LinearCurveHook(flags);

        // Test cases
        uint256[] memory inputs = new uint256[](5);
        inputs[0] = 0;
        inputs[1] = 10;
        inputs[2] = 20;
        inputs[3] = 30;
        inputs[4] = 40;

        uint256[] memory expectedOutputs = new uint256[](5);
        expectedOutputs[0] = 0;
        expectedOutputs[1] = 200;
        expectedOutputs[2] = 700;
        expectedOutputs[3] = 1500;
        expectedOutputs[4] = 2600;

        for (uint256 i = 0; i < inputs.length; i++) {
            uint256 actualOutput = hook.calculateIntegral(inputs[i]);
            assertEq(actualOutput, expectedOutputs[i], "Incorrect integral calculation");
        }
    }
}