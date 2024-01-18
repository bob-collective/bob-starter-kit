## bitcoin-spv

> Forked from [keep-network/bitcoin-spv](https://github.com/keep-network/bitcoin-spv) which was forked from [summa-tx/bitcoin-spv](https://github.com/summa-tx/bitcoin-spv).

`bitcoin-spv` is a low-level toolkit for working with Bitcoin from other
blockchains. It supplies a set of pure functions that can be used to validate
almost all Bitcoin transactions and headers, as well as higher-level
functions that can evaluate header chains and transaction inclusion proofs.

It also supplies a standardized JSON format for proofs.

### What smart contract chains are supported?

This support any EVM-based chain such as Ethereum.

### Bitcoin Endianness

Block explorers tend to show txids and merkle roots in big-endian (BE) format.
Most human-facing apps do this as well. However, due to Satoshi's inscrutable
wisdom, almost all in-protocol data structures use little-endian (LE) byte
order.

When pulling txids and merkle nodes, make sure the endianness is correct

1. They should be in LE for the proof construction
1. They need to be in LE for hashing
1. They are in LE in the merkle tree

## Getting Started

We use foundry extensively for maintaining and testing this contract suite:

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### IMPORTANT WARNING

It is extremely easy to write insecure code using these libraries. We do not
recommend a specific security model. Any SPV verification involves complex
security assumptions. Please seek external review for your design before
building with these libraries.