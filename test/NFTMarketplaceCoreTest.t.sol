// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/NFTMarketplaceCore.sol";
import "../src/CommonNFT.sol";
import "../src/TicketNFT.sol";
import "../src/NFTMarketplaceData.sol";

contract NFTMarketplaceCoreTest is Test {
    NFTMarketplaceCore public marketplace;
    CommonNFT public commonNFT;
    TicketNFT public ticketNFT;

    address public seller = address(1);
    address public buyer = address(2);
    address public organizer = address(3);
    address public outsider = address(4);
    address public zeroAddr = address(0);

    string public constant TEST_URI =
        "ipfs://bafkreihgcwbsvuucmehs4qqkkl5pbgd4rmytd3jfkrmbejx32ns25vtp5m/0.json";

    function setUp() public {
        marketplace = new NFTMarketplaceCore();
        commonNFT = new CommonNFT();
        ticketNFT = new TicketNFT();

        marketplace.setTicketContract(address(ticketNFT), true);
        vm.deal(buyer, 10 ether);
    }

    function test_SetTicketContract_Success() public {
        marketplace.setTicketContract(address(ticketNFT), true);
        bool result = marketplace.isTicketContract(address(ticketNFT));
        assertEq(result, true);
    }

    function test_SetTicketContract_InvalidNFTContract() public {
        vm.expectRevert(NFTMarketplace__InvalidNFTContract.selector);
        marketplace.setTicketContract(zeroAddr, true);
    }

    function test_ListCommonNFT_Success() public {
        commonNFT.mintCommonNFT(seller, TEST_URI);
        vm.prank(seller);
        commonNFT.approve(address(marketplace), 0);

        vm.prank(seller);
        marketplace.listNFT(address(commonNFT), 0, 0.5 ether, 1 days);

        NFTMarketplaceData.Listing memory listing = marketplace.getListing(
            address(commonNFT),
            0
        );
        assertEq(listing.seller, seller);
        assertEq(listing.priceWei, 0.5 ether);
        assertTrue(listing.isActive);
    }

    function test_ListTicketNFT_Success() public {
        ticketNFT.mintTicketNFT(
            seller,
            TEST_URI,
            1,
            block.timestamp + 1 days,
            organizer,
            true,
            1 ether
        );

        vm.prank(seller);
        ticketNFT.approve(address(marketplace), 0);

        vm.prank(seller);
        marketplace.listNFT(address(ticketNFT), 0, 0.5 ether, 1 days);

        NFTMarketplaceData.Listing memory listing = marketplace.getListing(
            address(ticketNFT),
            0
        );
        NFTMarketplaceData.Listing memory orderListing = marketplace
            .getListingByOrderId(0);

        assertEq(listing.orderId, 0);
        assertEq(listing.seller, seller);
        assertEq(listing.priceWei, 0.5 ether);
        assertTrue(listing.isActive);
        assertTrue(listing.expireTime > listing.createdAt);

        assertEq(orderListing.orderId, listing.orderId);
        assertEq(orderListing.seller, listing.seller);
        assertEq(orderListing.priceWei, listing.priceWei);
        assertEq(orderListing.isActive, listing.isActive);
    }

    function test_ListNFT_RevertIfExpireDurationTooShort() public {
        commonNFT.mintCommonNFT(seller, TEST_URI);

        vm.prank(seller);
        commonNFT.approve(address(marketplace), 0);

        vm.prank(seller);
        vm.expectRevert(NFTMarketplace__InvalidExpireDuration.selector);

        marketplace.listNFT(address(commonNFT), 0, 0.5 ether, 30);
    }

    function test_ListNFT_RevertIfCallerNotTokenOwner() public {
        commonNFT.mintCommonNFT(seller, TEST_URI);

        vm.prank(outsider);
        vm.expectRevert(NFTMarketplace__NFTNotOwnedBySender.selector);
        marketplace.listNFT(address(commonNFT), 0, 0.5 ether, 1 days);
    }

    function test_ListNFT_RevertIfNotApprovedForMarket() public {
        commonNFT.mintCommonNFT(seller, TEST_URI);

        vm.prank(seller);
        vm.expectRevert(NFTMarketplace__NFTNotApprovedForMarket.selector);
        marketplace.listNFT(address(commonNFT), 0, 0.5 ether, 1 days);
    }

    function test_ListTicket_RevertIfUsed() public {
        ticketNFT.mintTicketNFT(
            seller,
            TEST_URI,
            1,
            block.timestamp + 1 days,
            organizer,
            true,
            1 ether
        );

        vm.prank(organizer);
        ticketNFT.useTicket(0);

        vm.prank(seller);
        ticketNFT.approve(address(marketplace), 0);

        vm.prank(seller);
        vm.expectRevert(NFTMarketplace__TicketAlreadyUsed.selector);
        marketplace.listNFT(address(ticketNFT), 0, 0.5 ether, 1 days);
    }

    function test_ListTicket_RevertIfExpired() public {
        uint256 expireTime = block.timestamp + 1 hours;
        ticketNFT.mintTicketNFT(
            seller,
            TEST_URI,
            1,
            expireTime,
            organizer,
            true,
            1 ether
        );

        vm.prank(seller);
        ticketNFT.approve(address(marketplace), 0);

        vm.warp(expireTime + 1);
        vm.prank(seller);
        vm.expectRevert(NFTMarketplace__TicketExpiredForTrade.selector);
        marketplace.listNFT(address(ticketNFT), 0, 0.5 ether, 1 days);
    }

    function test_ListTicket_RevertIfResaleNotAllowed() public {
        ticketNFT.mintTicketNFT(
            seller,
            TEST_URI,
            1,
            block.timestamp + 1 days,
            organizer,
            false,
            1 ether
        );

        vm.prank(seller);
        ticketNFT.approve(address(marketplace), 0);

        vm.prank(seller);
        vm.expectRevert(NFTMarketplace__TicketResaleNotAllowed.selector);
        marketplace.listNFT(address(ticketNFT), 0, 0.5 ether, 1 days);
    }

    function test_ListTicket_RevertIfPriceExceedsMaxResale() public {
        ticketNFT.mintTicketNFT(
            seller,
            TEST_URI,
            1,
            block.timestamp + 1 days,
            organizer,
            true,
            0.1 ether
        );

        vm.prank(seller);
        ticketNFT.approve(address(marketplace), 0);

        vm.prank(seller);
        vm.expectRevert(NFTMarketplace__TicketPriceExceedsMaxResale.selector);
        marketplace.listNFT(address(ticketNFT), 0, 0.2 ether, 1 days);
    }

    function test_BuyCommonNFT_Success() public {
        commonNFT.mintCommonNFT(seller, TEST_URI);
        vm.prank(seller);
        commonNFT.approve(address(marketplace), 0);
        vm.prank(seller);
        marketplace.listNFT(address(commonNFT), 0, 0.5 ether, 1 days);

        uint256 sellerBalanceBefore = seller.balance;

        vm.prank(buyer);
        marketplace.buyNFT{value: 0.5 ether}(address(commonNFT), 0);

        assertEq(commonNFT.ownerOf(0), buyer);
        assertEq(seller.balance, sellerBalanceBefore + 0.5 ether);
    }

    function test_BuyTicket_Success() public {
        ticketNFT.mintTicketNFT(
            seller,
            TEST_URI,
            1,
            block.timestamp + 1 days,
            organizer,
            true,
            1 ether
        );

        vm.prank(seller);
        ticketNFT.approve(address(marketplace), 0);

        vm.prank(seller);
        marketplace.listNFT(address(ticketNFT), 0, 0.5 ether, 1 days);

        uint256 sellerBalanceBefore = seller.balance;

        vm.prank(buyer);
        marketplace.buyNFT{value: 0.5 ether}(address(ticketNFT), 0);

        assertEq(ticketNFT.ownerOf(0), buyer);
        assertEq(seller.balance, sellerBalanceBefore + 0.5 ether);
    }

    function test_BuyNFT_RevertIfNotEnoughETH() public {
        commonNFT.mintCommonNFT(seller, TEST_URI);

        vm.prank(seller);
        commonNFT.approve(address(marketplace), 0);

        vm.prank(seller);
        marketplace.listNFT(address(commonNFT), 0, 1 ether, 1 days);

        vm.prank(buyer);

        vm.expectRevert(NFTMarketplace__MoneyIsNotEnoughToBuy.selector);

        marketplace.buyNFT{value: 0.5 ether}(address(commonNFT), 0);
    }

    function test_BuyNFT_RevertIfListingExpired() public {
        commonNFT.mintCommonNFT(seller, TEST_URI);
        vm.prank(seller);
        commonNFT.approve(address(marketplace), 0);
        vm.prank(seller);
        marketplace.listNFT(address(commonNFT), 0, 0.5 ether, 1 days);

        vm.warp(block.timestamp + 1 days + 1);
        vm.prank(buyer);
        vm.expectRevert(NFTMarketplace__ListingExpired.selector);
        marketplace.buyNFT{value: 0.5 ether}(address(commonNFT), 0);
    }

    function test_BuyNFT_RevertIfSellerNotNFTOwner() public {
        commonNFT.mintCommonNFT(seller, TEST_URI);
        vm.prank(seller);
        commonNFT.approve(address(marketplace), 0);
        vm.prank(seller);
        marketplace.listNFT(address(commonNFT), 0, 0.5 ether, 1 days);

        vm.prank(seller);
        commonNFT.safeTransferFrom(seller, organizer, 0);

        vm.prank(buyer);
        vm.expectRevert(NFTMarketplace__SellerNotNFTOwner.selector);
        marketplace.buyNFT{value: 0.5 ether}(address(commonNFT), 0);
    }

    function test_BuyTicket_RevertIfUsedAfterListing() public {
        ticketNFT.mintTicketNFT(
            seller,
            TEST_URI,
            1,
            block.timestamp + 1 days,
            organizer,
            true,
            1 ether
        );

        vm.prank(seller);
        ticketNFT.approve(address(marketplace), 0);

        vm.prank(seller);
        marketplace.listNFT(address(ticketNFT), 0, 0.5 ether, 1 days);

        vm.prank(organizer);
        ticketNFT.useTicket(0);

        vm.prank(buyer);
        vm.expectRevert(NFTMarketplace__TicketAlreadyUsed.selector);
        marketplace.buyNFT{value: 0.5 ether}(address(ticketNFT), 0);
    }

    function test_BuyTicket_RevertIfExpiredAfterListing() public {
        uint256 expireTime = block.timestamp + 1 hours;
        ticketNFT.mintTicketNFT(
            seller,
            TEST_URI,
            1,
            expireTime,
            organizer,
            true,
            1 ether
        );

        vm.prank(seller);
        ticketNFT.approve(address(marketplace), 0);

        vm.prank(seller);
        marketplace.listNFT(address(ticketNFT), 0, 0.5 ether, 1 days);

        vm.warp(expireTime + 1);
        vm.prank(buyer);
        vm.expectRevert(NFTMarketplace__TicketExpiredForTrade.selector);
        marketplace.buyNFT{value: 0.5 ether}(address(ticketNFT), 0);
    }

    function test_CancelListing() public {
        commonNFT.mintCommonNFT(seller, TEST_URI);

        vm.prank(seller);
        commonNFT.approve(address(marketplace), 0);

        vm.prank(seller);
        marketplace.listNFT(address(commonNFT), 0, 0.5 ether, 1 days);

        vm.prank(seller);
        marketplace.cancelListing(address(commonNFT), 0);

        NFTMarketplaceData.Listing memory listing = marketplace.getListing(
            address(commonNFT),
            0
        );

        assertEq(listing.isActive, false);
    }

    function test_CancelListing_RevertIfNotSeller() public {
        commonNFT.mintCommonNFT(seller, TEST_URI);

        vm.prank(seller);
        commonNFT.approve(address(marketplace), 0);

        vm.prank(seller);
        marketplace.listNFT(address(commonNFT), 0, 0.5 ether, 1 days);

        vm.prank(outsider);
        vm.expectRevert(NFTMarketplace__NotListingSeller.selector);
        marketplace.cancelListing(address(commonNFT), 0);
    }
}
