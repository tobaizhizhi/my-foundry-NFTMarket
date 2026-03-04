// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

error MyNFT__InvalidRecipient();
error MyNFT__BatchMintAmountFalse();
error MyNFT__TokenNotExists();
error MyNFT__URIEmpty();
error MyNFT__NotTokenOwnerOrContractOwner();
error MyNFT__TicketExpired();
error MyNFT__InvalidNFTType();
error MyNFT__TicketAlreadyUsed();
error MyNFT__NotOrganizer();

/**
 * @title MyNFT
 * @notice Dual-mode ERC721 contract for Common collectible NFTs and functional Ticket NFTs
 * @dev Inherits ERC721Enumerable (for owner NFT enumeration) and ReentrancyGuard (anti-reentrancy protection)
 */
contract MyNFT is ERC721, Ownable, ERC721Enumerable, ReentrancyGuard {
    /**
     * @notice Enumeration to distinguish NFT types
     * @dev Common = standard collectible | Ticket = event ticket with redemption rules
     */
    enum NFTType {
        Common, // Regular collectible NFT (no special restrictions)
        Ticket // Event ticket NFT (with expiration/redemption/resale rules)
    }

    /**
     * @notice Struct for Ticket NFT exclusive attributes
     * @param eventId Unique ID of the associated event
     * @param expireTime Expiration timestamp (Unix time) of the ticket
     * @param isUsed Whether the ticket has been redeemed
     * @param organizer Address of the event organizer (authorized to redeem)
     * @param resaleAllowed Whether resale of the ticket is permitted
     * @param maxResalePrice Maximum allowed resale price (wei) to prevent scalping
     */
    struct TicketAttributes {
        uint256 eventId;
        uint256 expireTime;
        bool isUsed;
        address organizer;
        bool resaleAllowed;
        uint256 maxResalePrice;
    }

    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => NFTType) public tokenType;
    mapping(uint256 => TicketAttributes) public ticketAttributes;

    uint256 public nextTokenId;
    uint256 public constant MAX_BATCH_MINT = 10;

    event NFTMinted(address indexed to, uint256 indexed tokenId, string tokenURI, NFTType nftType);
    event BatchNFTMinted(address indexed to, uint256 indexed startTokenId, uint256 amount);
    event TicketMinted(address indexed to, uint256 indexed tokenId, uint256 indexed eventId, address organizer);
    event TicketUsed(uint256 indexed tokenId, address indexed checker, uint256 checkinTime);
    event TokenURIUpdated(uint256 indexed tokenId, string newURI);

    constructor() ERC721("MyNFT", "MNFT") Ownable(msg.sender) {}

    /**
     * @notice Mint a single Common NFT (collectible type)
     * @dev Restricted to contract owner, protected against reentrancy
     * @param to Recipient address of the NFT (cannot be zero address)
     * @param tokenURI Metadata URI of the NFT (cannot be empty)
     */
    function mintCommonNFT(address to, string calldata tokenURI) external onlyOwner nonReentrant {
        if (to == address(0)) revert MyNFT__InvalidRecipient();
        if (bytes(tokenURI).length == 0) revert MyNFT__URIEmpty();

        uint256 tokenId = nextTokenId;
        _safeMint(to, tokenId);
        _tokenURIs[tokenId] = tokenURI;
        tokenType[tokenId] = NFTType.Common;

        emit NFTMinted(to, tokenId, tokenURI, NFTType.Common);

        unchecked {
            nextTokenId += 1;
        }
    }

    /**
     * @notice Batch mint multiple Common NFTs (max 10 per batch)
     * @dev Restricted to contract owner, protected against reentrancy
     * @param to Recipient address of the NFTs (cannot be zero address)
     * @param amount Number of NFTs to mint (1 <= amount <= MAX_BATCH_MINT)
     * @param tokenURIs Array of metadata URIs (length must match amount)
     */
    function batchMint(address to, uint256 amount, string[] calldata tokenURIs) external onlyOwner nonReentrant {
        if (to == address(0)) revert MyNFT__InvalidRecipient();
        if (amount == 0 || amount > MAX_BATCH_MINT) {
            revert MyNFT__BatchMintAmountFalse();
        }
        if (tokenURIs.length != amount) revert MyNFT__BatchMintAmountFalse();

        uint256 startTokenId = nextTokenId;

        for (uint256 i = 0; i < amount;) {
            uint256 tokenId = startTokenId + i;
            if (bytes(tokenURIs[i]).length == 0) revert MyNFT__URIEmpty();
            _safeMint(to, tokenId);
            _tokenURIs[tokenId] = tokenURIs[i];
            tokenType[tokenId] = NFTType.Common;
            emit NFTMinted(to, tokenId, tokenURIs[i], NFTType.Common);

            unchecked {
                i++;
            }
        }

        emit BatchNFTMinted(to, startTokenId, amount);
        unchecked {
            nextTokenId = startTokenId + amount;
        }
    }

    /**
     * @notice Mint a single Ticket NFT (functional event ticket)
     * @dev Restricted to contract owner, protected against reentrancy
     * @param to Recipient address of the ticket (cannot be zero address)
     * @param tokenURI Metadata URI of the ticket (cannot be empty)
     * @param eventId Unique ID of the event associated with the ticket
     * @param expireTime Expiration timestamp (must be in the future)
     * @param organizer Address of the event organizer (cannot be zero address)
     * @param resaleAllowed Whether the ticket can be resold
     * @param maxResalePrice Maximum allowed resale price (wei)
     */
    function mintTicketNFT(
        address to,
        string calldata tokenURI,
        uint256 eventId,
        uint256 expireTime,
        address organizer,
        bool resaleAllowed,
        uint256 maxResalePrice
    ) external onlyOwner nonReentrant {
        if (to == address(0)) revert MyNFT__InvalidRecipient();
        if (bytes(tokenURI).length == 0) revert MyNFT__URIEmpty();
        if (block.timestamp > expireTime) revert MyNFT__TicketExpired();
        if (organizer == address(0)) revert MyNFT__InvalidRecipient();

        uint256 tokenId = nextTokenId;
        _safeMint(to, tokenId);
        _tokenURIs[tokenId] = tokenURI;
        tokenType[tokenId] = NFTType.Ticket;

        ticketAttributes[tokenId] = TicketAttributes({
            eventId: eventId,
            expireTime: expireTime,
            isUsed: false,
            organizer: organizer,
            resaleAllowed: resaleAllowed,
            maxResalePrice: maxResalePrice
        });

        emit NFTMinted(to, tokenId, tokenURI, NFTType.Ticket);
        emit TicketMinted(to, tokenId, eventId, organizer);

        unchecked {
            nextTokenId++;
        }
    }

    /**
     * @notice Update metadata URI of an existing NFT
     * @dev Only callable by NFT owner or contract owner
     * @param tokenId ID of the NFT to update
     * @param newURI New metadata URI (cannot be empty)
     */
    function updateTokenURI(uint256 tokenId, string calldata newURI) external {
        ownerOf(tokenId);
        if (bytes(newURI).length == 0) revert MyNFT__URIEmpty();
        if (ownerOf(tokenId) != msg.sender && msg.sender != owner()) {
            revert MyNFT__NotTokenOwnerOrContractOwner();
        }

        _tokenURIs[tokenId] = newURI;

        emit TokenURIUpdated(tokenId, newURI);
    }

    /**
     * @notice Get all NFT token IDs owned by a specific address
     * @dev Uses ERC721Enumerable's tokenOfOwnerByIndex to enumerate NFTs (gas-efficient for on-chain queries)
     * @param owner Address to query NFT ownership for (can be zero address, returns empty array)
     * @return tokenIds Array of token IDs owned by the provided address (in order of minting)
     */
    function getNFTsByOwner(address owner) external view returns (uint256[] memory) {
        uint256 balance = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](balance);

        for (uint256 i = 0; i < balance;) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
            unchecked {
                i++;
            }
        }

        return tokenIds;
    }

    /**
     * @notice Redeem (use) a Ticket NFT
     * @dev Only callable by event organizer or contract owner; validates ticket status
     * @param tokenId ID of the Ticket NFT to redeem
     */
    function useTicket(uint256 tokenId) external {
        ownerOf(tokenId);

        TicketAttributes storage attr = ticketAttributes[tokenId];
        if (block.timestamp > attr.expireTime) revert MyNFT__TicketExpired();
        if (attr.isUsed) revert MyNFT__TicketAlreadyUsed();
        if (tokenType[tokenId] != NFTType.Ticket) {
            revert MyNFT__InvalidNFTType();
        }
        if (msg.sender != attr.organizer && msg.sender != owner()) {
            revert MyNFT__NotOrganizer();
        }

        attr.isUsed = true;

        emit TicketUsed(tokenId, msg.sender, block.timestamp);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        ownerOf(tokenId);
        return _tokenURIs[tokenId];
    }

    // ==== Inherited function overrides (no additional comments needed) ====
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
