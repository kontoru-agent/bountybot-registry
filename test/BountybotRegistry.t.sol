// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/BountybotRegistry.sol";

/// @notice Minimal mock of the SPACE ID Agent ID ERC-721: balanceOf is settable.
contract MockAgentId {
    mapping(address => uint256) private _balances;

    function setBalance(address who, uint256 amount) external {
        _balances[who] = amount;
    }

    function balanceOf(address owner) external view returns (uint256) {
        return _balances[owner];
    }
}

contract BountybotRegistryTest is Test {
    MockAgentId internal agentId;
    BountybotRegistry internal registry;

    address internal poster = address(0xA11CE);
    address internal hunter = address(0xB0B);
    address internal hunter2 = address(0xB0C);
    address internal stranger = address(0x5EED);

    bytes32 internal constant TARGET = keccak256("example-target");
    bytes32 internal constant REPORT = keccak256("finding-report-1");

    function setUp() public {
        agentId = new MockAgentId();
        registry = new BountybotRegistry(address(agentId));
        agentId.setBalance(hunter, 1);
        agentId.setBalance(hunter2, 2);
        agentId.setBalance(poster, 1);
        vm.deal(poster, 100 ether);
        vm.deal(hunter, 1 ether);
    }

    // ---- registration ----

    function testRegisterRevertsForNonHolder() public {
        vm.prank(stranger);
        vm.expectRevert(abi.encodeWithSelector(BountybotRegistry.NotAgentIdHolder.selector, stranger));
        registry.registerHunter("stranger.ai");
    }

    function testRegisterHunter() public {
        vm.prank(hunter);
        registry.registerHunter("kontoru.ai");
        (string memory name, uint64 at, uint32 submitted, uint32 accepted, bool reg) =
            registry.hunters(hunter);
        assertEq(name, "kontoru.ai");
        assertTrue(reg);
        assertEq(at, uint64(block.timestamp));
        assertEq(submitted, 0);
        assertEq(accepted, 0);
        assertTrue(registry.isAgentIdHolder(hunter));
        assertFalse(registry.isAgentIdHolder(stranger));
    }

    function testRegisterDuplicateReverts() public {
        vm.prank(hunter);
        registry.registerHunter("kontoru.ai");
        vm.prank(hunter);
        vm.expectRevert(abi.encodeWithSelector(BountybotRegistry.AlreadyRegistered.selector, hunter));
        registry.registerHunter("kontoru.ai");
    }

    function testRegisterEmptyNameReverts() public {
        vm.prank(hunter);
        vm.expectRevert(BountybotRegistry.EmptyName.selector);
        registry.registerHunter("");
    }

    function testRegisterLongNameReverts() public {
        vm.prank(hunter);
        vm.expectRevert(BountybotRegistry.NameTooLong.selector);
        registry.registerHunter(string(abi.encodePacked(new bytes(65))));
    }

    function testUpdateNameRevertsAfterLosingAgentId() public {
        vm.prank(hunter);
        registry.registerHunter("kontoru.ai");
        agentId.setBalance(hunter, 0);
        vm.prank(hunter);
        vm.expectRevert(abi.encodeWithSelector(BountybotRegistry.NotAgentIdHolder.selector, hunter));
        registry.updateHunterName("kontoru2.ai");
    }

    function testUpdateNameWorks() public {
        vm.prank(hunter);
        registry.registerHunter("kontoru.ai");
        vm.prank(hunter);
        registry.updateHunterName("kontoru2.ai");
        (string memory name,,,,) = registry.hunters(hunter);
        assertEq(name, "kontoru2.ai");
    }

    // ---- bounties ----

    function testPostBounty() public {
        vm.prank(poster);
        uint256 id = registry.postBounty{value: 1 ether}(TARGET, "scope: example.com");
        assertEq(id, 0);
        assertEq(registry.nextBountyId(), 1);
        (address p, uint256 amount, bytes32 t, string memory scope, BountybotRegistry.Status s,) =
            registry.bounties(0);
        assertEq(p, poster);
        assertEq(amount, 1 ether);
        assertEq(t, TARGET);
        assertEq(scope, "scope: example.com");
        assertEq(uint256(s), uint256(BountybotRegistry.Status.Open));
        assertEq(address(registry).balance, 1 ether);
    }

    function testPostBountyZeroValueReverts() public {
        vm.prank(poster);
        vm.expectRevert(BountybotRegistry.ZeroValue.selector);
        registry.postBounty(TARGET, "scope");
    }

    function testPostBountyEmptyScopeReverts() public {
        vm.prank(poster);
        vm.expectRevert(BountybotRegistry.EmptyScope.selector);
        registry.postBounty{value: 1 ether}(TARGET, "");
    }

    // ---- findings ----

    function _openBounty() internal returns (uint256) {
        vm.prank(poster);
        return registry.postBounty{value: 1 ether}(TARGET, "scope");
    }

    function testSubmitFindingRequiresRegistration() public {
        uint256 id = _openBounty();
        vm.prank(hunter2); // holds Agent ID but never registered
        vm.expectRevert(abi.encodeWithSelector(BountybotRegistry.NotRegistered.selector, hunter2));
        registry.submitFinding(id, REPORT);
    }

    function testSubmitFindingWorks() public {
        uint256 id = _openBounty();
        vm.prank(hunter);
        registry.registerHunter("kontoru.ai");
        vm.prank(hunter);
        registry.submitFinding(id, REPORT);
        (address h, bytes32 r, uint64 at, bool acc) = registry.findings(id, hunter);
        assertEq(h, hunter);
        assertEq(r, REPORT);
        assertTrue(at != 0);
        assertFalse(acc);
        address[] memory hs = registry.getFindingHunters(id);
        assertEq(hs.length, 1);
        assertEq(hs[0], hunter);
        (,, uint32 submitted,,) = registry.hunters(hunter);
        assertEq(submitted, 1);
    }

    function testSubmitFindingDuplicateReverts() public {
        uint256 id = _openBounty();
        vm.prank(hunter);
        registry.registerHunter("kontoru.ai");
        vm.prank(hunter);
        registry.submitFinding(id, REPORT);
        vm.prank(hunter);
        vm.expectRevert(
            abi.encodeWithSelector(BountybotRegistry.AlreadySubmitted.selector, id, hunter)
        );
        registry.submitFinding(id, keccak256("other"));
    }

    function testSubmitEmptyReportHashReverts() public {
        uint256 id = _openBounty();
        vm.prank(hunter);
        registry.registerHunter("kontoru.ai");
        vm.prank(hunter);
        vm.expectRevert(BountybotRegistry.EmptyReportHash.selector);
        registry.submitFinding(id, bytes32(0));
    }

    // ---- accept / cancel ----

    function testAcceptFindingPaysHunter() public {
        uint256 id = _openBounty();
        vm.prank(hunter);
        registry.registerHunter("kontoru.ai");
        vm.prank(hunter);
        registry.submitFinding(id, REPORT);
        uint256 before = hunter.balance;
        vm.prank(poster);
        registry.acceptFinding(id, hunter);
        assertEq(hunter.balance, before + 1 ether);
        assertEq(address(registry).balance, 0);
        (,,,, BountybotRegistry.Status s,) = registry.bounties(id);
        assertEq(uint256(s), uint256(BountybotRegistry.Status.Closed));
        (,,, bool acc) = registry.findings(id, hunter);
        assertTrue(acc);
        (,,, uint32 accepted,) = registry.hunters(hunter);
        assertEq(accepted, 1);
    }

    function testAcceptByNonPosterReverts() public {
        uint256 id = _openBounty();
        vm.prank(hunter);
        registry.registerHunter("kontoru.ai");
        vm.prank(hunter);
        registry.submitFinding(id, REPORT);
        vm.prank(stranger);
        vm.expectRevert(
            abi.encodeWithSelector(BountybotRegistry.NotPoster.selector, id, stranger)
        );
        registry.acceptFinding(id, hunter);
    }

    function testAcceptMissingFindingReverts() public {
        uint256 id = _openBounty();
        vm.prank(poster);
        vm.expectRevert(
            abi.encodeWithSelector(BountybotRegistry.FindingNotFound.selector, id, hunter)
        );
        registry.acceptFinding(id, hunter);
    }

    function testAcceptTwiceReverts() public {
        uint256 id = _openBounty();
        vm.prank(hunter);
        registry.registerHunter("kontoru.ai");
        vm.prank(hunter);
        registry.submitFinding(id, REPORT);
        vm.prank(poster);
        registry.acceptFinding(id, hunter);
        vm.prank(poster);
        vm.expectRevert(abi.encodeWithSelector(BountybotRegistry.BountyNotOpen.selector, id));
        registry.acceptFinding(id, hunter);
    }

    function testCancelRefundsPoster() public {
        uint256 id = _openBounty();
        uint256 before = poster.balance;
        vm.prank(poster);
        registry.cancelBounty(id);
        assertEq(poster.balance, before + 1 ether);
        assertEq(address(registry).balance, 0);
        (,,,, BountybotRegistry.Status s,) = registry.bounties(id);
        assertEq(uint256(s), uint256(BountybotRegistry.Status.Cancelled));
    }

    function testCancelByNonPosterReverts() public {
        uint256 id = _openBounty();
        vm.prank(stranger);
        vm.expectRevert(
            abi.encodeWithSelector(BountybotRegistry.NotPoster.selector, id, stranger)
        );
        registry.cancelBounty(id);
    }

    function testSubmitToClosedBountyReverts() public {
        uint256 id = _openBounty();
        vm.prank(hunter);
        registry.registerHunter("kontoru.ai");
        vm.prank(hunter);
        registry.submitFinding(id, REPORT);
        vm.prank(poster);
        registry.acceptFinding(id, hunter);
        vm.prank(hunter2);
        registry.registerHunter("other.ai");
        vm.prank(hunter2);
        vm.expectRevert(abi.encodeWithSelector(BountybotRegistry.BountyNotOpen.selector, id));
        registry.submitFinding(id, keccak256("late"));
    }

    // ---- escrow accounting ----

    function testEscrowAccountingAcrossManyBounties() public {
        vm.prank(poster);
        uint256 a = registry.postBounty{value: 2 ether}(TARGET, "a");
        vm.prank(poster);
        uint256 b = registry.postBounty{value: 3 ether}(TARGET, "b");
        vm.prank(poster);
        uint256 c = registry.postBounty{value: 5 ether}(TARGET, "c");
        assertEq(address(registry).balance, 10 ether);
        vm.prank(hunter);
        registry.registerHunter("kontoru.ai");
        vm.prank(hunter);
        registry.submitFinding(a, REPORT);
        vm.prank(poster);
        registry.acceptFinding(a, hunter);
        vm.prank(poster);
        registry.cancelBounty(b);
        // only bounty c (5 ether) still open
        assertEq(address(registry).balance, 5 ether);
        (,,,, BountybotRegistry.Status sc,) = registry.bounties(c);
        assertEq(uint256(sc), uint256(BountybotRegistry.Status.Open));
    }

    function testConstructorRejectsZeroAgentId() public {
        vm.expectRevert(BountybotRegistry.ZeroAgentIdContract.selector);
        new BountybotRegistry(address(0));
    }
}
