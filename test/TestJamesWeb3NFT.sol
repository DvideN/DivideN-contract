pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/lock_nft/example/JamesWeb3NFT.sol";
import "../src/lock_nft/ERC721ToERC4610WrapperImpl.sol";

contract TestJamesWeb3NFT is Test {
    uint256 SAMPLE_TOKEN_ID;
    JamesWeb3NFT JAMES_WEB3_NFT;
    address DEFAULT_EOA;
    ERC721ToERC4610WrapperImpl JAMES_WEB3_NFT_WRAPPER;
    address TEST_NFT_WRAPPER_FACET_ADDR;

    function setUp() public {
        JAMES_WEB3_NFT = new JamesWeb3NFT("JAMES WEB3", "JW3");
        JAMES_WEB3_NFT_WRAPPER = new ERC721ToERC4610WrapperImpl("JAMES WEB3 WRAPPER", "WJW3");
        TEST_NFT_WRAPPER_FACET_ADDR = address(JAMES_WEB3_NFT_WRAPPER);

        DEFAULT_EOA = address(0xDeFa);

        vm.startPrank(DEFAULT_EOA, DEFAULT_EOA);
        SAMPLE_TOKEN_ID = JAMES_WEB3_NFT.mint("Sigrid Jin");
        JAMES_WEB3_NFT.approve(address(JAMES_WEB3_NFT_WRAPPER), SAMPLE_TOKEN_ID);
        // client 여기까지

        console.log("SAMPLE_TOKEN_ID :: ", SAMPLE_TOKEN_ID);

        JAMES_WEB3_NFT_WRAPPER.deposit(SAMPLE_TOKEN_ID, address(JAMES_WEB3_NFT));
        console.log("SAMPLE_TOKEN_ID: ", SAMPLE_TOKEN_ID);

        vm.stopPrank();
    }

    function testAddAllNFTWrapperImplFunctionSelectorsAndCall() public {
        assertEq(JAMES_WEB3_NFT_WRAPPER.ownerOf(SAMPLE_TOKEN_ID, address(JAMES_WEB3_NFT_WRAPPER)), DEFAULT_EOA);
        assertEq(JAMES_WEB3_NFT.ownerOf(SAMPLE_TOKEN_ID), address(TEST_NFT_WRAPPER_FACET_ADDR));
    }

    function testWithDrawLockedERC721() public {
        // withdraw locked ERC721
        vm.startPrank(DEFAULT_EOA, DEFAULT_EOA);
        JAMES_WEB3_NFT_WRAPPER.withdraw(SAMPLE_TOKEN_ID, address(JAMES_WEB3_NFT));
        vm.stopPrank();
        // verify data
        assertEq(JAMES_WEB3_NFT_WRAPPER.balanceOf(DEFAULT_EOA), 0);
        assertEq(JAMES_WEB3_NFT.ownerOf(SAMPLE_TOKEN_ID), DEFAULT_EOA);
    }
}
