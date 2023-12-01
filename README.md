# VotreX Voting System
The true Decentralized voting system.

** This smart contract mainly written initially on top of ethereum language and still in tought of main layer of ethereum.
I have currently consideration for implementation into L1 or L2 Ethereum network to achieve natural performance. Which network?
That is still currently in deep review.

## ** New notes about Blockchain Network :
Currently i tried to develop in Flare Network,
i also have consideration to make special token that will be used for registration instead of native FLR.



## Initial on-Dev Release 
What's new in this release:

1. Full Smart Contract Restructurization
2. Rename Contract to match latest system project name
3. Remodel Election status (introduced preparation status)
4. Remodel Election start and end time time stamping
5. Add new Pricing Fee for Registration (static pricing)
6. Add Digital Signature for Election Result

### Features 📢:

1. Ultra optimized contract, ⚠️
2. Could be use by multiple organization separately, ✅
3. Administrative function directly from smart contract, ✅
4. Election Event currently limited to 100 Events, ✅
5. 3 States of Election Event, ⚠️
6. Voter/Member of Organization limited around 281.474.976.710.656  per organization,but the id more restricted to 120.000.000.000.000, ✅
7. Final Election / Vote result also have its own storage that stored in blockchain. ✅
8. 1 Address per Organization for both voter and election admin

### Smart Contract flow consideration ✒️ :

1. ⚠️At this release, timestamp stamped while election started. Either from direct start, or schedule.
2. For schedule election still not working at all. you still need to force start the election.
3. For the final election result, i have consideration to store this info into web3.storage, after taken Election data from smart contract.
4. For digital signature, it only to create hash signature, but i still not create the verify function yet.
5. ⚠️ About contract optimization, it is currently use pretty high gas cost even after using auto optimized in remix. Probably because highly relied to blockchain storage, i still working on this optimization to achieve lower gas cost in smart contract and easy to connect to front-end, keeps the true decentralized nature and may impact the performance of whole system.

