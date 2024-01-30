# Random Raffle Contract

## About

This code is to create a proveably random smart contract raffle lottery.

## Features

1. Users can enter the lottery by sending a fixed amount of ETH to the contract.
2. The contract periodically picks a random winner from the pool of players using Chainlink VRF.
3. The winner receives the entire balance of the contract as a reward.
4. The contract uses Chainlink VRF to automate the process of requesting and fulfilling random numbers.

## Tools

* Chainlink VRF
* Solmate
* Foundry

## Installation

1. Clone the repository:

```bash
git clone https://github.com/PhantomOz/raffle-lottery.git
```
2. Install Libraries
```bash
make install
```
3. Compile
```bash
make build
```

for more info you run `make help`

## Tests!

To run tests locally on anvil you can just do
```bash
make test
```

## Live Address

Here is the live address to the verified smart contract on the sepolia testnet 
`0x820e3344daD54a086015cd210cead72390e12127`

made with ❤️ by Favour Aniogor.

