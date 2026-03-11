# Sui Loot Box Smart Contract

This is a complete Loot Box smart contract system built on Sui Move.

## Features
- **On-Chain Randomness:** Uses the `sui::random` feature to ensure verifiable and fair randomness when generating loot. 
- **NFT Minting & Rarity Tiers:** Mints `GameItem` NFTs with 5 distinct rarity tiers (Common, Uncommon, Rare, Epic, Legendary).
- **Strict Sui Object Model:** Utilizes Shared Objects, Owned Objects, Dynamic Fields, and Capabilities following Sui best practices.
- **Pity System:** Implements a pity counter using dynamic fields on the shared `GameConfig` to guarantee a Legendary item after 99 unsuccessful pulls.
- **Security First:** The `open_loot_box` function is strictly marked as `entry`. When an entry function accesses `&Random`, the Sui execution model ensures Programmable Transaction Blocks (PTB) cannot compute based on the random result and intentionally revert if the outcome is unfavourable.

## Objects
1. `GameConfig`: A shared object holding the price of the loot box, rarity weights, treasury balances, and dynamic fields acting as user pity counters.
2. `AdminCap`: An owned Object giving admin privileges to update the rarity weights.
3. `LootBox`: An owned Object purchased by users, which can be consumed to generate a `GameItem`.
4. `GameItem`: An owned NFT representing the in-game item received from the Loot Box, with full `key, store` capability to be transferred or traded.

## Methods
- `init_game`: Triggered on deployment, initializing the `GameConfig` and sending `AdminCap` to the deployer.
- `purchase_loot_box`: Takes SUI from the user, deposits it into the treasury, and mints an un-opened `LootBox`.
- `open_loot_box`: An `entry`-only function. Consumes the `LootBox`. Safely uses `&Random` to roll for rarity, resets or increments the dynamic field pity counter, and mints the `GameItem`. 
- `update_rarity_weights`: Modifies drop chances. Requires `&AdminCap`.
- Built-in utilities to read item stats, transfer, or burn NFTs.

## Requirements
- Sui CLI `2024.beta` edition
- Deploy on Sui Testnet/Mainnet `sui move build`

## Instructions
1. Run `sui move test` to verify the logic and the mock randomness flow for the pity system.
2. The logic simulates user purchases and fully emulates randomness safely on-chain.
