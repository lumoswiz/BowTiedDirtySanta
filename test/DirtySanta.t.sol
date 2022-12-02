// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "forge-std/Test.sol";

import {DirtySanta} from "../src/DirtySanta.sol";
import {toDaysWadUnsafe, toWadUnsafe} from "solmate/utils/SignedWadMath.sol";

contract DirtySantaTest is Test {
    DirtySanta internal nft;

    string internal URI =
        "ipfs://BmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/";

    int256 internal constant INITIAL_PRICE = 1e18;
    int256 internal constant SCALE_FACTOR = 1.2e18;
    int256 internal constant DECAY_CONSTANT = 0.5e18;

    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        vm.warp(1669961536);

        nft = new DirtySanta(INITIAL_PRICE, SCALE_FACTOR, DECAY_CONSTANT);
    }

    function test_initialPrice() public {
        uint256 price = nft.getGDAPrice(0, 0);
        assertEq(uint256(INITIAL_PRICE), price);
    }

    function test_mintNFT() public {
        startHoax(alice);

        nft.mint{value: uint256(INITIAL_PRICE)}();

        assertEq(nft.balanceOf(alice), 1);
        assertEq(nft.ownerOf(0), alice);
    }

    function test_cannotUnderpayForNFT() public {
        startHoax(alice);

        vm.expectRevert(DirtySanta.DirtySanta__Underpaid.selector);
        nft.mint{value: 0.1 ether}();
    }

    function test_cannotMintMoreThanOneNFT() public {
        startHoax(alice);

        nft.mint{value: uint256(INITIAL_PRICE)}();

        vm.expectRevert();
        nft.mint{value: uint256(INITIAL_PRICE)}();
    }

    function test_mintingStopsAtChristmas() public {
        vm.warp(1671886800);
        startHoax(alice);

        vm.expectRevert();
        nft.mint{value: uint256(INITIAL_PRICE)}();
    }

    function test_cannotReceiveNFTWhenAlreadyOwnOne() public {
        startHoax(alice);
        nft.mint{value: uint256(INITIAL_PRICE)}();
        vm.stopPrank();

        startHoax(bob);

        uint256 price = nft.getGDAPrice(
            toDaysWadUnsafe(block.timestamp - nft.startTime()),
            nft.totalSold() + 1
        );
        uint256 tokenId = nft.mint{value: price}();

        vm.expectRevert();
        nft.safeTransferFrom(bob, alice, tokenId);
    }
}
