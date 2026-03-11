import { ConnectButton, useCurrentAccount } from '@mysten/dapp-kit';
import { useState } from 'react';
import { LootBoxPanel } from './components/LootBox';
import { Background3D } from './components/Background3D';

function App() {
  const account = useCurrentAccount();
  const [pityCount, setPityCount] = useState(0);

  const handleOpenBox = (isLegendary: boolean) => {
    if (isLegendary) {
      setPityCount(0);
    } else {
      setPityCount(prev => prev + 1);
    }
  };

  return (
    <>
      <Background3D />
      <div className="app-container">
        <header className="header">
          <div className="logo">
            <h2>📦 Sui Loot Box</h2>
          </div>
          <ConnectButton />
        </header>
        <main>
          {!account ? (
            <div className="welcome">
              <h1>Unlock Epic Items on Sui</h1>
              <p>Connect your wallet to purchase and open Loot Boxes.</p>
            </div>
          ) : (
            <div className="dashboard">
              <div className="dashboard-header">
                <div>
                  <h2>Welcome to the Vault</h2>
                  <p>Connected: {account.address.slice(0, 6)}...{account.address.slice(-4)}</p>
                </div>
                <div className="pity-counter">
                  Pity Count: <span>{pityCount} / 99</span>
                </div>
              </div>
              <LootBoxPanel onOpenBox={handleOpenBox} />
            </div>
          )}
        </main>
      </div>
    </>
  );
}

export default App;
