// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MyNFT.sol";

contract MyNFTTest is Test {
    MyNFT public myNFT;
    address public owner = address(1);
    address public alice = address(2);
    address public bob = address(3);
    address public organizer = address(4);
    address public zeroAddr = address(0);

    string public constant TEST_URI1 = "ipfs://bafkreihgcwbsvuucmehs4qqkkl5pbgd4rmytd3jfkrmbejx32ns25vtp5m/0.json";
    string public constant TEST_URI2 = "ipfs://bafkreigip7xd5mfyyfe2bpd7bsep2uqqvbqw3lb24gabnatmizpsk45kae/1.json";
    string public constant TEST_URI3 = "ipfs://bafkreiflar37xm4k4iq6y3ahpo55cagl3pqr7gulmfkpb3gabjvr6gusb4/2.json";
    string public constant TICKET_URI = "ipfs://bafkreigltekelzk2s6dk3j4pur27fvkjns6w3yzxngz7lyfgfrypykekmu/123.json";
    string public constant EMPTY_URI = "";

    uint256 public constant EVENT_ID = 123;
    uint256 public constant TICKET_EXPIRE_TIME = 1712000000;
    uint256 public constant EXPIRED_TIME = 1000000000;
    bool public constant RESALE_ALLOWED = true;
    uint256 public constant MAX_RESALE_PRICE = 1 ether;

    function setUp() public {
        vm.prank(owner);
        myNFT = new MyNFT();
        vm.warp(EXPIRED_TIME + 1);
    }

    function test_Mint_Success() public {
        vm.prank(owner);
        myNFT.mintCommonNFT(alice, TEST_URI1);

        assertEq(myNFT.ownerOf(0), alice);
        assertEq(myNFT.tokenURI(0), TEST_URI1);
        assertEq(myNFT.nextTokenId(), 1);
        assertEq(uint256(myNFT.tokenType(0)), 0);
    }

    function test_Mint_OnlyOwner() public {
        vm.prank(alice);
        vm.expectRevert();
        myNFT.mintCommonNFT(alice, TEST_URI1);
    }

    function test_Mint_InvalidRecipient() public {
        vm.prank(owner);
        vm.expectRevert(MyNFT__InvalidRecipient.selector);
        myNFT.mintCommonNFT(zeroAddr, TEST_URI1);
    }

    function test_Mint_URIEmpty() public {
        vm.prank(owner);
        vm.expectRevert(MyNFT__URIEmpty.selector);
        myNFT.mintCommonNFT(alice, EMPTY_URI);
    }

    function test_BatchMint_Success() public {
        string[] memory uris = new string[](2);
        uris[0] = TEST_URI1;
        uris[1] = TEST_URI2;

        vm.prank(owner);
        myNFT.batchMint(alice, 2, uris);

        assertEq(myNFT.ownerOf(0), alice);
        assertEq(myNFT.ownerOf(1), alice);
        assertEq(myNFT.tokenURI(0), TEST_URI1);
        assertEq(myNFT.tokenURI(1), TEST_URI2);
        assertEq(myNFT.nextTokenId(), 2);
        assertEq(uint256(myNFT.tokenType(0)), 0);
        assertEq(uint256(myNFT.tokenType(1)), 0);
    }

    function test_BatchMint_AmountZero() public {
        string[] memory uris = new string[](2);
        uris[0] = TEST_URI1;
        uris[1] = TEST_URI2;

        vm.prank(owner);
        vm.expectRevert(MyNFT__BatchMintAmountFalse.selector);
        myNFT.batchMint(alice, 0, uris);
    }

    function test_BatchMint_AmountExceededMax() public {
        string[] memory uris = new string[](11);
        uris[0] = TEST_URI1;
        uris[1] = TEST_URI2;

        vm.prank(owner);
        vm.expectRevert(MyNFT__BatchMintAmountFalse.selector);
        myNFT.batchMint(alice, 11, uris);
    }

    function test_BatchMint_InvalidRecipient() public {
        string[] memory uris = new string[](2);
        uris[0] = TEST_URI1;
        uris[1] = TEST_URI2;

        vm.prank(owner);
        vm.expectRevert(MyNFT__InvalidRecipient.selector);
        myNFT.batchMint(zeroAddr, 2, uris);
    }

    function test_BatchMint_URIArrayMisMatch() public {
        string[] memory uris = new string[](2);
        uris[0] = TEST_URI1;
        uris[1] = TEST_URI2;

        vm.prank(owner);
        vm.expectRevert(MyNFT__BatchMintAmountFalse.selector);
        myNFT.batchMint(alice, 1, uris);
    }

    function test_UpdateTokenURI_TokenOwnerSuccess() public {
        vm.prank(owner);
        myNFT.mintCommonNFT(alice, TEST_URI1);

        vm.prank(alice);
        myNFT.updateTokenURI(0, TEST_URI2);

        assertEq(myNFT.tokenURI(0), TEST_URI2);
    }

    function test_UpdateTokenURI_ContractOwnerSuccess() public {
        vm.prank(owner);
        myNFT.mintCommonNFT(alice, TEST_URI1);

        vm.prank(owner);
        myNFT.updateTokenURI(0, TEST_URI2);

        assertEq(myNFT.tokenURI(0), TEST_URI2);
    }

    function test_UpdateTokenURI_UnrelatedUserFail() public {
        vm.prank(owner);
        myNFT.mintCommonNFT(alice, TEST_URI1);

        vm.prank(bob);
        vm.expectRevert(MyNFT__NotTokenOwnerOrContractOwner.selector);
        myNFT.updateTokenURI(0, TEST_URI2);
    }

    function test_UpdateTokenURI_TokenNotExist() public {
        vm.prank(owner);
        myNFT.mintCommonNFT(alice, TEST_URI1);

        vm.prank(owner);
        vm.expectRevert(MyNFT__TokenNotExists.selector);
        myNFT.updateTokenURI(999, TEST_URI2);
    }

    function test_UpdateTokenURI_URIEmpty() public {
        vm.prank(owner);
        myNFT.mintCommonNFT(alice, TEST_URI1);

        vm.prank(owner);
        vm.expectRevert(MyNFT__URIEmpty.selector);
        myNFT.updateTokenURI(0, EMPTY_URI);
    }

    function test_UpdateTicketURI_CommonNFTTypeCantUpdate() public {
        vm.prank(owner);
        myNFT.mintTicketNFT(
            alice, TICKET_URI, EVENT_ID, TICKET_EXPIRE_TIME, organizer, RESALE_ALLOWED, MAX_RESALE_PRICE
        );
        vm.prank(owner);
        vm.expectRevert(MyNFT__CommonNFTTypeCantUpdate.selector);
        myNFT.updateTokenURI(0, TEST_URI1);
    }

    function test_GetNFTsByOwner_Success() public {
        vm.startPrank(owner);
        myNFT.mintCommonNFT(alice, TEST_URI1);
        myNFT.mintCommonNFT(alice, TEST_URI2);
        myNFT.mintCommonNFT(alice, TEST_URI3);
        vm.stopPrank();

        uint256[] memory tokenIds = myNFT.getNFTsByOwner(alice);

        assertEq(tokenIds.length, 3);
        assertEq(tokenIds[0], 0);
        assertEq(tokenIds[1], 1);
        assertEq(tokenIds[2], 2);
    }

    function test_GetNFTsByOwner_NoNFTs() public {
        uint256[] memory tokenIds = myNFT.getNFTsByOwner(bob);
        assertEq(tokenIds.length, 0);
    }

    function test_TokenURI_Success() public {
        vm.prank(owner);
        myNFT.mintCommonNFT(alice, TEST_URI1);

        assertEq(myNFT.tokenURI(0), TEST_URI1);
    }

    function test_TokenURI_TokenNotExists() public {
        vm.expectRevert(MyNFT__TokenNotExists.selector);
        myNFT.tokenURI(999);
    }

    function test_MintTicketNFT_Success() public {
        vm.prank(owner);
        myNFT.mintTicketNFT(
            alice, TICKET_URI, EVENT_ID, TICKET_EXPIRE_TIME, organizer, RESALE_ALLOWED, MAX_RESALE_PRICE
        );

        assertEq(myNFT.ownerOf(0), alice);
        assertEq(myNFT.tokenURI(0), TICKET_URI);
        assertEq(uint256(myNFT.tokenType(0)), 1);
        assertEq(myNFT.nextTokenId(), 1);

        MyNFT.TicketAttributes memory attr = myNFT.getTicketAttributes(0);

        assertEq(attr.eventId, EVENT_ID);
        assertEq(attr.expireTime, TICKET_EXPIRE_TIME);
        assertEq(attr.isUsed, false);
        assertEq(attr.organizer, organizer);
        assertEq(attr.resaleAllowed, RESALE_ALLOWED);
        assertEq(attr.maxResalePrice, MAX_RESALE_PRICE);
    }

    function test_MintTicketNFT_InvalidRecipient() public {
        vm.prank(owner);
        vm.expectRevert(MyNFT__InvalidRecipient.selector);
        myNFT.mintTicketNFT(
            zeroAddr, TICKET_URI, EVENT_ID, TICKET_EXPIRE_TIME, organizer, RESALE_ALLOWED, MAX_RESALE_PRICE
        );
    }

    function test_MintTicketNFT_ExpiredTimeFail() public {
        vm.prank(owner);
        vm.expectRevert(MyNFT__TicketExpired.selector);
        myNFT.mintTicketNFT(alice, TICKET_URI, EVENT_ID, EXPIRED_TIME, organizer, RESALE_ALLOWED, MAX_RESALE_PRICE);
    }

    function test_MintTicketNFT_InvalidOrganizerFail() public {
        vm.prank(owner);
        vm.expectRevert(MyNFT__InvalidRecipient.selector);
        myNFT.mintTicketNFT(alice, TICKET_URI, EVENT_ID, TICKET_EXPIRE_TIME, zeroAddr, RESALE_ALLOWED, MAX_RESALE_PRICE);
    }

    function test_MintTicketNFT_EmptyURIFail() public {
        vm.prank(owner);
        vm.expectRevert(MyNFT__URIEmpty.selector);
        myNFT.mintTicketNFT(alice, EMPTY_URI, EVENT_ID, TICKET_EXPIRE_TIME, organizer, RESALE_ALLOWED, MAX_RESALE_PRICE);
    }

    function test_UseTicketNFT_OrganizerSuccess() public {
        vm.prank(owner);
        myNFT.mintTicketNFT(
            alice, TICKET_URI, EVENT_ID, TICKET_EXPIRE_TIME, organizer, RESALE_ALLOWED, MAX_RESALE_PRICE
        );

        vm.prank(organizer);
        myNFT.useTicket(0);

        MyNFT.TicketAttributes memory attr = myNFT.getTicketAttributes(0);
        assertEq(attr.isUsed, true);
    }

    function test_UseTicketNFT_UnAuthorizedFail() public {
        vm.prank(owner);
        myNFT.mintTicketNFT(
            alice, TICKET_URI, EVENT_ID, TICKET_EXPIRE_TIME, organizer, RESALE_ALLOWED, MAX_RESALE_PRICE
        );
        vm.prank(bob);
        vm.expectRevert(MyNFT__NotOrganizer.selector);
        myNFT.useTicket(0);
    }

    function test_UseTicketNFT_AlreadyUsedFail() public {
        vm.prank(owner);
        myNFT.mintTicketNFT(
            alice, TICKET_URI, EVENT_ID, TICKET_EXPIRE_TIME, organizer, RESALE_ALLOWED, MAX_RESALE_PRICE
        );
        vm.prank(organizer);
        myNFT.useTicket(0);

        vm.prank(organizer);
        vm.expectRevert(MyNFT__TicketAlreadyUsed.selector);
        myNFT.useTicket(0);
    }

    function test_UseTicketNFT_ExpiredFail() public {
        vm.prank(owner);
        myNFT.mintTicketNFT(
            alice, TICKET_URI, EVENT_ID, TICKET_EXPIRE_TIME, organizer, RESALE_ALLOWED, MAX_RESALE_PRICE
        );
        vm.warp(TICKET_EXPIRE_TIME + 1);
        vm.prank(organizer);
        vm.expectRevert(MyNFT__TicketExpired.selector);
        myNFT.useTicket(0);
    }

    function test_UseTicketNFT_InvalidNFTTypeFail() public {
        vm.prank(owner);
        myNFT.mintCommonNFT(alice, TEST_URI1);

        vm.prank(organizer);
        vm.expectRevert(MyNFT__InvalidNFTType.selector);
        myNFT.useTicket(0);
    }

    function test_UseTicketNFT_TokenNotExistsFail() public {
        vm.prank(owner);
        myNFT.mintTicketNFT(
            alice, TICKET_URI, EVENT_ID, TICKET_EXPIRE_TIME, organizer, RESALE_ALLOWED, MAX_RESALE_PRICE
        );
        vm.prank(organizer);
        vm.expectRevert(MyNFT__TokenNotExists.selector);
        myNFT.useTicket(99);
    }
}
