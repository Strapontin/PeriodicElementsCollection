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

contract PECBurnTest is PECBaseTest {
    function test_increaseRelativeAtomicMassIncrease() public {
        pec.mintAll(user);

        uint256 hydrogenRamBefore = pec.getElementArtificialRAMWeight(user, 1);
        uint256 heliumRamBefore = pec.getElementArtificialRAMWeight(user, 2);

        uint256[] memory ids = new uint256[](2);
        uint256[] memory values = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;
        values[0] = 1;
        values[1] = 1;

        vm.prank(user);
        pec.increaseRelativeAtomicMass(ids, values);

        uint256 hydrogenRamAfter = pec.getElementArtificialRAMWeight(user, 1);
        uint256 heliumRamAfter = pec.getElementArtificialRAMWeight(user, 2);

        assertGt(hydrogenRamBefore, hydrogenRamAfter);
        assertGt(heliumRamBefore, heliumRamAfter);
    }

    function test_burningMultipleTimesIncreaseMassMultipleTimes(uint256 times, bool isMatter) public {
        times = bound(times, 1, 100_000);
        vm.assume(times > 1 && times < 100_000);

        // Mint enough elements for the user
        uint256[] memory mintIds = new uint256[](2);
        uint256[] memory mintValues = new uint256[](2);
        mintIds[0] = 1 + (isMatter ? 0 : ANTIMATTER_OFFSET);
        mintIds[1] = 2 + (isMatter ? 0 : ANTIMATTER_OFFSET);
        mintValues[0] = times + 1;
        mintValues[1] = times + 1;
        pec.forceMint(user, mintIds, mintValues);
        pec.forceMint(user2, mintIds, mintValues);

        // Action of burning
        uint256[] memory ids = new uint256[](2);
        uint256[] memory values = new uint256[](2);
        ids[0] = 1 + (isMatter ? 0 : ANTIMATTER_OFFSET);
        ids[1] = 2 + (isMatter ? 0 : ANTIMATTER_OFFSET);
        values[0] = times;
        values[1] = times;

        vm.prank(user);
        pec.increaseRelativeAtomicMass(ids, values);

        values[0]++;
        values[1]++;

        vm.prank(user2);
        pec.increaseRelativeAtomicMass(ids, values);

        assertEq(pec.burnedTimes(user, 1 + (isMatter ? 0 : ANTIMATTER_OFFSET)), times * (isMatter ? 1 : 100));
        assertEq(pec.burnedTimes(user, 2 + (isMatter ? 0 : ANTIMATTER_OFFSET)), times * (isMatter ? 1 : 100));

        // since user2 burned one more time than user, we expect him to have a lower RAM weight
        assertGt(
            pec.getElementArtificialRAMWeight(user, 1 + (isMatter ? 0 : ANTIMATTER_OFFSET)),
            pec.getElementArtificialRAMWeight(user2, 1 + (isMatter ? 0 : ANTIMATTER_OFFSET))
        );
        assertGt(
            pec.getElementArtificialRAMWeight(user, 2 + (isMatter ? 0 : ANTIMATTER_OFFSET)),
            pec.getElementArtificialRAMWeight(user2, 2 + (isMatter ? 0 : ANTIMATTER_OFFSET))
        );
    }

    function test_cantIncreaseRelativeAtomicMassWithIncorrectParameters() public {
        pec.mintAll(user);

        uint256[] memory ids = new uint256[](0);
        uint256[] memory values = new uint256[](0);

        vm.prank(user);
        vm.expectRevert(PeriodicElementsCollection.PEC__IncorrectParameters.selector);
        pec.increaseRelativeAtomicMass(ids, values);

        ids = new uint256[](2);
        values = new uint256[](1);
        ids[0] = 1;
        ids[1] = 2;
        values[0] = 1;

        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(IERC1155Errors.ERC1155InvalidArrayLength.selector, 2, 1));
        pec.increaseRelativeAtomicMass(ids, values);
    }

    function test_burnHydrogen4TimesMakesItHeavierThanHelium() public {
        pec.mintAll(user, 5);

        uint256[] memory ids = new uint256[](1);
        uint256[] memory values = new uint256[](1);
        ids[0] = 1;
        values[0] = 1;

        vm.startPrank(user);
        for (uint256 i = 0; i < 3; i++) {
            // Before the 4th burn, Helium's RAM is lower than Hydrogen's
            assertLt(pec.getElementArtificialRAMWeight(user, 2), pec.getElementArtificialRAMWeight(user, 1));
            pec.increaseRelativeAtomicMass(ids, values);
        }

        // After the 4th burn, Hydrogen's RAM is higher than Helium's
        assertGt(pec.getElementArtificialRAMWeight(user, 2), pec.getElementArtificialRAMWeight(user, 1));
    }
}
