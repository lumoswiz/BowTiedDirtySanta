// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "forge-std/Test.sol";

import {DirtySanta} from "../src/DirtySanta.sol";

contract DirtySantaTest is Test {
    DirtySanta internal nft;

    string internal URI =
        "ipfs://BmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/";

    int256 internal constant INITIAL_PRICE = 1e18;
    int256 internal constant SCALE_FACTOR = 1.2e18;
    int256 internal constant DECAY_CONSTANT = 0.5e18;

    function setUp() public {
        nft = new DirtySanta(INITIAL_PRICE, SCALE_FACTOR, DECAY_CONSTANT);
    }

    function test_initialPrice() public {
        uint256 price = nft.getGDAPrice(0, 0);
        assertEq(uint256(INITIAL_PRICE), price);
    }
}
