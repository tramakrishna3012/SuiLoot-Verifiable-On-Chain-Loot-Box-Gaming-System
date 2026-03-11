#[test_only]
module loot_box::loot_box_tests {
    use sui::test_scenario::{Self as ts};
    use sui::coin;
    use sui::sui::SUI;
    use sui::random::{Self, Random};
    use loot_box::loot_box::{Self, GameConfig, LootBox, GameItem};
    use std::vector;

    #[test]
    fun test_purchase_and_open() {
        let user = @0xAAAA;
        let mut scenario = ts::begin(user);

        // 1. Initial configuration
        random::create_for_testing(ts::ctx(&mut scenario));
        loot_box::init_for_testing(ts::ctx(&mut scenario));
        ts::next_tx(&mut scenario, user);

        // 2. Buy Box
        let mut config = ts::take_shared<GameConfig>(&scenario);
        let payment = coin::mint_for_testing<SUI>(1_000_000_000, ts::ctx(&mut scenario));
        loot_box::purchase_loot_box(&mut config, payment, ts::ctx(&mut scenario));
        ts::return_shared(config);
        ts::next_tx(&mut scenario, user);
        
        // 3. Open Box
        let lootbox = ts::take_from_sender<LootBox>(&scenario);
        let mut config = ts::take_shared<GameConfig>(&scenario);
        let mut r = ts::take_shared<Random>(&scenario);
        
        // Mock randomness update - bytes provide entropy
        random::update_randomness_state_for_testing(
            &mut r,
            0,
            x"00112233445566778899AABBCCDDEEFF00112233445566778899AABBCCDDEEFF",
            ts::ctx(&mut scenario)
        );

        loot_box::open_loot_box(&mut config, lootbox, &r, ts::ctx(&mut scenario));

        ts::return_shared(config);
        ts::return_shared(r);
        ts::next_tx(&mut scenario, user);

        // 4. Verify properties of the received NFT
        let item = ts::take_from_sender<GameItem>(&scenario);
        let (_, rarity, _) = loot_box::get_item_stats(&item);
        
        assert!(rarity <= 4, 1);
        
        loot_box::burn_item(item);
        ts::end(scenario);
    }

    #[test]
    fun test_pity_system_triggers() {
        let user = @0xBBBB;
        let mut scenario = ts::begin(user);

        // Initialization
        random::create_for_testing(ts::ctx(&mut scenario));
        loot_box::init_for_testing(ts::ctx(&mut scenario));
        ts::next_tx(&mut scenario, user);

        // Seed random state deterministically
        let mut r = ts::take_shared<Random>(&scenario);
        random::update_randomness_state_for_testing(
            &mut r,
            0,
            x"0000000000000000000000000000000000000000000000000000000000000000",
            ts::ctx(&mut scenario)
        );
        ts::return_shared(r);
        ts::next_tx(&mut scenario, user);

        // Fast-forward user tries by manually triggering opening 100 times.
        let mut i = 0;
        while (i < 100) {
            let mut config = ts::take_shared<GameConfig>(&scenario);
            let payment = coin::mint_for_testing<SUI>(1_000_000_000, ts::ctx(&mut scenario));
            loot_box::purchase_loot_box(&mut config, payment, ts::ctx(&mut scenario));
            ts::return_shared(config);
            ts::next_tx(&mut scenario, user);

            let lootbox = ts::take_from_sender<LootBox>(&scenario);
            let mut config = ts::take_shared<GameConfig>(&scenario);
            let r_ref = ts::take_shared<Random>(&scenario);
            
            loot_box::open_loot_box(&mut config, lootbox, &r_ref, ts::ctx(&mut scenario));
            
            ts::return_shared(config);
            ts::return_shared(r_ref);
            ts::next_tx(&mut scenario, user);
            
            let item = ts::take_from_sender<GameItem>(&scenario);
            let (_, rarity, _) = loot_box::get_item_stats(&item);
            
            // On 100th pull (i=99), we must receive a legendary (rarity 4) due to pity. 
            if (i == 99) {
                assert!(rarity == 4, 100);
            };

            loot_box::burn_item(item);
            i = i + 1;
        };

        ts::end(scenario);
    }
}
