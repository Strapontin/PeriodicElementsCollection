// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {PeriodicElementsCollection} from "src/PeriodicElementsCollection.sol";
import {console2} from "forge-std/Test.sol";
import {PECBaseTest} from "test/PECBaseTest.t.sol";

contract PECFuseTest is PECBaseTest {
    function test_useCaseLevelUp() public {
        vm.warp(block.timestamp + 7 days);
        vm.startPrank(alice);

        // User is level 0
        assertEq(pec.usersLevel(alice), 0);

        pec.mintFreePacks();

        // User is level 1 and can only mint 2 elements
        assertEq(pec.usersLevel(alice), 1);
        uint256[] memory elements = pec.getElementsUnlockedByPlayer(alice);
        assertEq(elements.length, 2);

        pec.fuseToNextLevel(1, 5, true);

        // User is level 2 and can mint 10 elements
        assertEq(pec.usersLevel(alice), 2);
        elements = pec.getElementsUnlockedByPlayer(alice);
        assertEq(elements.length, 10);
    }

    function test_fuseNextLevel() public {
        // For this test to succeed:
        //  - alice needs to be lvl 7
        //  - alice needs to have one elements of each (matter & antimatter)
        pec.mintAll(alice);
        vm.startPrank(alice);

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
        for (uint256 i = 0; i < pec.getElementsUnlockedByPlayer(alice).length; i++) {
            amountLeft += pec.balanceOf(alice, i + 1);
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

        for (uint256 i = 0; i < pec.getElementsUnlockedByPlayer(alice).length; i++) {
            amountLeft += pec.balanceOf(alice, i + 1 + ANTIMATTER_OFFSET);
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

        pec.mintAll(alice);
        vm.startPrank(alice);

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

    function test_fuseMatterLvl7ShouldGiveAntimatterLvl1() public fundSubscriptionMax {
        pec.mintAll(alice);
        vm.startPrank(alice);

        uint256 requestId = pec.fuseToNextLevel(7, 1, true);
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = 1; // 1st element minted

        vrfCoordinator.fulfillRandomWordsWithOverride(requestId, address(pec), randomWords);
        (uint256[] memory ids,) = pec.unpackRandomMatter(requestId);

        assertEq(ids.length, 1);
        assertEq(ids[0], 1 + ANTIMATTER_OFFSET); // Should be antimatter lvl 1
        console2.log("Minted antimatter element:", ids[0]);
    }
}
