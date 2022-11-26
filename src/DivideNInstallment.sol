// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
        uint256 installmentId; // TODO: needs global state variable for +1 incrementation
        uint256 ERC721Id;
        uint256 priceInMatic; // x1000
        Status installmentStatus; // TODO: ENUM
        uint256 collateralRatio; // x1000
        uint256 installmentMonths;
        uint256 minimalCollateral; // (optional): priceInMatic * collateralRatio
    }

    uint256 latestInstallmentId;
    mapping(uint256 => InstallmentObject) installmentIdToInstallmentObject; // installment ID => InstallmentObject
    mapping(address => InstallmentObject[]) sellerToInstallmentObjectList; // seller => InstallmentObject[]
    mapping(address => InstallmentObject[]) buyerToInstallmentObjectList; // buyer => InstallmentObject[]

    function registerInstallment(
        address _seller,
        address _ERC721address,
        uint256 _ERC721Id,
        uint256 _priceInMatic,
        uint256 _collateralRatio,
        uint256 _installmentMonths
    ) internal returns (bool) {
        // Installment Object Creation
        InstallmentObject memory newInstallmentObject = InstallmentObject({
            isNFTLocked: false,
            seller: _seller,
            buyer: address(0),
            ERC721address: _ERC721address,
            installmentId: latestInstallmentId,
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

        latestInstallmentId++; // global state update

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
        installmentObject.installmentStatus = Status.StartedInstallment; // TODO: ENUM
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
        ); // TODO: ENUM

        if (succeeded == true) {
            installmentObject.installmentStatus = Status
                .EndedInstallmentSucceeded;
            // TODO: ERC721 NFT lock을 해제해주기
            installmentObject.isNFTLocked = false;
            _endInstallmentWithSuccess();
            return true;
        } else {
            installmentObject.installmentStatus = Status.EndedInstallmentFailed;
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

    // 특정 계정이 보유한 ERC721 리스트 => front에서 하기
    // 사람들이 판매 중인 NFT의 전체 리스트 (구매 가능 상태)
    // 내 꺼 중 결제가 진행 중인 애들 리스트
    // 1) 내가 사고 있는 애들 getter
    // 2) 내가 팔고 있는 애들 getter
    // 리스트에서 뭘 보여줘야 되냐면: 총 기간, 남은 기간, 월별 결제액, 초기 계약금, 할부 거래 Tx 주소 => front에서 하면 될거같은데?

    event InstallmentRegistered();
    event BeginInstallment();
    event EndInstallment();
}
