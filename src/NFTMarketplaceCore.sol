// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./NFTMarketplaceData.sol";
import "./interfaces/ITicketNFT.sol";

contract NFTMarketplaceCore is ReentrancyGuard, Ownable, NFTMarketplaceData {
    constructor() Ownable(msg.sender) {
        feeRecipient = msg.sender;
        platformFeeBps = 0;
    }

    function setPlatformFee(uint96 newFeeBps, address newFeeRecipient) external onlyOwner {
        if (newFeeRecipient == address(0)) {
            revert NFTMarketplace__InvalidFeeRecipient();
        }
        if (newFeeBps > MAX_PLATFORM_FEE_BPS) {
            revert NFTMarketplace__InvalidPlatformFeeBps();
        }

        platformFeeBps = newFeeBps;
        feeRecipient = newFeeRecipient;

        emit PlatformFeeUpdated(newFeeBps, newFeeRecipient);
    }

    function setTicketContract(address nftContract, bool enabled) external onlyOwner {
        if (nftContract == address(0)) {
            revert NFTMarketplace__InvalidNFTContract();
        }

        isTicketContract[nftContract] = enabled;
        emit TicketContractUpdated(nftContract, enabled);
    }

    function listNFT(address nftContract, uint256 tokenId, uint256 priceWei, uint256 expireDuration) external {
        if (nftContract == address(0)) {
            revert NFTMarketplace__InvalidNFTContract();
        }
        if (ERC721(nftContract).ownerOf(tokenId) != msg.sender) {
            revert NFTMarketplace__NFTNotOwnedBySender();
        }
        if (priceWei <= 0) revert NFTMarketplace__PriceMustBeGreaterThanZero();
        Listing storage previousListing = listings[nftContract][tokenId];
        if (previousListing.isActive) {
            if (block.timestamp < previousListing.expireTime) {
                revert NFTMarketplace__AlreadyListed();
            }
            // Keep orderId index consistent when an expired active listing is replaced.
            orderIdToListings[previousListing.orderId].isActive = false;
            previousListing.isActive = false;
        }

        bool isApproved = ERC721(nftContract).getApproved(tokenId) == address(this)
            || ERC721(nftContract).isApprovedForAll(msg.sender, address(this));
        if (!isApproved) revert NFTMarketplace__NFTNotApprovedForMarket();
        if (expireDuration < 1 minutes) {
            revert NFTMarketplace__InvalidExpireDuration();
        }
        _validateTicketTrade(nftContract, tokenId, priceWei);

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

        emit NFTListed(nftContract, tokenId, orderId, msg.sender, priceWei, block.timestamp);
    }

    function cancelListing(address nftContract, uint256 tokenId) external {
        Listing storage listing = listings[nftContract][tokenId];
        if (!listing.isActive) revert NFTMarketplace__ListingNotActive();
        if (listing.seller != msg.sender) {
            revert NFTMarketplace__NotListingSeller();
        }

        listing.isActive = false;
        orderIdToListings[listing.orderId].isActive = false;

        emit ListingCancelled(nftContract, tokenId, listing.orderId, msg.sender);
    }

    function updateListingPrice(address nftContract, uint256 tokenId, uint256 newPriceWei) external {
        NFTMarketplaceData.Listing storage listing = listings[nftContract][tokenId];
        if (!listing.isActive) revert NFTMarketplace__ListingNotActive();
        if (block.timestamp >= listing.expireTime) {
            revert NFTMarketplace__ListingExpired();
        }
        if (listing.seller != msg.sender) {
            revert NFTMarketplace__NotListingSeller();
        }
        if (newPriceWei <= 0) {
            revert NFTMarketplace__PriceMustBeGreaterThanZero();
        }
        _validateTicketTrade(nftContract, tokenId, newPriceWei);

        listing.priceWei = newPriceWei;
        orderIdToListings[listing.orderId].priceWei = newPriceWei;

        emit ListingPriceUpdated(nftContract, tokenId, listing.orderId, msg.sender, newPriceWei, block.timestamp);
    }

    function buyNFT(address nftContract, uint256 tokenId) external payable nonReentrant {
        Listing storage listing = listings[nftContract][tokenId];
        address seller = listing.seller;
        uint256 priceWei = listing.priceWei;

        if (block.timestamp >= listing.expireTime) {
            revert NFTMarketplace__ListingExpired();
        }
        if (!listing.isActive) revert NFTMarketplace__ListingNotActive();
        if (msg.value < priceWei) {
            revert NFTMarketplace__MoneyIsNotEnoughToBuy();
        }
        if (ERC721(nftContract).ownerOf(tokenId) != seller) {
            revert NFTMarketplace__SellerNotNFTOwner();
        }
        _validateTicketTrade(nftContract, tokenId, priceWei);

        listing.isActive = false;
        orderIdToListings[listing.orderId].isActive = false;

        ERC721(nftContract).safeTransferFrom(seller, msg.sender, tokenId);
        uint256 platformFee = (priceWei * platformFeeBps) / FEE_BPS_DENOMINATOR;
        uint256 sellerProceeds = priceWei - platformFee;
        pendingWithdrawals[seller] += sellerProceeds;
        emit ProceedsAccrued(seller, sellerProceeds);

        if (platformFee > 0) {
            pendingWithdrawals[feeRecipient] += platformFee;
            emit ProceedsAccrued(feeRecipient, platformFee);
        }

        if (msg.value > priceWei) {
            uint256 refund = msg.value - priceWei;
            pendingWithdrawals[msg.sender] += refund;
            emit ProceedsAccrued(msg.sender, refund);
        }

        emit NFTSold(nftContract, tokenId, listing.orderId, seller, msg.sender, priceWei, block.timestamp);
    }

    function withdrawProceeds() external nonReentrant {
        uint256 amount = pendingWithdrawals[msg.sender];
        if (amount == 0) revert NFTMarketplace__NoProceedsToWithdraw();

        pendingWithdrawals[msg.sender] = 0;
        (bool ok,) = payable(msg.sender).call{value: amount}("");
        if (!ok) revert NFTMarketplace__WithdrawTransferFailed();

        emit ProceedsWithdrawn(msg.sender, amount);
    }

    function getListingByOrderId(uint256 orderId) external view returns (Listing memory) {
        return orderIdToListings[orderId];
    }

    function getListing(address nft, uint256 tokenId) external view returns (Listing memory) {
        return listings[nft][tokenId];
    }

    function getActiveListingsByNFTContract(address nftContract) external view returns (Listing[] memory) {
        //TODO: 改为链下
    }

    function getListingsBySeller(address seller) external view returns (Listing[] memory) {
        //TODO改为链下
    }

    function _validateTicketTrade(address nftContract, uint256 tokenId, uint256 priceWei) internal view {
        if (!isTicketContract[nftContract]) {
            return;
        }

        (, uint256 expireTime, bool isUsed,, bool resaleAllowed, uint256 maxResalePrice) =
            ITicketNFT(nftContract).ticketAttributes(tokenId);

        if (isUsed) revert NFTMarketplace__TicketAlreadyUsed();
        if (block.timestamp >= expireTime) {
            revert NFTMarketplace__TicketExpiredForTrade();
        }
        if (!resaleAllowed) revert NFTMarketplace__TicketResaleNotAllowed();
        if (priceWei > maxResalePrice) {
            revert NFTMarketplace__TicketPriceExceedsMaxResale();
        }
    }
}
