// SPDX-License-Identifier:MIT
pragma solidity ^0.8.24;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
error MerkleAirdrop_InvalidProof();
error MerkleAirdrop_AlreadyClaimed();
error MerkleAirdrop_InvalidSignature();

contract MerkleAirdrop is EIP712 {
    using SafeERC20 for IERC20;
    bytes32 private immutable i_merkleRoot;
    IERC20 private immutable i_airdropToken;
    mapping(address claimant => bool) private s_hasClaimed;
    event Claim(address indexed account, uint256 amount);
    // It's good practice to pre-compute this hash: keccak256("AirdropClaim(address account,uint256 amount)")

    bytes32 private constant MESSAGE_TYPEHASH =
        0x810786b83997ad50983567660c1d9050f79500bb7c2470579e75690d45184163;

    // The struct representing the data to be signed
    struct AirdropClaim {
        address account;
        uint256 amount;
    }

    constructor(
        bytes32 merkleRoot,
        IERC20 airdropToken
    ) EIP712("MerkleAirdrop", "1") {
        i_merkleRoot = merkleRoot;
        i_airdropToken = airdropToken;
    }

    function claim(
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        if (s_hasClaimed[account]) {
            revert MerkleAirdrop_AlreadyClaimed();
        }

        bytes32 digest = getMessage(account, amount);
        // Verify the signature
        if (!_isValidSignature(account, digest, v, r, s)) {
            revert MerkleAirdrop_InvalidSignature();
        }

        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(account, amount)))
        );

        if (!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)) {
            revert MerkleAirdrop_InvalidProof();
        }
        s_hasClaimed[account] = true;
        emit Claim(account, amount);

        i_airdropToken.safeTransfer(account, amount);
    }

    function getMessage(
        address account,
        uint256 amount
    ) public view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(
                MESSAGE_TYPEHASH,
                AirdropClaim({account: account, amount: amount})
            )
        );

        // 2. Combine with domain separator using _hashTypedDataV4 from EIP712 contract
        // _hashTypedDataV4 constructs the EIP-712 digest:
        // keccak256(abi.encodePacked("\x19\x01", _domainSeparatorV4(), structHash))
        return _hashTypedDataV4(structHash);
    }

function _isValidSignature(
    address expectedSigner,
    bytes32 digest,
    uint8 v,
    bytes32 r,
    bytes32 s
) internal pure returns (bool) {
    // It's safer than the native ecrecover precompile because it includes checks against certain forms of signature malleability.

    (address actualSigner, ECDSA.RecoverError err,) =
        ECDSA.tryRecover(digest, v, r, s);

    if (err != ECDSA.RecoverError.NoError) {
        return false;
    }

    return actualSigner != address(0) && actualSigner == expectedSigner;
}


    function getMerkleRoot() external view returns (bytes32) {
        return i_merkleRoot;
    }

    function getAirdropToken() external view returns (IERC20) {
        return i_airdropToken;
    }
}
