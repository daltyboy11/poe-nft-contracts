// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {ERC721ReclaimableBaseTest} from "./ERC721Reclaimable.base.t.sol";
import {IERC721Reclaimable} from "../../src/interfaces/IERC721Reclaimable.sol";

contract ERC721ReclaimableTitleOwnerOfTest is ERC721ReclaimableBaseTest {
    function testTrueForTitleOwner() public view {
        assertEq(nft.titleOwnerOf(0), address(this));
    }

    function testFalseForRandomAddress(address notOwner) public view {
        vm.assume(notOwner != address(this));
        assertNotEq(nft.titleOwnerOf(0), notOwner);
    }

    function testFalseForApprovedOperator(address approvedOperator) public {
        vm.assume(approvedOperator != address(this));
        nft.titleApprove(approvedOperator, 1);
        assertNotEq(nft.titleOwnerOf(1), approvedOperator);
    }

    function testFalseForAllApprovedOperator(address allApprovedOperator) public {
        vm.assume(allApprovedOperator != address(this));
        nft.setTitleApprovalForAll(allApprovedOperator, true);
        assertNotEq(nft.titleOwnerOf(1), allApprovedOperator);
    }
}