// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title IERC721Reclaimable: NFT interface with title ownership and reclaim rights
/// @notice This interface extends the concept of NFT ownership to include both asset ownership
/// and title ownership, allowing for a reclaim mechanism and fixed transfer fees. Inspired by
/// the a16zcrypto article https://a16zcrypto.com/posts/article/how-nft-royalties-work/
/// @author Dalton G. Sweeney
/// @dev The ownership model can be visualized as follows:
///
///      +----------------+        +----------------+
///      |   Asset Owner  |        |   Title Owner  |
///      |    (0xabc...)  |        |    (0x123...)  |
///      +----------------+        +----------------+
///              ^                         ^
///              |                         |
///              |        +--------+       |
///              +--------|  NFT   |-------+
///                       +--------+
///
/// Asset ownership = Standard ERC721 ownership
/// Title ownership = Additional layer of ownership with reclaim rights
///                   Transferring title requires paying a fixed fee
///
/// Key operations:
///
/// 1. Transfer title (does NOT transfer asset):
///    +----------------+        +----------------+       +----------------+
///    |   Asset Owner  |        |   Title Owner  |       |  Fee Recipient |
///    |    (0xabc...)  |        |    (0x123...)  |       |    (0xfee...)  |
///    +----------------+        +----------------+       +----------------+
///            |                          |                        |
///            |                          |  Fixed Fee             |
///            |                          | +--------------------> |
///            |                          |                        |
///            |                          |                        |
///            |                          v                        |
///            |                 +----------------+                |
///            |                 | New Title Owner|                |
///            |                 |    (0x789...)  |                |
///                              +----------------+
///
/// 2. Transfer asset (does NOT transfer title):
///    +----------------+        +----------------+
///    |   Asset Owner  |        |   Title Owner  |
///    |    (0xabc...)  |        |    (0x123...)  |
///    +----------------+        +----------------+
///            |                          |
///            v                          |
///    +----------------+                 |
///    | New Asset Owner|                 |
///    |    (0xdef...)  |                 |
///    +----------------+                 |
///
/// 3. Title owner reclaims asset:
///    +----------------+        +----------------+
///    |   Asset Owner  |        |   Title Owner  |
///    |    (0xdef...)  |        |    (0x123...)  |
///    +----------------+        +----------------+
///            |                          |
///            |                          |
///            |         reclaim          |
///            <--------------------------+
///            |                          |
///            v                          v
///    +----------------+        +----------------+
///    |  Asset & Title |        |   Title Owner  |
///    |    (0x123...)  |        |    (0x123...)  |
///    +----------------+        +----------------+
///
/// The title owner can reclaim the NFT at any time if the asset owner differs.
/// This mechanism incentivizes paying the transfer fee (royalty) when transferring ownership,
/// while allowing free transfers between personal wallets.
interface IERC721Reclaimable {
    /// @dev This emits when title of an NFT changes by any mechanism. This event emits when NFTs are
    ///  created (`from` == 0) and destroyed (`to` == 0). At the time of any title transfer, the title
    ///  approved address for that NFT (if any) is reset to none.
    event TitleTransfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the title approved address for an NFT is changed or reaffirmed. The zero
    ///  address indicates there is no approved address. When a TitleTransfer event emits, this also
    ///  indicates that the title approved address for that NFT (if any) is reset to none.
    event TitleApproval(address indexed _titleOwner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an title operator is enabled or disabled for a title owner.
    ///  The title operator can manage the titles for all NFTs of the title owner
    event TitleApprovalForAll(address indexed _titleOwner, address indexed _titleOperator, bool _approved);

    /// @dev This emits when ownership of an NFT is claimed by a title owner or title operator
    event OwnershipClaim(address indexed _titleOwner, address indexed _assetOwner, uint256 indexed _tokenId);

    /// @notice The fixed fee required for transferring an NFT's title 
    function titleTransferFee() external view returns (uint256);

    /// @notice The recipient of the title transfer fee when a transfer is executed
    function titleTransferFeeRecipient() external view returns (address);

    /// @notice Count all NFT titles assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _titleOwner An address for whom to query the balance
    /// @return The number of NFT titles owned by `_titleOwner`, possibly zero
    function titleBalanceOf(address _titleOwner) external view returns (uint256);

    /// @notice Find the title owner of an NFT
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the title owner of the NFT
    function titleOwnerOf(uint256 _tokenId) external view returns (address);

    /// @notice Claim ownership of an NFT
    /// @dev Throws unless `msg.sender` is the title owner
    /// @dev Emits a ERC721.Transfer event
    /// @param _tokenId The NFT to claim ownership for
    function claimOwnership(uint256 _tokenId) external payable; 

    /// @notice Transfer the NFT's title -- THE CALLER IS RESPONSIBLE TO CONFIRM THAT `to` IS
    ///  CAPABLE OF RECEIVING NFTS OR ELSE THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the title owner, an authorized title operator, or the
    ///  title-approved address for this NFT.
    /// @dev Throws unless `msg.value` is at least the titleTransferFee
    /// @param _from The current title owner of an NFT
    /// @param _to The new title owner
    /// @param _tokenId The NFT whose title to transfer
    function titleTransferFrom(address _from, address _to, uint256 _tokenId) external payable; 

    /// @notice Set or reaffirm the approved address for an NFT's title.
    /// @dev Throws unless `msg.sender` is the current NFT title owner, or an authorized title
    ///  operator of the current owner
    /// @param _approved The new approved NFT title controller
    /// @param _tokenId The NFT to approve
    function titleApprove(address _approved, uint256 _tokenId) external payable;

    /// @notice Enable or disable title approval for a third party ("titleOperator") to manage
    ///  titles for all of `msg.sender`'s assets
    /// @param _titleOperator Address to add to the set of authorized title operators
    /// @param _approved True if the title operator is approved, false to revoke approval
    function setTitleApprovalForAll(address _titleOperator, bool _approved) external;

    /// @notice Get the approved title address for a single NFT
    /// @param _tokenId  The NFT to find the approved title address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getTitleApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized titleOperator for another address
    /// @param _titleOwner The address that owns the NFT's title
    /// @param _titleOperator The address that acts on behalf of the title owner
    /// @return True if `titleOperator` is an approved operator for `titleOwner`, false otherwise
    function isTitleApprovedForAll(address _titleOwner, address _titleOperator) external view returns (bool); 
}
