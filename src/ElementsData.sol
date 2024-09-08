// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ElementsData {
    struct ElementDataStruct {
        uint8 number; // Number of the element in the periodic table
        string name; // Full name of the element
        string symbol; // Short symbol of the element
        uint256 initialRAM; // Initial Relative Atomic Mass of the element
        uint8 level; // Level of the element (from 1 to 7)
    }

    mapping(uint8 elementNumber => ElementDataStruct data) public elementsData; // List of elements' datas
    mapping(uint8 level => uint8[] elementsNumberUnlocked) elementsUnlockedUnderUserLevel;

    mapping(address user => mapping(uint8 elementNumber => uint256 burnedTimes)) burnedTimes;

    constructor(ElementDataStruct[] memory datas) {
        for (uint256 i = 0; i < datas.length; i++) {
            elementsData[datas[i].number] = datas[i];

            for (uint8 lvl = 1; lvl <= datas[i].level; lvl++) {
                elementsUnlockedUnderUserLevel[lvl].push(datas[i].number);
            }
        }
    }
}
