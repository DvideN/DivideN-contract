// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./JamesWeb3NFT.sol";
import "../ERC721ToERC4610WrapperImpl.sol";
import "../interfaces/IERC4610.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @dev JamesWeb3NFTWrapperImpl is the JamesWeb3NFT that uses OpenZeppelin ERC721 after wrappering
 */
contract JamesWeb3NFTWrapperImpl is ERC721ToERC4610WrapperImpl {

    constructor(address underlyingToken_, string memory name_, string memory symbol_) ERC721ToERC4610WrapperImpl(underlyingToken_,name_,symbol_) {
    }

    // add READ function to get ratity property value from AToken
    function rarity() external view returns (uint256) {
        return JamesWeb3NFT(_underlyingToken).rarity();
    }

    // add READ function to get data property value from AToken
    function getData(uint256 tokenId) external view returns (string memory, uint256) {
        return JamesWeb3NFT(_underlyingToken).getData(tokenId);
    }

}
