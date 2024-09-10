// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {PeriodicElementsCollection} from "../src/PeriodicElementsCollection.sol";
import {DarkMatterTokens} from "../src/DarkMatterTokens.sol";
import {ElementsData} from "../src/ElementsData.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {PeriodicElementsCollectionDeployer} from "../script/PeriodicElementsCollectionDeployer.s.sol";

import {Test, console} from "forge-std/Test.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {FundSubscription} from "../script/VRFInteractions.s.sol";

contract PeriodicElementsCollectionTest is Test {
    PeriodicElementsCollection periodicElementsCollection;
    HelperConfig helperConfig;
    HelperConfig.NetworkConfig config;

    address owner;
    address user = makeAddr("user");

    VRFCoordinatorV2_5Mock vrfCoordinator;
    FundSubscription fundSubscription;

    function setUp() public {
        (periodicElementsCollection, helperConfig) = (new PeriodicElementsCollectionDeployer()).deployContract();
        fundSubscription = new FundSubscription();

        config = helperConfig.getConfig();
        config.subscriptionId = periodicElementsCollection.subscriptionId();

        vrfCoordinator = VRFCoordinatorV2_5Mock(config.vrfCoordinator);

        assert(address(periodicElementsCollection) != address(0));
        assertEq(config.account, periodicElementsCollection.owner());
    }

    function testIsAlive() public view {
        assertEq("Periodic Elements Collection", periodicElementsCollection.name());
        (uint256 number, string memory name, string memory symbol, uint256 ram, uint256 level) =
            periodicElementsCollection.elementsData(1);

        assertEq(1, number);
        assertEq("Hydrogen", name);
        assertEq("H", symbol);
        assertEq(1.008 * 1e18, ram);
        assertEq(1, level);

        uint256 expectedRAM = 1e22 / ram;
        assertEq(expectedRAM, periodicElementsCollection.getElementArtificialRAMWeight(1));
    }

    /**
     * VRF tests
     */
    modifier fundSubscriptionMax() {
        fundSubscription.fundSubscription(config, type(uint256).max - 3 ether);
        _;
    }

    function testElementsLevelIsCorrect() public view {
        for (uint256 lvl = 1; lvl <= 7; lvl++) {
            uint256[] memory lvlElements = periodicElementsCollection.getElementsUnlockedUnderLevel(lvl);

            assertEq(
                lvlElements.length,
                lvl == 1
                    ? 2
                    : lvl == 2 ? 10 : lvl == 3 ? 18 : lvl == 4 ? 36 : lvl == 5 ? 54 : lvl == 6 ? 86 : lvl == 7 ? 118 : 0
            );
        }
    }

    function testFulfillRandomWordsCanOnlyBeCalledAfterRequestId() public {
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(0, address(periodicElementsCollection));

        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(1, address(periodicElementsCollection));
    }

    function testRandomness() public fundSubscriptionMax {
        uint256 numOfUsers = 1000;

        vm.warp(block.timestamp + 25 hours);

        for (uint256 i = 1; i <= numOfUsers; i++) {
            vm.prank(address(bytes20(uint160(i))));
            uint256 requestID = periodicElementsCollection.mintPack();

            //Have to impersonate the VRFCoordinatorV2Mock contract
            //since only the VRFCoordinatorV2Mock contract
            //can call the fulfillRandomWords function
            vm.prank(address(vrfCoordinator));
            vrfCoordinator.fulfillRandomWords(requestID, address(periodicElementsCollection));
        }

        //Calling the total supply function on all tokenIDs
        //to get a final tally, before logging the values.
        console.log("TotalSupply", periodicElementsCollection.totalSupply());
        assertEq(numOfUsers * 5, periodicElementsCollection.totalSupply());

        console.log("Supply of tokenId 1 =", periodicElementsCollection.totalSupply(1));
        console.log("Supply of tokenId 2 =", periodicElementsCollection.totalSupply(2));
        console.log("Supply of antimatter tokenId 1 =", periodicElementsCollection.totalSupply(10_001));
        console.log("Supply of antimatter tokenId 2 =", periodicElementsCollection.totalSupply(10_002));
    }

    function testUserCanMintOneFreePackPerDay() public fundSubscriptionMax {
        uint256 totalMintedElements = 0;
        vm.warp(block.timestamp + 12 hours);

        // User mints daily for 100 days
        for (uint256 i = 0; i < 100; i++) {
            vm.warp(block.timestamp + 1 days);

            vm.prank(user);
            uint256 requestID = periodicElementsCollection.mintPack();

            vm.prank(address(vrfCoordinator));
            vrfCoordinator.fulfillRandomWords(requestID, address(periodicElementsCollection));

            assertEq(totalMintedElements + 5, periodicElementsCollection.totalSupply());
            totalMintedElements = periodicElementsCollection.totalSupply();
        }

        assertEq(500, periodicElementsCollection.totalSupply());
        assertEq(500, periodicElementsCollection.totalSupply(1) + periodicElementsCollection.totalSupply(2));
    }

    // Level up user and test pack mints
    // TODO : Create a test contract that inherit the normal contract.
    // The test contract contains additionnal getters/setters to interact and set states of specific variables
}
