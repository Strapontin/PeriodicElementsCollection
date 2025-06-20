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
import {PECBaseTest} from "test/PECBaseTest.t.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract PECBigBangTest is PECBaseTest {
    function test_bigBangWorksWhenUserHaveAllElements() public {
        pec.mintAll(alice);

        // Increase `usersLevel`
        pec.setUserLevel(alice, 7);
        assertEq(pec.usersLevel(alice), 7);

        // Increase `amountTransfers`
        pec.setAmountTransfers(alice, 10);
        assertEq(pec.amountTransfers(alice), 10);

        // Increase `burnedTimes`
        pec.setUserElementBurnedTimes(alice, 1, 5);
        assertEq(pec.burnedTimes(alice, 1), 5);

        pec.bigBang(alice);

        // Variables related to big bang increase
        assertEq(pec.universesCreated(alice), 1);
        assertEq(pec.totalUniversesCreated(), 1);

        // `usersLevel` is reset to 1
        assertEq(pec.usersLevel(alice), 1);
        // `amountTransfers` is reset to 0
        assertEq(pec.amountTransfers(alice), 0);
        // `burnedTimes` is reset to 0
        assertEq(pec.burnedTimes(alice, 1), 0);
    }

    function test_bigBangRevertsWhenUsersDontHaveAllElements(uint256 elementToRemove, bool removeMatter) public {
        elementToRemove = bound(elementToRemove, 1, pec.getElementsUnlockedUnderLevel(7).length);
        if (!removeMatter) {
            elementToRemove += ANTIMATTER_OFFSET;
        }

        pec.mintAll(alice);

        uint256[] memory ids = new uint256[](1);
        uint256[] memory values = new uint256[](1);

        ids[0] = elementToRemove;
        values[0] = 1;

        vm.prank(alice);
        pec.increaseRelativeAtomicMass(ids, values);

        vm.expectRevert(
            abi.encodeWithSelector(
                PeriodicElementsCollection.PEC__UserDoesNotHaveAllElementsToCallBigBang.selector, elementToRemove
            )
        );
        pec.bigBang(alice);
    }
}
