# VotreX Voting System
The true Decentralized voting system.

** This smart contract mainly written initially on top of ethereum language and still in tought of main layer of ethereum.
I have currently consideration for implementation into L1 or L2 Ethereum network to achieve natural performance. Which network?
That is still currently in deep review.



## Initial on-Dev Release 
What's new in this release:

1. Full smart contract release (on initial-1 branches)
2. Front-End Layout Release (on initial-2 branches)

### Features 📢:

1. Ultra optimized contract, ⚠️
2. Could be use by multiple organization separately, ✅
3. Administrative function directly from smart contract, ✅
4. Election Event currently limited to 100 Events, ✅
5. 3 States of Election Event, ⚠️
6. Voter/Member of Organization limited around 281.474.976.710.656  per organization,but the id more restricted to 120.000.000.000.000, ✅
7. Final Election / Vote result also have its own storage that stored in blockchain. ✅

### Smart Contract flow consideration ✒️ :

1. ⚠️ Currently i still not sure for block time stamp that included currently in contract.
It could be overriden by startElection function, but it is actually still not meets my expectation.
The actual design is to create some scheduling Election Event. In near future i will redesign this schedule flow.
2. For the final election result, i have consideration to store this info into web3.storage, after taken Election data from smart contract.
3. ⚠️ About contract optimization, it is currently use pretty high gas cost even after using auto optimized in remix. Probably because highly relied to blockchain storage, i still working on this optimization to achieve lower gas cost in smart contract and easy to connect to front-end, keeps the true decentralized nature and may impact the performance of whole system.

