//Its used for interacting with deployed airdrop contract
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {MerkleAirdrop} from "../../src/MerkleAirdrop.sol";

contract ClaimAirdrop is Script {
    bytes32[] public PROOF;

    uint8 v = 27; // Or 0x1c
    bytes32 r =
        0x17a20c3780a6520e68207746fddc9a31b1f94ae5d5f72504b09404afc8b65cd9;
    bytes32 s =
        0x60a50d353a784f2f2ebcac7f9bc82edf63dae3d04fed05c4b38463274cd77d75;

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "MerkleAirdrop",
            block.chainid
        );
        claimAirdrop(mostRecentlyDeployed);
    }

    function claimAirdrop(address airdropContractAddress) public {
        address MERKLE_AIRDROP_CONTRACT=0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512;
        address CLAIMING_ADDRESS = 0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D; // Example address
        uint256 CLAIMING_AMOUNT = 2500 * 1e18; // Example: 25 tokens with 18 decimals
        bytes32 PROOF_ONE = 0x9e10faf86d92c4c65f81ac54ef2a27cc0fdf6bfea6ba4b1df5955e47f187115b; // Example proof element
        bytes32 PROOF_TWO = 0x8c1fd7b608678f6dfced176fa3e3086954e8aa495613efcd312768d41338ceab;
        PROOF.push(PROOF_ONE);
        PROOF.push(PROOF_TWO);
        vm.startBroadcast();
        MerkleAirdrop(MERKLE_AIRDROP_CONTRACT).claim(
            CLAIMING_ADDRESS,
            CLAIMING_AMOUNT,
            proof, // Pass the Merkle proof
            v, // Pass the 'v' component of the signature
            r, // Pass the 'r' component of the signature
            s // Pass the 's' component of the signature
        );
        vm.stopBroadcast();
    }
}
