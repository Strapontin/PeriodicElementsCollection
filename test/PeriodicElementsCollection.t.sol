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

    address owner;
    VRFCoordinatorV2_5Mock vrfCoordinator;
    FundSubscription fundSubscription;

    function setUp() public {
        (periodicElementsCollection, helperConfig) = (new PeriodicElementsCollectionDeployer()).deployContract();
        fundSubscription = new FundSubscription();

        owner = helperConfig.getConfig().account;
        vrfCoordinator = VRFCoordinatorV2_5Mock(helperConfig.getConfig().vrfCoordinator);

        assert(address(periodicElementsCollection) != address(0));
        assertEq(owner, periodicElementsCollection.owner());
    }

    // Test this
    function testIsAlive() public view {
        assertEq("Periodic Elements Collection", periodicElementsCollection.name());
        (uint8 number, string memory name, string memory symbol, uint256 ram, uint8 level) =
            periodicElementsCollection.elementsData(1);

        assertEq(1, number);
        assertEq("Hydrogen", name);
        assertEq("H", symbol);
        assertEq(1.008 * 1e18, ram);
        assertEq(1, level);

        uint256 expectedRAM = 1e22 / ram;
        assertEq(expectedRAM, periodicElementsCollection.getElementArtificialRelativeAtomicMass(1));
    }

    function testRandomness() public {
        vm.warp(block.timestamp + 25 hours);

        for (uint256 i = 1; i <= 1000; i++) {
            address addr = address(bytes20(uint160(i)));

            applyFundSubscription();

            vm.prank(addr);
            uint256 requestID = periodicElementsCollection.mintPack();

            //Have to impersonate the VRFCoordinatorV2Mock contract
            //since only the VRFCoordinatorV2Mock contract
            //can call the fulfillRandomWords function
            vm.prank(address(vrfCoordinator));
            vrfCoordinator.fulfillRandomWords(requestID, address(periodicElementsCollection));
        }

        // //Calling the total supply function on all tokenIDs
        // //to get a final tally, before logging the values.
        // supplytracker[1] = periodicElementsCollection.totalSupply(1);
        // supplytracker[2] = periodicElementsCollection.totalSupply(2);
        // supplytracker[3] = periodicElementsCollection.totalSupply(3);

        // console2.log("Supply with tokenID 1 is " , supplytracker[1]);
        // console2.log("Supply with tokenID 2 is " , supplytracker[2]);
        // console2.log("Supply with tokenID 3 is " , supplytracker[3]);
    }

    /**
     * Private functions
     */
    function applyFundSubscription() private {
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        config.subscriptionId = periodicElementsCollection.subscriptionId();
        fundSubscription.fundSubscription(config);
    }
}
