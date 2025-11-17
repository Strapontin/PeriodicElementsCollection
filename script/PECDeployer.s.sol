// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {PeriodicElementsCollection} from "../src/PeriodicElementsCollection.sol";
import {PECTestContract} from "../test/contracts/PECTestContract.sol";
import {IElementsData} from "../src/interfaces/IElementsData.sol";

import {Script} from "forge-std/Script.sol";

import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, AddConsumer} from "./VRFInteractions.s.sol";

contract PECDeployer is Script {
    uint256 public constant LOCAL_CHAIN_ID = 31337;

    function run() public {
        deployContract(address(0));
    }

    function deployContract(address _feeReceiver) public returns (address, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        // Create subscription
        if (config.subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            (config.subscriptionId, config.vrfCoordinator) =
                createSubscription.createSubscription(config.vrfCoordinator, config.account);
        }

        address periodicElementsCollection;

        vm.startBroadcast(config.account);
        // If we're on the anvil network, deploy the test contract
        if (block.chainid == LOCAL_CHAIN_ID) {
            periodicElementsCollection = address(
                new PECTestContract(config.subscriptionId, config.vrfCoordinator, getElementsData(), _feeReceiver)
            );
        } else {
            address feeReceiver = msg.sender; // TODO: Change this to a specific fee receiver

            periodicElementsCollection = address(
                new PeriodicElementsCollection(
                    config.subscriptionId, config.vrfCoordinator, getElementsData(), feeReceiver
                )
            );
        }
        vm.stopBroadcast();

        // Don't need to broadcast because it's in 'addConsumer'
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(
            periodicElementsCollection, config.vrfCoordinator, config.subscriptionId, config.account
        );

        return (periodicElementsCollection, helperConfig);
    }

    // This function sets the default values for each elements
    function getElementsData() public pure returns (IElementsData.ElementDataStruct[] memory) {
        IElementsData.ElementDataStruct[] memory data = new IElementsData.ElementDataStruct[](118);

        data[0] = IElementsData.ElementDataStruct(1, "Hydrogen", "H", 1008, 1);
        data[1] = IElementsData.ElementDataStruct(2, "Helium", "He", 4002, 1);
        data[2] = IElementsData.ElementDataStruct(3, "Lithium", "Li", 6940, 2);
        data[3] = IElementsData.ElementDataStruct(4, "Beryllium", "Be", 9012, 2);
        data[4] = IElementsData.ElementDataStruct(5, "Boron", "B", 10810, 2);
        data[5] = IElementsData.ElementDataStruct(6, "Carbon", "C", 12011, 2);
        data[6] = IElementsData.ElementDataStruct(7, "Nitrogen", "N", 14007, 2);
        data[7] = IElementsData.ElementDataStruct(8, "Oxygen", "O", 15999, 2);
        data[8] = IElementsData.ElementDataStruct(9, "Fluorine", "F", 18998, 2);
        data[9] = IElementsData.ElementDataStruct(10, "Neon", "Ne", 20179, 2);
        data[10] = IElementsData.ElementDataStruct(11, "Sodium", "Na", 22989, 3);
        data[11] = IElementsData.ElementDataStruct(12, "Magnesium", "Mg", 24305, 3);
        data[12] = IElementsData.ElementDataStruct(13, "Aluminium", "Al", 26981, 3);
        data[13] = IElementsData.ElementDataStruct(14, "Silicon", "Si", 28085, 3);
        data[14] = IElementsData.ElementDataStruct(15, "Phosphorus", "P", 30973, 3);
        data[15] = IElementsData.ElementDataStruct(16, "Sulfur", "S", 32060, 3);
        data[16] = IElementsData.ElementDataStruct(17, "Chlorine", "Cl", 35450, 3);
        data[17] = IElementsData.ElementDataStruct(18, "Argon", "Ar", 39948, 3);
        data[18] = IElementsData.ElementDataStruct(19, "Potassium", "K", 39098, 4);
        data[19] = IElementsData.ElementDataStruct(20, "Calcium", "Ca", 40078, 4);
        data[20] = IElementsData.ElementDataStruct(21, "Scandium", "Sc", 44955, 4);
        data[21] = IElementsData.ElementDataStruct(22, "Titanium", "Ti", 47867, 4);
        data[22] = IElementsData.ElementDataStruct(23, "Vanadium", "V", 50941, 4);
        data[23] = IElementsData.ElementDataStruct(24, "Chromium", "Cr", 51996, 4);
        data[24] = IElementsData.ElementDataStruct(25, "Manganese", "Mn", 54938, 4);
        data[25] = IElementsData.ElementDataStruct(26, "Iron", "Fe", 55845, 4);
        data[26] = IElementsData.ElementDataStruct(27, "Cobalt", "Co", 58933, 4);
        data[27] = IElementsData.ElementDataStruct(28, "Nickel", "Ni", 58693, 4);
        data[28] = IElementsData.ElementDataStruct(29, "Copper", "Cu", 63546, 4);
        data[29] = IElementsData.ElementDataStruct(30, "Zinc", "Zn", 65382, 4);
        data[30] = IElementsData.ElementDataStruct(31, "Gallium", "Ga", 69723, 4);
        data[31] = IElementsData.ElementDataStruct(32, "Germanium", "Ge", 72630, 4);
        data[32] = IElementsData.ElementDataStruct(33, "Arsenic", "As", 74921, 4);
        data[33] = IElementsData.ElementDataStruct(34, "Selenium", "Se", 78971, 4);
        data[34] = IElementsData.ElementDataStruct(35, "Bromine", "Br", 79904, 4);
        data[35] = IElementsData.ElementDataStruct(36, "Krypton", "Kr", 83798, 4);
        data[36] = IElementsData.ElementDataStruct(37, "Rubidium", "Rb", 85467, 5);
        data[37] = IElementsData.ElementDataStruct(38, "Strontium", "Sr", 87621, 5);
        data[38] = IElementsData.ElementDataStruct(39, "Yttrium", "Y", 88905, 5);
        data[39] = IElementsData.ElementDataStruct(40, "Zirconium", "Zr", 91224, 5);
        data[40] = IElementsData.ElementDataStruct(41, "Niobium", "Nb", 92906, 5);
        data[41] = IElementsData.ElementDataStruct(42, "Molybdenum", "Mo", 95951, 5);
        data[42] = IElementsData.ElementDataStruct(43, "Technetium", "Tc", 98000, 5);
        data[43] = IElementsData.ElementDataStruct(44, "Ruthenium", "Ru", 101072, 5);
        data[44] = IElementsData.ElementDataStruct(45, "Rhodium", "Rh", 102905, 5);
        data[45] = IElementsData.ElementDataStruct(46, "Palladium", "Pd", 106421, 5);
        data[46] = IElementsData.ElementDataStruct(47, "Silver", "Ag", 107868, 5);
        data[47] = IElementsData.ElementDataStruct(48, "Cadmium", "Cd", 112414, 5);
        data[48] = IElementsData.ElementDataStruct(49, "Indium", "In", 114818, 5);
        data[49] = IElementsData.ElementDataStruct(50, "Tin", "Sn", 118710, 5);
        data[50] = IElementsData.ElementDataStruct(51, "Antimony", "Sb", 121760, 5);
        data[51] = IElementsData.ElementDataStruct(52, "Tellurium", "Te", 127603, 5);
        data[52] = IElementsData.ElementDataStruct(53, "Iodine", "I", 126904, 5);
        data[53] = IElementsData.ElementDataStruct(54, "Xenon", "Xe", 131293, 5);
        data[54] = IElementsData.ElementDataStruct(55, "Cesium", "Cs", 132905, 6);
        data[55] = IElementsData.ElementDataStruct(56, "Barium", "Ba", 137327, 6);
        data[56] = IElementsData.ElementDataStruct(57, "Lanthanum", "La", 138905, 6);
        data[57] = IElementsData.ElementDataStruct(58, "Cerium", "Ce", 140116, 6);
        data[58] = IElementsData.ElementDataStruct(59, "Praseodymium", "Pr", 140907, 6);
        data[59] = IElementsData.ElementDataStruct(60, "Neodymium", "Nd", 144242, 6);
        data[60] = IElementsData.ElementDataStruct(61, "Promethium", "Pm", 145000, 6);
        data[61] = IElementsData.ElementDataStruct(62, "Samarium", "Sm", 150362, 6);
        data[62] = IElementsData.ElementDataStruct(63, "Europium", "Eu", 151964, 6);
        data[63] = IElementsData.ElementDataStruct(64, "Gadolinium", "Gd", 157253, 6);
        data[64] = IElementsData.ElementDataStruct(65, "Terbium", "Tb", 158925, 6);
        data[65] = IElementsData.ElementDataStruct(66, "Dysprosium", "Dy", 162500, 6);
        data[66] = IElementsData.ElementDataStruct(67, "Holmium", "Ho", 164930, 6);
        data[67] = IElementsData.ElementDataStruct(68, "Erbium", "Er", 167259, 6);
        data[68] = IElementsData.ElementDataStruct(69, "Thulium", "Tm", 168934, 6);
        data[69] = IElementsData.ElementDataStruct(70, "Ytterbium", "Yb", 173045, 6);
        data[70] = IElementsData.ElementDataStruct(71, "Lutetium", "Lu", 174966, 6);
        data[71] = IElementsData.ElementDataStruct(72, "Hafnium", "Hf", 178492, 6);
        data[72] = IElementsData.ElementDataStruct(73, "Tantalum", "Ta", 180947, 6);
        data[73] = IElementsData.ElementDataStruct(74, "Tungsten", "W", 183841, 6);
        data[74] = IElementsData.ElementDataStruct(75, "Rhenium", "Re", 186207, 6);
        data[75] = IElementsData.ElementDataStruct(76, "Osmium", "Os", 190233, 6);
        data[76] = IElementsData.ElementDataStruct(77, "Iridium", "Ir", 192217, 6);
        data[77] = IElementsData.ElementDataStruct(78, "Platinum", "Pt", 195084, 6);
        data[78] = IElementsData.ElementDataStruct(79, "Gold", "Au", 196966, 6);
        data[79] = IElementsData.ElementDataStruct(80, "Mercury", "Hg", 200592, 6);
        data[80] = IElementsData.ElementDataStruct(81, "Thallium", "Tl", 204380, 6);
        data[81] = IElementsData.ElementDataStruct(82, "Lead", "Pb", 207210, 6);
        data[82] = IElementsData.ElementDataStruct(83, "Bismuth", "Bi", 208980, 6);
        data[83] = IElementsData.ElementDataStruct(84, "Polonium", "Po", 209000, 6);
        data[84] = IElementsData.ElementDataStruct(85, "Astatine", "At", 210000, 6);
        data[85] = IElementsData.ElementDataStruct(86, "Radon", "Rn", 222000, 6);
        data[86] = IElementsData.ElementDataStruct(87, "Francium", "Fr", 223000, 7);
        data[87] = IElementsData.ElementDataStruct(88, "Radium", "Ra", 226000, 7);
        data[88] = IElementsData.ElementDataStruct(89, "Actinium", "Ac", 227000, 7);
        data[89] = IElementsData.ElementDataStruct(90, "Thorium", "Th", 232037, 7);
        data[90] = IElementsData.ElementDataStruct(91, "Protactinium", "Pa", 231035, 7);
        data[91] = IElementsData.ElementDataStruct(92, "Uranium", "U", 238028, 7);
        data[92] = IElementsData.ElementDataStruct(93, "Neptunium", "Np", 237000, 7);
        data[93] = IElementsData.ElementDataStruct(94, "Plutonium", "Pu", 244000, 7);
        data[94] = IElementsData.ElementDataStruct(95, "Americium", "Am", 243000, 7);
        data[95] = IElementsData.ElementDataStruct(96, "Curium", "Cm", 247000, 7);
        data[96] = IElementsData.ElementDataStruct(97, "Berkelium", "Bk", 247000, 7);
        data[97] = IElementsData.ElementDataStruct(98, "Californium", "Cf", 251000, 7);
        data[98] = IElementsData.ElementDataStruct(99, "Einsteinium", "Es", 252000, 7);
        data[99] = IElementsData.ElementDataStruct(100, "Fermium", "Fm", 257000, 7);
        data[100] = IElementsData.ElementDataStruct(101, "Mendelevium", "Md", 258000, 7);
        data[101] = IElementsData.ElementDataStruct(102, "Nobelium", "No", 259000, 7);
        data[102] = IElementsData.ElementDataStruct(103, "Lawrencium", "Lr", 266000, 7);
        data[103] = IElementsData.ElementDataStruct(104, "Rutherfordium", "Rf", 267000, 7);
        data[104] = IElementsData.ElementDataStruct(105, "Dubnium", "Db", 268000, 7);
        data[105] = IElementsData.ElementDataStruct(106, "Seaborgium", "Sg", 269000, 7);
        data[106] = IElementsData.ElementDataStruct(107, "Bohrium", "Bh", 270000, 7);
        data[107] = IElementsData.ElementDataStruct(108, "Hassium", "Hs", 269000, 7);
        data[108] = IElementsData.ElementDataStruct(109, "Meitnerium", "Mt", 278000, 7);
        data[109] = IElementsData.ElementDataStruct(110, "Darmstadtium", "Ds", 281000, 7);
        data[110] = IElementsData.ElementDataStruct(111, "Roentgenium", "Rg", 282000, 7);
        data[111] = IElementsData.ElementDataStruct(112, "Copernicium", "Cn", 285000, 7);
        data[112] = IElementsData.ElementDataStruct(113, "Nihonium", "Nh", 286000, 7);
        data[113] = IElementsData.ElementDataStruct(114, "Flerovium", "Fl", 289000, 7);
        data[114] = IElementsData.ElementDataStruct(115, "Moscovium", "Mc", 289000, 7);
        data[115] = IElementsData.ElementDataStruct(116, "Livermorium", "Lv", 293000, 7);
        data[116] = IElementsData.ElementDataStruct(117, "Tennessine", "Ts", 294000, 7);
        data[117] = IElementsData.ElementDataStruct(118, "Oganesson", "Og", 294000, 7);

        return data;
    }
}
