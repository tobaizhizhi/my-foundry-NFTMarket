// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MyNFT.sol";

contract MintNFT is Script {
    address public constant MY_NFT_ADDRESS = 0x056681Aebe519ed484C4cDaBCD9323F536fe0034;
    address public constant RECIPIENT = 0x6f933fdc96Ee0BDEF306621C739ffdFc846c681a;

    function run() external {
        require(block.chainid == 11155111, "Only run on Sepolia!");
        uint256 deployPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployPrivateKey);
        MyNFT myNFT = MyNFT(MY_NFT_ADDRESS);

        string memory tokenURI0 = "ipfs://bafkreihgcwbsvuucmehs4qqkkl5pbgd4rmytd3jfkrmbejx32ns25vtp5m/0.json";
        myNFT.mint(RECIPIENT, tokenURI0);
        console.log("Mint successful:tokenId=0");

        string[] memory tokenURIs = new string[](2);
        tokenURIs[0] = "ipfs://bafkreigip7xd5mfyyfe2bpd7bsep2uqqvbqw3lb24gabnatmizpsk45kae/1.json";
        tokenURIs[1] = "ipfs://bafkreiflar37xm4k4iq6y3ahpo55cagl3pqr7gulmfkpb3gabjvr6gusb4/2.json";
        myNFT.batchMint(RECIPIENT, 2, tokenURIs);
        console.log("Batch mint successful:tokenId=1,2");

        uint256 nextId = myNFT.nextTokenId();
        console.log("nextTokenId:", nextId); // 应输出3（0+2=3）
        console.log("tokenId=0 URI:", myNFT.tokenURI(0)); // 输出你的IPFS链接

        vm.stopBroadcast();
    }
}
