// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {PeriodicElementsCollection} from "src/PeriodicElementsCollection.sol";
import {DarkMatterTokens} from "src/DarkMatterTokens.sol";
import {ElementsData} from "src/ElementsData.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {PECDeployer} from "script/PECDeployer.s.sol";
import {PECTestContract, RevertOnReceive} from "test/contracts/PECTestContract.sol";

import {Test, console2} from "forge-std/Test.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {PECBaseTest} from "test/PECBaseTest.t.sol";

contract PECMintTest is PECBaseTest {
    function test_fulfillRandomWordsCanOnlyBeCalledAfterRequestId() public {
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(0, address(pec));

        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(1, address(pec));
    }

    function test_mintingStates() public fundSubscriptionMax {
        vm.prank(alice);
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
        vm.startPrank(alice);
        pec.mintPack{value: PACK_PRICE + PACK_PRICE / 2}();

        assertEq(type(uint128).max - PACK_PRICE, alice.balance);

        // 2nd test, should not pay more than max amount possible
        // Note that it pays back 1 more PACK_PRICE due to previous mintPack
        pec.mintPack{value: alice.balance}();
        assertEq(type(uint128).max - (PACK_PRICE + PACK_PRICE * NUM_MAX_PACKS_MINTED_AT_ONCE), alice.balance);
    }

    function test_mintFreePacksShouldMint5HeliumAndHydrogen() public {
        vm.warp(block.timestamp + 30 days);
        vm.startPrank(alice);
        pec.mintFreePacks();

        assertEq(pec.totalSupply(), 70);
    }

    function test_mintFreeTwiceShouldNotGiveMore() public {
        vm.warp(block.timestamp + 30 days);
        vm.startPrank(alice);
        pec.mintFreePacks();

        vm.expectRevert(PeriodicElementsCollection.PEC__NoPackToMint.selector);
        pec.mintFreePacks();

        assertEq(pec.totalSupply(), 70);
    }

    function test_mintFreeEveryDayShouldGive1Pack() public {
        vm.warp(block.timestamp + 1e18);
        vm.startPrank(alice);
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

    function test_shouldNotMintMoreThan500RandomWords(uint32 packsToMint) public fundSubscriptionMax {
        packsToMint = uint32(bound(packsToMint, 1, type(uint32).max));

        // Go through the process of minting a pack
        vm.prank(alice);
        uint256 requestId = pec.mintPack{value: PACK_PRICE * packsToMint}();
        vm.prank(address(vrfCoordinator));

        // After fulfillRandomWords is called, the state contains the amount of words requested
        vrfCoordinator.fulfillRandomWords(requestId, address(pec));
        PeriodicElementsCollection.VRFState memory state = pec.getVRFStateFromRequestId(requestId);

        assert(state.randomWords.length > 0 && state.randomWords.length <= 500);
    }

    function test_payForXpacksMints5XElements(uint256 packsToMint) public fundSubscriptionMax {
        packsToMint = bound(packsToMint, 1, NUM_MAX_PACKS_MINTED_AT_ONCE);

        vm.prank(alice);
        uint256 requestId = pec.mintPack{value: PACK_PRICE * packsToMint}();
        vm.prank(address(vrfCoordinator));
        vrfCoordinator.fulfillRandomWords(requestId, address(pec));

        (, uint256[] memory values) = pec.unpackRandomMatter(requestId);

        uint256 allValues;
        for (uint256 i = 0; i < values.length; i++) {
            allValues += values[i];
        }

        assertEq(allValues, pec.totalSupply());
        assertEq(pec.totalSupply(), packsToMint * ELEMENTS_IN_PACK);
    }

    function test_mintMatter() public fundSubscriptionMax {
        // Shift to avoid having a modulo of 10k to not mint antimatter
        uint256 matter = 1 << 242;

        (, uint256 totalWeight,) = pec.getRealUserWeightsAtLevel(alice, 0);
        uint256 offset = matter % totalWeight;

        uint256[] memory randomWords = new uint256[](5);
        randomWords[0] = matter;
        randomWords[1] = matter - offset + totalWeight - 1; // Last unlocked element
        randomWords[2] = matter - offset + totalWeight - 1;
        randomWords[3] = matter;
        randomWords[4] = matter;

        vm.prank(alice);
        uint256 requestId = pec.mintPack{value: PACK_PRICE}();

        vrfCoordinator.fulfillRandomWordsWithOverride(requestId, address(pec), randomWords);
        (uint256[] memory ids, uint256[] memory values) = pec.unpackRandomMatter(requestId);

        assertEq(pec.balanceOf(alice, 1), 3); // 3 Hydrogen
        assertEq(ids[0], 1);
        assertEq(values[0], 3);
        assertEq(pec.balanceOf(alice, 2), 2); // 2 Helium
        assertEq(ids[1], 2);
        assertEq(values[1], 2);
    }

    function test_mintAntimatter() public fundSubscriptionMax {
        (, uint256 totalWeight,) = pec.getRealUserWeightsAtLevel(alice, 0);

        uint256[] memory randomWords = new uint256[](5);
        randomWords[0] = 0;
        randomWords[1] = totalWeight - 1; // Last unlocked element
        randomWords[2] = totalWeight - 1;
        randomWords[3] = 0;
        randomWords[4] = 0;

        vm.prank(alice);
        uint256 requestId = pec.mintPack{value: PACK_PRICE}();

        vm.prank(address(vrfCoordinator));
        vrfCoordinator.fulfillRandomWordsWithOverride(requestId, address(pec), randomWords);
        (uint256[] memory ids, uint256[] memory values) = pec.unpackRandomMatter(requestId);

        assertEq(pec.balanceOf(alice, ANTIMATTER_OFFSET + 1), 3); // 3 Hydrogen
        assertEq(ids[0], ANTIMATTER_OFFSET + 1);
        assertEq(values[0], 3);
        assertEq(pec.balanceOf(alice, ANTIMATTER_OFFSET + 2), 2); // 2 Helium
        assertEq(ids[1], ANTIMATTER_OFFSET + 2);
        assertEq(values[1], 2);
    }

    function test_elementsUnlockedByPlayer() public {
        // By default should be 2 elements
        pec.setUserLevel(alice, 0);
        uint256[] memory elements = pec.getElementsUnlockedByPlayer(alice);
        assertEq(elements.length, 2);

        pec.setUserLevel(alice, 1);
        elements = pec.getElementsUnlockedByPlayer(alice);
        assertEq(elements.length, 2);

        // At level 2 should be 10, etc
        pec.setUserLevel(alice, 2);
        elements = pec.getElementsUnlockedByPlayer(alice);
        assertEq(elements.length, 10);

        pec.setUserLevel(alice, 3);
        elements = pec.getElementsUnlockedByPlayer(alice);
        assertEq(elements.length, 18);

        pec.setUserLevel(alice, 4);
        elements = pec.getElementsUnlockedByPlayer(alice);
        assertEq(elements.length, 36);

        pec.setUserLevel(alice, 5);
        elements = pec.getElementsUnlockedByPlayer(alice);
        assertEq(elements.length, 54);

        pec.setUserLevel(alice, 6);
        elements = pec.getElementsUnlockedByPlayer(alice);
        assertEq(elements.length, 86);

        pec.setUserLevel(alice, 7);
        elements = pec.getElementsUnlockedByPlayer(alice);
        assertEq(elements.length, 118);
    }

    function test_elementsAtLevel() public view {
        uint256[] memory elements = pec.getElementsAtLevel(1);
        assertEq(elements.length, 2);

        elements = pec.getElementsAtLevel(2);
        assertEq(elements.length, 8);

        elements = pec.getElementsAtLevel(3);
        assertEq(elements.length, 8);

        elements = pec.getElementsAtLevel(4);
        assertEq(elements.length, 18);

        elements = pec.getElementsAtLevel(5);
        assertEq(elements.length, 18);

        elements = pec.getElementsAtLevel(6);
        assertEq(elements.length, 32);

        elements = pec.getElementsAtLevel(7);
        assertEq(elements.length, 32);
    }

    function test_cantMintWithoutPaying(uint256 price) public {
        price = bound(price, 0, PACK_PRICE - 1);

        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(PeriodicElementsCollection.PEC__UserDidNotPayEnough.selector, PACK_PRICE - price)
        );
        pec.mintPack{value: price}();
    }

    function test_cantUnpackIfNotStatusReadyToMint() public fundSubscriptionMax {
        vm.startPrank(alice);

        uint256 requestId = 0;

        // Status == None
        assert(pec.getVRFStateFromRequestId(requestId).status == PeriodicElementsCollection.VRFStatus.None);
        vm.expectRevert(
            abi.encodeWithSelector(
                PeriodicElementsCollection.PEC__NotInReadyToMintState.selector,
                PeriodicElementsCollection.VRFStatus.None
            )
        );
        pec.unpackRandomMatter(requestId);

        // Status == PendingVRFCallback
        requestId = pec.mintPack{value: PACK_PRICE}();
        assert(
            pec.getVRFStateFromRequestId(requestId).status == PeriodicElementsCollection.VRFStatus.PendingVRFCallback
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                PeriodicElementsCollection.PEC__NotInReadyToMintState.selector,
                PeriodicElementsCollection.VRFStatus.PendingVRFCallback
            )
        );
        pec.unpackRandomMatter(requestId);

        // Status == Minted
        requestId = pec.mintPack{value: PACK_PRICE}();
        vm.stopPrank();
        vm.prank(address(vrfCoordinator));
        vrfCoordinator.fulfillRandomWords(requestId, address(pec));
        pec.unpackRandomMatter(requestId);

        assert(pec.getVRFStateFromRequestId(requestId).status == PeriodicElementsCollection.VRFStatus.Minted);
        vm.expectRevert(PeriodicElementsCollection.PEC__RequestIdAlreadyMinted.selector);
        pec.unpackRandomMatter(requestId);
    }

    function test_revertOnReceiveCantMint() public {
        RevertOnReceive revertOnReceive = new RevertOnReceive();
        vm.deal(address(revertOnReceive), 1 ether);

        vm.prank(address(revertOnReceive));
        vm.expectRevert(PeriodicElementsCollection.PEC__EthNotSend.selector);
        pec.mintPack{value: PACK_PRICE + 1}();
    }

    function test_mintAccross2DaysAllow2Mint() public {
        vm.warp(block.timestamp + 1 days + 23 hours);

        vm.startPrank(alice);

        // Minting a free pack just before 2 days gives one pack
        pec.mintFreePacks();
        assertEq(pec.balanceOf(alice, 1), 5);

        vm.warp(block.timestamp + 2 hours);

        // Minting a free pack again 2 hours later gives another pack
        pec.mintFreePacks();
        assertEq(pec.balanceOf(alice, 1), 10);
    }
}
