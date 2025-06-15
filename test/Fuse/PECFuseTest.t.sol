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
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract PECFuseTest is PECBaseTest {
    function test_useCaseLevelUp() public {
        vm.warp(block.timestamp + 7 days);
        vm.startPrank(user);

        // User is level 0
        assertEq(pec.usersLevel(user), 0);

        pec.mintFreePacks();

        // User is level 1 and can only mint 2 elements
        assertEq(pec.usersLevel(user), 1);
        uint256[] memory elements = pec.getElementsUnlockedByPlayer(user);
        assertEq(elements.length, 2);

        pec.fuseToNextLevel(1, 5, true);

        // User is level 2 and can mint 10 elements
        assertEq(pec.usersLevel(user), 2);
        elements = pec.getElementsUnlockedByPlayer(user);
        assertEq(elements.length, 10);
    }

    function test_fuseNextLevel() public {
        // For this test to succeed:
        //  - user needs to be lvl 7
        //  - user needs to have one elements of each (matter & antimatter)
        pec.mintAll(user);
        vm.startPrank(user);

        // The function fails when called with a level outside of the range
        vm.expectRevert(PeriodicElementsCollection.PEC__LevelDoesNotExist.selector);
        pec.fuseToNextLevel(0, 1, true);
        vm.expectRevert(PeriodicElementsCollection.PEC__LevelDoesNotExist.selector);
        pec.fuseToNextLevel(8, 1, true);

        // The function succeeds for all matter lvl, leaving 0 element behind
        pec.fuseToNextLevel(1, 1, true);
        pec.fuseToNextLevel(2, 1, true);
        pec.fuseToNextLevel(3, 1, true);
        pec.fuseToNextLevel(4, 1, true);
        pec.fuseToNextLevel(5, 1, true);
        pec.fuseToNextLevel(6, 1, true);
        pec.fuseToNextLevel(7, 1, true);

        // No element should be left (no newly created)
        uint256 amountLeft;
        for (uint256 i = 0; i < pec.getElementsUnlockedByPlayer(user).length; i++) {
            amountLeft += pec.balanceOf(user, i + 1);
        }
        assertEq(amountLeft, 0);

        // The function succeeds for all antimatter lvl except 7
        pec.fuseToNextLevel(1, 1, false);
        pec.fuseToNextLevel(2, 1, false);
        pec.fuseToNextLevel(3, 1, false);
        pec.fuseToNextLevel(4, 1, false);
        pec.fuseToNextLevel(5, 1, false);
        pec.fuseToNextLevel(6, 1, false);
        vm.expectRevert(PeriodicElementsCollection.PEC__CantFuseLastLevelOfAntimatter.selector);
        pec.fuseToNextLevel(7, 1, false);

        for (uint256 i = 0; i < pec.getElementsUnlockedByPlayer(user).length; i++) {
            amountLeft += pec.balanceOf(user, i + 1 + ANTIMATTER_OFFSET);
        }

        // User ends with the 32 antimatter elements of level 7, un-fusable
        assertEq(amountLeft, 32);
        assertEq(pec.totalSupply(), 32);
    }

    function test_fuseToNextLevelMustGiveElementOfNextLevel(uint256 level, bool isMatter, uint256 randomValue)
        public
        fundSubscriptionMax
    {
        level = bound(level, 1, 7);

        // Can't fuse to next level lvl 7 antimatter
        if (level == 7 && !isMatter) {
            vm.expectRevert(PeriodicElementsCollection.PEC__ZeroValue.selector);
            pec.fuseToNextLevel(level, 0, isMatter);
            return;
        }

        pec.mintAll(user);
        vm.startPrank(user);

        uint256 requestId = pec.fuseToNextLevel(level, 1, isMatter);

        // Now, we verify that the minting of new elements works correctly
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = randomValue;

        // For each request id, we unpack the element and assert it's from the next level
        vrfCoordinator.fulfillRandomWordsWithOverride(requestId, address(pec), randomWords);
        (uint256[] memory ids, uint256[] memory values) = pec.unpackRandomMatter(requestId);

        assertEq(ids.length, 1);
        assertEq(values.length, 1);
    }
}
