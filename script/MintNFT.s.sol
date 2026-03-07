// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/CommonNFT.sol";

contract MintNFT is Script {
    address public constant COMMON_NFT_ADDRESS = 0x056681Aebe519ed484C4cDaBCD9323F536fe0034;
    address public constant RECIPIENT = 0x6f933fdc96Ee0BDEF306621C739ffdFc846c681a;

    function run() external {
        require(block.chainid == 11155111, "Only run on Sepolia!");
        uint256 deployPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployPrivateKey);
        CommonNFT commonNFT = CommonNFT(COMMON_NFT_ADDRESS);

        string memory tokenURI0 = "ipfs://bafkreihgcwbsvuucmehs4qqkkl5pbgd4rmytd3jfkrmbejx32ns25vtp5m/0.json";
        commonNFT.mintCommonNFT(RECIPIENT, tokenURI0);
        console.log("Mint successful:tokenId=0");

        string[] memory tokenURIs = new string[](2);
        tokenURIs[0] = "ipfs://bafkreigip7xd5mfyyfe2bpd7bsep2uqqvbqw3lb24gabnatmizpsk45kae/1.json";
        tokenURIs[1] = "ipfs://bafkreiflar37xm4k4iq6y3ahpo55cagl3pqr7gulmfkpb3gabjvr6gusb4/2.json";
        commonNFT.batchMint(RECIPIENT, 2, tokenURIs);
        console.log("Batch mint successful:tokenId=1,2");

        uint256 nextId = commonNFT.nextTokenId();
        console.log("nextTokenId:", nextId);
        console.log("tokenId=0 URI:", commonNFT.tokenURI(0));

        vm.stopBroadcast();
    }
}
