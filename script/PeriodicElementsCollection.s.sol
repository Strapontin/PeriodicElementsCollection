// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {PeriodicElementsCollection} from "../src/PeriodicElementsCollection.sol";
import {ElementsData} from "../src/ElementsData.sol";
import {VRFCoordinatorV2Mock} from
    "../lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract PeriodicElementsCollectionDeployer is Script {
    function run()
        public
        returns (PeriodicElementsCollection periodicElementsCollection, VRFCoordinatorV2Mock mockVRF)
    {
        // Can ignore this. Just sets some base values
        // In real-world scenarios, you won't be deciding the
        // constructor values of the coordinator contract anyways
        mockVRF = new VRFCoordinatorV2Mock(100000000000000000, 1000000000);

        // Creating a new subscription through account 0x1
        uint64 subId = mockVRF.createSubscription();

        ElementsData.ElementDataStruct[] memory datas = getElementsData();
        periodicElementsCollection = new PeriodicElementsCollection(subId, address(mockVRF), datas);

        mockVRF.addConsumer(subId, address(periodicElementsCollection));
    }

    // This function sets the default values for each elements
    function getElementsData() public pure returns (ElementsData.ElementDataStruct[] memory) {
        ElementsData.ElementDataStruct[] memory data = new ElementsData.ElementDataStruct[](118);

        data[0] = ElementsData.ElementDataStruct(1, "Hydrogen", "H", 1008000000000000000, 1);
        data[1] = ElementsData.ElementDataStruct(2, "Helium", "He", 4002602200000000000, 1);
        data[2] = ElementsData.ElementDataStruct(3, "Lithium", "Li", 6940000000000000000, 2);
        data[3] = ElementsData.ElementDataStruct(4, "Beryllium", "Be", 9012183150000000000, 2);
        data[4] = ElementsData.ElementDataStruct(5, "Boron", "B", 10810000000000000000, 2);
        data[5] = ElementsData.ElementDataStruct(6, "Carbon", "C", 12011000000000000000, 2);
        data[6] = ElementsData.ElementDataStruct(7, "Nitrogen", "N", 14007000000000000000, 2);
        data[7] = ElementsData.ElementDataStruct(8, "Oxygen", "O", 15999000000000000000, 2);
        data[8] = ElementsData.ElementDataStruct(9, "Fluorine", "F", 18998403163600000000, 2);
        data[9] = ElementsData.ElementDataStruct(10, "Neon", "Ne", 20179760000000000000, 2);
        data[10] = ElementsData.ElementDataStruct(11, "Sodium", "Na", 22989769282000003000, 3);
        data[11] = ElementsData.ElementDataStruct(12, "Magnesium", "Mg", 24305000000000000000, 3);
        data[12] = ElementsData.ElementDataStruct(13, "Aluminium", "Al", 26981538570000003000, 3);
        data[13] = ElementsData.ElementDataStruct(14, "Silicon", "Si", 28085000000000000000, 3);
        data[14] = ElementsData.ElementDataStruct(15, "Phosphorus", "P", 30973761998500000000, 3);
        data[15] = ElementsData.ElementDataStruct(16, "Sulfur", "S", 32060000000000004000, 3);
        data[16] = ElementsData.ElementDataStruct(17, "Chlorine", "Cl", 35450000000000004000, 3);
        data[17] = ElementsData.ElementDataStruct(18, "Argon", "Ar", 39948100000000000000, 3);
        data[18] = ElementsData.ElementDataStruct(19, "Potassium", "K", 39098310000000000000, 4);
        data[19] = ElementsData.ElementDataStruct(20, "Calcium", "Ca", 40078400000000000000, 4);
        data[20] = ElementsData.ElementDataStruct(21, "Scandium", "Sc", 44955908500000000000, 4);
        data[21] = ElementsData.ElementDataStruct(22, "Titanium", "Ti", 47867100000000000000, 4);
        data[22] = ElementsData.ElementDataStruct(23, "Vanadium", "V", 50941510000000000000, 4);
        data[23] = ElementsData.ElementDataStruct(24, "Chromium", "Cr", 51996160000000000000, 4);
        data[24] = ElementsData.ElementDataStruct(25, "Manganese", "Mn", 54938044300000000000, 4);
        data[25] = ElementsData.ElementDataStruct(26, "Iron", "Fe", 55845200000000000000, 4);
        data[26] = ElementsData.ElementDataStruct(27, "Cobalt", "Co", 58933194400000000000, 4);
        data[27] = ElementsData.ElementDataStruct(28, "Nickel", "Ni", 58693440000000000000, 4);
        data[28] = ElementsData.ElementDataStruct(29, "Copper", "Cu", 63546300000000000000, 4);
        data[29] = ElementsData.ElementDataStruct(30, "Zinc", "Zn", 65382000000000010000, 4);
        data[30] = ElementsData.ElementDataStruct(31, "Gallium", "Ga", 69723100000000000000, 4);
        data[31] = ElementsData.ElementDataStruct(32, "Germanium", "Ge", 72630799999999990000, 4);
        data[32] = ElementsData.ElementDataStruct(33, "Arsenic", "As", 74921595600000010000, 4);
        data[33] = ElementsData.ElementDataStruct(34, "Selenium", "Se", 78971800000000000000, 4);
        data[34] = ElementsData.ElementDataStruct(35, "Bromine", "Br", 79904000000000000000, 4);
        data[35] = ElementsData.ElementDataStruct(36, "Krypton", "Kr", 83798200000000000000, 4);
        data[36] = ElementsData.ElementDataStruct(37, "Rubidium", "Rb", 85467830000000000000, 5);
        data[37] = ElementsData.ElementDataStruct(38, "Strontium", "Sr", 87621000000000000000, 5);
        data[38] = ElementsData.ElementDataStruct(39, "Yttrium", "Y", 88905842000000010000, 5);
        data[39] = ElementsData.ElementDataStruct(40, "Zirconium", "Zr", 91224200000000000000, 5);
        data[40] = ElementsData.ElementDataStruct(41, "Niobium", "Nb", 92906372000000000000, 5);
        data[41] = ElementsData.ElementDataStruct(42, "Molybdenum", "Mo", 95951000000000000000, 5);
        data[42] = ElementsData.ElementDataStruct(43, "Technetium", "Tc", 98000000000000000000, 5);
        data[43] = ElementsData.ElementDataStruct(44, "Ruthenium", "Ru", 101072000000000000000, 5);
        data[44] = ElementsData.ElementDataStruct(45, "Rhodium", "Rh", 102905501999999990000, 5);
        data[45] = ElementsData.ElementDataStruct(46, "Palladium", "Pd", 106421000000000000000, 5);
        data[46] = ElementsData.ElementDataStruct(47, "Silver", "Ag", 107868220000000000000, 5);
        data[47] = ElementsData.ElementDataStruct(48, "Cadmium", "Cd", 112414400000000000000, 5);
        data[48] = ElementsData.ElementDataStruct(49, "Indium", "In", 114818100000000000000, 5);
        data[49] = ElementsData.ElementDataStruct(50, "Tin", "Sn", 118710700000000000000, 5);
        data[50] = ElementsData.ElementDataStruct(51, "Antimony", "Sb", 121760100000000000000, 5);
        data[51] = ElementsData.ElementDataStruct(52, "Tellurium", "Te", 127603000000000000000, 5);
        data[52] = ElementsData.ElementDataStruct(53, "Iodine", "I", 126904473000000000000, 5);
        data[53] = ElementsData.ElementDataStruct(54, "Xenon", "Xe", 131293600000000000000, 5);
        data[54] = ElementsData.ElementDataStruct(55, "Cesium", "Cs", 132905451965999990000, 6);
        data[55] = ElementsData.ElementDataStruct(56, "Barium", "Ba", 137327700000000000000, 6);
        data[56] = ElementsData.ElementDataStruct(57, "Lanthanum", "La", 138905477000000000000, 6);
        data[57] = ElementsData.ElementDataStruct(58, "Cerium", "Ce", 140116099999999980000, 6);
        data[58] = ElementsData.ElementDataStruct(59, "Praseodymium", "Pr", 140907661999999990000, 6);
        data[59] = ElementsData.ElementDataStruct(60, "Neodymium", "Nd", 144242300000000000000, 6);
        data[60] = ElementsData.ElementDataStruct(61, "Promethium", "Pm", 145000000000000000000, 6);
        data[61] = ElementsData.ElementDataStruct(62, "Samarium", "Sm", 150362000000000000000, 6);
        data[62] = ElementsData.ElementDataStruct(63, "Europium", "Eu", 151964100000000020000, 6);
        data[63] = ElementsData.ElementDataStruct(64, "Gadolinium", "Gd", 157253000000000000000, 6);
        data[64] = ElementsData.ElementDataStruct(65, "Terbium", "Tb", 158925352000000000000, 6);
        data[65] = ElementsData.ElementDataStruct(66, "Dysprosium", "Dy", 162500100000000020000, 6);
        data[66] = ElementsData.ElementDataStruct(67, "Holmium", "Ho", 164930331999999980000, 6);
        data[67] = ElementsData.ElementDataStruct(68, "Erbium", "Er", 167259300000000000000, 6);
        data[68] = ElementsData.ElementDataStruct(69, "Thulium", "Tm", 168934222000000000000, 6);
        data[69] = ElementsData.ElementDataStruct(70, "Ytterbium", "Yb", 173045099999999980000, 6);
        data[70] = ElementsData.ElementDataStruct(71, "Lutetium", "Lu", 174966810000000020000, 6);
        data[71] = ElementsData.ElementDataStruct(72, "Hafnium", "Hf", 178492000000000000000, 6);
        data[72] = ElementsData.ElementDataStruct(73, "Tantalum", "Ta", 180947882000000000000, 6);
        data[73] = ElementsData.ElementDataStruct(74, "Tungsten", "W", 183841000000000000000, 6);
        data[74] = ElementsData.ElementDataStruct(75, "Rhenium", "Re", 186207099999999980000, 6);
        data[75] = ElementsData.ElementDataStruct(76, "Osmium", "Os", 190233000000000000000, 6);
        data[76] = ElementsData.ElementDataStruct(77, "Iridium", "Ir", 192217300000000000000, 6);
        data[77] = ElementsData.ElementDataStruct(78, "Platinum", "Pt", 195084900000000020000, 6);
        data[78] = ElementsData.ElementDataStruct(79, "Gold", "Au", 196966569500000000000, 6);
        data[79] = ElementsData.ElementDataStruct(80, "Mercury", "Hg", 200592299999999980000, 6);
        data[80] = ElementsData.ElementDataStruct(81, "Thallium", "Tl", 204380000000000000000, 6);
        data[81] = ElementsData.ElementDataStruct(82, "Lead", "Pb", 207210000000000000000, 6);
        data[82] = ElementsData.ElementDataStruct(83, "Bismuth", "Bi", 208980401000000000000, 6);
        data[83] = ElementsData.ElementDataStruct(84, "Polonium", "Po", 209000000000000000000, 6);
        data[84] = ElementsData.ElementDataStruct(85, "Astatine", "At", 210000000000000000000, 6);
        data[85] = ElementsData.ElementDataStruct(86, "Radon", "Rn", 222000000000000000000, 6);
        data[86] = ElementsData.ElementDataStruct(87, "Francium", "Fr", 223000000000000000000, 7);
        data[87] = ElementsData.ElementDataStruct(88, "Radium", "Ra", 226000000000000000000, 7);
        data[88] = ElementsData.ElementDataStruct(89, "Actinium", "Ac", 227000000000000000000, 7);
        data[89] = ElementsData.ElementDataStruct(90, "Thorium", "Th", 232037740000000000000, 7);
        data[90] = ElementsData.ElementDataStruct(91, "Protactinium", "Pa", 231035882000000000000, 7);
        data[91] = ElementsData.ElementDataStruct(92, "Uranium", "U", 238028913000000000000, 7);
        data[92] = ElementsData.ElementDataStruct(93, "Neptunium", "Np", 237000000000000000000, 7);
        data[93] = ElementsData.ElementDataStruct(94, "Plutonium", "Pu", 244000000000000000000, 7);
        data[94] = ElementsData.ElementDataStruct(95, "Americium", "Am", 243000000000000000000, 7);
        data[95] = ElementsData.ElementDataStruct(96, "Curium", "Cm", 247000000000000000000, 7);
        data[96] = ElementsData.ElementDataStruct(97, "Berkelium", "Bk", 247000000000000000000, 7);
        data[97] = ElementsData.ElementDataStruct(98, "Californium", "Cf", 251000000000000000000, 7);
        data[98] = ElementsData.ElementDataStruct(99, "Einsteinium", "Es", 252000000000000000000, 7);
        data[99] = ElementsData.ElementDataStruct(100, "Fermium", "Fm", 257000000000000000000, 7);
        data[100] = ElementsData.ElementDataStruct(101, "Mendelevium", "Md", 258000000000000000000, 7);
        data[101] = ElementsData.ElementDataStruct(102, "Nobelium", "No", 259000000000000000000, 7);
        data[102] = ElementsData.ElementDataStruct(103, "Lawrencium", "Lr", 266000000000000000000, 7);
        data[103] = ElementsData.ElementDataStruct(104, "Rutherfordium", "Rf", 267000000000000000000, 7);
        data[104] = ElementsData.ElementDataStruct(105, "Dubnium", "Db", 268000000000000000000, 7);
        data[105] = ElementsData.ElementDataStruct(106, "Seaborgium", "Sg", 269000000000000000000, 7);
        data[106] = ElementsData.ElementDataStruct(107, "Bohrium", "Bh", 270000000000000000000, 7);
        data[107] = ElementsData.ElementDataStruct(108, "Hassium", "Hs", 269000000000000000000, 7);
        data[108] = ElementsData.ElementDataStruct(109, "Meitnerium", "Mt", 278000000000000000000, 7);
        data[109] = ElementsData.ElementDataStruct(110, "Darmstadtium", "Ds", 281000000000000000000, 7);
        data[110] = ElementsData.ElementDataStruct(111, "Roentgenium", "Rg", 282000000000000000000, 7);
        data[111] = ElementsData.ElementDataStruct(112, "Copernicium", "Cn", 285000000000000000000, 7);
        data[112] = ElementsData.ElementDataStruct(113, "Nihonium", "Nh", 286000000000000000000, 7);
        data[113] = ElementsData.ElementDataStruct(114, "Flerovium", "Fl", 289000000000000000000, 7);
        data[114] = ElementsData.ElementDataStruct(115, "Moscovium", "Mc", 289000000000000000000, 7);
        data[115] = ElementsData.ElementDataStruct(116, "Livermorium", "Lv", 293000000000000000000, 7);
        data[116] = ElementsData.ElementDataStruct(117, "Tennessine", "Ts", 294000000000000000000, 7);
        data[117] = ElementsData.ElementDataStruct(118, "Oganesson", "Og", 294000000000000000000, 7);
        
        return data;
    }
}
