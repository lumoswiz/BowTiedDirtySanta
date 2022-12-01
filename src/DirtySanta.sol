// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ERC721} from "openzeppelin-contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "openzeppelin-contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";

import "prb-math/SD59x18.sol";

contract DirtySanta is ERC721, ERC721Enumerable, Ownable {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------
    error DirtySanta__AlreadyOwnNFT();

    error DirtySanta__InsufficientPayment();

    error DirtySanta__UnableToRefund();

    /// -----------------------------------------------------------------------
    /// Immutable variables
    /// -----------------------------------------------------------------------
    uint256 public immutable maxSupply;

    uint256 public immutable walletLimit;

    SD59x18 internal immutable initialPrice;
    SD59x18 internal immutable scaleFactor;
    SD59x18 internal immutable decayConstant;
    SD59x18 internal immutable auctionStartTime;

    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------
    string private _baseURIextended;

    uint256 private currentIndex = 0;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------
    constructor(
        string memory _uri,
        uint256 _maxSupply,
        uint256 _walletLimit,
        SD59x18 _initialPrice,
        SD59x18 _scaleFactor,
        SD59x18 _decayConstant
    ) ERC721("Dirty Santa", "DIRTYSANTA") {
        _baseURIextended = _uri;
        maxSupply = _maxSupply;
        walletLimit = _walletLimit;
        initialPrice = _initialPrice;
        scaleFactor = _scaleFactor;
        decayConstant = _decayConstant;
        auctionStartTime = sd(int256(block.timestamp));
    }

    /// -----------------------------------------------------------------------
    /// User actions
    /// -----------------------------------------------------------------------

    /// @notice purchase a specific number of tokens from the GDA
    function purchaseToken(address to) public payable {
        if (balanceOf(msg.sender) != 0) revert DirtySanta__AlreadyOwnNFT();

        uint256 cost = purchasePrice(1);

        if (msg.value < cost) revert DirtySanta__InsufficientPayment();

        // mint a token
        _mint(to, ++currentIndex);

        // refund extra payment
        uint256 refund = msg.value - cost;
        (bool sent, ) = msg.sender.call{value: refund}("");
        if (!sent) revert DirtySanta__UnableToRefund();
    }

    /// -----------------------------------------------------------------------
    /// View functions
    /// -----------------------------------------------------------------------

    /// @notice calculate purchase price using exponential discrete GDA formula
    function purchasePrice(uint256 numTokens) public view returns (uint256) {
        SD59x18 quantity = sd(int256(numTokens));
        SD59x18 numSold = sd(int256(currentIndex));
        SD59x18 timeSinceStart = sd(int256(block.timestamp)).sub(
            auctionStartTime
        );

        SD59x18 num1 = initialPrice.mul(scaleFactor.pow(numSold));
        SD59x18 num2 = scaleFactor.pow(quantity).sub(sd(int256(1)));
        SD59x18 den1 = decayConstant.mul(timeSinceStart).exp();
        SD59x18 den2 = scaleFactor.sub(sd(int256(1)));

        uint256 totalCost = uint256(
            fromSD59x18(num1.mul(num2).div(den1.mul(den2)))
        );

        return totalCost;
    }

    /// -----------------------------------------------------------------------
    /// Overrides
    /// -----------------------------------------------------------------------

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
