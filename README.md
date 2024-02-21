# VotreX Voting System
The true Decentralized voting system.

** This smart contract mainly written initially on top of ethereum language and still in tought of main layer of ethereum.
I have currently consideration for implementation into L1 or L2 Ethereum network to achieve natural performance. Which network?
That is still currently in deep review.

## ** New notes about Blockchain Network :
Currently i tried to develop in Flare Network,
i also have consideration to make special token that will be used for registration instead of native FLR.



## Release Candidate Contract Version A 
What's new in this release:

1. Full Smart Contract Restructurization
2. Rename Contract to match latest system project name
3. Remodel Election status (introduced preparation status)
4. Remodel Election start and end time time stamping
5. Add new Pricing Fee for Registration (static pricing)
6. Add Digital Signature for Election Result
7. Add new Vote Power Mechanism

### Features 📢:

1. Ultra optimized contract, ✅
2. Could be use by multiple organization separately, ✅
3. Administrative function directly from smart contract, ✅
4. Election Event currently limited to 100 Events, ✅
5. 3 States of Election Event, ⚠️
6. Voter/Member of Organization limited around 4500  per organization, And organizations limited to 3200 ✅
7. Final Election / Vote result also have its own storage that stored in blockchain. ✅
8. 2 available organization per user. It can be 2 times as voter in 2 organization, or 1 Voter + Election Admin in different org, or 2 times as election admin in 2 different organizations.
9. 

### Smart Contract flow consideration ✒️ :

1. For schedule election still pending.
2. For the final election result, i have consideration to store this info into web3.storage, after taken Election data from smart contract.
3. For digital signature, it only to create hash signature, but i still not create the verify function yet.
4. New Vote power introduced with vote power limit to 5 vote power
5. Introduced new Tokenization scheme.

