pragma solidity ^0.5.0;

import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

import "./Governance.sol";
import "./Verifier.sol";
import "./Operations.sol";


/// @title zkSync storage contract
/// @author Matter Labs
contract Storage {

    /// @notice Flag indicates that upgrade preparation status is active
    /// @dev Will store false in case of not active upgrade mode
    bool public upgradePreparationActive;

    /// @notice Upgrade preparation activation timestamp (as seconds since unix epoch)
    /// @dev Will be equal to zero in case of not active upgrade mode
    uint public upgradePreparationActivationTime;

    /// @notice Verifier contract. Used to verify block proof and exit proof
    Verifier internal verifier;

    /// @notice Governance contract. Contains the governor (the owner) of whole system, validators list, possible tokens list
    Governance internal governance;

    /// @notice Root-chain balances (per owner and token id) to withdraw
    mapping(address => mapping(uint16 => uint128)) public balancesToWithdraw;

    /// @notice verified withdrawal pending to be executed.
    struct PendingWithdrawal {
        address to;
        uint16 tokenId;
    }
    
    /// @notice Verified but not executed withdrawals for addresses stored in here (key is pendingWithdrawal's index)
    mapping(uint32 => PendingWithdrawal) public pendingWithdrawals;
    uint32 public firstPendingWithdrawalIndex;
    uint32 public numberOfPendingWithdrawals;

    /// @notice Total number of verified blocks i.e. blocks[totalBlocksVerified] points at the latest verified block (block 0 is genesis)
    uint32 public totalBlocksVerified;

    /// @notice Total number of committed blocks i.e. blocks[totalBlocksCommitted] points at the latest committed block
    uint32 public totalBlocksCommitted;

    /// @notice Rollup block data (once per block)
    /// @member validator Block producer
    /// @member committedAtBlock ETH block number at which this block was committed
    /// @member cumulativeOnchainOperations Total number of operations in this and all previous blocks
    /// @member priorityOperations Total number of priority operations for this block
    /// @member commitment Hash of the block circuit commitment
    /// @member stateRoot New tree root hash
    ///
    /// Consider memory alignment when changing field order: https://solidity.readthedocs.io/en/v0.4.21/miscellaneous.html
    struct Block {
        uint24 validatorId;
        uint32 committedAtBlock;
        uint64 cumulativeOnchainOperations;
        uint64 priorityOperations;
        uint32 chunks;
        bytes32 commitment;
        bytes32 stateRoot;
    }

    /// @notice Blocks by Franklin block id
    mapping(uint32 => Block) public blocks;

    /// @notice Onchain operations - operations processed inside rollup blocks
    /// @member opType Onchain operation type
    /// @member amount Amount used in the operation
    /// @member pubData Operation pubdata
    struct OnchainOperation {
        Operations.OpType opType;
        bytes pubData;
    }

    /// @notice Total number of registered onchain operations
    uint64 public totalOnchainOps;

    /// @notice Onchain operations by index
    mapping(uint64 => OnchainOperation) public onchainOps;

    /// @notice Flag indicates that a user has exited certain token balance (per owner and tokenId)
    mapping(address => mapping(uint16 => bool)) public exited;

    /// @notice Flag indicates that exodus (mass exit) mode is triggered
    /// @notice Once it was raised, it can not be cleared again, and all users must exit
    bool public exodusMode;

    /// @notice User authenticated fact hashes for some nonce.
    mapping(address => mapping(uint32 => bytes32)) public authFacts;

    /// @notice Priority Operation container
    /// @member opType Priority operation type
    /// @member pubData Priority operation public data
    /// @member expirationBlock Expiration block number (ETH block) for this request (must be satisfied before)
    /// @member fee Validators fee
    struct PriorityOperation {
        Operations.OpType opType;
        bytes pubData;
        uint256 expirationBlock;
        uint256 fee;
    }

    /// @notice Priority Requests mapping (request id - operation)
    /// @dev Contains op type, pubdata, fee and expiration block of unsatisfied requests.
    /// @dev Numbers are in order of requests receiving
    mapping(uint64 => PriorityOperation) public priorityRequests;

    /// @notice First open priority request id
    uint64 public firstPriorityRequestId;

    /// @notice Total number of requests
    uint64 public totalOpenPriorityRequests;

    /// @notice Total number of committed requests.
    /// @dev Used in checks: if the request matches the operation on Rollup contract and if provided number of requests is not too big
    uint64 public totalCommittedPriorityRequests;

}
