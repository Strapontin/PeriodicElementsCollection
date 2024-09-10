// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {PeriodicElementsCollection} from "../src/PeriodicElementsCollection.sol";
import {DarkMatterTokens} from "../src/DarkMatterTokens.sol";
import {ElementsData} from "../src/ElementsData.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {PeriodicElementsCollectionDeployer} from "../script/PeriodicElementsCollectionDeployer.s.sol";
import {PeriodicElementsCollectionTestContract} from "./contracts/PeriodicElementsCollectionTestContract.sol";

import {Test, console} from "forge-std/Test.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {FundSubscription} from "../script/VRFInteractions.s.sol";

contract PeriodicElementsCollectionTest is Test {
    PeriodicElementsCollectionTestContract pec;
    HelperConfig helperConfig;
    HelperConfig.NetworkConfig config;

    address owner;
    address user = makeAddr("user");

    VRFCoordinatorV2_5Mock vrfCoordinator;
    FundSubscription fundSubscription;

    function setUp() public {
        address periodicElementsCollectionTestContract;
        (periodicElementsCollectionTestContract, helperConfig) =
            (new PeriodicElementsCollectionDeployer()).deployContract();
        pec = PeriodicElementsCollectionTestContract(periodicElementsCollectionTestContract);

        fundSubscription = new FundSubscription();

        config = helperConfig.getConfig();
        config.subscriptionId = pec.subscriptionId();

        vrfCoordinator = VRFCoordinatorV2_5Mock(config.vrfCoordinator);

        assert(address(pec) != address(0));
        assertEq(config.account, pec.owner());
    }

    function testIsAlive() public view {
        assertEq("Periodic Elements Collection", pec.name());
        (uint256 number, string memory name, string memory symbol, uint256 ram, uint256 level) = pec.elementsData(1);

        assertEq(1, number);
        assertEq("Hydrogen", name);
        assertEq("H", symbol);
        assertEq(1.008 * 1e18, ram);
        assertEq(1, level);

        uint256 expectedRAM = 1e22 / ram;
        assertEq(expectedRAM, pec.getElementArtificialRAMWeight(1));
    }

    /**
     * VRF tests
     */
    modifier fundSubscriptionMax() {
        fundSubscription.fundSubscription(config, type(uint256).max - 3 ether);
        _;
    }

    modifier setAllEllementsArtificialRamEqual() {
        pec.setAllEllementsArtificialRamEqual();
        _;
    }

    function testElementsLevelIsCorrect() public view {
        for (uint256 lvl = 1; lvl <= 7; lvl++) {
            uint256[] memory lvlElements = pec.getElementsUnlockedUnderLevel(lvl);

            assertEq(
                lvlElements.length,
                lvl == 0
                    ? 2
                    : lvl == 1 ? 10 : lvl == 2 ? 18 : lvl == 3 ? 36 : lvl == 4 ? 54 : lvl == 5 ? 86 : lvl == 6 ? 118 : 0
            );
        }
    }

    function testFulfillRandomWordsCanOnlyBeCalledAfterRequestId() public {
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(0, address(pec));

        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(1, address(pec));
    }

    function testRandomness() public fundSubscriptionMax {
        uint256 numOfUsers = 1000;

        vm.warp(block.timestamp + 25 hours);

        for (uint256 i = 1; i <= numOfUsers; i++) {
            vm.prank(address(bytes20(uint160(i))));
            uint256 requestId = pec.mintPack();

            //Have to impersonate the VRFCoordinatorV2Mock contract
            //since only the VRFCoordinatorV2Mock contract
            //can call the fulfillRandomWords function
            vm.prank(address(vrfCoordinator));
            vrfCoordinator.fulfillRandomWords(requestId, address(pec));
        }

        //Calling the total supply function on all tokenIDs
        //to get a final tally, before logging the values.
        console.log("TotalSupply", pec.totalSupply());
        assertEq(numOfUsers * 5, pec.totalSupply());

        console.log("Supply of tokenId 1 =", pec.totalSupply(1));
        console.log("Supply of tokenId 2 =", pec.totalSupply(2));
        console.log("Supply of antimatter tokenId 1 =", pec.totalSupply(10_001));
        console.log("Supply of antimatter tokenId 2 =", pec.totalSupply(10_002));
    }

    function testUserCanMintOneFreePackPerDay() public fundSubscriptionMax {
        uint256 totalMintedElements = 0;
        vm.warp(block.timestamp + 12 hours);

        // User mints daily for 100 days
        for (uint256 i = 0; i < 100; i++) {
            vm.warp(block.timestamp + 1 days);

            vm.prank(user);
            uint256 requestId = pec.mintPack();

            vm.prank(address(vrfCoordinator));
            vrfCoordinator.fulfillRandomWords(requestId, address(pec));

            assertEq(totalMintedElements + 5, pec.totalSupply());
            totalMintedElements = pec.totalSupply();
        }

        assertEq(500, totalMintedElements);
        assertEq(500, pec.totalSupply(1) + pec.totalSupply(2));
        assertEq(500, pec.balanceOf(user, 1) + pec.balanceOf(user, 2));
    }

    function testUserCanMintMorePacksIfPayCorrectAmount(uint256 nbMints) public fundSubscriptionMax {
        nbMints = bound(nbMints, 0, 150);
        vm.deal(user, pec.mintPackPrice() * nbMints);

        for (uint256 i = 0; i < nbMints; i++) {
            vm.startPrank(user);
            uint256 requestId = pec.mintPack{value: pec.mintPackPrice()}();
            vm.stopPrank();

            vm.prank(address(vrfCoordinator));
            vrfCoordinator.fulfillRandomWords(requestId, address(pec));
        }

        assertEq(5 * nbMints, pec.totalSupply());
    }

    function testSetAllEllementsArtificialRamEqual() public setAllEllementsArtificialRamEqual {
        uint256 hydrogenArtificialRam = pec.getElementArtificialRAMWeight(1);

        for (uint256 i = 2; i <= 118; i++) {
            assertEq(hydrogenArtificialRam, pec.getElementArtificialRAMWeight(i));
        }
    }

    // function testUserCanMintElementsUnderHisLevel() public fundSubscriptionMax setAllEllementsArtificialRamEqual {
    //     vm.warp(block.timestamp + 25 hours);

    //     pec.setUserLevel(user, 1); <- Check this
    //     assertEq(1, pec.getUserLevel(user));

    //     // Mints elements
    //     vm.prank(user);
    //     uint256 requestId = pec.mintPack();

    //     vm.prank(address(vrfCoordinator));
    //     vrfCoordinator.fulfillRandomWords(requestId, address(pec));

    //     // assert(pec.totalSupply(1) + pec.totalSupply(2) < 5);
    //     assertLt(pec.totalSupply(1) + pec.totalSupply(2), 5);
    // }
}
