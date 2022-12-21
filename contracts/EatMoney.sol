// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "@openzeppelin/contracts/utils/Counters.sol";

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract EatMoney is
    ERC1155,
    ERC1155Burnable,
    Ownable,
    VRFConsumerBaseV2,
    ERC1155Holder
{

    /* Declarations */
    uint256 constant EAT_DECIMALS = 8;

    uint256 FACTOR_1 = 1; //cofficent for efficency (will change according to the market)
    uint256 FACTOR_2 = 3; // random start
    uint256 FACTOR_3 = 5; // random end

    VRFCoordinatorV2Interface immutable COORDINATOR;
    bytes32 immutable s_keyHash;
    uint32 callbackGasLimit = 2500000;
    uint16 requestConfirmations = 3;
    uint64 s_subscriptionId;

    AggregatorV3Interface internal priceFeed;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _restaurants;
    Counters.Counter private _listings;

    enum Category {
        BRONZE,
        SILVER,
        GOLD,
        EMERALD
    }

    enum ChainlinkRequestType {
        MINT,
        EAT,
        SPIN
    }

    mapping(uint256 => ChainlinkRequestType) public chailinkRequestsTypes;
    mapping(uint256 => uint8) public reqIdTocategory;

    mapping(uint256 => EatRequest) public reqIdToEatRequest;
    mapping(uint256 => SpinRequest) public reqIdToSpinRequest;


     struct EatPlate {
        uint256 id;
        uint256 efficiency;
        uint256 fortune;
        uint256 durablity;
        uint256 shiny;
        uint8 level;
        Category category;
        uint256 lastEat;
        uint256 eats;
        mapping(uint256 => Spin) idToSpin;
    }

    struct EatPlateReturn {
        uint256 id;
        uint256 efficiency;
        uint256 fortune;
        uint256 durablity;
        uint256 shiny;
        uint8 level;
        Category category;
        uint256 lastEat;
        uint256 eats;
    }

    struct MintRequest {
        uint8 category;
        uint256[] randomWords;
        bool isMinted;
    }

    struct SpinRequest {
        uint256 plateId;
        address owner;
        uint256 eatCoins;
        bool active;
    }

    struct EatRequest {
        uint256 plateId;
        address owner;
        uint256 restaurantId;
        uint256 amount;
        bool active;
    }

     MintRequest[] public mintRequests;

     mapping(uint256 => EatPlate) public idToEatPlate;
    mapping(uint256 => Restaurant) public idToRestaurant;

    struct Spin {
        uint256 spinId;
        uint32 result; //   1/2/3/4
        uint256 eatCoins;
        bool isSpinned;
    }

    struct MarketItem {
        uint256 id;
        uint256 price;
        address payable owner;
        bool active;
        uint256 tokenId;
    }

    mapping(uint256 => MarketItem) public idToMarketplaceItem;

    struct Restaurant {
        uint256 id;
        string info;
        address payable owner;
    }

    mapping(address => uint256) public addressToRestaurantId;

    event EatFinished(
        uint256 indexed plateId,
        uint256 restaurantId,
        uint256 amount,
        uint256 eatCoinsMinted
    );

    event LevelUp(
        uint256 plateId,
        uint256 efficency,
        uint256 fortune,
        uint256 durability,
        uint256 level
    );

    event SpinFinished(
        uint256 indexed plateId,
        uint256 indexed spinId,
        uint256 eatCoinsWon
    );


// constructor call:

    constructor(
        uint64 subscriptionId,
        address vrfCoordinator,
        bytes32 keyHash
    ) VRFConsumerBaseV2(vrfCoordinator) ERC1155("ipfs://bafybeickwso5eac5krffgzdk2ktfg5spnryiygk3mbenryxdsapg3a54va/")
    {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_keyHash = keyHash;
        s_subscriptionId = subscriptionId;
        priceFeed = AggregatorV3Interface(
            0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada
        ); //MATIC/USD price feed mumbai
    }

function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC1155Receiver)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        ChainlinkRequestType requestType = chailinkRequestsTypes[requestId];
        if (requestType == ChainlinkRequestType.MINT) {
            mintRequests.push(
                MintRequest(reqIdTocategory[requestId], randomWords, false)
            );
        } else if (requestType == ChainlinkRequestType.EAT) {
            // _finishEat(requestId, randomWords);
        } else if (requestType == ChainlinkRequestType.SPIN) {
            // _finishSpin(requestId, randomWords);
        }
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function getLatestPrice() public view returns(int256){
        (, int256 price, , , ) = priceFeed.latestRoundData();
         return price;
    }


}
