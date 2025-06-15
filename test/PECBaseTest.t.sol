// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {PeriodicElementsCollection} from "src/PeriodicElementsCollection.sol";
import {DarkMatterTokens} from "src/DarkMatterTokens.sol";
import {ElementsData} from "src/ElementsData.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {PECDeployer} from "script/PECDeployer.s.sol";
import {PECTestContract} from "test/contracts/PECTestContract.sol";
import {IElementsData} from "src/interfaces/IElementsData.sol";

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
    address user2 = makeAddr("user2");

    VRFCoordinatorV2_5Mock vrfCoordinator;
    FundSubscription fundSubscription;

    modifier fundSubscriptionMax() {
        fundSubscription.fundSubscription(config, type(uint256).max - 3 ether);
        _;
    }

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
        config.subscriptionId = pec.SUBSCRIPTION_ID();

        vrfCoordinator = VRFCoordinatorV2_5Mock(config.vrfCoordinator);

        assert(address(pec) != address(0));
        assertEq(config.account, pec.owner());

        vm.deal(user, type(uint128).max);
        vm.deal(user2, type(uint128).max);
    }
}

contract BasicTests is PECBaseTest {
    function test_isAlive() public view {
        (uint256 number, string memory name, string memory symbol, uint256 ram, uint256 level) = pec.elementsData(1);

        assertEq(1, number);
        assertEq("Hydrogen", name);
        assertEq("H", symbol);
        assertEq(1.008 * 1_000, ram);
        assertEq(1, level);

        uint256 expectedRAM = 1e18 / ram;
        assertEq(expectedRAM, pec.getElementArtificialRAMWeight(user, 1));
    }

    function test_elementsLevelIsCorrect() public view {
        for (uint256 lvl = 1; lvl <= 7; lvl++) {
            uint256[] memory lvlElements = pec.getElementsUnlockedUnderLevel(lvl);

            assertEq(
                lvlElements.length,
                lvl == 1
                    ? 2
                    : lvl == 2 ? 10 : lvl == 3 ? 18 : lvl == 4 ? 36 : lvl == 5 ? 54 : lvl == 6 ? 86 : lvl == 7 ? 118 : 0
            );
        }
    }

    /* Test constructors inherited to reach 100% coverage (they aren't taken
            into account in the other tests somehow) */

    function test_pecConstructor() public {
        ElementsData.ElementDataStruct[] memory eds = new ElementsData.ElementDataStruct[](7);
        eds[0] = IElementsData.ElementDataStruct({number: 1, name: "", symbol: "", initialRAM: 0, level: 1});
        eds[1] = IElementsData.ElementDataStruct({number: 2, name: "", symbol: "", initialRAM: 0, level: 2});
        eds[2] = IElementsData.ElementDataStruct({number: 3, name: "", symbol: "", initialRAM: 0, level: 3});
        eds[3] = IElementsData.ElementDataStruct({number: 4, name: "", symbol: "", initialRAM: 0, level: 4});
        eds[4] = IElementsData.ElementDataStruct({number: 5, name: "", symbol: "", initialRAM: 0, level: 5});
        eds[5] = IElementsData.ElementDataStruct({number: 6, name: "", symbol: "", initialRAM: 0, level: 6});
        eds[6] = IElementsData.ElementDataStruct({number: 7, name: "", symbol: "", initialRAM: 0, level: 7});

        new PeriodicElementsCollection(0, address(this), eds);
    }
}
