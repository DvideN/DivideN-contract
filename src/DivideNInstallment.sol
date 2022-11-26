// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./lock_nft/ERC721ToERC4610WrapperImpl.sol";

contract DivideNInstallment {
    struct InstallmentObject {
        bool isNFTLocked;
        address seller;
        address buyer;
        address ERC721address;
        uint256 installmentId; // TODO: needs global state variable for +1 incrementation
        uint256 ERC721Id;
        uint256 priceInMatic; // x1000
        uint256 installmentStatus; // TODO: ENUM
        uint256 collateralRatio; // x1000
        uint256 installmentMonths;
        uint256 minimalCollateral; // (optional): priceInMatic * collateralRatio
    }

    uint256 latestInstallmentId;
    mapping(uint256 => InstallmentObject) installmentIdToInstallmentObject; // installment ID => InstallmentObject
    mapping(address => InstallmentObject[]) sellerToInstallmentObjectList; // seller => InstallmentObject[]
    mapping(address => InstallmentObject[]) buyerToInstallmentObjectList; // buyer => InstallmentObject[]
    ERC721ToERC4610WrapperImpl ERC721_WRAPPER;

    function registerInstallment(
        address _seller,
        address _ERC721address,
        uint256 _ERC721Id,
        uint256 _priceInMatic,
        uint256 _collateralRatio,
        uint256 _installmentMonths,
        address _ERC721WrapperAddr
    ) public returns (bool) {
        // Installment Object Creation
        ERC721_WRAPPER = ERC721ToERC4610WrapperImpl(_ERC721WrapperAddr);
        ERC721_WRAPPER.deposit(_ERC721Id, _ERC721address);

        InstallmentObject memory newInstallmentObject = InstallmentObject({
            isNFTLocked: false,
            seller: _seller,
            buyer: address(0),
            ERC721address: _ERC721address,
            installmentId: latestInstallmentId,
            ERC721Id: _ERC721Id,
            priceInMatic: _priceInMatic,
            installmentStatus: 0,
            collateralRatio: _collateralRatio,
            installmentMonths: _installmentMonths,
            minimalCollateral: _priceInMatic * _collateralRatio
        });

        installmentIdToInstallmentObject[
            latestInstallmentId
        ] = newInstallmentObject;
        sellerToInstallmentObjectList[_seller].push(newInstallmentObject);

        latestInstallmentId++; // global state update

        return true;
    }

    function beginInstallment(
        uint256 _installmentId
    ) internal returns (bool) {
        address _buyer = msg.sender;
        InstallmentObject
            memory installmentObject = installmentIdToInstallmentObject[
                _installmentId
            ];
        require(installmentObject.buyer == address(0)); // buyer must not be designated yet.
        // TODO: 보증금 전송 (buyer to seller)
        installmentObject.buyer = _buyer;
        installmentObject.installmentStatus = 1; // TODO: ENUM
        installmentObject.isNFTLocked = true;
        return true;
    }

    function endInstallment(
        uint256 _installmentId,
        bool succeeded
    ) internal returns (bool) {
        InstallmentObject
            memory installmentObject = installmentIdToInstallmentObject[
                _installmentId
            ];
        require(installmentObject.installmentStatus == 1); // TODO: ENUM

        if (succeeded == true) {
            installmentObject.installmentStatus = 2;
            // TODO: ERC721 NFT lock을 해제해주기
            installmentObject.isNFTLocked = false;
            _endInstallmentWithSuccess();
            return true;
        } else {
            installmentObject.installmentStatus = 3;
            installmentObject.isNFTLocked = false;
            _endInstallmentWithFailure();
            return true;
        }
    }

    function _endInstallmentWithSuccess() private {
        // TODO: NFT를 buyer에게 보내주고, 종료
    }

    function _endInstallmentWithFailure() private {
        // TODO: NFT를 seller에게 보내주고, 종료
    }

    event InstallmentRegistered();
    event BeginInstallment();
    event EndInstallment();
}
