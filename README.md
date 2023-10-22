# DU-vote-v2
or in complete
# Decentralized Unified E-Voters
The true Decentralized voting system.



# Initial Dev Package Release 
What's new in this release:

1. Full smart contract release

Features 📢:
1. Multiple Organization ready ✅
2. Administrative function directly from smart contract ✅
3. Election Event currently limited to 100 Events ✅
4. Voter limited around  281.474.976.710.656 but the id more restricted to 120.000.000.000.000 ✅
5. Final Election / Vote result also have its own storage that stored in blockchain ✅

Smart Contract flow consideration ✒️:

1. Currently i still not sure for block time stamp that include currently in contract.
It could be overriden by startElection function, but it is actually still not meets my expectation.
The actual design is to create some scheduled Election Event. In near future i will redesign this schedule flow.
2. For the final election result, i have consideration to store this info into web3.storage,after taken Election data from smart contract

