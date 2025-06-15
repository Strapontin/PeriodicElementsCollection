// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {PeriodicElementsCollection} from "src/PeriodicElementsCollection.sol";
import {DarkMatterTokens} from "src/DarkMatterTokens.sol";
import {ElementsData} from "src/ElementsData.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {PECDeployer} from "script/PECDeployer.s.sol";
import {PECTestContract} from "test/contracts/PECTestContract.sol";

import {Test, console2} from "forge-std/Test.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {FundSubscription} from "script/VRFInteractions.s.sol";
import {PECBaseTest} from "../PECBaseTest.t.sol";
import {IERC1155Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

contract PECTransfersTest is PECBaseTest {
    function test_dmtIsNotBuyableBefore14Days() public {
        vm.expectRevert(DarkMatterTokens.DMT__DelayNotPassedYet.selector);
        dmt.buy{value: 1 ether}();

        vm.warp(block.timestamp + 14 days);

        vm.expectRevert(DarkMatterTokens.DMT__DelayNotPassedYet.selector);
        dmt.buy{value: 1 ether}();

        vm.warp(block.timestamp + 1);

        dmt.buy{value: 1 ether}();
    }

    // TODO
}
