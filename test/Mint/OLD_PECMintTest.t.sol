// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.20;

// import {PeriodicElementsCollection} from "src/PeriodicElementsCollection.sol";
// import {DarkMatterTokens} from "src/DarkMatterTokens.sol";
// import {ElementsData} from "src/ElementsData.sol";
// import {HelperConfig} from "script/HelperConfig.s.sol";
// import {PECDeployer} from "script/PECDeployer.s.sol";
// import {PECTestContract} from "test/contracts/PECTestContract.sol";

// import {Test, console} from "forge-std/Test.sol";
// import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
// import {FundSubscription} from "script/VRFInteractions.s.sol";
// import {PECBaseTest} from "../PECBaseTest.t.sol";

// contract PECMintTest is PECBaseTest {
//     modifier fundSubscriptionMax() {
//         fundSubscription.fundSubscription(config, type(uint256).max - 3 ether);
//         _;
//     }

//     modifier setAllEllementsArtificialRamEqual() {
//         pec.setAllEllementsArtificialRamEqual();
//         _;
//     }

//     function testRandomness() public fundSubscriptionMax {
//         uint256 numOfUsers = 1000;

//         vm.warp(block.timestamp + 1 days);

//         for (uint256 i = 1; i <= numOfUsers; i++) {
//             vm.prank(address(bytes20(uint160(i))));
//             uint256 requestId = pec.mintPack();

//             vm.prank(address(vrfCoordinator));
//             vrfCoordinator.fulfillRandomWords(requestId, address(pec));
//             pec.unpackRandomMatter(requestId);
//         }

//         //Calling the total supply function on all tokenIDs
//         //to get a final tally, before logging the values.
//         console.log("TotalSupply", pec.totalSupply());
//         assertEq(numOfUsers * 5 + (numOfUsers * 10 * 7), pec.totalSupply());

//         console.log("Supply of tokenId 1 =", pec.totalSupply(1));
//         console.log("Supply of tokenId 2 =", pec.totalSupply(2));
//         console.log("Supply of antimatter tokenId 1 =", pec.totalSupply(10_001));
//         console.log("Supply of antimatter tokenId 2 =", pec.totalSupply(10_002));
//     }

//     function testUserCantMintIfNoPackToMintAndNoPayement() public fundSubscriptionMax {
//         vm.expectRevert(PeriodicElementsCollection.PEC__NoPackToMint.selector);

//         vm.prank(user);
//         pec.mintPack();
//     }

//     function testUserCanMintOneFreePackPerDay() public fundSubscriptionMax {
//         uint256 totalMintedElements = 0;
//         vm.warp(block.timestamp + 12 hours);

//         // User mints daily for 100 days
//         for (uint256 i = 0; i < 100; i++) {
//             vm.warp(block.timestamp + 1 days);

//             vm.prank(user);
//             uint256 requestId = pec.mintPack();

//             vm.prank(address(vrfCoordinator));
//             vrfCoordinator.fulfillRandomWords(requestId, address(pec));
//             pec.unpackRandomMatter(requestId);

//             assertEq(totalMintedElements + 5, pec.totalSupply());
//             totalMintedElements = pec.totalSupply();
//         }

//         assertEq(500, totalMintedElements);
//         assertEq(500, pec.totalSupply(1) + pec.totalSupply(2));
//         assertEq(500, pec.balanceOf(user, 1) + pec.balanceOf(user, 2));
//     }

//     function testUserCanMintMax7FreePacks() public fundSubscriptionMax {
//         vm.warp(block.timestamp + 50 weeks);

//         vm.prank(user);
//         uint256 requestId = pec.mintPack();

//         vm.prank(address(vrfCoordinator));
//         vrfCoordinator.fulfillRandomWords(requestId, address(pec));
//         pec.unpackRandomMatter(requestId);

//         assertEq(7 * 5, pec.totalSupply());
//     }

//     function testUserCanMintMorePacksIfPayCorrectAmount(uint256 nbPacksToMints) public fundSubscriptionMax {
//         nbPacksToMints = bound(nbPacksToMints, 1, 20);
//         vm.deal(user, pec.PACK_PRICE() * nbPacksToMints);

