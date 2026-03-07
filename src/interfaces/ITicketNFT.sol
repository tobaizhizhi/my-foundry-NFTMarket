// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITicketNFT {
    function ticketAttributes(
        uint256 tokenId
    )
        external
        view
        returns (
            uint256 eventId,
            uint256 expireTime,
            bool isUsed,
            address organizer,
            bool resaleAllowed,
            uint256 maxResalePrice
        );
}
