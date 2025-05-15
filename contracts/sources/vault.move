module YieldAggregator::Vault {
    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::aptos_coin::AptosCoin;
    use std::signer;
    use aptos_std::simple_map::{Self, SimpleMap};
    
    struct Vault has key {
        total_assets: u64,
        total_shares: u64,
        user_shares: SimpleMap<address, u64>,
        reserves: Coin<AptosCoin>
    }
    
    public entry fun initialize(admin: &signer) {
        move_to(admin, Vault {
            total_assets: 0,
            total_shares: 0,
            user_shares: simple_map::create(),
            reserves: coin::zero<AptosCoin>()
        });
    }
    
    public entry fun deposit(user: &signer, amount: u64) acquires Vault {
        let user_addr = signer::address_of(user);
        let vault = borrow_global_mut<Vault>(@YieldAggregator);
        
        // Transfer APT from user
        let coins = coin::withdraw<AptosCoin>(user, amount);
        coin::merge(&mut vault.reserves, coins);
        
        // Calculate shares
        let shares = if (vault.total_shares == 0) {
            amount
        } else {
            (amount * vault.total_shares) / vault.total_assets
        };
        
        // Update user shares
        if (simple_map::contains_key(&vault.user_shares, &user_addr)) {
            let user_shares = simple_map::borrow_mut(&mut vault.user_shares, &user_addr);
            *user_shares = *user_shares + shares;
        } else {
            simple_map::add(&mut vault.user_shares, user_addr, shares);
        };
        
        vault.total_shares = vault.total_shares + shares;
        vault.total_assets = vault.total_assets + amount;
    }
    
    public entry fun withdraw(user: &signer, shares: u64) acquires Vault {
        let user_addr = signer::address_of(user);
        let vault = borrow_global_mut<Vault>(@YieldAggregator);
        
        // Calculate amount to withdraw
        let amount = (shares * vault.total_assets) / vault.total_shares;
        
        // Update user shares
        let user_shares = simple_map::borrow_mut(&mut vault.user_shares, &user_addr);
        *user_shares = *user_shares - shares;
        
        // Update totals
        vault.total_shares = vault.total_shares - shares;
        vault.total_assets = vault.total_assets - amount;
        
        // Transfer APT to user
        let coins = coin::extract(&mut vault.reserves, amount);
        coin::deposit(user_addr, coins);
    }
}