//         vm.startPrank(user);
//         uint256 requestId = pec.mintPack{value: pec.PACK_PRICE() * nbPacksToMints}();
//         vm.stopPrank();

//         vm.prank(address(vrfCoordinator));
//         vrfCoordinator.fulfillRandomWords(requestId, address(pec));
//         pec.unpackRandomMatter(requestId);

//         assertEq(pec.ELEMENTS_IN_PACK() * nbPacksToMints, pec.totalSupply());
//     }

//     function testRefundIfUserPayTooMuch() public fundSubscriptionMax {
//         uint256 initialUserFund = 1 ether;
//         vm.deal(user, initialUserFund);

//         vm.startPrank(user);
//         uint256 requestId = pec.mintPack{value: initialUserFund}();
//         vm.stopPrank();

//         vm.prank(address(vrfCoordinator));
//         vrfCoordinator.fulfillRandomWords(requestId, address(pec));
//         pec.unpackRandomMatter(requestId);

//         assertEq(pec.NUM_MAX_PACKS_MINTED_AT_ONCE() * 5, pec.totalSupply(), "Not correct amount of elements minted");

//         uint256 expectedRefund = initialUserFund - (pec.PACK_PRICE() * pec.totalSupply() / pec.ELEMENTS_IN_PACK());
//         assertEq(expectedRefund, user.balance, "User should be refunded correct amount");
//     }

//     // Test to be sure that the modifier works as expected
//     function testSetAllEllementsArtificialRamEqual() public setAllEllementsArtificialRamEqual {
//         for (uint256 i = 2; i <= 118; i++) {
//             assertEq(1, pec.getElementArtificialRAMWeight(i));
//         }
//     }

//     function testFuzzUserCanMintElementsUnderTheirLevel(uint256 levelToSet) public fundSubscriptionMax {
//         // Forces level to be up to 7 (0 indexed so - 1)
//         levelToSet = bound(levelToSet, 0, 6);

//         uint256 NUM_TOTAL_ELEMENTS_TO_MINT = 120;

//         uint256 mintAllValue = NUM_TOTAL_ELEMENTS_TO_MINT * pec.PACK_PRICE() / pec.ELEMENTS_IN_PACK();
//         vm.deal(user, mintAllValue * 14);

//         uint256 requestId = 0;

//         uint256[] memory randomWords = new uint256[](NUM_TOTAL_ELEMENTS_TO_MINT);

//         for (uint256 i = 0; i < NUM_TOTAL_ELEMENTS_TO_MINT; i++) {
//             randomWords[i] = i + 1; // + 1 is to avoid minting antimatter
//         }

//         pec.setAllEllementsArtificialRamEqual();

//         pec.setUserLevel(user, levelToSet);
//         assertEq(levelToSet, pec.getUserLevel(user));

//         // Mints elements
//         vm.prank(user);
//         requestId = pec.mintPack{value: mintAllValue}();
//         vm.prank(address(vrfCoordinator));
//         vrfCoordinator.fulfillRandomWordsWithOverride(requestId, address(pec), randomWords);
//         pec.unpackRandomMatter(requestId);

//         uint256[] memory elementsUnlocked = pec.getElementsUnlockedByPlayer(user);
//         uint256 countElementsUnlocked = 0;
//         uint256 averageMintingCount = NUM_TOTAL_ELEMENTS_TO_MINT / elementsUnlocked.length;

//         for (uint256 i = 0; i < elementsUnlocked.length; i++) {
//             uint256 totalSupplyThisElement = pec.totalSupply(elementsUnlocked[i]);
//             assert(totalSupplyThisElement - averageMintingCount <= 1); // Assert that we minted an average amount of the element or max + 1

//             countElementsUnlocked += totalSupplyThisElement;
//         }

//         assertEq(NUM_TOTAL_ELEMENTS_TO_MINT, countElementsUnlocked);
//     }
// }
