// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

error MyNFT__InvalidRecipient();
error MyNFT__BatchMintAmountFalse();
error MyNFT__TokenNotExists();
error MyNFT__URIEmpty();
error MyNFT__NotTokenOwnerOrContractOwner();

contract MyNFT is ERC721, Ownable, ERC721Enumerable {
    mapping(uint256 => string) private _tokenURIs;

    uint256 public nextTokenId;
    uint256 public constant MAX_BATCH_MINT = 10;

    event NFTMinted(
        address indexed to,
        uint256 indexed tokenId,
        string tokenURI
    );
    event BatchNFTMinted(
        address indexed to,
        uint256 indexed startTokenId,
        uint256 amount
    );
    event TokenURIUpdate(uint256 indexed tokenId, string newURI);

    constructor() ERC721("MyNFT", "MNFT") Ownable(msg.sender) {}

    function mint(address to, string calldata tokenURI) external onlyOwner {
        if (to == address(0)) revert MyNFT__InvalidRecipient();
        if (bytes(tokenURI).length == 0) revert MyNFT__URIEmpty();

        uint256 tokenId = nextTokenId;
        _safeMint(to, tokenId);
        _tokenURIs[tokenId] = tokenURI;

        emit NFTMinted(to, tokenId, tokenURI);

        unchecked {
            nextTokenId += 1;
        }
    }

    function batchMint(
        address to,
        uint256 amount,
        string[] calldata tokenURIs
    ) external onlyOwner {
        if (to == address(0)) revert MyNFT__InvalidRecipient();
        if (amount == 0 || amount > MAX_BATCH_MINT)
            revert MyNFT__BatchMintAmountFalse();
        if (tokenURIs.length != amount) revert MyNFT__BatchMintAmountFalse();

        uint256 startTokenId = nextTokenId;

        for (uint256 i = 0; i < amount; ) {
            uint256 tokenId = startTokenId + i;
            if (bytes(tokenURIs[i]).length == 0) revert MyNFT__URIEmpty();
            _safeMint(to, tokenId);
            _tokenURIs[tokenId] = tokenURIs[i];
            emit NFTMinted(to, tokenId, tokenURIs[i]);

            unchecked {
                i++;
            }
        }

        emit BatchNFTMinted(to, startTokenId, amount);
        unchecked {
            nextTokenId = startTokenId + amount;
        }
    }

    function updateTokenURI(uint256 tokenId, string calldata newURI) external {
        try this.ownerOf(tokenId) {} catch {
            revert MyNFT__TokenNotExists();
        }
        if (bytes(newURI).length == 0) revert MyNFT__URIEmpty();
        if (ownerOf(tokenId) != msg.sender && msg.sender != owner())
            revert MyNFT__NotTokenOwnerOrContractOwner();

        _tokenURIs[tokenId] = newURI;

        emit TokenURIUpdate(tokenId, newURI);
    }

    function getNFTsByOwner(
        address owner
    ) external view returns (uint256[] memory) {
        uint256 balance = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](balance);

        for (uint256 i = 0; i < balance; ) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
            unchecked {
                i++;
            }
        }

        return tokenIds;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721) returns (string memory) {
        try this.ownerOf(tokenId) {
            return _tokenURIs[tokenId];
        } catch {
            revert MyNFT__TokenNotExists();
        }
    }

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(
        address account,
        uint128 value
    ) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
