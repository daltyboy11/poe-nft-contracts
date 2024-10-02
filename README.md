## Poe NFT

This is the repository for Poe NFT smart contracts. Poe NFT is the first collection to implement title transfers and the right of reclaim (explained in [this article](https://a16zcrypto.com/posts/article/how-nft-royalties-work/)).

This project combines my love for Edgar Allan Poe's stories with my passion for crypto and smart contract programming.

**View the collection**: https://www.poenft.com/

### IERC721Reclaimable.sol and ERC721Reclaimable.sol
`IERC721Reclaimable` is the interface I devised for title transfers and the right of reclaim. You can think of it as
a two tiered ownership system.

Layer 1 is the traditional asset ownership concept of ERC-721: `ownerOf`, `approve`, `transfer`, etc.

Layer 2 is the new concept of title ownership. Title ownership is a stronger form of ownership than asset ownership. It has functions analagous to Layer 1 like `titleOwnerOf`, `titleApprove`, `titleTransfer`, ..., with two additional features:

1. A fixed ETH fee for transferring title ownership
2. The `claimOwnership` function, callable by the title owner, that will transfer asset ownership back to the title owner.

When the asset and title owners are different entities, you can think of the token as being rented out to the asset owner. To fully own the token, you must own the title.

`ERC721Reclaimable` is my canonical implementation of this new standard.

### PoeRewards.sol
I created a rewards contract to spice up the collection.