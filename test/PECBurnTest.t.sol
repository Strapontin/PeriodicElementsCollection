// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {PeriodicElementsCollection} from "src/PeriodicElementsCollection.sol";
import {PECBaseTest} from "test/PECBaseTest.t.sol";
import {IERC1155Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

contract PECBurnTest is PECBaseTest {
    function test_increaseRelativeAtomicMassIncrease() public {
        pec.mintAll(alice);

        uint256 hydrogenRamBefore = pec.getElementArtificialRAMWeight(alice, 1);
        uint256 heliumRamBefore = pec.getElementArtificialRAMWeight(alice, 2);

        uint256[] memory ids = new uint256[](2);
        uint256[] memory values = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;
        values[0] = 1;
        values[1] = 1;

        vm.prank(alice);
        pec.increaseRelativeAtomicMass(ids, values);

        uint256 hydrogenRamAfter = pec.getElementArtificialRAMWeight(alice, 1);
        uint256 heliumRamAfter = pec.getElementArtificialRAMWeight(alice, 2);

        assertGt(hydrogenRamBefore, hydrogenRamAfter);
        assertGt(heliumRamBefore, heliumRamAfter);
    }

    function test_burningMultipleTimesIncreaseMassMultipleTimes(uint256 times, bool isMatter) public {
        times = bound(times, 1, 100_000);
        vm.assume(times > 1 && times < 100_000);

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

        assertEq(pec.burnedTimes(alice, 1 + (isMatter ? 0 : ANTIMATTER_OFFSET)), times * (isMatter ? 1 : 100));
        assertEq(pec.burnedTimes(alice, 2 + (isMatter ? 0 : ANTIMATTER_OFFSET)), times * (isMatter ? 1 : 100));

        // since bob burned one more time than alice, we expect him to have a lower RAM weight
        assertGt(
            pec.getElementArtificialRAMWeight(alice, 1 + (isMatter ? 0 : ANTIMATTER_OFFSET)),
            pec.getElementArtificialRAMWeight(bob, 1 + (isMatter ? 0 : ANTIMATTER_OFFSET))
        );
        assertGt(
            pec.getElementArtificialRAMWeight(alice, 2 + (isMatter ? 0 : ANTIMATTER_OFFSET)),
            pec.getElementArtificialRAMWeight(bob, 2 + (isMatter ? 0 : ANTIMATTER_OFFSET))
        );
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
            assertLt(pec.getElementArtificialRAMWeight(alice, 2), pec.getElementArtificialRAMWeight(alice, 1));
            pec.increaseRelativeAtomicMass(ids, values);
        }

        // After the 30th burn, Hydrogen's RAM is higher than Helium's
        assertGt(pec.getElementArtificialRAMWeight(alice, 2), pec.getElementArtificialRAMWeight(alice, 1));
    }
}
