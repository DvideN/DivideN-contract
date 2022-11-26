pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/DivideNInstallment.sol";
import "../src/lock_nft/example/JamesWeb3NFT.sol";

contract TestRegisterInstallment is Test {
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

    function setUp() public {
        JAMES_WEB3_NFT = new JamesWeb3NFT("JAMES WEB3", "JW3");
        DEFAULT_EOA = address(0xDeFa);

        SAMPLE_TOKEN_ID = JAMES_WEB3_NFT.mint("Sigrid Jin");
        console.log("SAMPLE_TOKEN_ID :: ", SAMPLE_TOKEN_ID);

        DIVIDEN = new DivideNInstallment();
        SELLER = DEFAULT_EOA;
        ERC721_ADDR = address(JAMES_WEB3_NFT);
        ERC721_ID = SAMPLE_TOKEN_ID;
        PRICE_IN_MATIC = 5 * (10 ** 18);
        COLLATERAL_RATIO_BP = 2000; // BP (1/10000)
        INSTALLMENT_MONTHS = 6;

        // approve
        JAMES_WEB3_NFT.approve(address(DIVIDEN), SAMPLE_TOKEN_ID);
    }

    function testRegisterInstallment() public {
        bool result = DIVIDEN.registerInstallment(SELLER, ERC721_ADDR, ERC721_ID, PRICE_IN_MATIC, COLLATERAL_RATIO_BP, INSTALLMENT_MONTHS);
        assertEq(result, true);
        vm.stopPrank();
    }
}
