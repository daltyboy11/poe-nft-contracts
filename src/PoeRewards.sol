// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {ERC721Reclaimable} from "./ERC721Reclaimable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract PoeRewards {
    /// @notice Poe NFT contract
    ERC721Reclaimable public immutable erc721;

    /// @notice Amount in ETH paid out for a correct guess
    uint256 public immutable payoutAmount;

    /// @notice True if the correct answer was already submitted for the token
    mapping(uint256 tokenId => bool) public answered;

    /// @notice After the rewards period ends the rewards beneficiary can reclaim any unclaimed rewards
    uint256 public immutable endsAt;

    /// @notice The address that is authorized to reclaim unclaimed rewards when the rewards period ends
    address public immutable leftoverRewardsBeneficiary;

    uint256 public nonce = 0;

    mapping(uint256 tokenId => address answerAddress) private answerAddresses;

    constructor(
        ERC721Reclaimable _erc721,
        uint256 _payoutAmount,
        uint256[] memory _tokenIds,
        address[] memory _answerAddresses,
        uint256 _endsAt,
        address _leftoverRewardsBeneficiary
    ) payable {
        require(
            _tokenIds.length == _answerAddresses.length,
            "Invalid constructor input"
        );
        require(
            msg.value >= _tokenIds.length * _payoutAmount,
            "Insufficient funds for payouts"
        );
        erc721 = _erc721;
        payoutAmount = _payoutAmount;
        for (uint i = 0; i < _tokenIds.length; ++i) {
            answerAddresses[_tokenIds[i]] = _answerAddresses[i];
        }
        endsAt = _endsAt;
        leftoverRewardsBeneficiary = _leftoverRewardsBeneficiary;
    }

    /**
     * The title owner can submit a guess for which Edgar Allan Poe story inspired their token
     * art. The signature is an ERC-191 compliant signature of the token ID and the contract nonce.
     * 
     * A valid guess is when the recovered address corresponds to the saved `answerAddress`, which is
     * an EOA whose private key seed is a concatenation of the raw story title and its token ID.
     */
    function submitGuess(uint256 tokenId, uint8 v, bytes32 r, bytes32 s) external {
        require(block.timestamp < endsAt, RewardsEnded());
        require(!answered[tokenId], AlreadyAnswered(tokenId)); 

        address titleOwner = erc721.titleOwnerOf(tokenId);
        require(msg.sender == titleOwner, NotTitleOwner(tokenId));

        if (verifyAnswer(tokenId, nonce, v, r, s)) {
            nonce += 1;
            answered[tokenId] = true;
            (bool success, ) = payable(msg.sender).call{value: payoutAmount}("");
            require(success, TransferFailed(msg.sender));
            emit TokenAnswered(tokenId);
        }
    }

    function verifyAnswer(uint256 tokenId, uint256 _nonce, uint8 v, bytes32 r, bytes32 s) private view returns (bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(tokenId, _nonce));
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(messageHash);
        address answerAddress = answerAddresses[tokenId];
        address signer = ecrecover(ethSignedMessageHash, v, r, s);
        return signer == answerAddress;
    }

    /**
     * Once the rewards period is over, the leftoever rewards beneficiary can reclaim rewards. At this point, the rewards
     * program has ended and you can no longer submit guesses.
     */
    function claimLeftoverRewards() external {
        require(msg.sender == leftoverRewardsBeneficiary, NotLeftoverRewardsBeneficiary());
        require(block.timestamp > endsAt, RewardsStillClaimable());
        uint256 remainingBalance = address(this).balance;
        require(remainingBalance > 0, NoRewardsToClaim());
        // Send all remaining ETH to leftoverRewardsBeneficiary
        (bool success, ) = leftoverRewardsBeneficiary.call{value: remainingBalance}("");
        require(success, LeftoverRewardsTransferFailed());     
    }
}

event TokenAnswered(uint256 indexed tokenId);
error NotTitleOwner(uint256 tokenId);
error NotLeftoverRewardsBeneficiary();
error RewardsStillClaimable();
error RewardsEnded();
error NoRewardsToClaim();
error LeftoverRewardsTransferFailed();
error AlreadyAnswered(uint256 tokenId);
error TransferFailed(address recipient);