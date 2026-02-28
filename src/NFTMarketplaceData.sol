// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

error NFTMarketplace__InvalidNFTContract();
error NFTMarketplace__NFTNotOwnedBySender();
error NFTMarketplace__PriceMustBeGreaterThanZero();
error NFTMarketplace__NFTNotApprovedForMarket();
error NFTMarketplace__ListingNotActive();
error NFTMarketplace__SellerNotNFTOwner();
error NFTMarketplace__SellerTransferFailed();
error NFTMarketplace__BuyerTransferFailed();
error NFTMarketplace__MoneyIsNotEnoughToBuy();
error NFTMarketplace__NotListingSeller();
error NFTMarketplace__ListingExpired();

contract NFTMarketplaceData {
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
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 indexed orderId,
        address seller
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
}
