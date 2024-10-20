// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";

// import "forge-std/Console.sol";
import {console} from "forge-std/console.sol";
import {LinearCurveHook} from "@main/curves/LinearCurveHook.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {Deployers} from "v4-core/test/utils/Deployers.sol";

import {UD60x18, ud, convert} from "@prb/math/src/UD60x18.sol";
import {PRBMathAssertions} from "@prb/math/test/utils/Assertions.sol";
import {PRBTest} from "@prb/test/PRBTest.sol";

contract LinearCurveHookTest is PRBTest, StdCheats, Deployers {
    LinearCurveHook public hook;

    function setUp() public {
        // creates the pool manager, utility routers, and test tokens
        deployFreshManagerAndRouters();
        deployMintAndApprove2Currencies();

        // These defaults yield a total raised amount of 50k
        uint256 slope = 9999999999999; // m in y=mx+b
        uint256 initialPrice = 0.001e18; // b in y=mx+b

        // Deploy the hook to an address with the correct flags
        address flags = address(
            uint160(Hooks.BEFORE_ADD_LIQUIDITY_FLAG | Hooks.BEFORE_SWAP_FLAG | Hooks.BEFORE_SWAP_RETURNS_DELTA_FLAG)
                ^ (0x4444 << 144) // Namespace the hook to avoid collisions
        );
        bytes memory constructorArgs = abi.encode(manager, currency1, currency0, 1_000_000, slope, initialPrice); // Add all the necessary constructor arguments from the hook
        deployCodeTo("LinearCurveHook.sol:LinearCurveHook", constructorArgs, flags);
        hook = LinearCurveHook(flags);
    }

    // function testCalculateIntegral() public {
    //     // Test cases
    //     uint256[] memory inputs = new uint256[](5);
    //     inputs[0] = 0;
    //     inputs[1] = 10e18;
    //     inputs[2] = 20e18;
    //     inputs[3] = 30e18;
    //     inputs[4] = 40e18;

    //     uint256[] memory expectedOutputs = new uint256[](5);
    //     expectedOutputs[0] = 0;
    //     expectedOutputs[1] = 200e18;
    //     expectedOutputs[2] = 700e18;
    //     expectedOutputs[3] = 1500e18;
    //     expectedOutputs[4] = 2600e18;

    //     for (uint256 i = 0; i < inputs.length; i++) {
    //         uint256 actualOutput = hook.calculateIntegral(inputs[i]);
    //         assertEq(actualOutput, expectedOutputs[i], "Incorrect integral calculation");
    //     }
    // }

    function testCalculateTokensSold() public {
        // Test case 1: Positive input token amount
        uint256 inputTokenAmount = 100e18;
        uint256 tokensSold = hook.calculateTokensSold(inputTokenAmount);
        console.log("tokensSold:", tokensSold);
    }

    function testUnsignedPercentage() public {
        UD60x18 one_hundred_eth = ud(100 ether);
        UD60x18 fivePercent = ud(0.05e18);
        console.log("one_hundred_eth * 5%", UD60x18.unwrap(one_hundred_eth.mul(fivePercent)));
    }
}
