## TDC smart contracts

Material referente aos workshops ministrados no TDC 2024 Sao Paulo.

Linkedin: [Afonso Dalvi](https://www.linkedin.com/in/afonso-dalvi-711635112/)

FanTonken deployado: [PolygonScan](https://amoy.polygonscan.com/address/0xbd1b775f7841c77b2cf767839b8f4197742f2f40)

Collection deployado: [PolygonScan](https://amoy.polygonscan.com/address/0xadbbea9629d7836160eae2c5d3b9fdb815e42d85#code)


Comandos:

```javascript
forge install
```

```javascript
forge test -vvvv
```

```javascript
make deploy network=amoy
```

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

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

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
