// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {PeriodicElementsCollection} from "src/PeriodicElementsCollection.sol";
import {DarkMatterTokens} from "src/DarkMatterTokens.sol";
import {ElementsData} from "src/ElementsData.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {PECDeployer} from "script/PECDeployer.s.sol";
import {PECTestContract} from "test/contracts/PECTestContract.sol";

import {Test, console} from "forge-std/Test.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {FundSubscription} from "script/VRFInteractions.s.sol";

contract PECBaseTest is Test {
    uint256 public ELEMENTS_IN_PACK;
    uint256 public NUM_MAX_PACKS_MINTED_AT_ONCE;
    uint256 public PACK_PRICE;
    uint256 public ANTIMATTER_OFFSET;

    PECTestContract pec;
    HelperConfig helperConfig;
    HelperConfig.NetworkConfig config;

    address owner;
    address user = makeAddr("user");

    VRFCoordinatorV2_5Mock vrfCoordinator;
    FundSubscription fundSubscription;

    function setUp() public {
        address pecTestContract;
        (pecTestContract, helperConfig) = (new PECDeployer()).deployContract();
        pec = PECTestContract(pecTestContract);
        ELEMENTS_IN_PACK = pec.ELEMENTS_IN_PACK();
        NUM_MAX_PACKS_MINTED_AT_ONCE = pec.NUM_MAX_PACKS_MINTED_AT_ONCE();
        PACK_PRICE = pec.PACK_PRICE();
        ANTIMATTER_OFFSET = pec.ANTIMATTER_OFFSET();

        fundSubscription = new FundSubscription();

        config = helperConfig.getConfig();
        config.subscriptionId = pec.subscriptionId();

        vrfCoordinator = VRFCoordinatorV2_5Mock(config.vrfCoordinator);

        assert(address(pec) != address(0));
        assertEq(config.account, pec.owner());

        vm.deal(user, type(uint128).max);
    }

    function testIsAlive() public view {
        assertEq("Periodic Elements Collection", pec.name());
        (uint256 number, string memory name, string memory symbol, uint256 ram, uint256 level) = pec.elementsData(1);

        assertEq(1, number);
        assertEq("Hydrogen", name);
        assertEq("H", symbol);
        assertEq(1.008 * 1_000, ram);
        assertEq(1, level);

        uint256 expectedRAM = 1e18 / ram;
        assertEq(expectedRAM, pec.getElementArtificialRAMWeight(user, 1));
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
}
