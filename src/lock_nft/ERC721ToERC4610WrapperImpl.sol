// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC4610.sol";
import "./interfaces/IWrapper.sol";
import "lib/forge-std/src/console.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";


contract ERC721ToERC4610WrapperImpl is ERC4610, IWrapper, IERC721Receiver {

    address internal _underlyingToken;

    constructor(address underlyingToken_, string memory name_, string memory symbol_) ERC4610(name_,symbol_) {
        _underlyingToken = underlyingToken_;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function underlyingToken() public view virtual returns (address) {
        return _underlyingToken;
    }

    function deposit(uint256 tokenId) public virtual override {
        address owner = IERC721(_underlyingToken).ownerOf(tokenId);
        require(_msgSender() == owner, "only owner can call");
        console.log("DEPOSIT", _msgSender(), address(this));

        // delegatecall safeTransferFrom
        // convert "safeTransferFrom(address,address,uint256)" which is literal_string to bytes4
//        bytes4 sig = bytes4(keccak256(bytes("safeTransferFrom(address,address,uint256)")));
//        (bool success, bytes memory data) = _underlyingToken.call(abi.encodeWithSelector(sig, owner, address(this), tokenId));
//        console.log("IS SUCCESSFUL ?", success);
        ERC721(_underlyingToken).safeTransferFrom(_msgSender(), address(this), tokenId);
        _mint(_msgSender(), tokenId);

        emit Deposit(_msgSender(), tokenId);
    }

    function withdraw(uint256 tokenId) public override virtual {
        address owner = IERC721(_underlyingToken).ownerOf(tokenId);
        require(_msgSender() == ownerOf(tokenId), "only owner can call");
        require(address(this) == owner, "invalid tokenId");

        _burn(tokenId);
        ERC721(_underlyingToken).safeTransferFrom(address(this), _msgSender(), tokenId);

        emit Withdraw(_msgSender(), tokenId);
    }

    function tokenURI(uint256 tokenId) public view override virtual returns (string memory) {
        return ERC721(_underlyingToken).tokenURI(tokenId);
    }

}
