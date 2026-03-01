// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MyNFT.sol";

contract CallNFTsByOwner is Script {
    address public constant NFT_CONTRACT = 0x056681Aebe519ed484C4cDaBCD9323F536fe0034;

    address public constant YOUR_WALLET = 0x6f933fdc96Ee0BDEF306621C739ffdFc846c681a;

    function run() public view {
        MyNFT nft = MyNFT(NFT_CONTRACT);

        uint256[] memory tokenIds = nft.getNFTsByOwner(YOUR_WALLET);

        console.log("Your NFT IDs:");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            console.log(tokenIds[i]); // 输出 0, 1, 2...
        }
    }
}
