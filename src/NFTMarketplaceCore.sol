// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./NFTMarketplaceData.sol";

contract NFTMarketplaceCore is ReentrancyGuard, NFTMarketplaceData {
    function listNFT(
        address nftContract,
        uint256 tokenId,
        uint256 priceWei,
        uint256 expireDuration
    ) external {
        if (nftContract == address(0))
            revert NFTMarketplace__InvalidNFTContract();
        if (ERC721(nftContract).ownerOf(tokenId) != msg.sender)
            revert NFTMarketplace__NFTNotOwnedBySender();
        if (priceWei <= 0) revert NFTMarketplace__PriceMustBeGreaterThanZero();

        bool isApproved = ERC721(nftContract).getApproved(tokenId) ==
            address(this) ||
            ERC721(nftContract).isApprovedForAll(msg.sender, address(this));
        if (!isApproved) revert NFTMarketplace__NFTNotApprovedForMarket();

        uint256 orderId = nextOrderId;
        uint256 expireTime = block.timestamp + expireDuration;
        OrderType orderType = OrderType.FixedPrice;

        Listing memory newlisting = Listing({
            orderId: orderId,
            seller: msg.sender,
            priceWei: priceWei,
            isActive: true,
            createdAt: block.timestamp,
            expireTime: expireTime,
            orderType: orderType
        });
        listings[nftContract][tokenId] = newlisting;
        orderIdToListings[orderId] = newlisting;
        unchecked {
            nextOrderId++;
        }

        emit NFTListed(
            nftContract,
            tokenId,
            orderId,
            msg.sender,
            priceWei,
            block.timestamp
        );
    }

    function cancelListing(address nftContract, uint256 tokenId) external {
        Listing storage listing = listings[nftContract][tokenId];
        if (!listing.isActive) revert NFTMarketplace__ListingNotActive();
        if (listing.seller != msg.sender)
            revert NFTMarketplace__NotListingSeller();

        listing.isActive = false;
        orderIdToListings[listing.orderId].isActive = false;

        emit ListingCancelled(
            nftContract,
            tokenId,
            listing.orderId,
            msg.sender
        );
    }

    function buyNFT(
        address nftContract,
        uint256 tokenId
    ) external payable nonReentrant {
        Listing storage listing = listings[nftContract][tokenId];
        address seller = listing.seller;
        uint256 priceWei = listing.priceWei;

        if (listing.expireTime < block.timestamp)
            revert NFTMarketplace__ListingExpired();
        if (!listing.isActive) revert NFTMarketplace__ListingNotActive();
        if (msg.value < priceWei)
            revert NFTMarketplace__MoneyIsNotEnoughToBuy();
        if (ERC721(nftContract).ownerOf(tokenId) != seller)
            revert NFTMarketplace__SellerNotNFTOwner();

        listing.isActive = false;
        orderIdToListings[listing.orderId].isActive = false;

        (bool okSeller, ) = payable(seller).call{value: priceWei, gas: 2300}(
            ""
        );
        if (!okSeller) revert NFTMarketplace__SellerTransferFailed();
        if (msg.value > priceWei) {
            (bool okBuyer, ) = payable(msg.sender).call{
                value: msg.value - priceWei,
                gas: 2300
            }("");
            if (!okBuyer) revert NFTMarketplace__BuyerTransferFailed();
        }
        ERC721(nftContract).safeTransferFrom(seller, msg.sender, tokenId);

        emit NFTSold(
            nftContract,
            tokenId,
            listing.orderId,
            seller,
            msg.sender,
            priceWei,
            block.timestamp
        );
    }

    function getListingByOrderId(
        uint256 orderId
    ) external view returns (Listing memory) {
        return orderIdToListings[orderId];
    }

    function getListing(
        address nft,
        uint256 tokenId
    ) external view returns (Listing memory) {
        return listings[nft][tokenId];
    }
}
