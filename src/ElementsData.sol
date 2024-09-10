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
    mapping(address user => uint256 level) public usersLevel;

    constructor(ElementDataStruct[] memory datas) {
        for (uint256 i = 0; i < datas.length; i++) {
            elementsData[datas[i].number] = datas[i];

            // Fills lvl 1 elements in all levels, lvl 2 in all except lvl 1, ...
            for (uint256 lvl = 7; lvl >= datas[i].level; lvl--) {
                elementsUnlockedUnderLevel[lvl].push(datas[i].number);
            }
        }
    }

    function pickRandomElementAvailable(uint256 randomWord) internal view returns (uint256) {
        uint256 userLevel = usersLevel[msg.sender] + 1; // initial Userlvl = 0
        uint256[] memory elementsUnlocked = elementsUnlockedUnderLevel[userLevel];
        uint256 availableElementsLength = elementsUnlocked.length;

        uint256[] memory weights = new uint256[](availableElementsLength);
        uint256 totalWeight = 0;

        for (uint256 i = 0; i < availableElementsLength; i++) {
            weights[i] = getElementArtificialRAMWeight(elementsUnlocked[i]);
            totalWeight += weights[i];
        }
        
        uint256 random = randomWord % totalWeight;

        uint256 cumulativeWeight = 0;
        for (uint256 i = 0; i < elementsUnlocked.length; i++) {
            cumulativeWeight += weights[i];
            if (random < cumulativeWeight) {
                return elementsUnlocked[i];
            }
        }

        // This should not be reached; return the last element as a fallback
        return elementsUnlocked[elementsUnlocked.length - 1];
    }

    function getElementArtificialRAMWeight(uint256 elementNumber) public view returns (uint256 artificialRAM) {
        uint256 elementBaseRAM = elementsData[elementNumber].initialRAM;
        uint256 numBurnedTimes = burnedTimes[msg.sender][elementNumber];

        // 1e22 allows the heaviest burnable element (Radon) to be burned (10_000 - 222) times
        artificialRAM = 1e22 / (elementBaseRAM + (numBurnedTimes * 1e18));
    }
}
