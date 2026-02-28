// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

error MyNFT__InvalidRecipient();
error MyNFT__BatchMintAmountFalse();

contract MyNFT is ERC721, Ownable,ERC721URIStorage {
    uint256 public nextTokenId;
    uint256 public constant MAX_BATCH_MINT = 10;

    event NFTMinted(address indexed to,uint256 indexed tokenId,string tokenURI);
    event BatchNFTMinted(address indexed to, uint256 indexed startTokenId, uint256 amount);

    constructor() ERC721("MyNFT", "MNFT") Ownable(msg.sender) {}

    // ✅ Mint NFT 给指定地址
    function mint(address to , string calldata tokenURI) external onlyOwner {
        // TODO: mint NFT
        if(to==address(0)) revert MyNFT__InvalidRecipient();

        uint256 tokenId = nextTokenId;
        _safeMint(to,tokenId);
        _setTokenURI(tokenId,tokenURI);

        emit NFTMinted(to,tokenId,tokenURI);

        unchecked{
            nextTokenId += 1;
        }
        
    }
    function batchMint(address to,uint256 amount,string[] calldata tokenURIs)external onlyOwner{
        if(to==address(0)) revert MyNFT__InvalidRecipient();
        if(amount==0||amount>MAX_BATCH_MINT) revert MyNFT__BatchMintAmountFalse();
        if(tokenURIs.length != amount) revert MyNFT__BatchMintAmountFalse();

        uint256 startTokenId = nextTokenId;

        for(uint256 i=0;i<amount;){
             uint256 tokenId = startTokenId + i;
            _safeMint(to,tokenId);
            _setTokenURI(tokenId,tokenURIs[i]);

            emit NFTMinted(to,tokenId,tokenURIs[i]);

            unchecked{
                i++;
            }
        }

        emit BatchNFTMinted(to,startTokenId,amount);
        nextTokenId = startTokenId + amount;
    }

    // ✅ NFT 转移逻辑直接用 ERC721 提供的 safeTransferFrom

    function tokenURI(uint256 tokenId)public view override(ERC721,ERC721URIStorage) returns(string memory){
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)public view override(ERC721,ERC721URIStorage) returns(bool){
        return super.supportsInterface(interfaceId);
    }
}