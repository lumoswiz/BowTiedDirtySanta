// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import {ERC721} from "./ERC721.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";

import {GDA} from "./GDA.sol";

import {toDaysWadUnsafe, toWadUnsafe} from "solmate/utils/SignedWadMath.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

contract DirtySanta is ERC721, GDA, Ownable {
    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------
    event Stolen(
        address indexed thief,
        uint256 indexed tokenId,
        uint256 indexed targetTokenId,
        address victim
    );

    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------
    error DirtySanta__MaximumAlreadyMinted();

    error DirtySanta__Underpaid();

    error DirtySanta__CannotExceedWalletLimit();

    error DirtySanta__SwapsAndMintingDisabled();

    error DirtySanta__TargetTokenIdDoesNotExist();

    error DirtySanta__CannotBeStolen();

    error DirtySanta__NotNFTOwner();

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
    /// Steal storage
    /// -----------------------------------------------------------------------

    /// @dev tokenId => number of times stolen
    mapping(uint256 => uint256) public stolenCount;

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

        uint256 price = getGDAPrice(
            toDaysWadUnsafe(block.timestamp - startTime),
            mintedId = totalSold++
        );

        if (msg.value < price) revert DirtySanta__Underpaid();

        _mint(msg.sender, mintedId);

        SafeTransferLib.safeTransferETH(msg.sender, msg.value - price);
    }

    /// -----------------------------------------------------------------------
    /// Steal logic
    /// -----------------------------------------------------------------------

    function steal(uint256 tokenId, uint256 targetTokenId) external {
        /*=== Checks ===*/
        if (block.timestamp >= 1671886800)
            revert DirtySanta__SwapsAndMintingDisabled();

        if (_exists(targetTokenId) != true)
            revert DirtySanta__TargetTokenIdDoesNotExist();

        if (ownerOf(tokenId) != msg.sender) revert DirtySanta__NotNFTOwner();

        if (stolenCount[targetTokenId] == 2)
            revert DirtySanta__CannotBeStolen();

        /*=== Storage loads ===*/

        address targetOwner = ownerOf(targetTokenId);

        /*=== State updates ===*/

        delete _tokenApprovals[tokenId];
        delete _tokenApprovals[targetTokenId];

        _owners[targetTokenId] = msg.sender;
        _owners[tokenId] = targetOwner;

        stolenCount[targetTokenId]++;

        emit Stolen(msg.sender, tokenId, targetTokenId, targetOwner);
    }

    /// -----------------------------------------------------------------------
    /// Overrides
    /// -----------------------------------------------------------------------

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (block.timestamp >= 1671886800)
            revert DirtySanta__SwapsAndMintingDisabled();

        if (balanceOf(msg.sender) != 0)
            revert DirtySanta__CannotExceedWalletLimit();
    }
}
