# Dirty Santa NFT

**An NFT project inspired by a [BowTiedPickle](https://twitter.com/BowTiedPickle/status/1596617232897159168) post.**

## Setup

- Install [Foundry](https://github.com/foundry-rs/foundry).
- To run all tests, in command line enter:

```sh
forge test
```

## Exercise Description

Problem specification from project brief:

- [x] ERC-721 NFT
  - Changed some private mappings to internal. Mappings changed: `_owners`, `_balances`, `tokenApprovals`.
- [x] Public mint
  - Minting enabled upon contract deployment.
  - Maximum mintable: 1000.
- [x] After minting, users can swap their NFT for another eligible NFT.
  - Users can steal an eligible `targetTokenId` by offering up their NFT with `tokenId` in exchange.
- [x] Each wallet can only hold one NFT at any time.
  - Checked in the `_beforeTokenTransfer` hook.
- [x] Each NFT can only be stolen twice, then it is protected from future swap attempts.
  - Tracked in the `stolenCount` mapping.
- [x] Swaps and minting disabled on Sun Dec 25 2022 00:00:00 GMT+0000.

Optional specifications:

- [x] Instant reveal.
  - Fake `_baseURIExtended` storage variable initialised in the constructor.
- [x] Pricing mechanism (e.g. VRGDA, Dutch auction).
  - Discrete GDA implemented (see acknowledgements for references used).

## Testing

Test coverage:

- `test_initialPrice`: price should be `INITIAL_PRICE` when 0 days passed and 0 NFTs sold.
- `test_mintNFT`: user can mint an NFT.
- `test_cannotUnderpayForNFT`: user cannot underpay for an NFT.
- `test_cannotMintMoreThanOneNFT`: user cannot mint more than one NFT (wallet limit holds).
- `test_mintingStopsAtChristmas`: at Sun Dec 25 2022 00:00:00 GMT+0000, users cannot mint an NFT.
- `test_cannotReceiveNFTWhenAlreadyOwnOne`: user cannot receive an NFT from another wallet if they already own one (wallet limit holds).
- `test_steal`: a user that owns an NFT, can steal the NFT of another user assuming conditions for stealing are satisfied.
- `test_cannotStealBeyondChristmas`: users cannot steal an NFT from another user after Sun Dec 25 2022 00:00:00 GMT+0000.
- `test_cannotStealTokenIdThatDoesNotExist`: user cannot steal a tokenId that doesn't exist.
- `test_cannotStealWithTokenIdNotOwned`: user cannot steal an NFT with a tokenID that they don't own.
- `test_cannotBeStolenMoreThanTwice`: a tokenId that has already been stolen twice, cannot be stolen again by another user.
- `test_tokenURI`: emits tokenURI for tokenId = 0 (after minting).

## Acknowledgements

- [FrankieIsLost](https://twitter.com/FrankieIsLost) for the gradual Dutch auction [repo](https://github.com/FrankieIsLost/gradual-dutch-auction).
- [Transmissions11](https://twitter.com/transmissions11) for VRGDA [repo](https://github.com/transmissions11/VRGDAs).
- Gradual Dutch Auction [article](https://www.paradigm.xyz/2022/04/gda#discrete-gda) from Paradigm.
- OpenZeppelin: [Extending Contracts](https://docs.openzeppelin.com/contracts/3.x/extending-contracts#using-hooks).
- [Solmate](https://github.com/transmissions11/solmate).
