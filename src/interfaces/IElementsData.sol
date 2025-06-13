// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IElementsData {
    struct ElementDataStruct {
        uint256 number; // Number of the element in the periodic table
        string name; // Full name of the element
        string symbol; // Short symbol of the element
        uint256 initialRAM; // Initial Relative Atomic Mass of the element
        uint256 level; // Level of the element (from 1 to 7)
    }
}
