// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MyNFT.sol";

contract DeployMyNFT is Script {
    function run() external {
        uint256 deployPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployPrivateKey);
        MyNFT myNFT = new MyNFT();
        vm.stopBroadcast();

        console.log("MyNFT contract address: ", address(myNFT));
    }
}
