// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title BountybotRegistry — Agent ID-gated bug-bounty registry on BNB Chain
/// @notice Bounty hunters must hold a Binance Agent ID (ERC-721, non-transferable)
///         to register, submit findings, and get paid. The Agent ID is the identity
///         layer: every finding is tied to an Agent ID holder, not a bare address.
/// @dev No owner, no pause, no mint, no admin withdraw. The only privileged role is
///      a bounty poster over their own bounty (accept / cancel). Escrow flows only
///      poster -> hunter (on accept) or poster -> poster (on cancel).
///      Agent ID contract (BNB Chain mainnet): 0x60b9262456de011f7d15a54cdd8c48baaa8b022f
///      (SPACE ID Agent ID, ERC-721, non-transferable). Holder check: balanceOf > 0.

interface IAgentId {
    function balanceOf(address owner) external view returns (uint256);
}

contract BountybotRegistry {
    IAgentId public immutable agentId;

    uint256 public constant MAX_NAME_BYTES = 64;
    uint256 public constant MAX_SCOPE_BYTES = 512;

    enum Status {
        Open,
        Closed,
        Cancelled
    }

    struct Hunter {
        string agentIdName;
        uint64 registeredAt;
        uint32 findingsSubmitted;
        uint32 findingsAccepted;
        bool registered;
    }

    struct Bounty {
        address poster;
        uint256 amount;
        bytes32 targetHash;
        string scope;
        Status status;
        uint64 createdAt;
    }

    struct Finding {
        address hunter;
        bytes32 reportHash;
        uint64 submittedAt;
        bool accepted;
    }

    uint256 public nextBountyId;
    mapping(address => Hunter) public hunters;
    mapping(uint256 => Bounty) public bounties;
    mapping(uint256 => mapping(address => Finding)) public findings;
    mapping(uint256 => address[]) private findingHunters;

    // Simple reentrancy guard (no external deps, no network needed to build).
    uint256 private _locked;

    event HunterRegistered(address indexed hunter, string agentIdName);
    event HunterNameUpdated(address indexed hunter, string agentIdName);
    event BountyPosted(uint256 indexed bountyId, address indexed poster, uint256 amount, bytes32 targetHash);
    event FindingSubmitted(uint256 indexed bountyId, address indexed hunter, bytes32 reportHash);
    event FindingAccepted(uint256 indexed bountyId, address indexed hunter, uint256 amount);
    event BountyCancelled(uint256 indexed bountyId, address indexed poster, uint256 amount);

    error NotAgentIdHolder(address who);
    error AlreadyRegistered(address who);
    error NotRegistered(address who);
    error EmptyName();
    error NameTooLong();
    error EmptyScope();
    error ScopeTooLong();
    error ZeroValue();
    error BountyNotFound(uint256 bountyId);
    error BountyNotOpen(uint256 bountyId);
    error EmptyReportHash();
    error AlreadySubmitted(uint256 bountyId, address hunter);
    error NotPoster(uint256 bountyId, address who);
    error FindingNotFound(uint256 bountyId, address hunter);
    error AlreadyAccepted(uint256 bountyId, address hunter);
    error TransferFailed(address to, uint256 amount);
    error ZeroAgentIdContract();

    modifier nonReentrant() {
        require(_locked == 0, "reentrant");
        _locked = 1;
        _;
        _locked = 0;
    }

    constructor(address agentId_) {
        if (agentId_ == address(0)) revert ZeroAgentIdContract();
        agentId = IAgentId(agentId_);
    }

    /// @notice True when `who` holds at least one Agent ID (balanceOf > 0).
    function isAgentIdHolder(address who) public view returns (bool) {
        return agentId.balanceOf(who) > 0;
    }

    /// @notice Register as a hunter. Caller must hold an Agent ID. The declared
    ///         name (e.g. "kontoru.ai") is stored with the wallet; the on-chain
    ///         hard gate is the Agent ID holding. Name ownership is verified
    ///         off-chain by Bountybot against SPACE ID / BscScan before the
    ///         hunter is presented under that name.
    function registerHunter(string calldata agentIdName) external {
        if (!isAgentIdHolder(msg.sender)) revert NotAgentIdHolder(msg.sender);
        if (hunters[msg.sender].registered) revert AlreadyRegistered(msg.sender);
        _validateName(agentIdName);
        hunters[msg.sender] = Hunter({
            agentIdName: agentIdName,
            registeredAt: uint64(block.timestamp),
            findingsSubmitted: 0,
            findingsAccepted: 0,
            registered: true
        });
        emit HunterRegistered(msg.sender, agentIdName);
    }

    /// @notice Update the declared Agent ID name. Re-verifies the holding.
    function updateHunterName(string calldata agentIdName) external {
        if (!hunters[msg.sender].registered) revert NotRegistered(msg.sender);
        if (!isAgentIdHolder(msg.sender)) revert NotAgentIdHolder(msg.sender);
        _validateName(agentIdName);
        hunters[msg.sender].agentIdName = agentIdName;
        emit HunterNameUpdated(msg.sender, agentIdName);
    }

    /// @notice Post a bounty with BNB escrow. Anyone may post; only Agent ID
    ///         holders may hunt it.
    function postBounty(bytes32 targetHash, string calldata scope) external payable returns (uint256 bountyId) {
        if (msg.value == 0) revert ZeroValue();
        if (bytes(scope).length == 0) revert EmptyScope();
        if (bytes(scope).length > MAX_SCOPE_BYTES) revert ScopeTooLong();
        bountyId = nextBountyId++;
        bounties[bountyId] = Bounty({
            poster: msg.sender,
            amount: msg.value,
            targetHash: targetHash,
            scope: scope,
            status: Status.Open,
            createdAt: uint64(block.timestamp)
        });
        emit BountyPosted(bountyId, msg.sender, msg.value, targetHash);
    }

    /// @notice Submit a finding (hash of the off-chain report) for an open bounty.
    ///         Caller must be a registered Agent ID holder. One finding per hunter
    ///         per bounty.
    function submitFinding(uint256 bountyId, bytes32 reportHash) external {
        if (bountyId >= nextBountyId) revert BountyNotFound(bountyId);
        if (bounties[bountyId].status != Status.Open) revert BountyNotOpen(bountyId);
        if (!hunters[msg.sender].registered) revert NotRegistered(msg.sender);
        if (reportHash == bytes32(0)) revert EmptyReportHash();
        if (findings[bountyId][msg.sender].submittedAt != 0) {
            revert AlreadySubmitted(bountyId, msg.sender);
        }
        findings[bountyId][msg.sender] = Finding({
            hunter: msg.sender,
            reportHash: reportHash,
            submittedAt: uint64(block.timestamp),
            accepted: false
        });
        findingHunters[bountyId].push(msg.sender);
        hunters[msg.sender].findingsSubmitted += 1;
        emit FindingSubmitted(bountyId, msg.sender, reportHash);
    }

    /// @notice Accept a finding: pays the full escrow to the hunter and closes
    ///         the bounty. Only the poster. Checks-effects-interactions + guard.
    function acceptFinding(uint256 bountyId, address hunter) external nonReentrant {
        if (hunter == address(0)) revert FindingNotFound(bountyId, hunter);
        if (bountyId >= nextBountyId) revert BountyNotFound(bountyId);
        if (bounties[bountyId].status != Status.Open) revert BountyNotOpen(bountyId);
        if (bounties[bountyId].poster != msg.sender) revert NotPoster(bountyId, msg.sender);
        Finding storage f = findings[bountyId][hunter];
        if (f.submittedAt == 0) revert FindingNotFound(bountyId, hunter);
        if (f.accepted) revert AlreadyAccepted(bountyId, hunter);
        uint256 amount = bounties[bountyId].amount;
        f.accepted = true;
        bounties[bountyId].status = Status.Closed;
        hunters[hunter].findingsAccepted += 1;
        emit FindingAccepted(bountyId, hunter, amount);
        (bool ok, ) = payable(hunter).call{value: amount}("");
        if (!ok) revert TransferFailed(hunter, amount);
    }

    /// @notice Cancel an open bounty and refund the escrow to the poster.
    ///         Only the poster; only while open (an accepted bounty is closed).
    function cancelBounty(uint256 bountyId) external nonReentrant {
        if (bountyId >= nextBountyId) revert BountyNotFound(bountyId);
        if (bounties[bountyId].status != Status.Open) revert BountyNotOpen(bountyId);
        if (bounties[bountyId].poster != msg.sender) revert NotPoster(bountyId, msg.sender);
        uint256 amount = bounties[bountyId].amount;
        bounties[bountyId].status = Status.Cancelled;
        emit BountyCancelled(bountyId, msg.sender, amount);
        (bool ok, ) = payable(msg.sender).call{value: amount}("");
        if (!ok) revert TransferFailed(msg.sender, amount);
    }

    /// @notice All hunters that submitted a finding for a bounty.
    function getFindingHunters(uint256 bountyId) external view returns (address[] memory) {
        return findingHunters[bountyId];
    }

    function _validateName(string calldata name) internal pure {
        if (bytes(name).length == 0) revert EmptyName();
        if (bytes(name).length > MAX_NAME_BYTES) revert NameTooLong();
    }
}
