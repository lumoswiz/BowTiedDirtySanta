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

- ERC-721 NFT
- Public mint
- After minting, users can swap their NFT for another eligible NFT.
- Each wallet can only hold one NFT at any time.
- Each NFT can only be stolen twice, then it is protected from future swap attempts.
- Swaps and minting disabled on 25/12/2022 (1671886800).

Optional specifications:

- Instant reveal.
- Pricing mechanism (e.g. VRGDA, Dutch auction).

## Testing

## Acknowledgements

- [FrankieIsLost](https://twitter.com/FrankieIsLost) for the gradual Dutch auction [repo](https://github.com/FrankieIsLost/gradual-dutch-auction).
- [Solmate](https://github.com/transmissions11/solmate).
- [Transmissions11](https://twitter.com/transmissions11) for VRGDA [repo](https://github.com/transmissions11/VRGDAs).
- OpenZeppelin: [Extending Contracts](https://docs.openzeppelin.com/contracts/3.x/extending-contracts#using-hooks).
