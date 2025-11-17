// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {PeriodicElementsCollection} from "src/PeriodicElementsCollection.sol";
import {PECBaseTest} from "test/PECBaseTest.t.sol";

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

    function test_minAmountToSendToMint(uint32 universesCreated) public {
        universesCreated = uint32(bound(universesCreated, 0, 1_000_000));
        pec.setTotalUniversesCreated(universesCreated);

        uint256 expected =
            pec.DMT_FEE_PER_TRANSFER() * (1e18 + uint256(universesCreated) * pec.DMT_PRICE_INCREASE_PER_UNIVERSE())
            / 1e18;
        assertEq(dmt.minAmountToSendToMint(), expected);
    }
}
