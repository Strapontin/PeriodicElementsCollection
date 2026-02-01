// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {PeriodicElementsCollection} from "src/PeriodicElementsCollection.sol";
import {PECBaseTest} from "test/PECBaseTest.t.sol";
import {IERC1155Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

contract PECBurnTest is PECBaseTest {
    function test_increaseRelativeAtomicMassIncrease() public {
        pec.mintAll(alice);

        uint256 hydrogenRamBefore = pec.getElementArtificialRamWeight(alice, 1);
        uint256 heliumRamBefore = pec.getElementArtificialRamWeight(alice, 2);

        uint256[] memory ids = new uint256[](2);
        uint256[] memory values = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;
        values[0] = 1;
        values[1] = 1;

        vm.prank(alice);
        pec.increaseRelativeAtomicMass(ids, values);

        uint256 hydrogenRamAfter = pec.getElementArtificialRamWeight(alice, 1);
        uint256 heliumRamAfter = pec.getElementArtificialRamWeight(alice, 2);

        assertGt(hydrogenRamBefore, hydrogenRamAfter);
        assertGt(heliumRamBefore, heliumRamAfter);
    }

    function test_burningMultipleTimesIncreaseMassMultipleTimes(uint256 times, bool isMatter) public {
        times = bound(times, 1, 100_000);

        // Mint enough elements for the alice
        uint256[] memory mintIds = new uint256[](2);
        uint256[] memory mintValues = new uint256[](2);
        mintIds[0] = 1 + (isMatter ? 0 : ANTIMATTER_OFFSET);
        mintIds[1] = 2 + (isMatter ? 0 : ANTIMATTER_OFFSET);
        mintValues[0] = times + 1;
        mintValues[1] = times + 1;
        pec.forceMint(alice, mintIds, mintValues);
        pec.forceMint(bob, mintIds, mintValues);

        // Action of burning
        uint256[] memory ids = new uint256[](2);
        uint256[] memory values = new uint256[](2);
        ids[0] = 1 + (isMatter ? 0 : ANTIMATTER_OFFSET);
        ids[1] = 2 + (isMatter ? 0 : ANTIMATTER_OFFSET);
        values[0] = times;
        values[1] = times;

        vm.prank(alice);
        pec.increaseRelativeAtomicMass(ids, values);

        values[0]++;
        values[1]++;

        vm.prank(bob);
        pec.increaseRelativeAtomicMass(ids, values);

        assertEq(pec.burnedTimes(alice, 1), times * (isMatter ? 1 : 1_000));
        assertEq(pec.burnedTimes(alice, 2), times * (isMatter ? 1 : 1_000));

        // since bob burned one more time than alice, we expect him to have a lower RAM weight
        assertGt(pec.getElementArtificialRamWeight(alice, 1), pec.getElementArtificialRamWeight(bob, 1));
        assertGt(pec.getElementArtificialRamWeight(alice, 2), pec.getElementArtificialRamWeight(bob, 2));
    }

    function test_cantIncreaseRelativeAtomicMassWithIncorrectParameters() public {
        pec.mintAll(alice);

        uint256[] memory ids = new uint256[](0);
        uint256[] memory values = new uint256[](0);

        vm.prank(alice);
        vm.expectRevert(PeriodicElementsCollection.PEC__IncorrectParameters.selector);
        pec.increaseRelativeAtomicMass(ids, values);

        ids = new uint256[](2);
        values = new uint256[](1);
        ids[0] = 1;
        ids[1] = 2;
        values[0] = 1;

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IERC1155Errors.ERC1155InvalidArrayLength.selector, 2, 1));
        pec.increaseRelativeAtomicMass(ids, values);
    }

    function test_burnHydrogen30TimesMakesItHeavierThanHelium() public {
        // Hydrogen RAM = 1.008
        // Helium RAM   = 4.002
        // Hydrogen's RAM will be higher than Helium's after the 30th burn
        // 1.008 + 30 * 0.1 = 4.008
        pec.mintAll(alice, 50);

        uint256[] memory ids = new uint256[](1);
        uint256[] memory values = new uint256[](1);
        ids[0] = 1;
        values[0] = 1;

        vm.startPrank(alice);
        for (uint256 i = 0; i < 30; i++) {
            // Before the 30th burn, Helium's RAM is lower than Hydrogen's
            assertLt(pec.getElementArtificialRamWeight(alice, 2), pec.getElementArtificialRamWeight(alice, 1));
            pec.increaseRelativeAtomicMass(ids, values);
        }

        // After the 30th burn, Hydrogen's RAM is higher than Helium's
        assertGt(pec.getElementArtificialRamWeight(alice, 2), pec.getElementArtificialRamWeight(alice, 1));
    }

    function test_lightestElementIsExpected() public {
        assertEq(pec.getLightestElementFromUserAtLevel(alice, 1), 1);
        assertEq(pec.getLightestElementFromUserAtLevel(alice, 2), 3);
        assertEq(pec.getLightestElementFromUserAtLevel(alice, 3), 11);
        assertEq(pec.getLightestElementFromUserAtLevel(alice, 4), 19);
        assertEq(pec.getLightestElementFromUserAtLevel(alice, 5), 37);
        assertEq(pec.getLightestElementFromUserAtLevel(alice, 6), 55);
        assertEq(pec.getLightestElementFromUserAtLevel(alice, 7), 87);
    }

    function test_lightestElementChangesAfterExpectedBurn() public {
        pec.mintAll(alice, 999);
        vm.startPrank(alice);

        assertLightestBurn(1, 1, 1, 29);
        assertLightestBurn(2, 3, 3, 20);
        assertLightestBurn(3, 11, 11, 13);
        assertLightestBurn(4, 19, 19, 9);
        assertLightestBurn(5, 37, 37, 21);
        assertLightestBurn(6, 55, 55, 44);
        assertLightestBurn(7, 87, 87, 30);
    }

    function assertLightestBurn(uint256 level, uint256 lightestElement, uint256 elementToBurn, uint256 amtBurnNecessary)
        private
    {
        burnAtLevel(elementToBurn, amtBurnNecessary);
        assertEq(pec.getLightestElementFromUserAtLevel(alice, level), lightestElement);
        burnAtLevel(elementToBurn, 1);
        assertEq(pec.getLightestElementFromUserAtLevel(alice, level), lightestElement + 1);
    }

    function burnAtLevel(uint256 id, uint256 amount) private {
        uint256[] memory ids = new uint256[](1);
        uint256[] memory values = new uint256[](1);
        ids[0] = id;
        values[0] = amount;

        pec.increaseRelativeAtomicMass(ids, values);
    }

    function test_lightestElementChanges100xAfterAntimatterBurn() public {
        pec.mintAll(alice, 99999);
        vm.startPrank(alice);

        // Burning one element of antimatter should be equivalent to burning 1000 elements of matter
        assertLightestBurn(1, 1, 1, 29);
        burnAtLevel(2 + ANTIMATTER_OFFSET, 1);
        assertLightestBurn(1, 1, 1, 999);
    }
}
