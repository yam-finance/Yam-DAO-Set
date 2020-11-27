# 🍠 Yam DAO Set 🍠

# Development

## Building

This repo uses truffle and `dapptest` for testing. Most of the updated tests were done using dapptest, while deployment will be handled by truffle. Some tests weren't transfered over from v1, particularly around governance.

Then, to build the contracts for deployment run:

```
$ truffle compile
```

To run tests, install Nix and dapptools:

```
$ curl -L https://nixos.org/nix/install > nix.sh
$ nix-env -iA dapp hevm -f https://github.com/dapphub/dapptools/tarball/master -v
```

Running tests:

```
$ export ETH_RPC_URL=http://localhost:8545 # mainnet node
$ ./scripts/dapp-test.sh
```