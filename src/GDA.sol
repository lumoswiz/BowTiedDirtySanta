// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import {wadExp, wadPow, wadMul, wadDiv, unsafeWadMul, toWadUnsafe} from "solmate/utils/SignedWadMath.sol";

abstract contract GDA {
    /// -----------------------------------------------------------------------
    /// GDA Parameters
    /// -----------------------------------------------------------------------

    int256 public immutable initalPrice;

    int256 public immutable scaleFactor;

    int256 public immutable decayConstant;

    constructor(
        int256 _initialPrice,
        int256 _scaleFactor,
        int256 _decayConstant
    ) {
        initalPrice = _initialPrice;
        scaleFactor = _scaleFactor;
        decayConstant = _decayConstant;
    }

    /// -----------------------------------------------------------------------
    /// Pricing logic
    /// -----------------------------------------------------------------------

    function getGDAPrice(int256 timeSinceStart, uint256 sold)
        public
        view
        virtual
        returns (uint256)
    {
        return
            uint256(
                wadDiv(
                    wadMul(initalPrice, wadPow(scaleFactor, toWadUnsafe(sold))),
                    wadExp(wadMul(decayConstant, timeSinceStart))
                )
            );
    }
}
