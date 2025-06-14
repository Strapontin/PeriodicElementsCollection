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

contract PECMintTest is PECBaseTest {
    modifier fundSubscriptionMax() {
        fundSubscription.fundSubscription(config, type(uint256).max - 3 ether);
        _;
    }

    modifier setAllEllementsArtificialRamEqual() {
        pec.setAllEllementsArtificialRamEqual();
        _;
    }

    function test_fulfillRandomWordsCanOnlyBeCalledAfterRequestId() public {
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(0, address(pec));

        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(1, address(pec));
    }

    function test_mintingStates() public fundSubscriptionMax {
        vm.prank(user);
        uint256 requestId = pec.mintPack{value: PACK_PRICE}();

        // Status is now Pending for VRF Callback
        assertEq(
            uint256(PeriodicElementsCollection.VRFStatus.PendingVRFCallback),
            uint256(pec.getVRFStateFromRequestId(requestId).status)
        );

        vm.prank(address(vrfCoordinator));
        vrfCoordinator.fulfillRandomWords(requestId, address(pec));

        // Status is now Ready To Mint (need EOA call)
        assertEq(
            uint256(PeriodicElementsCollection.VRFStatus.ReadyToMint),
            uint256(pec.getVRFStateFromRequestId(requestId).status)
        );

        pec.unpackRandomMatter(requestId);

        // Status is now Minted
        assertEq(
            uint256(PeriodicElementsCollection.VRFStatus.Minted),
            uint256(pec.getVRFStateFromRequestId(requestId).status)
        );
    }

    function test_refund() public {
        // 1st test, pay 1.5 pack, should pay back 0.5
        vm.startPrank(user);
        pec.mintPack{value: PACK_PRICE + PACK_PRICE / 2}();

        assertEq(type(uint128).max - PACK_PRICE, user.balance);

        // 2nd test, should not pay more than max amount possible
        // Note that it pays back 1 more PACK_PRICE due to previous mintPack
        pec.mintPack{value: user.balance}();
        assertEq(type(uint128).max - (PACK_PRICE + PACK_PRICE * NUM_MAX_PACKS_MINTED_AT_ONCE), user.balance);
    }

    function test_mintFreePacksShouldMint5HeliumAndHydrogen() public {
        vm.warp(block.timestamp + 1e18);
        vm.startPrank(user);
        pec.mintFreePacks();

        assertEq(pec.totalSupply(), 70);
    }

    function test_mintFreeTwiceShouldNotGiveMore() public {
        vm.warp(block.timestamp + 1e18);
        vm.startPrank(user);
        pec.mintFreePacks();

        vm.expectRevert(PeriodicElementsCollection.PEC__NoPackToMint.selector);
        pec.mintFreePacks();

        assertEq(pec.totalSupply(), 70);
    }

    function test_mintFreeEveryDayShouldGive1Pack() public {
        vm.warp(block.timestamp + 1e18);
        vm.startPrank(user);
        pec.mintFreePacks();

        vm.warp(block.timestamp + 1 days);

        pec.mintFreePacks();
        assertEq(pec.totalSupply(), 80);

        vm.warp(block.timestamp + 1 days);

        pec.mintFreePacks();
        assertEq(pec.totalSupply(), 90);

        vm.warp(block.timestamp + 1 days);

        pec.mintFreePacks();
        assertEq(pec.totalSupply(), 100);
    }

    function test_payForXpacksMints5XElements(uint256 packsToMint) public fundSubscriptionMax {
        packsToMint = bound(packsToMint, 1, NUM_MAX_PACKS_MINTED_AT_ONCE);

        vm.prank(user);
        uint256 requestId = pec.mintPack{value: PACK_PRICE * packsToMint}();

        vm.prank(address(vrfCoordinator));
        vrfCoordinator.fulfillRandomWords(requestId, address(pec));

        pec.unpackRandomMatter(requestId);

        assertEq(pec.totalSupply(), packsToMint * ELEMENTS_IN_PACK);
    }

    function test_matterWorks() public fundSubscriptionMax {
        // Shift to avoid having a modulo of 10k to not mint antimatter
        uint256 matter = 1 << 242;

        (, uint256 totalWeight,) = pec.getRealUserWeights(user);
        uint256 offset = matter % totalWeight;

        uint256[] memory randomWords = new uint256[](5);
        randomWords[0] = matter;
        randomWords[1] = matter - offset + totalWeight - 1; // Last unlocked element
        randomWords[2] = matter - offset + totalWeight - 1;
        randomWords[3] = matter;
        randomWords[4] = matter;

        vm.prank(user);
        uint256 requestId = pec.mintPack{value: PACK_PRICE}();

        vm.prank(address(vrfCoordinator));
        vrfCoordinator.fulfillRandomWordsWithOverride(requestId, address(pec), randomWords);
        pec.unpackRandomMatter(requestId);

        for (uint256 i = 0; i < 3; i++) {
            console2.log("Matter", i, pec.balanceOf(user, i));
        }
        for (uint256 i = 0; i < 3; i++) {
            console2.log("Antimatter", i, pec.balanceOf(user, i + ANTIMATTER_OFFSET));
        }

        assertEq(pec.balanceOf(user, 1), 3); // 3 Hydrogen
        assertEq(pec.balanceOf(user, 2), 2); // 2 Helium
    }

    function test_mintAntimatter() public fundSubscriptionMax {
        (, uint256 totalWeight,) = pec.getRealUserWeights(user);

        uint256[] memory randomWords = new uint256[](5);
        randomWords[0] = 0;
        randomWords[1] = totalWeight - 1; // Last unlocked element
        randomWords[2] = totalWeight - 1;
        randomWords[3] = 0;
        randomWords[4] = 0;

        vm.prank(user);
        uint256 requestId = pec.mintPack{value: PACK_PRICE}();

        vm.prank(address(vrfCoordinator));
        vrfCoordinator.fulfillRandomWordsWithOverride(requestId, address(pec), randomWords);
        pec.unpackRandomMatter(requestId);

        assertEq(pec.balanceOf(user, ANTIMATTER_OFFSET + 1), 3); // 3 Hydrogen
        assertEq(pec.balanceOf(user, ANTIMATTER_OFFSET + 2), 2); // 2 Helium
    }

    function test_elementsUnlockedByPlayer() public {
        // By default should be 2 elements
        uint256[] memory elements = pec.getElementsUnlockedByPlayer(user);
        assertEq(elements.length, 2);

        // At level 2 should be 10, etc
        pec.setUserLevel(user, 1);
        elements = pec.getElementsUnlockedByPlayer(user);
        assertEq(elements.length, 10);

        pec.setUserLevel(user, 2);
        elements = pec.getElementsUnlockedByPlayer(user);
        assertEq(elements.length, 18);

        pec.setUserLevel(user, 3);
        elements = pec.getElementsUnlockedByPlayer(user);
        assertEq(elements.length, 36);

        pec.setUserLevel(user, 4);
        elements = pec.getElementsUnlockedByPlayer(user);
        assertEq(elements.length, 54);

        pec.setUserLevel(user, 5);
        elements = pec.getElementsUnlockedByPlayer(user);
        assertEq(elements.length, 86);

        pec.setUserLevel(user, 6);
        elements = pec.getElementsUnlockedByPlayer(user);
        assertEq(elements.length, 118);
    }
}
