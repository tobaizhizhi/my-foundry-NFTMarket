// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/CommonNFT.sol";
import "../src/TicketNFT.sol";

contract DeployMyNFT is Script {
    function run() external {
        require(block.chainid == 11155111, "Only deploy to Sepolia Testnet!");

        uint256 deployPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployPrivateKey);
        CommonNFT commonNFT = new CommonNFT();
        TicketNFT ticketNFT = new TicketNFT();
        vm.stopBroadcast();

        console.log("CommonNFT contract address: ", address(commonNFT));
        console.log("TicketNFT contract address: ", address(ticketNFT));
    }
}
