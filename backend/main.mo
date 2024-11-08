import Bool "mo:base/Bool";
import Text "mo:base/Text";

import Timer "mo:base/Timer";
import Random "mo:base/Random";
import Array "mo:base/Array";
import HashMap "mo:base/HashMap";
import Hash "mo:base/Hash";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Debug "mo:base/Debug";
import Buffer "mo:base/Buffer";
import Option "mo:base/Option";
import Blob "mo:base/Blob";

actor LuckySavings {
    // Stable storage
    private stable var userBalancesEntries : [(Principal, Nat)] = [];
    private stable var transactionHistoryEntries : [(Principal, Text, Int, Int)] = [];
    private stable var isInitialized : Bool = false;

    // Runtime state
    private var userBalances = HashMap.HashMap<Principal, Nat>(10, Principal.equal, Principal.hash);
    private var transactionHistory = Buffer.Buffer<(Principal, Text, Int, Int)>(0);
    private var timerID : Nat = 0;

    // Initialize state from stable storage
    system func preupgrade() {
        userBalancesEntries := Iter.toArray(userBalances.entries());
        transactionHistoryEntries := Buffer.toArray(transactionHistory);
    };

    system func postupgrade() {
        for ((principal, balance) in userBalancesEntries.vals()) {
            userBalances.put(principal, balance);
        };
        for (entry in transactionHistoryEntries.vals()) {
            transactionHistory.add(entry);
        };
    };

    // Public initialization function
    public shared func init() : async () {
        if (not isInitialized) {
            isInitialized := true;
            await startRewardTimer();
        };
    };

    // Start the reward timer when the canister is deployed
    private func startRewardTimer() : async () {
        timerID := Timer.setTimer(#seconds(3600), func() : async () {
            await selectAndRewardWinner();
        });
    };

    // Helper function to get a random number
    private func getRandomNumber(max : Nat) : async Nat {
        let seed = await Random.blob();
        let randomBytes = Blob.toArray(seed);
        let randomNum = Nat8.toNat(randomBytes[0]);
        randomNum % max;
    };

    // Select and reward a random winner
    private func selectAndRewardWinner() : async () {
        let users = Iter.toArray(userBalances.keys());
        if (users.size() > 0) {
            let randomIndex = await getRandomNumber(users.size());
            let winner = users[randomIndex];
            let currentBalance = Option.get(userBalances.get(winner), 0);
            let reward = 100; // Fixed reward of 100 tokens
            userBalances.put(winner, currentBalance + reward);
            transactionHistory.add((winner, "REWARD", reward, Time.now()));
        };
        // Set the next timer
        ignore startRewardTimer();
    };

    // Public functions
    public shared(msg) func deposit(amount : Nat) : async Bool {
        let caller = msg.caller;
        let currentBalance = Option.get(userBalances.get(caller), 0);
        userBalances.put(caller, currentBalance + amount);
        transactionHistory.add((caller, "DEPOSIT", amount, Time.now()));
        true
    };

    public shared(msg) func withdraw(amount : Nat) : async Bool {
        let caller = msg.caller;
        let currentBalance = Option.get(userBalances.get(caller), 0);
        if (currentBalance >= amount) {
            userBalances.put(caller, currentBalance - amount);
            transactionHistory.add((caller, "WITHDRAW", -1 * amount, Time.now()));
            true
        } else {
            false
        };
    };

    public query(msg) func getBalance() : async Nat {
        Option.get(userBalances.get(msg.caller), 0)
    };

    public query func getTransactionHistory(user : Principal) : async [(Text, Int, Int)] {
        let userTransactions = Buffer.Buffer<(Text, Int, Int)>(0);
        for ((principal, txType, amount, timestamp) in transactionHistory.vals()) {
            if (Principal.equal(principal, user)) {
                userTransactions.add((txType, amount, timestamp));
            };
        };
        Buffer.toArray(userTransactions)
    };
}
