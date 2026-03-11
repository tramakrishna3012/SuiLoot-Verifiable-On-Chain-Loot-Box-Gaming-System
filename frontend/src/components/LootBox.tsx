import { useState } from 'react';
// import { useSignAndExecuteTransaction, useSuiClient } from '@mysten/dapp-kit';
import { Transaction } from '@mysten/sui/transactions';
import { CONTRACT } from '../config';
import { motion, AnimatePresence } from 'framer-motion';
import { PackageOpen, Sparkles, Coins } from 'lucide-react';

export function LootBoxPanel({ onOpenBox }: { onOpenBox: (isLegendary: boolean) => void }) {
  // const { mutateAsync: _signAndExecuteTransaction } = useSignAndExecuteTransaction();
  // const _suiClient = useSuiClient();

  const [loading, setLoading] = useState(false);
  const [hasBox, setHasBox] = useState(false);
  const [unlockedItem, setUnlockedItem] = useState<{ name: string; rarity: number } | null>(null);

  const handlePurchase = async () => {
    try {
      setLoading(true);
      const tx = new Transaction();
      
      // The box costs 1 SUI
      const [paymentCoin] = tx.splitCoins(tx.gas, [1_000_000_000]);

      tx.moveCall({
        target: `${CONTRACT.PACKAGE_ID}::loot_box::purchase_loot_box`,
        arguments: [
          tx.object(CONTRACT.GAME_CONFIG_ID),
          paymentCoin,
        ],
      });

      // Assuming success or using Devnet where we don't have real money right now
      // Let's visualize the "Box Acquired" state
      setTimeout(() => {
        setHasBox(true);
        setLoading(false);
      }, 1500);
      
      /* Real execution (commented out until contract is deployed):
      const res = await signAndExecuteTransaction({
        transaction: tx,
      });
      await suiClient.waitForTransaction({ digest: res.digest });
      */

    } catch (e) {
      console.error(e);
      setLoading(false);
    }
  };

  const handleOpen = async () => {
    try {
      setLoading(true);
      
      /* Real execution involves fetching the user's owned box ID and calling open_loot_box
      const tx = new Transaction();
      tx.moveCall({
         target: `${CONTRACT.PACKAGE_ID}::loot_box::open_loot_box`,
         arguments: [
           tx.object(CONTRACT.GAME_CONFIG_ID),
           tx.object(OWNED_BOX_ID),
           tx.object('0x8') // sui::random parameter
         ]
      })
      */

      // Mocking the result for UI visualization
      setTimeout(() => {
        const mockRarity = Math.random() > 0.9 ? 4 : Math.random() > 0.7 ? 3 : Math.random() > 0.4 ? 2 : 1;
        const mockNames = ["Common Sword", "Uncommon Shield", "Rare Armor", "Epic Ring", "Legendary Crown"];
        
        onOpenBox(mockRarity === 4); // Pass true if legendary to reset pity
        setUnlockedItem({ name: mockNames[mockRarity], rarity: mockRarity });
        setHasBox(false);
        setLoading(false);
      }, 2000);

    } catch (e) {
      console.error(e);
      setLoading(false);
    }
  };

  const reset = () => {
    setUnlockedItem(null);
  }

  // Rarity Colors Mapping
  const rarityColors = ['#94a3b8', '#10b981', '#3b82f6', '#a855f7', '#f59e0b'];
  const rarityShadows = [
    '0 0 10px #94a3b8', 
    '0 0 20px #10b981', 
    '0 0 30px #3b82f6', 
    '0 0 40px #a855f7', 
    '0 0 50px #f59e0b, 0 0 100px #f59e0b'
  ];

  return (
    <div className="loot-panel-container">
      <AnimatePresence mode="wait">
        {unlockedItem ? (
          <motion.div 
            key="unlocked"
            initial={{ scale: 0.5, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            className="item-reveal-card"
            style={{ 
              borderColor: rarityColors[unlockedItem.rarity],
              boxShadow: rarityShadows[unlockedItem.rarity]
            }}
          >
            <Sparkles size={48} color={rarityColors[unlockedItem.rarity]} className="sparkle-icon" />
            <h3 style={{ color: rarityColors[unlockedItem.rarity] }}>{unlockedItem.name}</h3>
            <span className="rarity-badge" style={{ backgroundColor: rarityColors[unlockedItem.rarity] }}>
               Tier {unlockedItem.rarity}
            </span>
            <button onClick={reset} className="btn btn-outline mt-4">Collect Item</button>
          </motion.div>
        ) : (
          <motion.div 
            key="box"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            className="box-interaction-area"
          >
            <motion.div 
              className={`mystery-box ${hasBox ? 'acquired' : ''}`}
              animate={loading && hasBox ? { rotate: [0, -10, 10, -10, 10, 0] } : {}}
              transition={{ repeat: Infinity, duration: 0.5 }}
            >
              <PackageOpen size={80} />
            </motion.div>

            <div className="action-buttons">
              {!hasBox ? (
                <button 
                  className="btn btn-primary" 
                  onClick={handlePurchase} 
                  disabled={loading}
                >
                  <Coins className="icon" size={18} />
                  {loading ? 'Purchasing...' : 'Buy Box (1 SUI)'}
                </button>
              ) : (
                <button 
                  className="btn btn-action shadow-glow" 
                  onClick={handleOpen}
                  disabled={loading}
                >
                  <Sparkles className="icon" size={18} />
                  {loading ? 'Unlocking...' : 'Open Loot Box'}
                </button>
              )}
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
