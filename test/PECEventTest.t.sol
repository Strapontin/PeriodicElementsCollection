// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {PeriodicElementsCollection} from "src/PeriodicElementsCollection.sol";
import {DarkMatterTokens} from "src/DarkMatterTokens.sol";
import {PrizePool} from "src/PrizePool.sol";
import {PECBaseTest} from "test/PECBaseTest.t.sol";

contract PECEventTest is PECBaseTest {
    function test_mintPack_emit(uint32 packsToMint) public fundSubscriptionMax {
        packsToMint = uint32(bound(packsToMint, 1, type(uint32).max));

        vm.expectEmit(false, true, true, false, address(pec));
        emit PeriodicElementsCollection.MintRequestInitalized(0, address(alice), packsToMint);

        // Go through the process of minting a pack
        vm.prank(alice);
        pec.mintPack{value: PACK_PRICE * packsToMint}();
    }

    function test_fundingSubscription_emit(uint256 amount) public {
        amount = _bound(amount, 0, 100 ether);

        uint256[] memory ids = new uint256[](2);
        uint256[] memory values = new uint256[](2);
        ids[0] = 1; // Hydrogen
        ids[1] = 2; // Helium
        // Earns 5 hydrogen and helium per pack price send to refuel the subscription
        values[0] = amount * 5 / PACK_PRICE;
        values[1] = amount * 5 / PACK_PRICE;

        vm.expectEmit(true, true, true, false, address(pec));
        emit PeriodicElementsCollection.ElementsMinted(address(alice), ids, values);

        vm.prank(alice);
        pec.fundSubscription{value: amount}();
    }

    function test_mintFreePacks_emit() public {
        vm.warp(block.timestamp + 8 days);

        // Calculates amount of free elements minted for the event
        uint256[] memory ids = new uint256[](2);
        uint256[] memory values = new uint256[](2);
        ids[0] = 1; // Hydrogen
        ids[1] = 2; // Helium
        values[0] = 5 * 7;
        values[1] = 5 * 7;

        vm.expectEmit(false, true, true, false, address(pec));
        emit PeriodicElementsCollection.ElementsMinted(address(alice), ids, values);

        vm.startPrank(alice);
        pec.mintFreePacks();
    }

    function test_unpackRandomMatter_emit(uint256 packsToMint) public fundSubscriptionMax {
        packsToMint = bound(packsToMint, 1, NUM_MAX_PACKS_MINTED_AT_ONCE);

        vm.prank(alice);
        uint256 requestId = pec.mintPack{value: PACK_PRICE * packsToMint}();

        vm.prank(address(vrfCoordinator));
        vrfCoordinator.fulfillRandomWords(requestId, address(pec));

        uint256[] memory ids = new uint256[](2);
        uint256[] memory values = new uint256[](2);
        ids[0] = 1; // Hydrogen
        ids[1] = 2; // Helium
        // Earns 5 hydrogen and helium per pack price send to refuel the subscription
        values[0] = packsToMint * 5 / PACK_PRICE;
        values[1] = packsToMint * 5 / PACK_PRICE;

        vm.expectEmit(true, true, true, false, address(pec));
        emit PeriodicElementsCollection.ElementsMinted(address(alice), ids, values);

        pec.unpackRandomMatter(requestId);
    }

    function test_fulfillRandomWords_emit(address caller) public fundSubscriptionMax {
        vm.assume(caller != address(0));
        vm.deal(caller, PACK_PRICE);
        vm.prank(caller);
        uint256 requestId = pec.mintPack{value: PACK_PRICE}();

        vm.expectEmit(true, true, true, true, address(pec));
        emit PeriodicElementsCollection.ElementsReadyToMint(caller);

        vm.prank(address(vrfCoordinator));
        vrfCoordinator.fulfillRandomWords(requestId, address(pec));
    }

    function test_fuseToNextLevel_emit(uint256 level, bool isMatter, uint32 amountOfLinesFused) public {
        level = _bound(level, 1, 7);
        vm.assume(level != 7 || isMatter);

        amountOfLinesFused = uint32(_bound(amountOfLinesFused, 1, 100));

        pec.mintAll(alice, amountOfLinesFused);

        vm.warp(block.timestamp + 7 days);
        vm.startPrank(alice);
        pec.mintFreePacks();

        vm.expectEmit(true, true, true, true, address(pec));
        emit PeriodicElementsCollection.ElementsFused(alice, level, isMatter, amountOfLinesFused);

        pec.fuseToNextLevel(level, amountOfLinesFused, isMatter);
    }

    function test_increaseRelativeAtomicMass_emit(uint256 elementToRemove, bool removeMatter) public {
        elementToRemove = bound(elementToRemove, 1, pec.getElementsUnlockedUnderLevel(7).length);
        if (!removeMatter) {
            elementToRemove += ANTIMATTER_OFFSET;
        }

        pec.mintAll(alice);

        uint256[] memory ids = new uint256[](1);
        uint256[] memory values = new uint256[](1);

        ids[0] = elementToRemove;
        values[0] = 1;

        vm.expectEmit(true, true, true, true, address(pec));
        emit PeriodicElementsCollection.ElementsBurned(alice, ids, values);

        vm.prank(alice);
        pec.increaseRelativeAtomicMass(ids, values);
    }

    function test_addAuthorizeTransfer_emit(uint256 newValue) public {
        uint256 id = 1;

        vm.expectEmit(true, true, true, true, address(pec));
        emit PeriodicElementsCollection.AuthorizeTransferChanged(bob, alice, id, 0, newValue);

        vm.prank(alice);
        pec.addAuthorizeTransfer(bob, id, newValue);
    }

    function test_decreaseAuthorizeTransfer_emit(uint256 addValue, uint256 removeValue) public {
        test_addAuthorizeTransfer_emit(addValue);

        uint256 id = 1;
        uint256 newValue = addValue > removeValue ? addValue - removeValue : 0;

        vm.expectEmit(true, true, true, true, address(pec));
        emit PeriodicElementsCollection.AuthorizeTransferChanged(bob, alice, id, addValue, newValue);

        vm.prank(alice);
        pec.decreaseAuthorizeTransfer(bob, id, removeValue);
    }

    function test_setAuthorizedAddressForTransfer_emit(address from, bool isAuthorized) public {
        vm.expectEmit(true, true, true, true, address(pec));
        emit PeriodicElementsCollection.AddressSetAsAuthorized(from, alice, isAuthorized);

        vm.prank(alice);
        pec.setAuthorizedAddressForTransfer(from, isAuthorized);
    }

    function test_bigBang_emit(uint32 amount) public {
        pec.mintAll(alice);

        vm.deal(address(pec), amount);
        vm.prank(address(pec));
        prizePool.playerBoughtPacks{value: amount}(alice);

        vm.expectEmit(true, true, true, true, address(pec));
        emit PeriodicElementsCollection.BigBangExploded(alice, amount - amount / 100);

        vm.prank(alice);
        pec.bigBang(alice);
    }

    function test_buyDMT_emit(uint256 amount) public {
        amount = _bound(amount, DMT_FEE_PER_TRANSFER, type(uint128).max);

        vm.expectEmit(true, true, true, true, address(dmt));
        emit DarkMatterTokens.DMTMinted(alice, amount);
        vm.prank(alice);
        dmt.buy{value: amount}();
    }

    function test_buyDMT_emit_dependsBasedOnUniversesCreated(uint32 universesCreated, uint256 amount) public {
        pec.setTotalUniversesCreated(universesCreated);

        uint256 minAmountToSend =
            pec.DMT_FEE_PER_TRANSFER() * (1e18 + universesCreated * pec.DMT_PRICE_INCREASE_PER_UNIVERSE()) / 1e18;

        amount = _bound(amount, minAmountToSend, type(uint128).max);

        uint256 expectedLogAmount = amount * 1e18 / (1e18 + universesCreated * pec.DMT_PRICE_INCREASE_PER_UNIVERSE());

        vm.expectEmit(true, true, true, true, address(dmt));
        emit DarkMatterTokens.DMTMinted(alice, expectedLogAmount);
        vm.prank(alice);
        dmt.buy{value: amount}();
    }

    function test_burnDMT_emit(uint256 amount) public {
        amount = _bound(amount, DMT_FEE_PER_TRANSFER, type(uint128).max);

        vm.prank(alice);
        dmt.buy{value: amount}();

        uint256 minted = amount * 1e18 / (1e18 + pec.totalUniversesCreated() * pec.DMT_PRICE_INCREASE_PER_UNIVERSE());

        vm.expectEmit(true, true, true, true, address(dmt));
        emit DarkMatterTokens.DMTBurned(address(pec), minted);

        vm.prank(address(pec));
        dmt.burn(alice, minted);
    }

    function test_proposeNewFeeReceiver_emit() public {
        vm.expectEmit(true, true, true, true, address(prizePool));
        emit PrizePool.NewFeeReceiverProposed(bob);

        vm.prank(feeReceiver);
        prizePool.proposeNewFeeReceiver(bob);
    }

    function test_acceptNewFeeReceiver_emit() public {
        vm.prank(feeReceiver);
        prizePool.proposeNewFeeReceiver(bob);

        vm.expectEmit(true, true, true, true, address(prizePool));
        emit PrizePool.NewFeeReceiverAccepted(bob);

        vm.prank(bob);
        prizePool.acceptFeeReceiver();
    }
}

