// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import {ERC721} from "openzeppelin-contracts/token/ERC721/ERC721.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";

import {GDA} from "./GDA.sol";

import {toDaysWadUnsafe, toWadUnsafe} from "solmate/utils/SignedWadMath.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

contract DirtySanta is ERC721, GDA, Ownable {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------
    error DirtySanta__MaximumAlreadyMinted();

    error DirtySanta__Underpaid();

    error DirtySanta__WalletBalanceNonZero();

    /// -----------------------------------------------------------------------
    /// Constants
    /// -----------------------------------------------------------------------
    uint256 public constant WALLET_LIMIT = 1;

    uint256 public constant MAX_MINTABLE = 1000;

    /// -----------------------------------------------------------------------
    /// Sales storage
    /// -----------------------------------------------------------------------
    uint256 public totalSold = 0;

    uint256 public immutable startTime = block.timestamp;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------
    constructor(
        int256 _initialPrice,
        int256 _scaleFactor,
        int256 _decayConstant
    )
        ERC721("Dirty Santa", "DIRTYSANTA")
        GDA(_initialPrice, _scaleFactor, _decayConstant)
    {}

    /// -----------------------------------------------------------------------
    /// Minting logic
    /// -----------------------------------------------------------------------

    function mint() external payable returns (uint256 mintedId) {
        if (totalSold > MAX_MINTABLE) revert DirtySanta__MaximumAlreadyMinted();

        if (balanceOf(msg.sender) != 0)
            revert DirtySanta__WalletBalanceNonZero();

        uint256 price = getGDAPrice(
            toDaysWadUnsafe(block.timestamp - startTime),
            mintedId = totalSold++
        );

        if (msg.value < price) revert DirtySanta__Underpaid();

        _mint(msg.sender, mintedId);

        SafeTransferLib.safeTransferETH(msg.sender, msg.value - price);
    }
}
