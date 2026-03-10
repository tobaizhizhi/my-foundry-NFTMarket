// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

error NFTMarketplace__InvalidNFTContract();
error NFTMarketplace__NFTNotOwnedBySender();
error NFTMarketplace__PriceMustBeGreaterThanZero();
error NFTMarketplace__NFTNotApprovedForMarket();
error NFTMarketplace__AlreadyListed();
error NFTMarketplace__ListingNotActive();
error NFTMarketplace__SellerNotNFTOwner();
error NFTMarketplace__MoneyIsNotEnoughToBuy();
error NFTMarketplace__NotListingSeller();
error NFTMarketplace__ListingExpired();
error NFTMarketplace__InvalidExpireDuration();
error NFTMarketplace__TicketAlreadyUsed();
error NFTMarketplace__TicketExpiredForTrade();
error NFTMarketplace__TicketResaleNotAllowed();
error NFTMarketplace__TicketPriceExceedsMaxResale();
error NFTMarketplace__NoProceedsToWithdraw();
error NFTMarketplace__WithdrawTransferFailed();
error NFTMarketplace__InvalidPlatformFeeBps();
error NFTMarketplace__InvalidFeeRecipient();

contract NFTMarketplaceData {
    uint96 public constant FEE_BPS_DENOMINATOR = 10_000;
    uint96 public constant MAX_PLATFORM_FEE_BPS = 1_000; // 10%

    enum OrderType {
        FixedPrice,
        Offer
    }

    struct Listing {
        uint256 orderId;
        address seller;
        uint256 priceWei;
        bool isActive;
        uint256 createdAt;
        uint256 expireTime;
        OrderType orderType;
    }

    mapping(address => mapping(uint256 => Listing)) public listings;
    mapping(uint256 => Listing) public orderIdToListings;
    mapping(address => bool) public isTicketContract;
    mapping(address => uint256) public pendingWithdrawals;
    uint96 public platformFeeBps;
    address public feeRecipient;
    uint256 public nextOrderId;

    event NFTListed(
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 indexed orderId,
        address seller,
        uint256 priceWei,
        uint256 timestamp
    );

    event ListingCancelled(
        address indexed nftContract, uint256 indexed tokenId, uint256 indexed orderId, address seller
    );

    event NFTSold(
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 indexed orderId,
        address seller,
        address buyer,
        uint256 priceWei,
        uint256 timestamp
    );

    event ListingPriceUpdated(
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 indexed orderId,
        address seller,
        uint256 newPriceWei,
        uint256 timestamp
    );

    event PlatformFeeUpdated(uint96 newFeeBps, address indexed newFeeRecipient);
    event TicketContractUpdated(address indexed nftContract, bool enabled);
    event ProceedsAccrued(address indexed user, uint256 amount);
    event ProceedsWithdrawn(address indexed user, uint256 amount);
}
