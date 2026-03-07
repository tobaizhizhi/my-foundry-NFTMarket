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

    string public constant TEST_URI = "ipfs://bafkreihgcwbsvuucmehs4qqkkl5pbgd4rmytd3jfkrmbejx32ns25vtp5m/0.json";

    function setUp() public {
        marketplace = new NFTMarketplaceCore();
        commonNFT = new CommonNFT();
        ticketNFT = new TicketNFT();

        marketplace.setTicketContract(address(ticketNFT), true);
        vm.deal(buyer, 10 ether);
    }

    function test_ListCommonNFT_Success() public {
        commonNFT.mintCommonNFT(seller, TEST_URI);
        vm.prank(seller);
        commonNFT.approve(address(marketplace), 0);

        vm.prank(seller);
        marketplace.listNFT(address(commonNFT), 0, 0.5 ether, 1 days);

        NFTMarketplaceData.Listing memory listing = marketplace.getListing(address(commonNFT), 0);
        assertEq(listing.seller, seller);
        assertEq(listing.priceWei, 0.5 ether);
        assertTrue(listing.isActive);
    }

    function test_ListTicket_RevertIfUsed() public {
        ticketNFT.mintTicketNFT(seller, TEST_URI, 1, block.timestamp + 1 days, organizer, true, 1 ether);

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
        ticketNFT.mintTicketNFT(seller, TEST_URI, 1, expireTime, organizer, true, 1 ether);

        vm.prank(seller);
        ticketNFT.approve(address(marketplace), 0);

        vm.warp(expireTime + 1);
        vm.prank(seller);
        vm.expectRevert(NFTMarketplace__TicketExpiredForTrade.selector);
        marketplace.listNFT(address(ticketNFT), 0, 0.5 ether, 1 days);
    }

    function test_ListTicket_RevertIfResaleNotAllowed() public {
        ticketNFT.mintTicketNFT(seller, TEST_URI, 1, block.timestamp + 1 days, organizer, false, 1 ether);

        vm.prank(seller);
        ticketNFT.approve(address(marketplace), 0);

        vm.prank(seller);
        vm.expectRevert(NFTMarketplace__TicketResaleNotAllowed.selector);
        marketplace.listNFT(address(ticketNFT), 0, 0.5 ether, 1 days);
    }

    function test_ListTicket_RevertIfPriceExceedsMaxResale() public {
        ticketNFT.mintTicketNFT(seller, TEST_URI, 1, block.timestamp + 1 days, organizer, true, 0.1 ether);

        vm.prank(seller);
        ticketNFT.approve(address(marketplace), 0);

        vm.prank(seller);
        vm.expectRevert(NFTMarketplace__TicketPriceExceedsMaxResale.selector);
        marketplace.listNFT(address(ticketNFT), 0, 0.2 ether, 1 days);
    }

    function test_BuyTicket_RevertIfUsedAfterListing() public {
        ticketNFT.mintTicketNFT(seller, TEST_URI, 1, block.timestamp + 1 days, organizer, true, 1 ether);

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
        ticketNFT.mintTicketNFT(seller, TEST_URI, 1, expireTime, organizer, true, 1 ether);

        vm.prank(seller);
        ticketNFT.approve(address(marketplace), 0);

        vm.prank(seller);
        marketplace.listNFT(address(ticketNFT), 0, 0.5 ether, 1 days);

        vm.warp(expireTime + 1);
        vm.prank(buyer);
        vm.expectRevert(NFTMarketplace__TicketExpiredForTrade.selector);
        marketplace.buyNFT{value: 0.5 ether}(address(ticketNFT), 0);
    }
}
