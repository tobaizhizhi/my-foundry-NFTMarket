// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

error CommonNFT__InvalidRecipient();
error CommonNFT__BatchMintAmountFalse();
error CommonNFT__TokenNotExists();
error CommonNFT__URIEmpty();
error CommonNFT__NotTokenOwnerOrContractOwner();

contract CommonNFT is ERC721, Ownable, ERC721Enumerable, ReentrancyGuard {
    mapping(uint256 => string) private _tokenURIs;

    uint256 public nextTokenId;
    uint256 public constant MAX_BATCH_MINT = 10;

    event NFTMinted(address indexed to, uint256 indexed tokenId, string tokenURI);
    event BatchNFTMinted(address indexed to, uint256 indexed startTokenId, uint256 amount);
    event TokenURIUpdated(uint256 indexed tokenId, string newURI);

    constructor() ERC721("CommonNFT", "CNFT") Ownable(msg.sender) {}

    function mintCommonNFT(address to, string calldata tokenUri) external onlyOwner nonReentrant {
        if (to == address(0)) revert CommonNFT__InvalidRecipient();
        if (bytes(tokenUri).length == 0) revert CommonNFT__URIEmpty();

        uint256 tokenId = nextTokenId;
        _safeMint(to, tokenId);
        _tokenURIs[tokenId] = tokenUri;

        emit NFTMinted(to, tokenId, tokenUri);

        unchecked {
            nextTokenId += 1;
        }
    }

    function batchMint(address to, uint256 amount, string[] calldata tokenURIs) external onlyOwner nonReentrant {
        if (to == address(0)) revert CommonNFT__InvalidRecipient();
        if (amount == 0 || amount > MAX_BATCH_MINT) revert CommonNFT__BatchMintAmountFalse();
        if (tokenURIs.length != amount) revert CommonNFT__BatchMintAmountFalse();

        uint256 startTokenId = nextTokenId;

        for (uint256 i = 0; i < amount;) {
            uint256 tokenId = startTokenId + i;
            if (bytes(tokenURIs[i]).length == 0) revert CommonNFT__URIEmpty();

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
        _requireTokenExists(tokenId);
        if (bytes(newURI).length == 0) revert CommonNFT__URIEmpty();
        if (ownerOf(tokenId) != msg.sender && msg.sender != owner()) {
            revert CommonNFT__NotTokenOwnerOrContractOwner();
        }

        _tokenURIs[tokenId] = newURI;
        emit TokenURIUpdated(tokenId, newURI);
    }

    function getNFTsByOwner(address ownerAddress) external view returns (uint256[] memory) {
        uint256 balance = balanceOf(ownerAddress);
        uint256[] memory tokenIds = new uint256[](balance);

        for (uint256 i = 0; i < balance;) {
            tokenIds[i] = tokenOfOwnerByIndex(ownerAddress, i);
            unchecked {
                i++;
            }
        }

        return tokenIds;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireTokenExists(tokenId);
        return _tokenURIs[tokenId];
    }

    function _requireTokenExists(uint256 tokenId) private view {
        if (_ownerOf(tokenId) == address(0)) revert CommonNFT__TokenNotExists();
    }

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
