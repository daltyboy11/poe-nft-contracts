// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {ERC721ReclaimableMintable} from "./ERC721ReclaimableMintable.sol";
import {
    PoeRewards,
    AlreadyAnswered,
    NotTitleOwner,
    TokenAnswered,
    RewardsStillClaimable,
    NotLeftoverRewardsBeneficiary,
    RewardsEnded
} from "../src/PoeRewards.sol";

contract PoeRewardsTest is Test {
    ERC721ReclaimableMintable public erc721;
    uint256 public payoutAmount;
    PoeRewards public poeRewards;

    uint8 v_token0_nonce0 = 27;
    bytes32 r_token0_nonce0 = 0x168297575ea76a62c156924ab0b8cc6d7a819281d225a7c84009cca1b262226e;
    bytes32 s_token0_nonce0 = 0x079ca67c2f8dd8f8dbe80fb8b94bf9a17b17a67ade0856cd804e3af76b9ca2cf;

    uint8 v_token1_nonce0 = 27;
    bytes32 r_token1_nonce0 = 0xa435abe687e714bac8b6ab36b6100e931ae65e973318dd3673e3e850c6ea9494;
    bytes32 s_token1_nonce0 = 0x0b3f567bba56d3e7f931155c62f5a9220e3df8a74ed68bb8bf6ed30fa23c7055;

    uint8 v_token1_nonce1 = 27;
    bytes32 r_token1_nonce1 = 0xdfaf3d3a4c59cada4c2ac018b580c486529d97d6c71235de43bd5350f0b97b66;
    bytes32 s_token1_nonce1 = 0x35b266b6bb2707e3b230d588a8ec7c1165362b07a888ff844ae98f3d1b0e46ac;

    address leftoverRewardsBeneficiary = 0xfFfFFFEEEeeEaA5b98D4B51220383faA5ad7bbD2;

    function setUp() public {
        erc721 = new ERC721ReclaimableMintable({
            name: "Poe NFT",
            symbol: "PNFT",
            titleTransferFee: 0.0001 ether,
            titleFeeRecipient: address(this),
            minter: address(this),
            mintAmount: 3
        });

        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = 0;
        tokenIds[1] = 1;
        tokenIds[2] = 2;

        address[] memory answerAddresses = new address[](3);
        answerAddresses[0] = 0xeA3543748fB3a677c9273cB221b25480B661dc41; // The Devil in the Belfry
        answerAddresses[1] = 0x1A3594C86a8d22C7B877210b9ced045d813d95F9; // Diddling Considered as One of the Exact Sciences
        answerAddresses[2] = 0x27Aee44e21D3aA5b98D4b51220383faa5AD7BbD2; // The Imp of the Perverse

        payoutAmount = 0.02 ether;
        uint256 payoutFunds = payoutAmount * 3;
        vm.deal(address(this), payoutFunds);
        poeRewards = new PoeRewards{ value: payoutFunds } ({
            _erc721: erc721,
            _payoutAmount: 0.02 ether,
            _tokenIds: tokenIds,
            _answerAddresses: answerAddresses,
            _endsAt: block.timestamp + 1,
            _leftoverRewardsBeneficiary: leftoverRewardsBeneficiary
        });
    }

    function testRevertsIfCallerIsNotTitleOwner() public {
        address notTitleOwner = address(uint160(1));
        vm.startPrank(notTitleOwner);
        vm.expectRevert(
            abi.encodeWithSelector(
                NotTitleOwner.selector,
                0
            )
        );
        poeRewards.submitGuess(0, 0, bytes32(0), bytes32(0));
    }

    function testGuessingAfterCorrectGuessReverts() public {
        poeRewards.submitGuess(0, v_token0_nonce0, r_token0_nonce0, s_token0_nonce0);
        vm.expectRevert(
            abi.encodeWithSelector(
                AlreadyAnswered.selector,
                0
            )
        );
        poeRewards.submitGuess(0, v_token0_nonce0, r_token0_nonce0, s_token0_nonce0);
    }

    function testCorrectGuessExecutesPayout() public {
        uint256 balanceBefore = address(this).balance;
        poeRewards.submitGuess(0, v_token0_nonce0, r_token0_nonce0, s_token0_nonce0);
        uint256 balanceAfter = address(this).balance;
        assertEq(balanceAfter, balanceBefore + payoutAmount);
    } 

    function testCorrectGuessEmitsEvent() public {
        vm.expectEmit(true, false, false, true);
        emit TokenAnswered(0);
        poeRewards.submitGuess(0, v_token0_nonce0, r_token0_nonce0, s_token0_nonce0);
    }

    function testCorrectGuessMarksTokenAsAnswered() public {
        poeRewards.submitGuess(0, v_token0_nonce0, r_token0_nonce0, s_token0_nonce0);
        assertTrue(poeRewards.answered(0));
    }

    function testCorrectGuessMustMatchCurrentNonce() public {
        // Successful guess on first token, nonce = 0
        poeRewards.submitGuess(0, v_token0_nonce0, r_token0_nonce0, s_token0_nonce0);
        assertTrue(poeRewards.answered(0));

        // Second token nonce 0 does not work
        poeRewards.submitGuess(1, v_token1_nonce0, r_token1_nonce0, s_token1_nonce0);
        assertFalse(poeRewards.answered(1));

        // Successful guess on second token, nonce = 1
        poeRewards.submitGuess(1, v_token1_nonce1, r_token1_nonce1, s_token1_nonce1);
        assertTrue(poeRewards.answered(1));
    }

    function executeTitleTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 fee
    ) private {
        vm.deal(from, fee);
        vm.prank(from);
        erc721.titleTransferFrom{ value: fee }(from, to, tokenId);
    }

    function testClaimLeftoversBeforeEndReverts() public {
        vm.prank(leftoverRewardsBeneficiary);
        vm.expectRevert(abi.encodeWithSelector(RewardsStillClaimable.selector));
        poeRewards.claimLeftoverRewards();
    }

    function testClaimLeftoverRewardsAsNonBeneficiaryReverts() public {
        vm.expectRevert(abi.encodeWithSelector(NotLeftoverRewardsBeneficiary.selector));
        poeRewards.claimLeftoverRewards();
    }

    function testSubmitGuessAfterEndsAtReverts() public {
        vm.warp(poeRewards.endsAt() + 1);
        vm.expectRevert(abi.encodeWithSelector(RewardsEnded.selector));
        poeRewards.submitGuess(0, v_token0_nonce0, r_token0_nonce0, s_token0_nonce0);
    }

    function testClaimLeftoverRewardsAfterEndAsBeneficiaryWorks() public {
        vm.warp(poeRewards.endsAt() + 1);
        vm.prank(leftoverRewardsBeneficiary);
        uint256 claimableRewards = address(poeRewards).balance;
        uint256 beneficiaryBalanceBefore = leftoverRewardsBeneficiary.balance;
        poeRewards.claimLeftoverRewards();
        uint256 beneficiaryBalanceAfter = leftoverRewardsBeneficiary.balance;
        assertEq(beneficiaryBalanceAfter, beneficiaryBalanceBefore + claimableRewards);
        assertEq(address(poeRewards).balance, 0);
    }

    receive() external payable {}
}