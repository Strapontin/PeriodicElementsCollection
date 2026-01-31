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

        // The function succeeds for all matter lvl
        pec.fuseToNextLevel(1, 1, true);
        pec.fuseToNextLevel(2, 1, true);
        pec.fuseToNextLevel(3, 1, true);
        pec.fuseToNextLevel(4, 1, true);
        pec.fuseToNextLevel(5, 1, true);
        pec.fuseToNextLevel(6, 1, true);
        pec.fuseToNextLevel(7, 1, true);

        // Only the newly created elements should remain (6 elements + 1 antimatter not counted here)
        uint256 amountLeft;
        for (uint256 i = 0; i < pec.getElementsUnlockedByPlayer(alice).length; i++) {
            amountLeft += pec.balanceOf(alice, i + 1);
        }
        uint256 matterExpected = 6;
        assertEq(amountLeft, matterExpected);

        // The function succeeds for all antimatter lvl except 7
        pec.fuseToNextLevel(1, 1, false);
        pec.fuseToNextLevel(2, 1, false);
        pec.fuseToNextLevel(3, 1, false);
        pec.fuseToNextLevel(4, 1, false);
        pec.fuseToNextLevel(5, 1, false);
        pec.fuseToNextLevel(6, 1, false);
        vm.expectRevert(PeriodicElementsCollection.PEC__CantFuseLastLevelOfAntimatter.selector);
        pec.fuseToNextLevel(7, 1, false);

        amountLeft = 0;
        for (uint256 i = 0; i < pec.getElementsUnlockedByPlayer(alice).length; i++) {
            amountLeft += pec.balanceOf(alice, i + 1 + ANTIMATTER_OFFSET);
        }
        uint256 antimatterExpected = 7;

        // User ends with the 32 antimatter elements of level 7, un-fusable, + 6 new elements created + 1 created earlier
        assertEq(amountLeft, 32 + antimatterExpected);
        assertEq(pec.totalSupply(), 32 + antimatterExpected + matterExpected);
    }

    function test_fuseMustGiveElementOfNextLevel() public {
        pec.mintAll(alice, 99);
        vm.startPrank(alice);

        // Fusing matter of level 1 mints one element of id 3 (lightest of level 2)
        uint256 elementMinted = pec.fuseToNextLevel(1, 1, true);
        assertEq(elementMinted, 3);

        // Having burned a lot of id 11 (lightest of level 3) should result in minting element 12
        elementMinted = pec.fuseToNextLevel(2, 1, true);
        assertEq(elementMinted, 11);

        uint256[] memory ids = new uint256[](1);
        uint256[] memory values = new uint256[](1);
        ids[0] = 11;
        values[0] = 20;
        pec.increaseRelativeAtomicMass(ids, values);

        elementMinted = pec.fuseToNextLevel(2, 1, true);
        assertEq(elementMinted, 12);

        // Fusing lvl 7 should mint an antimatter of id 1
        elementMinted = pec.fuseToNextLevel(7, 1, true);
        assertEq(elementMinted, ANTIMATTER_OFFSET + 1);

        // Fusing antimatter should mint antimatter
        elementMinted = pec.fuseToNextLevel(1, 1, false);
        assertEq(elementMinted, ANTIMATTER_OFFSET + 3);
    }
}
