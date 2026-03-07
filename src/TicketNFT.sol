// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

error TicketNFT__InvalidRecipient();
error TicketNFT__TokenNotExists();
error TicketNFT__URIEmpty();
error TicketNFT__TicketExpired();
error TicketNFT__TicketAlreadyUsed();
error TicketNFT__NotOrganizer();

contract TicketNFT is ERC721, Ownable, ERC721Enumerable, ReentrancyGuard {
    struct TicketAttributes {
        uint256 eventId;
        uint256 expireTime;
        bool isUsed;
        address organizer;
        bool resaleAllowed;
        uint256 maxResalePrice;
    }

    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => TicketAttributes) public ticketAttributes;

    uint256 public nextTokenId;

    event TicketMinted(
        address indexed to, uint256 indexed tokenId, uint256 indexed eventId, address organizer, string tokenURI
    );
    event TicketUsed(uint256 indexed tokenId, address indexed checker, uint256 checkinTime);

    constructor() ERC721("TicketNFT", "TNFT") Ownable(msg.sender) {}

    function mintTicketNFT(
        address to,
        string calldata tokenUri,
        uint256 eventId,
        uint256 expireTime,
        address organizer,
        bool resaleAllowed,
        uint256 maxResalePrice
    ) external onlyOwner nonReentrant {
        if (to == address(0)) revert TicketNFT__InvalidRecipient();
        if (bytes(tokenUri).length == 0) revert TicketNFT__URIEmpty();
        if (block.timestamp > expireTime) revert TicketNFT__TicketExpired();
        if (organizer == address(0)) revert TicketNFT__InvalidRecipient();

        uint256 tokenId = nextTokenId;
        _safeMint(to, tokenId);
        _tokenURIs[tokenId] = tokenUri;

        ticketAttributes[tokenId] = TicketAttributes({
            eventId: eventId,
            expireTime: expireTime,
            isUsed: false,
            organizer: organizer,
            resaleAllowed: resaleAllowed,
            maxResalePrice: maxResalePrice
        });

        emit TicketMinted(to, tokenId, eventId, organizer, tokenUri);

        unchecked {
            nextTokenId++;
        }
    }

    function useTicket(uint256 tokenId) external {
        _requireTokenExists(tokenId);
        TicketAttributes storage attr = ticketAttributes[tokenId];
        if (block.timestamp > attr.expireTime) {
            revert TicketNFT__TicketExpired();
        }
        if (attr.isUsed) revert TicketNFT__TicketAlreadyUsed();
        if (msg.sender != attr.organizer && msg.sender != owner()) {
            revert TicketNFT__NotOrganizer();
        }

        attr.isUsed = true;
        emit TicketUsed(tokenId, msg.sender, block.timestamp);
    }

    function getTicketAttributes(uint256 tokenId) external view returns (TicketAttributes memory) {
        _requireTokenExists(tokenId);
        return ticketAttributes[tokenId];
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
        if (_ownerOf(tokenId) == address(0)) revert TicketNFT__TokenNotExists();
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
