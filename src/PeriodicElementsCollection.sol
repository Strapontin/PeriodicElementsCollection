// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import {ElementsData} from "./ElementsData.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
// import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
// import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

//Chainlink VRF imports
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/// @custom:security-contact "strapontin" on discord. Join Cyfrin server to contact more easily.
contract PeriodicElementsCollection is
    Initializable,
    ERC1155Upgradeable,
    OwnableUpgradeable,
    ERC1155BurnableUpgradeable,
    ERC1155SupplyUpgradeable,
    UUPSUpgradeable,
    VRFConsumerBaseV2,
    ElementsData
{
    string public constant name = "Periodic Elements Collection";

    mapping(uint256 => address) public _requestIdToMinter;

    //Chainlink Variables
    VRFCoordinatorV2Interface private immutable coordinatorInterface;
    uint64 public immutable subscriptionId;
    address private immutable vrfCoordinatorV2Address;
    // TODO : put this value in constructor, define it in deployer.s.sol
    bytes32 keyHash = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c; // 750 gwei Sepolia
    uint32 callbackGasLimit = 200000;
    uint16 blockConfirmations = 10;
    uint32 numWords = 1;

    event MintRequestInitalized(uint256 indexed requestId, address indexed account);
    event TokenMinted(address indexed account, uint256 indexed id);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(uint64 _subscriptionId, address _vrfCoordinatorV2Address, ElementDataStruct[] memory datas)
        VRFConsumerBaseV2(vrfCoordinatorV2Address)
        ElementsData(datas)
    {
        // _disableInitializers();

        subscriptionId = _subscriptionId;
        vrfCoordinatorV2Address = _vrfCoordinatorV2Address;
        coordinatorInterface = VRFCoordinatorV2Interface(_vrfCoordinatorV2Address);
    }

    function initialize(address initialOwner) public initializer {
        __ERC1155_init(
            "https://gray-acute-wildfowl-4.mypinata.cloud/ipfs/QmcYB1e51yEXG5hosQ2N8RP8zVLTy5wUrc6523Jy21YczT/{id}.json"
        );
        __Ownable_init(initialOwner);
        __ERC1155Burnable_init();
        __ERC1155Supply_init();
        __UUPSUpgradeable_init();
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint() public returns (uint256 requestId) {
        // _mint(account, id, amount, data);
        requestId = coordinatorInterface.requestRandomWords(
            keyHash, subscriptionId, blockConfirmations, callbackGasLimit, numWords
        );

        _requestIdToMinter[requestId] = msg.sender;

        emit MintRequestInitalized(requestId, msg.sender);
    }

    // function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    //     public
    //     onlyOwner
    // {
    //     // TODO : Accounts can mint several packs at once, depending on the ether they provided
    //     _mintBatch(to, ids, amounts, data);
    // }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        address accountMinting = _requestIdToMinter[requestId];

        // To generate a random number between 1 and 100 inclusive
        uint256 randomNumber = (randomWords[0] % 100) + 1;

        uint256 tokenId;

        //manipulate the random number to get the tokenId with a variable probability
        if (randomNumber == 100) {
            tokenId = 1;
        } else if (randomNumber % 3 == 0) {
            tokenId = 2;
        } else {
            tokenId = 3;
        }

        // Finally mint the token
        _mint(accountMinting, tokenId, 1, "");

        // emit an event
        emit TokenMinted(accountMinting, tokenId);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // The following functions are overrides required by Solidity.
    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        override(ERC1155Upgradeable, ERC1155SupplyUpgradeable)
    {
        // put the code to run **before** the transfer HERE
        super._update(from, to, ids, values);
    }

    uint256[50] private __gap;
}
