// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {PeriodicElementsCollection} from "src/PeriodicElementsCollection.sol";
import {DarkMatterTokens} from "src/DarkMatterTokens.sol";
import {PrizePool} from "src/PrizePool.sol";
import {WithdrawalPool} from "src/WithdrawalPool.sol";
import {ElementsData} from "src/ElementsData.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {PECDeployer} from "script/PECDeployer.s.sol";
import {PECTestContract} from "test/contracts/PECTestContract.sol";
import {IElementsData} from "src/interfaces/IElementsData.sol";

import {Test, console} from "forge-std/Test.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract PECBaseTest is Test {
    uint256 public ELEMENTS_IN_PACK;
    uint256 public NUM_MAX_PACKS_MINTED_AT_ONCE;
    uint256 public PACK_PRICE;
    uint256 public ANTIMATTER_OFFSET;
    uint256 public DMT_FEE_PER_TRANSFER;
    uint256 public SUBSCRIPTION_ID;

    PECTestContract pec;
    DarkMatterTokens dmt;
    PrizePool prizePool;
    WithdrawalPool withdrawalPool;

    HelperConfig helperConfig;
    HelperConfig.NetworkConfig config;

    address owner;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address feeReceiver = makeAddr("feeReceiver");

    VRFCoordinatorV2_5Mock vrfCoordinator;

    modifier fundSubscriptionMax() {
        vm.deal(address(this), 100 ether);
        pec.s_vrfCoordinator().fundSubscriptionWithNative{value: 100 ether}(SUBSCRIPTION_ID);
        _;
    }

    function setUp() public {
        address pecTestContract;
        (pecTestContract, helperConfig) = (new PECDeployer()).deployContract(feeReceiver);
        pec = PECTestContract(pecTestContract);
        dmt = pec.darkMatterTokens();
        prizePool = pec.prizePool();
        withdrawalPool = prizePool.withdrawalPool();

        ELEMENTS_IN_PACK = pec.ELEMENTS_IN_PACK();
        NUM_MAX_PACKS_MINTED_AT_ONCE = pec.NUM_MAX_PACKS_MINTED_AT_ONCE();
        PACK_PRICE = pec.PACK_PRICE();
        ANTIMATTER_OFFSET = pec.ANTIMATTER_OFFSET();
        DMT_FEE_PER_TRANSFER = pec.DMT_FEE_PER_TRANSFER();
        SUBSCRIPTION_ID = pec.SUBSCRIPTION_ID();

        config = helperConfig.getConfig();
        config.subscriptionId = pec.SUBSCRIPTION_ID();

        vrfCoordinator = VRFCoordinatorV2_5Mock(config.vrfCoordinator);

        assert(address(pec) != address(0));
        assertEq(config.account, pec.owner());

        vm.deal(alice, type(uint128).max);
        vm.deal(bob, type(uint128).max);
    }

    function buyDmt(address user, uint256 amount) internal {
        vm.startPrank(user);
        dmt.buy{value: amount}();
        pec.mintFreePacks();
        vm.stopPrank();
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
        assertEq(expectedRAM, pec.getElementArtificialRAMWeight(alice, 1));
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

        new PeriodicElementsCollection(0, address(this), eds, msg.sender);
    }

    function test_fundingSubscriptionWorks(uint256 amount) public {
        amount = _bound(amount, 0, 100 ether);
        vm.prank(alice);
        pec.fundSubscription{value: amount}();

        (, uint96 nativeBalance,,,) = pec.s_vrfCoordinator().getSubscription(SUBSCRIPTION_ID);

        assertEq(nativeBalance, amount);
    }

    function test_fundingSubscriptionGivesExpectedAmountOfFreeElements(uint256 amount) public {
        amount = _bound(amount, 0, 100 ether);

        vm.prank(alice);
        pec.fundSubscription{value: amount}();

        // We expect to have 5 H & 5 He per pack-price refuel
        uint256 elementsExpected = amount * 5 / PACK_PRICE;
        assertEq(pec.balanceOf(alice, 1), elementsExpected);
        assertEq(pec.balanceOf(alice, 2), elementsExpected);
    }
}
