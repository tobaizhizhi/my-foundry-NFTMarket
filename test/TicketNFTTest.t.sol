// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/TicketNFT.sol";

contract TicketNFTTest is Test {
    TicketNFT public ticketNFT;
    address public owner = address(1);
    address public alice = address(2);
    address public bob = address(3);
    address public organizer = address(4);
    address public zeroAddr = address(0);

    string public constant TICKET_URI = "ipfs://bafkreigltekelzk2s6dk3j4pur27fvkjns6w3yzxngz7lyfgfrypykekmu/123.json";
    string public constant EMPTY_URI = "";

    uint256 public constant EVENT_ID = 123;
    uint256 public constant TICKET_EXPIRE_TIME = 1712000000;
    uint256 public constant EXPIRED_TIME = 1000000000;
    bool public constant RESALE_ALLOWED = true;
    uint256 public constant MAX_RESALE_PRICE = 1 ether;

    function setUp() public {
        vm.prank(owner);
        ticketNFT = new TicketNFT();
        vm.warp(EXPIRED_TIME + 1);
    }

    function test_MintTicketNFT_Success() public {
        vm.prank(owner);
        ticketNFT.mintTicketNFT(
            alice, TICKET_URI, EVENT_ID, TICKET_EXPIRE_TIME, organizer, RESALE_ALLOWED, MAX_RESALE_PRICE
        );

        assertEq(ticketNFT.ownerOf(0), alice);
        assertEq(ticketNFT.tokenURI(0), TICKET_URI);
        assertEq(ticketNFT.nextTokenId(), 1);

        TicketNFT.TicketAttributes memory attr = ticketNFT.getTicketAttributes(0);
        assertEq(attr.eventId, EVENT_ID);
        assertEq(attr.expireTime, TICKET_EXPIRE_TIME);
        assertEq(attr.isUsed, false);
        assertEq(attr.organizer, organizer);
        assertEq(attr.resaleAllowed, RESALE_ALLOWED);
        assertEq(attr.maxResalePrice, MAX_RESALE_PRICE);
    }

    function test_MintTicketNFT_InvalidRecipient() public {
        vm.prank(owner);
        vm.expectRevert(TicketNFT__InvalidRecipient.selector);
        ticketNFT.mintTicketNFT(
            zeroAddr, TICKET_URI, EVENT_ID, TICKET_EXPIRE_TIME, organizer, RESALE_ALLOWED, MAX_RESALE_PRICE
        );
    }

    function test_MintTicketNFT_ExpiredTimeFail() public {
        vm.prank(owner);
        vm.expectRevert(TicketNFT__TicketExpired.selector);
        ticketNFT.mintTicketNFT(alice, TICKET_URI, EVENT_ID, EXPIRED_TIME, organizer, RESALE_ALLOWED, MAX_RESALE_PRICE);
    }

    function test_MintTicketNFT_InvalidOrganizerFail() public {
        vm.prank(owner);
        vm.expectRevert(TicketNFT__InvalidRecipient.selector);
        ticketNFT.mintTicketNFT(
            alice, TICKET_URI, EVENT_ID, TICKET_EXPIRE_TIME, zeroAddr, RESALE_ALLOWED, MAX_RESALE_PRICE
        );
    }

    function test_MintTicketNFT_EmptyURIFail() public {
        vm.prank(owner);
        vm.expectRevert(TicketNFT__URIEmpty.selector);
        ticketNFT.mintTicketNFT(
            alice, EMPTY_URI, EVENT_ID, TICKET_EXPIRE_TIME, organizer, RESALE_ALLOWED, MAX_RESALE_PRICE
        );
    }

    function test_UseTicketNFT_OrganizerSuccess() public {
        vm.prank(owner);
        ticketNFT.mintTicketNFT(
            alice, TICKET_URI, EVENT_ID, TICKET_EXPIRE_TIME, organizer, RESALE_ALLOWED, MAX_RESALE_PRICE
        );

        vm.prank(organizer);
        ticketNFT.useTicket(0);

        TicketNFT.TicketAttributes memory attr = ticketNFT.getTicketAttributes(0);
        assertEq(attr.isUsed, true);
    }

    function test_UseTicketNFT_ContractOwnerSuccess() public {
        vm.prank(owner);
        ticketNFT.mintTicketNFT(
            alice, TICKET_URI, EVENT_ID, TICKET_EXPIRE_TIME, organizer, RESALE_ALLOWED, MAX_RESALE_PRICE
        );

        vm.prank(owner);
        ticketNFT.useTicket(0);

        TicketNFT.TicketAttributes memory attr = ticketNFT.getTicketAttributes(0);
        assertEq(attr.isUsed, true);
    }

    function test_UseTicketNFT_UnAuthorizedFail() public {
        vm.prank(owner);
        ticketNFT.mintTicketNFT(
            alice, TICKET_URI, EVENT_ID, TICKET_EXPIRE_TIME, organizer, RESALE_ALLOWED, MAX_RESALE_PRICE
        );

        vm.prank(bob);
        vm.expectRevert(TicketNFT__NotOrganizer.selector);
        ticketNFT.useTicket(0);
    }

    function test_UseTicketNFT_AlreadyUsedFail() public {
        vm.prank(owner);
        ticketNFT.mintTicketNFT(
            alice, TICKET_URI, EVENT_ID, TICKET_EXPIRE_TIME, organizer, RESALE_ALLOWED, MAX_RESALE_PRICE
        );

        vm.prank(organizer);
        ticketNFT.useTicket(0);

        vm.prank(organizer);
        vm.expectRevert(TicketNFT__TicketAlreadyUsed.selector);
        ticketNFT.useTicket(0);
    }

    function test_UseTicketNFT_ExpiredFail() public {
        vm.prank(owner);
        ticketNFT.mintTicketNFT(
            alice, TICKET_URI, EVENT_ID, TICKET_EXPIRE_TIME, organizer, RESALE_ALLOWED, MAX_RESALE_PRICE
        );

        vm.warp(TICKET_EXPIRE_TIME + 1);
        vm.prank(organizer);
        vm.expectRevert(TicketNFT__TicketExpired.selector);
        ticketNFT.useTicket(0);
    }

    function test_UseTicketNFT_TokenNotExistsFail() public {
        vm.prank(organizer);
        vm.expectRevert(TicketNFT__TokenNotExists.selector);
        ticketNFT.useTicket(99);
    }

    function test_GetTicketAttributes_TokenNotExistsFail() public {
        vm.expectRevert(TicketNFT__TokenNotExists.selector);
        ticketNFT.getTicketAttributes(999);
    }

    function test_TokenURI_TokenNotExists() public {
        vm.expectRevert(TicketNFT__TokenNotExists.selector);
        ticketNFT.tokenURI(999);
    }

    function test_GetNFTsByOwner_Success() public {
        vm.startPrank(owner);
        ticketNFT.mintTicketNFT(
            alice, TICKET_URI, EVENT_ID, TICKET_EXPIRE_TIME, organizer, RESALE_ALLOWED, MAX_RESALE_PRICE
        );
        ticketNFT.mintTicketNFT(
            alice, TICKET_URI, EVENT_ID + 1, TICKET_EXPIRE_TIME, organizer, RESALE_ALLOWED, MAX_RESALE_PRICE
        );
        vm.stopPrank();

        uint256[] memory tokenIds = ticketNFT.getNFTsByOwner(alice);
        assertEq(tokenIds.length, 2);
        assertEq(tokenIds[0], 0);
        assertEq(tokenIds[1], 1);
    }

    function test_GetNFTsByOwner_NoNFTs() public {
        uint256[] memory tokenIds = ticketNFT.getNFTsByOwner(bob);
        assertEq(tokenIds.length, 0);
    }
}
