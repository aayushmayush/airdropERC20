// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {BagelToken} from "../src/BagelToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MerkleAirdropTest is Test {
    MerkleAirdrop public airdrop;
    BagelToken public token;
    bytes32 public ROOT =
        0xa4d8c8776abd94bb36f381cff5af341303a00299fe70e1c3ba365f7004c4d0b2;
    uint256 public AMOUNT_TO_CLAIM = 2500 * 1e18; // Example claim amount for the test user
    uint256 public AMOUNT_TO_SEND; // Total tokens to fund the airdrop contract

    address user;
    uint256 userPrivKey; // Private key for the test user
    bytes32[] public PROOF;

    // bytes32 proofOne=0x9e10faf86d92c4c65f81ac54ef2a27cc0fdf6bfea6ba4b1df5955e47f187115b;
    // bytes32 proofTwo=0x8c1fd7b608678f6dfced176fa3e3086954e8aa495613efcd312768d41338ceab;
    // bytes32[2] public PROOF=[proofOne,proofTwo];

    function setUp() public {
        token = new BagelToken();

        (user, userPrivKey) = makeAddrAndKey("testUser");

        airdrop = new MerkleAirdrop(ROOT, IERC20(address(token)));

        AMOUNT_TO_SEND = AMOUNT_TO_CLAIM * 4;

        address owner = address(this);

        token.mint(owner, AMOUNT_TO_SEND);

        token.transfer(address(airdrop), AMOUNT_TO_SEND);

        PROOF.push(
            0x9e10faf86d92c4c65f81ac54ef2a27cc0fdf6bfea6ba4b1df5955e47f187115b
        );
        PROOF.push(
            0x8c1fd7b608678f6dfced176fa3e3086954e8aa495613efcd312768d41338ceab
        );
    }

    function testUsersCanClaim() public {
        // 1. Get the user's starting token balance
        uint256 startingBalance = token.balanceOf(user);

        // 2. Simulate the claim transaction from the user's address
        // `vm.prank(address)` sets `msg.sender` for the *next* external call only.
        vm.prank(user);

        // 3. Call the claim function on the airdrop contract
        airdrop.claim(user, AMOUNT_TO_CLAIM, PROOF);

        // 4. Get the user's ending token balance
        uint256 endingBalance = token.balanceOf(user);

        // For debugging, you can log the ending balance:
        console.log("User's Ending Balance: ", endingBalance);

        // 5. Assert that the balance increased by the expected claim amount
        assertEq(
            endingBalance - startingBalance,
            AMOUNT_TO_CLAIM,
            "User did not receive the correct amount of tokens"
        );
    }
}
