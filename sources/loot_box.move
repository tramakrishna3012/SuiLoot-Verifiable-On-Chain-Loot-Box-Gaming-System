module loot_box::loot_box {
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::event;
    use sui::random::{Self, Random};
    use sui::dynamic_field as df;
    use std::string::{Self, String};
    use std::vector;
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::balance::{Self, Balance};

    // --- Errors ---
    const EInvalidRarityWeights: u64 = 1;
    const EInsufficientPayment: u64 = 2;

    // --- Objects ---

    /// Admin Capability to manage game settings
    public struct AdminCap has key, store {
        id: UID,
    }

    /// Shared Game Configuration storing price, weights, and treasury
    public struct GameConfig has key {
        id: UID,
        price: u64,
        rarity_weights: vector<u8>,
        treasury: Balance<SUI>,
    }

    /// Owned Loot Box purchased by the user
    public struct LootBox has key, store {
        id: UID,
    }

    /// Owned Game Item NFT generated from the Loot Box
    public struct GameItem has key, store {
        id: UID,
        name: String,
        rarity: u8, // 0: Common, 1: Uncommon, 2: Rare, 3: Epic, 4: Legendary
        stats: u64,
    }

    // --- Events ---

    /// Event emitted when a Game Item is minted
    public struct ItemMintedEvent has copy, drop {
        item_id: ID,
        rarity: u8,
        minter: address,
        is_pity: bool,
    }
    
    // --- Dynamic Field Keys ---

    /// Key for the pity counter stored on the GameConfig per user
    public struct PityKey has copy, drop, store {
        user: address
    }

    // --- Functions ---

    /// Initialize the game, creating AdminCap and shared GameConfig.
    fun init(ctx: &mut TxContext) {
        let admin_cap = AdminCap {
            id: object::new(ctx),
        };
        transfer::public_transfer(admin_cap, tx_context::sender(ctx));

        let config = GameConfig {
            id: object::new(ctx),
            price: 1_000_000_000, // Default 1 SUI
            rarity_weights: vector[50, 30, 15, 4, 1], // 50% Common, 30% Unc, 15% Rare, 4% Epic, 1% Leg
            treasury: balance::zero(),
        };
        transfer::share_object(config);
    }

    /// Test initialization helper
    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }

    /// Purchase a LootBox by paying the exact SUI amount.
    public fun purchase_loot_box(
        config: &mut GameConfig,
        payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        assert!(coin::value(&payment) >= config.price, EInsufficientPayment);
        
        let coin_balance = coin::into_balance(payment);
        balance::join(&mut config.treasury, coin_balance);

        let loot_box = LootBox {
            id: object::new(ctx),
        };
        // Transfer the newly created LootBox to the purchaser
        transfer::public_transfer(loot_box, tx_context::sender(ctx));
    }

    /// Open a LootBox to receive a GameItem. Uses on-chain randomness.
    /// Restricted to `entry` function ensuring PTB composability cannot abuse random checks to revert.
    entry fun open_loot_box(
        config: &mut GameConfig,
        loot_box: LootBox,
        r: &Random,
        ctx: &mut TxContext
    ) {
        let LootBox { id } = loot_box;
        object::delete(id);

        let user = tx_context::sender(ctx);
        let mut is_pity = false;

        // Fetch user's pity counter
        let pity_key = PityKey { user };
        let mut user_opens = 0u64;
        if (df::exists_(&config.id, pity_key)) {
            user_opens = *df::borrow(&config.id, pity_key);
        };
        
        let mut rarity = 0u8;
        
        if (user_opens >= 99) {
            // Guaranteed Legendary after 99 unsuccessful tries
            rarity = 4; // Legendary
            is_pity = true;
            // Reset counter
            if (df::exists_(&config.id, pity_key)) {
                let count_mut = df::borrow_mut<PityKey, u64>(&mut config.id, pity_key);
                *count_mut = 0;
            };
        } else {
            // Select rarity using random generator
            let mut generator = random::new_generator(r, ctx);
            let rand_val = random::generate_u8_in_range(&mut generator, 0, 99);
            
            let mut cumulative_weight = 0u8;
            let mut i = 0;
            let mut found = false;
            while (i < 5 && !found) {
                cumulative_weight = cumulative_weight + *vector::borrow(&config.rarity_weights, i);
                if (rand_val < cumulative_weight) {
                    rarity = (i as u8);
                    found = true;
                };
                i = i + 1;
            };

            // Update pity counter
            if (rarity == 4) {
                // Reset pity on Legendary pull
                if (df::exists_(&config.id, pity_key)) {
                    let count_mut = df::borrow_mut<PityKey, u64>(&mut config.id, pity_key);
                    *count_mut = 0;
                };
            } else {
                // Increment pity
                if (df::exists_(&config.id, pity_key)) {
                    let count_mut = df::borrow_mut<PityKey, u64>(&mut config.id, pity_key);
                    *count_mut = *count_mut + 1;
                } else {
                    df::add(&mut config.id, pity_key, 1u64);
                };
            }
        };

        // Define item names based on rarity tiers
        let mut item_name = string::utf8(b"Unknown");
        if (rarity == 0) { item_name = string::utf8(b"Common Sword"); };
        if (rarity == 1) { item_name = string::utf8(b"Uncommon Shield"); };
        if (rarity == 2) { item_name = string::utf8(b"Rare Armor"); };
        if (rarity == 3) { item_name = string::utf8(b"Epic Ring"); };
        if (rarity == 4) { item_name = string::utf8(b"Legendary Crown"); };

        let item = GameItem {
            id: object::new(ctx),
            name: item_name,
            rarity,
            stats: ((rarity as u64) + 1) * 15, // Calculated stats per tier
        };

        event::emit(ItemMintedEvent {
            item_id: object::id(&item),
            rarity,
            minter: user,
            is_pity,
        });

        transfer::public_transfer(item, user);
    }

    /// Admin function to update rarity probabilities
    public fun update_rarity_weights(
        _: &AdminCap,
        config: &mut GameConfig,
        new_weights: vector<u8>,
        _ctx: &mut TxContext
    ) {
        let mut sum = 0u64;
        let mut i = 0;
        let len = vector::length(&new_weights);
        while (i < len) {
            sum = sum + (*vector::borrow(&new_weights, i) as u64);
            i = i + 1;
        };
        // Expect weights to add up to 100
        assert!(sum == 100, EInvalidRarityWeights);
        assert!(len == 5, EInvalidRarityWeights);
        
        config.rarity_weights = new_weights;
    }

    /// Get stats of an item
    public fun get_item_stats(item: &GameItem): (String, u8, u64) {
        (item.name, item.rarity, item.stats)
    }

    /// Transfer item to someone else (could be custom logic inserted)
    public fun transfer_item(item: GameItem, recipient: address) {
        transfer::public_transfer(item, recipient);
    }

    /// Burn/destroy item
    public fun burn_item(item: GameItem) {
        let GameItem { id, name: _, rarity: _, stats: _ } = item;
        object::delete(id);
    }
}
