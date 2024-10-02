// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {ERC721ReclaimableBaseTest} from "./ERC721Reclaimable.base.t.sol";
import {IERC721Reclaimable} from "../../src/interfaces/IERC721Reclaimable.sol";
import {ERC721Reclaimable} from "../../src/ERC721Reclaimable.sol";

contract ERC721ReclaimableTitleTransferFromTest is ERC721ReclaimableBaseTest {
    function executeTitleTransfer(
        address caller,
        address from,
        address to,
        uint256 tokenId,
        uint256 fee
    ) private {
        vm.deal(caller, fee);
        vm.prank(caller);
        nft.titleTransferFrom{ value: fee }(from, to, tokenId);
    }

    function testTitleTransferFromRevertsForInsuffcientFunds(uint256 amount) public {
        amount = bound(amount, 0, nft.titleTransferFee() - 1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ERC721Reclaimable.InsufficientTitleTransferFee.selector,
                address(this),
                address(1),
                1,
                amount
            )
        );
        executeTitleTransfer({
            caller: address(this),
            from: address(this),
            to: address(1),
            tokenId: 1,
            fee: amount
        });
    }

    function testTitleTransferFromCallableByTitleOwner() public {
        executeTitleTransfer({
            caller: address(this),
            from: address(this),
            to: address(0),
            tokenId: 0,
            fee: nft.titleTransferFee()
        });
    }

    function testTitleTransferFromCallableByTokenApprovedOperator() public {
        nft.titleApprove(address(1), 2);
        executeTitleTransfer({
            caller: address(1),
            from: address(this),
            to: address(0),
            tokenId: 2,
            fee: nft.titleTransferFee()
        });
    }

    function testTitleTransferFromCallableByAllApprovedOperator() public {
        nft.setTitleApprovalForAll(address(1), true);
        executeTitleTransfer({
            caller: address(1),
            from: address(this),
            to: address(0),
            tokenId: 0,
            fee: nft.titleTransferFee()
        });
        executeTitleTransfer({
            caller: address(1),
            from: address(this),
            to: address(0),
            tokenId: 1,
            fee: nft.titleTransferFee()
        });
    }

    function testTitleTransferFromChangesTitleOwner() public {
        executeTitleTransfer({
            caller: address(this),
            from: address(this),
            to: address(1),
            tokenId: 9,
            fee: nft.titleTransferFee()
        });
        assertEq(nft.titleOwnerOf(9), address(1));
    }

    function testTitleTransferFromAdjustsTitleBalances(address receiver) public {
        vm.assume(receiver != address(this) && receiver != address(0));
        uint256 titleBalanceBeforeFrom = nft.titleBalanceOf(address(this));
        uint256 titleBalanceBeforeTo = nft.titleBalanceOf(receiver);

        executeTitleTransfer({
            caller: address(this),
            from: address(this),
            to: receiver,
            tokenId: 1,
            fee: nft.titleTransferFee()
        });

        assertEq(nft.titleBalanceOf(address(this)), titleBalanceBeforeFrom - 1);
        assertEq(nft.titleBalanceOf(receiver), titleBalanceBeforeTo + 1);
    }

    function testTitleTransferFromTransfersTheTitleFee() public {
        uint balanceBefore = TITLE_FEE_RECIPIENT.balance;
        executeTitleTransfer({
            caller: address(this),
            from: address(this),
            to: address(1),
            tokenId: 9,
            fee: nft.titleTransferFee()
        });
        uint balanceAfter = TITLE_FEE_RECIPIENT.balance;
        assertEq(balanceAfter - balanceBefore, nft.titleTransferFee());
    }

    function testTitleTransferFromDoesNotChangeAssetOwnership() public {
        executeTitleTransfer({
            caller: address(this),
            from: address(this),
            to: address(1),
            tokenId: 3,
            fee: nft.titleTransferFee()
        });
        assertEq(nft.ownerOf(3), address(this));
    }

    function testTitleTransferFromEmitsTitleTransferEvent() public {
        vm.expectEmit(true, true, true, true);
        emit IERC721Reclaimable.TitleTransfer(address(this), address(5), 1);
        executeTitleTransfer({
            caller: address(this),
            from: address(this),
            to: address(5),
            tokenId: 1,
            fee: nft.titleTransferFee()
        });
    }
}