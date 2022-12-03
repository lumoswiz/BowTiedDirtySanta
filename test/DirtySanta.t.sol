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
    address charlee = makeAddr("charlee");

    function setUp() public {
        vm.warp(1669961536);

        vm.deal(bob, 1000 ether);
        vm.deal(charlee, 1000 ether);

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

        changePrank(bob);

        uint256 price = nft.getGDAPrice(
            toDaysWadUnsafe(block.timestamp - nft.startTime()),
            nft.totalSold() + 1
        );
        uint256 tokenId = nft.mint{value: price}();

        vm.expectRevert();
        nft.safeTransferFrom(bob, alice, tokenId);
    }

    function test_steal() public {
        startHoax(alice);
        uint256 targetTokenId = nft.mint{value: uint256(INITIAL_PRICE)}();

        assertEq(nft.balanceOf(alice), 1, "alice balance not 1");
        assertEq(nft.ownerOf(targetTokenId), alice);

        changePrank(bob);
        uint256 price = nft.getGDAPrice(
            toDaysWadUnsafe(block.timestamp - nft.startTime()),
            nft.totalSold() + 1
        );

        uint256 tokenId = nft.mint{value: price}();

        assertEq(nft.balanceOf(bob), 1, "bob balance not 1");
        assertEq(nft.ownerOf(tokenId), bob);

        nft.steal(tokenId, targetTokenId);

        assertEq(nft.balanceOf(alice), 1, "alice balance not 1");
        assertEq(nft.balanceOf(bob), 1, "bob balance not 1");

        // token IDs should be swapped
        assertEq(nft.ownerOf(tokenId), alice); // before: alice owned targetTokenId
        assertEq(nft.ownerOf(targetTokenId), bob); // before: bob owned tokenId

        // approvals should be reset
        assertEq(
            nft.getApproved(tokenId),
            address(0),
            "tokenId approval not reset"
        );
        assertEq(
            nft.getApproved(targetTokenId),
            address(0),
            "targetTokenId approval not reset"
        );

        // stolen count should increment once for targetTokenId
        assertEq(
            nft.stolenCount(targetTokenId),
            1,
            "targetTokenId stolenCount not 1"
        );

        assertEq(nft.stolenCount(tokenId), 0, "tokenId stolenCount not 0");
    }

    function test_cannotStealBeyondChristmas() public {
        startHoax(alice);
        uint256 targetTokenId = nft.mint{value: uint256(INITIAL_PRICE)}();

        changePrank(bob);
        uint256 price = nft.getGDAPrice(
            toDaysWadUnsafe(block.timestamp - nft.startTime()),
            nft.totalSold() + 1
        );

        uint256 tokenId = nft.mint{value: price}();

        vm.warp(1671886800);

        vm.expectRevert(
            DirtySanta.DirtySanta__SwapsAndMintingDisabled.selector
        );
        nft.steal(tokenId, targetTokenId);
    }

    function test_cannotStealTokenIdThatDoesNotExist() public {
        startHoax(alice);
        uint256 tokenId = nft.mint{value: uint256(INITIAL_PRICE)}();

        vm.expectRevert(
            DirtySanta.DirtySanta__TargetTokenIdDoesNotExist.selector
        );
        nft.steal(tokenId, 1);
    }

    function test_cannotStealWithTokenIdNotOwned() public {
        startHoax(alice);
        uint256 targetTokenId = nft.mint{value: uint256(INITIAL_PRICE)}();

        changePrank(bob);
        uint256 price = nft.getGDAPrice(
            toDaysWadUnsafe(block.timestamp - nft.startTime()),
            nft.totalSold() + 1
        );
        uint256 tokenId = nft.mint{value: price}();

        changePrank(charlee);
        vm.expectRevert(DirtySanta.DirtySanta__NotNFTOwner.selector);
        nft.steal(tokenId, targetTokenId);
    }

    function test_cannotBeStolenMoreThanTwice() public {
        startHoax(alice);
        uint256 tokenIdA = nft.mint{value: uint256(INITIAL_PRICE)}();

        changePrank(bob);
        uint256 price = nft.getGDAPrice(
            toDaysWadUnsafe(block.timestamp - nft.startTime()),
            nft.totalSold() + 1
        );
        uint256 tokenIdB = nft.mint{value: price}();

        changePrank(charlee);
        price = nft.getGDAPrice(
            toDaysWadUnsafe(block.timestamp - nft.startTime()),
            nft.totalSold() + 1
        );
        uint256 tokenIdC = nft.mint{value: price}();

        nft.steal(tokenIdC, tokenIdB);

        assertEq(
            nft.stolenCount(tokenIdB),
            1,
            "tokenIdB stolenCount not 1 after first steal"
        );

        changePrank(alice);
        nft.steal(tokenIdA, tokenIdB);

        assertEq(
            nft.stolenCount(tokenIdB),
            2,
            "tokenIdB stolenCount not 2 after second steal"
        );

        changePrank(bob);
        vm.expectRevert(DirtySanta.DirtySanta__CannotBeStolen.selector);
        nft.steal(tokenIdC, tokenIdB);
    }
}
