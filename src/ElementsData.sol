// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {console} from "forge-std/console.sol";

contract ElementsData {
    struct ElementDataStruct {
        uint256 number; // Number of the element in the periodic table
        string name; // Full name of the element
        string symbol; // Short symbol of the element
        uint256 initialRAM; // Initial Relative Atomic Mass of the element
        uint256 level; // Level of the element (from 1 to 7)
    }

    mapping(uint256 elementNumber => ElementDataStruct data) public elementsData; // List of elements' datas
    mapping(uint256 level => uint256[] elementsNumberUnlocked) public elementsUnlockedUnderLevel;
    mapping(address user => mapping(uint256 elementNumber => uint256 burnedTimes)) burnedTimes;
    mapping(address user => uint256 level) public usersLevel; // 0 indexed : lvl 1 = 0

    constructor(ElementDataStruct[] memory datas) {
        for (uint256 i = 0; i < datas.length; i++) {
            elementsData[datas[i].number] = datas[i];

            // Fills lvl 1 elements in all levels, lvl 2 in all except lvl 1, ...
            for (uint256 lvl = 7; lvl >= datas[i].level; lvl--) {
                elementsUnlockedUnderLevel[lvl - 1].push(datas[i].number);
            }
        }
    }

    function pickRandomElementAvailable(address user, uint256[] memory randomWords)
        internal
        view
        returns (uint256[] memory result)
    {
        result = new uint256[](randomWords.length);
        (uint256[] memory weights, uint256 totalWeight, uint256[] memory elementsUnlocked) = getRealUserWeights(user);

        for (uint256 rngIndex = 0; rngIndex < randomWords.length; rngIndex++) {
            uint256 random = randomWords[rngIndex] % totalWeight;

            uint256 cumulativeWeight = 0;
            for (uint256 i = 0; i < elementsUnlocked.length; i++) {
                cumulativeWeight += weights[i];

                if (cumulativeWeight > random) {
                    result[rngIndex] = elementsUnlocked[i];

                    // 1/10k chances to be antimatter
                    if (randomWords[rngIndex] % 10_000 == 0) {
                        console.log("ANTIMATTER");
                        result[rngIndex] += 10_000;
                    }

                    break;
                }
            }
        }
    }

    function getRealUserWeights(address user)
        public
        view
        returns (uint256[] memory elementsWeight, uint256 totalWeight, uint256[] memory elementsUnlocked)
    {
        elementsUnlocked = getElementsUnlockedByPlayer(user);
        uint256 availableElementsLength = elementsUnlocked.length;

        elementsWeight = new uint256[](availableElementsLength);

        for (uint256 i = 0; i < availableElementsLength; i++) {
            elementsWeight[i] = getElementArtificialRAMWeight(elementsUnlocked[i]);
            totalWeight += elementsWeight[i];
        }
    }

    function getElementsUnlockedByPlayer(address user) public view returns (uint256[] memory) {
        return elementsUnlockedUnderLevel[usersLevel[user]];
    }

    function getElementArtificialRAMWeight(uint256 elementNumber) public view returns (uint256 artificialRAM) {
        uint256 elementBaseRAM = elementsData[elementNumber].initialRAM;
        uint256 numBurnedTimes = burnedTimes[msg.sender][elementNumber];

        // elementBaseRAM is set in deployer
        artificialRAM = 1e18 / (elementBaseRAM + (numBurnedTimes * 1_000));
    }
}
