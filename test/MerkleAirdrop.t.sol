// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {BagelToken} from "../src/BagelToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ZkSyncChainChecker} from "lib/foundry-devops/src/ZkSyncChainChecker.sol"; // If using foundry-devops
import {DeployMerkleAirdrop} from "../script/DeployMerkleAirdrop.s.sol";

contract MerkleAirdropTest is ZkSyncChainChecker, Test {
    MerkleAirdrop public airdrop;
    BagelToken public token;
    bytes32 public ROOT =
        0xb1e815a99ee56f7043ed94e7e2316238187a59d85c211d06f9be7c5f94424aec;
    uint256 public AMOUNT_TO_CLAIM = 2500 * 1e18; // Example claim amount for the test user
    uint256 public AMOUNT_TO_SEND; // Total tokens to fund the airdrop contract

    address user;
    uint256 userPrivKey; // Private key for the test user
    bytes32[] public PROOF;

    // bytes32 proofOne=0x9e10faf86d92c4c65f81ac54ef2a27cc0fdf6bfea6ba4b1df5955e47f187115b;
    // bytes32 proofTwo=0x8c1fd7b608678f6dfced176fa3e3086954e8aa495613efcd312768d41338ceab;
    // bytes32[2] public PROOF=[proofOne,proofTwo];
    address public gasPayer;

    function setUp() public {
        if (!isZkSyncChain()) {
            // This check is from ZkSyncChainChecker
            // Deploy with the script
            DeployMerkleAirdrop deployer = new DeployMerkleAirdrop();
            (airdrop, token) = deployer.deployMerkleAirdrop();
        } else {
            // Original manual deployment for ZKsync environments (or other specific cases)
            token = new BagelToken();
            // Ensure 'ROOT' here is consistent with s_merkleRoot in the script
            airdrop = new MerkleAirdrop(ROOT, IERC20(address(token)));
            // Ensure 'AMOUNT_TO_SEND' here is consistent with s_amountToTransfer in the script
            token.mint(address(this), AMOUNT_TO_SEND);
            token.transfer(address(airdrop), AMOUNT_TO_SEND);
        }

        (user, userPrivKey) = makeAddrAndKey("user");
        console.log("The users address",user);
        
        gasPayer = makeAddr("gasPayer");
        console.log("The gaspayer address", gasPayer);
        vm.deal(gasPayer,20 ether);

        PROOF.push(
            0x9e10faf86d92c4c65f81ac54ef2a27cc0fdf6bfea6ba4b1df5955e47f187115b
        );
        PROOF.push(
            0x8c1fd7b608678f6dfced176fa3e3086954e8aa495613efcd312768d41338ceab
        );
    }

    function testUsersCanClaim() public {
        uint256 startingBalance = token.balanceOf(user);

        // 1. Get the message digest that the user needs to sign
        // This calls the getMessageHash function from the MerkleAirdrop contract
        bytes32 digest = airdrop.getMessageHash(user, AMOUNT_TO_CLAIM);

        // 2. User signs the digest using their private key
        // vm.sign is a Foundry cheatcode
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = vm.sign(userPrivKey, digest);

        // 3. The gasPayer calls the claim function with the user's signature
        vm.prank(gasPayer); // Set the next msg.sender to be gasPayer
        airdrop.claim(user, AMOUNT_TO_CLAIM, PROOF, v, r, s);

        uint256 endingBalance = token.balanceOf(user);
        console.log("Ending Balance: ", endingBalance);
        assertEq(endingBalance, startingBalance + AMOUNT_TO_CLAIM);
    }
}
