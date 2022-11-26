pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/DivideNInstallment.sol";
import "../src/lock_nft/example/JamesWeb3NFT.sol";

contract TestEndInstallment is Test {
    uint256 SAMPLE_TOKEN_ID;
    JamesWeb3NFT JAMES_WEB3_NFT;
    address DEFAULT_EOA;
    address TEST_NFT_WRAPPER_FACET_ADDR;
    DivideNInstallment DIVIDEN;
    address SELLER;
    address ERC721_ADDR;
    uint256 ERC721_ID;
    uint256 PRICE_IN_MATIC;
    uint256 COLLATERAL_RATIO_BP;
    uint256 INSTALLMENT_MONTHS;
    ERC721ToERC4610WrapperImpl ERC721_WRAPPER;
    address ERC721ToERC4610WrapperImpl_ADDR;
    uint256 INSTALLMENT_ID;

    function setUp() public {
        console.log("HEY READ ME~");
        JAMES_WEB3_NFT = new JamesWeb3NFT("JAMES WEB3", "JW3");
        DEFAULT_EOA = address(0xDeFa);
        BUYER_EOA = address(0xFaDe);
        vm.startPrank(DEFAULT_EOA, DEFAULT_EOA);

        SAMPLE_TOKEN_ID = JAMES_WEB3_NFT.mint("Sigrid Jin");
        console.log("SAMPLE_TOKEN_ID :: ", SAMPLE_TOKEN_ID);

        DIVIDEN = new DivideNInstallment();
        SELLER = DEFAULT_EOA;
        ERC721_ADDR = address(JAMES_WEB3_NFT);
        ERC721_ID = SAMPLE_TOKEN_ID;
        PRICE_IN_MATIC = 5 * (10 ** 18);
        COLLATERAL_RATIO_BP = 2000; // BP (1/10000)
        INSTALLMENT_MONTHS = 6;

        ERC721_WRAPPER = new ERC721ToERC4610WrapperImpl("WRAPPER", "WRAP");
        ERC721ToERC4610WrapperImpl_ADDR = address(ERC721_WRAPPER);

        // approve
        JAMES_WEB3_NFT.approve(ERC721ToERC4610WrapperImpl_ADDR, SAMPLE_TOKEN_ID);

        uint256 installmentId = DIVIDEN.registerInstallment(ERC721_ADDR, ERC721_ID, PRICE_IN_MATIC, COLLATERAL_RATIO_BP, INSTALLMENT_MONTHS, ERC721ToERC4610WrapperImpl_ADDR);
        // installmentId zero
        assertEq(installmentId, 1);
        INSTALLMENT_ID = installmentId;
        vm.stopPrank();
    }

    function testStartInstallmentWithSuccess() public {
        // given
        console.log("INSTALLMENT_ID :: ", INSTALLMENT_ID);
        vm.startPrank(DEFAULT_EOA, DEFAULT_EOA);
        // startInstallment
        DIVIDEN.startInstallment(INSTALLMENT_ID);

        // when
        bool result = DIVIDEN.endInstallment(INSTALLMENT_ID, true);

        // then
        console.log("result :: ", result);
        console.log("JAMES_WEB3_NFT.ownerOf(SAMPLE_TOKEN_ID) :: ", JAMES_WEB3_NFT.ownerOf(SAMPLE_TOKEN_ID));
        assertEq(result, true);

        // verify whether original ERC721 NFT has been transferred to the original seller
        assertEq(JAMES_WEB3_NFT.ownerOf(SAMPLE_TOKEN_ID), SELLER);

        // finally
        vm.stopPrank();
    }

    function testEndInstallmentWithFailure() public {
        // given
        console.log("INSTALLMENT_ID :: ", INSTALLMENT_ID);
        vm.startPrank(DEFAULT_EOA, DEFAULT_EOA);
        // startInstallment
        DIVIDEN.startInstallment(INSTALLMENT_ID);

        // when
        bool result = DIVIDEN.endInstallment(INSTALLMENT_ID, false);

        // then
        console.log("result :: ", result);
        console.log("JAMES_WEB3_NFT.ownerOf(SAMPLE_TOKEN_ID) :: ", JAMES_WEB3_NFT.ownerOf(SAMPLE_TOKEN_ID));
        assertEq(result, true);

        // verify whether original ERC721 NFT has been transferred to the original seller
        assertEq(JAMES_WEB3_NFT.ownerOf(SAMPLE_TOKEN_ID), SELLER);

        // finally
        vm.stopPrank();
    }
}
