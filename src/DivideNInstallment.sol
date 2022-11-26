// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./lock_nft/ERC721ToERC4610WrapperImpl.sol";

contract DivideNInstallment {
    enum Status {
        Registered,
        StartedInstallment,
        EndedInstallmentSucceeded,
        EndedInstallmentFailed
    }

    struct InstallmentObject {
        bool isNFTLocked;
        address seller;
        address buyer;
        address ERC721address;
        uint256 installmentId;
        uint256 ERC721Id;
        uint256 priceInMatic; // in wei
        Status installmentStatus;
        uint256 collateralRatio; // in bp (1/10000)
        uint256 installmentMonths;
        uint256 minimalCollateral; // (optional): priceInMatic * collateralRatio
    }

    uint256 latestInstallmentId = 1;
    mapping(uint256 => InstallmentObject) installmentIdToInstallmentObject; // installment ID => InstallmentObject
    mapping(address => InstallmentObject[]) sellerToInstallmentObjectList; // seller => InstallmentObject[]
    mapping(address => InstallmentObject[]) buyerToInstallmentObjectList; // buyer => InstallmentObject[]
    ERC721ToERC4610WrapperImpl ERC721_WRAPPER;

    mapping(uint256 => Status) installmentIdToStatus; // status별 Installment Object 조회 용도

    function registerInstallment(
        address _seller,
        address _ERC721address,
        uint256 _ERC721Id,
        uint256 _priceInMatic,
        uint256 _collateralRatio,
        uint256 _installmentMonths,
        address _ERC721WrapperAddr
    ) public returns (bool) {
        uint256 installmentId = latestInstallmentId;

        // Installment Object Creation
        ERC721_WRAPPER = ERC721ToERC4610WrapperImpl(_ERC721WrapperAddr);
        ERC721_WRAPPER.deposit(_ERC721Id, _ERC721address);

        InstallmentObject memory newInstallmentObject = InstallmentObject({
            isNFTLocked: false,
            seller: _seller,
            buyer: address(0),
            ERC721address: _ERC721address,
            installmentId: installmentId,
            ERC721Id: _ERC721Id,
            priceInMatic: _priceInMatic,
            installmentStatus: Status.Registered,
            collateralRatio: _collateralRatio,
            installmentMonths: _installmentMonths,
            minimalCollateral: _priceInMatic * _collateralRatio
        });

        installmentIdToInstallmentObject[
            latestInstallmentId
        ] = newInstallmentObject;
        sellerToInstallmentObjectList[_seller].push(newInstallmentObject);

        installmentIdToStatus[installmentId] = Status.Registered; // Status update

        latestInstallmentId++; // global state update (incrementation)

        return true;
    }

    function startInstallment(uint256 _installmentId) internal returns (bool) {
        address _buyer = msg.sender;
        InstallmentObject
            memory installmentObject = installmentIdToInstallmentObject[
                _installmentId
            ];
        require(installmentObject.buyer == address(0)); // buyer must not be designated yet.
        // TODO: 보증금 전송 (buyer to seller)
        installmentObject.buyer = _buyer;
        installmentObject.installmentStatus = Status.StartedInstallment;
        installmentIdToStatus[_installmentId] = Status.StartedInstallment; // Status update
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
        require(
            installmentObject.installmentStatus == Status.StartedInstallment
        );

        if (succeeded == true) {
            installmentObject.installmentStatus = Status
                .EndedInstallmentSucceeded;
            installmentIdToStatus[_installmentId] = Status
                .EndedInstallmentSucceeded; // Status update
            // TODO: ERC721 NFT lock을 해제해주기
            installmentObject.isNFTLocked = false;
            _endInstallmentWithSuccess();
            return true;
        } else {
            installmentObject.installmentStatus = Status.EndedInstallmentFailed;
            installmentIdToStatus[_installmentId] = Status
                .EndedInstallmentFailed; // Status update
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

    function getBuyableInstallments()
        public
        view
        returns (InstallmentObject[] memory)
    {
        InstallmentObject[] memory returnData = new InstallmentObject[](
            latestInstallmentId
        );

        uint256 counter = 0;

        for (uint i = 1; i <= latestInstallmentId; i++) {
            if (installmentIdToStatus[i] == Status.Registered) {
                returnData[counter] = installmentIdToInstallmentObject[i];
                counter++;
            }
        }

        return returnData;
    }

    function getBuyingInstallmentsInProgress()
        public
        view
        returns (InstallmentObject[] memory)
    {
        InstallmentObject[]
            memory sendersInstallments = buyerToInstallmentObjectList[
                msg.sender
            ]; // msg.sender가 buyer인 할부계약 리스트
        uint256 sendersInstallmentsMaxLength = sendersInstallments.length;

        InstallmentObject[] memory returnData = new InstallmentObject[](
            sendersInstallmentsMaxLength
        );

        uint256 counter = 0;

        // msg.sender가 buyer이고 status가 Start인 것들

        for (uint i = 0; i < sendersInstallmentsMaxLength; i++) {
            // index of the array
            if (
                sendersInstallments[i].installmentStatus ==
                Status.StartedInstallment
            ) {
                returnData[counter] = sendersInstallments[i];
                counter++;
            }
        }
        return returnData;
    }

    function getSellingInstallmentsInProgress()
        public
        view
        returns (InstallmentObject[] memory)
    {
        InstallmentObject[]
            memory sendersInstallments = sellerToInstallmentObjectList[
                msg.sender
            ]; // msg.sender가 buyer인 할부계약 리스트
        uint256 sendersInstallmentsMaxLength = sendersInstallments.length;

        InstallmentObject[] memory returnData = new InstallmentObject[](
            sendersInstallmentsMaxLength
        );

        uint256 counter = 0;

        // msg.sender가 seller이고 status가 Start인 것들

        for (uint i = 0; i < sendersInstallmentsMaxLength; i++) {
            // index of the array
            if (
                sendersInstallments[i].installmentStatus ==
                Status.StartedInstallment
            ) {
                returnData[counter] = sendersInstallments[i];
                counter++;
            }
        }
        return returnData;
    }

    event InstallmentRegistered();
    event BeginInstallment();
    event EndInstallment();
}
