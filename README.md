# DevStarterKit

## Build on Bitcoin

BOB is a Bitcoin-augmented rollup bringing experimentation and freedom of choice to builders to make a real-world impact. BOBs vision is to onboard the next billion users to Bitcoin.

## Learn more

- [Website](https://www.gobob.xyz/)
- [Docs](https://docs.gobob.xyz/)
- [BOB Repository](https://github.com/bob-collective/bob)

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

### To Deploy HelloBitcoin Contract on testnet

```shell
export PRIVATE_KEY=<private_key>
export USDT_ADDRESS=0xF58de5056b7057D74f957e75bFfe865F571c3fB6
export RPC_URL=https://testnet.rpc.gobob.xyz
export VERIFIER_URL=https://testnet-explorer.gobob.xyz/api?

forge script script/HelloWorld.sol --rpc-url=$RPC_URL --broadcast --verify --verifier blockscout --verifier-url=$VERIFIER_URL
```