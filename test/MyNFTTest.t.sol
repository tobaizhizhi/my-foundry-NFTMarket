// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MyNFT.sol";

contract MyNFTTest is Test {
    MyNFT public myNFT;
    address public owner = address(1);
    address public alice = address(2);
    address public bob = address(3);
    address public zeroAddr = address(0);

    string public constant TEST_URI1 =
        "ipfs://bafkreihgcwbsvuucmehs4qqkkl5pbgd4rmytd3jfkrmbejx32ns25vtp5m/0.json";
    string public constant TEST_URI2 =
        "ipfs://bafkreigip7xd5mfyyfe2bpd7bsep2uqqvbqw3lb24gabnatmizpsk45kae/1.json";
    string public constant TEST_URI3 =
        "ipfs://bafkreiflar37xm4k4iq6y3ahpo55cagl3pqr7gulmfkpb3gabjvr6gusb4/2.json";
    string public constant EMPTY_URI = "";

    function setUp() public {
        vm.prank(owner);
        myNFT = new MyNFT();
    }

    function test_Mint_Success() public {
        vm.prank(owner);
        myNFT.mint(alice, TEST_URI1);

        assertEq(myNFT.ownerOf(0), alice);
        assertEq(myNFT.tokenURI(0), TEST_URI1);
        assertEq(myNFT.nextTokenId(), 1);
    }

    function test_Mint_OnlyOwner() public {
        vm.prank(alice);
        vm.expectRevert();
        myNFT.mint(alice, TEST_URI1);
    }

    function test_Mint_InvalidRecipient() public {
        vm.prank(owner);
        vm.expectRevert(MyNFT__InvalidRecipient.selector);
        myNFT.mint(zeroAddr, TEST_URI1);
    }

    function test_Mint_URIEmpty() public {
        vm.prank(owner);
        vm.expectRevert(MyNFT__URIEmpty.selector);
        myNFT.mint(alice, EMPTY_URI);
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
        myNFT.mint(alice, TEST_URI1);

        vm.prank(alice);
        myNFT.updateTokenURI(0, TEST_URI2);

        assertEq(myNFT.tokenURI(0), TEST_URI2);
    }

    function test_UpdateTokenURI_ContractOwnerSuccess() public {
        vm.prank(owner);
        myNFT.mint(alice, TEST_URI1);

        vm.prank(owner);
        myNFT.updateTokenURI(0, TEST_URI2);

        assertEq(myNFT.tokenURI(0), TEST_URI2);
    }

    function test_UpdateTokenURI_UnrelatedUserFail() public {
        vm.prank(owner);
        myNFT.mint(alice, TEST_URI1);

        vm.prank(bob);
        vm.expectRevert(MyNFT__NotTokenOwnerOrContractOwner.selector);
        myNFT.updateTokenURI(0, TEST_URI2);
    }

    function test_UpdateTokenURI_TokenNotExist() public {
        vm.prank(owner);
        myNFT.mint(alice, TEST_URI1);

        vm.prank(owner);
        vm.expectRevert(MyNFT__TokenNotExists.selector);
        myNFT.updateTokenURI(999, TEST_URI2);
    }

    function test_UpdateTokenURI_URIEmpty() public {
        vm.prank(owner);
        myNFT.mint(alice, TEST_URI1);

        vm.prank(owner);
        vm.expectRevert(MyNFT__URIEmpty.selector);
        myNFT.updateTokenURI(0, EMPTY_URI);
    }

    function test_GetNFTsByOwner_Success() public {
        vm.startPrank(owner);
        myNFT.mint(alice, TEST_URI1);
        myNFT.mint(alice, TEST_URI2);
        myNFT.mint(alice, TEST_URI3);
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
        myNFT.mint(alice, TEST_URI1);

        assertEq(myNFT.tokenURI(0), TEST_URI1);
    }

    function test_TokenURI_TokenNotExists() public {
        vm.expectRevert(MyNFT__TokenNotExists.selector);
        myNFT.tokenURI(999);
    }
}
