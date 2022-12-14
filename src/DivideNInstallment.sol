// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./lock_nft/ERC721ToERC4610WrapperImpl.sol";
import "./superfluid/FlowSender.sol";

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
    FlowSender flowSender;

    mapping(uint256 => Status) installmentIdToStatus; // status별 Installment Object 조회 용도

    function addSuperfluidOnMATIC(address hostAddr, address fDaiXAddr) public {
//        address MATIC_HOST = 0xEB796bdb90fFA0f28255275e16936D25d3418603;
//        address MATIC_FDAIX = 0x5D8B4C2554aeB7e86F387B4d6c00Ac33499Ed01f;
        flowSender = new FlowSender(hostAddr, fDaiXAddr);
    }

    function registerInstallment(
        address _ERC721address,
        uint256 _ERC721Id,
        uint256 _priceInMatic,
        uint256 _collateralRatio,
        uint256 _installmentMonths,
        address _ERC721WrapperAddr
    ) public returns (uint256) {
        uint256 installmentId = latestInstallmentId;

        // Installment Object Creation
        ERC721_WRAPPER = ERC721ToERC4610WrapperImpl(_ERC721WrapperAddr);
        ERC721_WRAPPER.deposit(_ERC721Id, _ERC721address);

        InstallmentObject memory newInstallmentObject = InstallmentObject({
            isNFTLocked: false,
            seller: msg.sender,
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
        sellerToInstallmentObjectList[msg.sender].push(newInstallmentObject);

        installmentIdToStatus[installmentId] = Status.Registered; // Status update

        latestInstallmentId++; // global state update (incrementation)

        return installmentId;
    }

    function registerInstallmentWithSuperfluid(
        address _ERC721address,
        uint256 _ERC721Id,
        uint256 _priceInMatic,
        uint256 _collateralRatio,
        uint256 _installmentMonths,
        address _ERC721WrapperAddr
    ) public returns (uint256) {
        uint256 installmentId = latestInstallmentId;

        // Installment Object Creation
        ERC721_WRAPPER = ERC721ToERC4610WrapperImpl(_ERC721WrapperAddr);
        ERC721_WRAPPER.deposit(_ERC721Id, _ERC721address);

        InstallmentObject memory newInstallmentObject = InstallmentObject({
            isNFTLocked: false,
            seller: msg.sender,
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
        sellerToInstallmentObjectList[msg.sender].push(newInstallmentObject);

        installmentIdToStatus[installmentId] = Status.Registered; // Status update

        latestInstallmentId++; // global state update (incrementation)

        address MATIC_HOST = 0xEB796bdb90fFA0f28255275e16936D25d3418603;
        address MATIC_FDAIX = 0x5D8B4C2554aeB7e86F387B4d6c00Ac33499Ed01f;
        addSuperfluidOnMATIC(MATIC_HOST, MATIC_FDAIX);

        // 10 * (10**18) fDAIx / ( 60 seconds * 60 minutes )
        int96 FLOW_RATE = 2777777800000000;
        address RECEIVER_EXAMPLE = 0x01725BE700413D34bCC5e961de1d0C777d3A52F4;

        flowSender.gainDaiX(msg.sender);
        flowSender.createStream(FLOW_RATE, newInstallmentObject.seller);

        return installmentId;
    }

    function startInstallment(uint256 _installmentId) public returns (bool) {
        address _buyer = msg.sender;
        InstallmentObject
            storage installmentObject = installmentIdToInstallmentObject[
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
    ) public returns (bool) {
        InstallmentObject
            storage installmentObject = installmentIdToInstallmentObject[
                _installmentId
            ];

        require(
            installmentObject.installmentStatus == Status.StartedInstallment
        );

        console.log("SUCCEEED", succeeded);

        if (succeeded == true) {
            console.log("WHEN TRUE");
            installmentObject.installmentStatus = Status
                .EndedInstallmentSucceeded;
            installmentIdToStatus[_installmentId] = Status
                .EndedInstallmentSucceeded; // Status update
            // TODO: ERC721 NFT lock을 해제해주기
            installmentObject.isNFTLocked = false;
            _endInstallmentWithSuccess(
                installmentObject.ERC721Id,
                installmentObject.ERC721address,
                installmentObject.buyer
            );
            return true;
        } else {
            console.log("WHEN FALSE");
            installmentObject.installmentStatus = Status.EndedInstallmentFailed;
            installmentIdToStatus[_installmentId] = Status
                .EndedInstallmentFailed; // Status update
            installmentObject.isNFTLocked = false;
            _endInstallmentWithFailure(
                installmentObject.ERC721Id,
                installmentObject.ERC721address,
                installmentObject.seller
            );
            return true;
        }
    }

    function _endInstallmentWithSuccess(
        uint256 tokenId,
        address erc721Addr,
        address buyerAddr
    ) private {
        ERC721_WRAPPER.withdraw(tokenId, buyerAddr, erc721Addr);
    }

    function _endInstallmentWithFailure(
        uint256 tokenId,
        address erc721Addr,
        address originalSellerAddr
    ) private {
        ERC721_WRAPPER.withdraw(tokenId, originalSellerAddr, erc721Addr);
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
