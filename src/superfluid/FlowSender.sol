//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

import {IFakeDAI} from "./IFakeDAI.sol";

import "forge-std/console.sol";

import { ISuperfluid, ISuperToken } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

import {IConstantFlowAgreementV1} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";

import {CFAv1Library} from "@superfluid-finance/ethereum-contracts/contracts/apps/CFAv1Library.sol";

// For deployment on Goerli Testnet
contract FlowSender {

    using CFAv1Library for CFAv1Library.InitData;
    CFAv1Library.InitData public cfaV1; //initialize cfaV1 variable

    mapping (address => bool) public accountList;

    ISuperToken public daiX;

    // Host address on Goerli = 0x22ff293e14F1EC3A09B137e9e06084AFd63adDF9
    // fDAIx address on Goerli = 0xF2d68898557cCb2Cf4C10c3Ef2B034b2a69DAD00
    constructor(address _hostAddr, address _daiXAddr) {
        // ISuperfluid _host, ISuperToken _goerliDaiX
        ISuperfluid _host = ISuperfluid(_hostAddr);
        ISuperToken _daiX = ISuperToken(_daiXAddr);

        cfaV1 = CFAv1Library.InitData(
            _host,
            IConstantFlowAgreementV1(
                address(_host.getAgreementClass(
                    keccak256("org.superfluid-finance.agreements.ConstantFlowAgreement.v1")
                ))
            )
        );

        daiX = _daiX;

    }

    /// @dev Mints 10,000 fDAI to this contract and wraps it all into fDAIx
    function gainDaiX(address receiver) external {

        // Get address of fDAI by getting underlying token address from DAIx token
        IFakeDAI fdai = IFakeDAI( daiX.getUnderlyingToken() );

        // Mint 10,000 fDAI
//        fdai.mint(address(this), 10000e18);
        fdai.mint(receiver, 10000e18);

        // Approve fDAIx contract to spend fDAI
//        fdai.approve(address(daiX), 20000e18);
        fdai.approve(address(daiX), 20000e18);

        // Wrap the fDAI into fDAIx
        daiX.upgrade(10000e18);

    }

    /// @dev creates a stream from this contract to desired receiver at desired rate
    function createStream(int96 flowRate, address receiver) external {

        // Create stream
        cfaV1.createFlow(receiver, daiX, flowRate);

    }

    /// @dev updates a stream from this contract to desired receiver to desired rate
    function updateStream(int96 flowRate, address receiver) external {

        // Update stream
        cfaV1.updateFlow(receiver, daiX, flowRate);

    }

    /// @dev deletes a stream from this contract to desired receiver
    function deleteStream(address receiver) external {

        // Delete stream
        cfaV1.deleteFlow(address(this), receiver, daiX);

    }

    /// @dev get flow rate between this contract to certain receiver
    function readFlowRate(address receiver) external view returns (int96 flowRate) {

        // Get flow rate
        (,flowRate,,) = cfaV1.cfa.getFlow(daiX, address(this), receiver);

    }

}
