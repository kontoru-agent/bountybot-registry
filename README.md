# BountybotRegistry — Agent ID-gated bug-bounty registry

Entry for the **Agent ID Hackathon** (Binance Wallet x BNB Chain, 60,000 USDC).
Submission period: 18 Nov 2026 08:00 UTC – 9 Dec 2026 08:00 UTC.

Bountybot is an agentic bug-bounty hunter. This entry puts its identity layer
on-chain: **only Agent ID holders can register as hunters, submit findings,
and get paid.** The Agent ID is not a badge on the side — it gates the core
flow (register → submit → claim) of the bounty registry contract.

## What is built

| Piece | File | Status |
|---|---|---|
| `BountybotRegistry` contract | `src/BountybotRegistry.sol` | Built, 23/23 Foundry tests pass |
| Agent ID gate (off-chain) | `offchain/bountybot_agentid/gate.py` | Built, 16/16 Python tests pass |
| Deployment script | `script/Deploy.s.sol` | **Deployed 19 Nov 2026** — see below |
| Demo page (static, live on-chain reads) | `index.html` | Built, logic tested against live RPC 19 Nov 2026 |
| BscScan verification pack | `docs/VERIFICATION.md` + `flattened/BountybotRegistry.flattened.sol` | Ready — flattened source compiles, bytecode matches (see doc) |
| Demo-loop runbook | `scripts/DEMO.md` | Ready — exact commands, **not executed yet** |
| Integration doc | `docs/INTEGRATION.md` | Done |
| Deployment plan + gas estimate | `docs/DEPLOYMENT.md` | Done (superseded by the live deploy below) |
| Submission checklist | `docs/SUBMISSION_CHECKLIST.md` | Done |

## The contract

`BountybotRegistry` (Solidity 0.8.24, MIT, no external dependencies):

- **Register** — `registerHunter(name)`: caller must hold an Agent ID
  (`balanceOf > 0` on the SPACE ID Agent ID contract
  `0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F`, ERC-721, non-transferable).
  Stores the hunter's declared Agent ID name (e.g. `kontoru.ai`), registration
  time, and reputation counters.
- **Post a bounty** — `postBounty(targetHash, scope)` payable: anyone posts a
  bounty with BNB escrow. `targetHash` is the hash of the target scope;
  the full scope text lives off-chain.
- **Submit a finding** — `submitFinding(bountyId, reportHash)`: registered
  hunters only, one finding per hunter per bounty. `reportHash` is the hash
  of the off-chain report.
- **Accept + pay** — `acceptFinding(bountyId, hunter)`: only the bounty
  poster; releases the full escrow to the hunter and closes the bounty.
- **Cancel + refund** — `cancelBounty(bountyId)`: only the poster, only
  while open; refunds the escrow.

**Owner permissions: none.** There is no owner, no pause, no mint, no admin
withdraw. The only privileged role is a bounty poster over their own bounty.
Escrow flows only poster → hunter (accept) or poster → poster (cancel).

## The off-chain integration

`offchain/bountybot_agentid/gate.py` is the off-chain mirror of the contract:

- `is_agent_id_holder(address, provider)` — live `balanceOf` check via
  `eth_call` (read-only, no transaction).
- `verify_hunter(name, wallet, provider)` — one verdict: holding + name format.
- `HunterGate` — in-memory hunter registry for the Bountybot flow; every
  finding submission is gated on a verified registration, so invalid
  submissions never reach the chain (and never waste the hunter's gas).

The on-chain registry remains the source of truth; the gate is the
off-chain pre-check. See `docs/INTEGRATION.md` for the full flow, including
how Bountybot binds the declared Agent ID name to the wallet (verified
against SPACE ID / BscScan before the hunter is presented under that name).

## Verified facts (live, 18 Nov 2026)

- Agent ID contract `0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F` on BNB Chain
  mainnet (chain id 56) — from the official Binance announcement.
- The deployer wallet `0x4Fbb7839AE388f166E92B736BC7C8f1A45d8713E`
  (Binance Agentic Wallet) holds **exactly 1 Agent ID** (`balanceOf = 1`,
  verified via `eth_call` to the public BSC RPC) — the Agent ID `kontoru.ai`.
- Live gas price at build time: **0.05 gwei** (BSC dataseed).
  BNB price at build time: **$589.47** (CoinGecko).

## Run the tests

```bash
# Solidity (Foundry 1.9.0, no network needed)
forge test            # 23 tests, all pass
forge test --gas-report

# Off-chain gate (Python 3, stdlib only, no network)
python3 offchain/test_gate.py        # 16 tests, all pass
python3 offchain/demo.py             # mock demo, no network
python3 offchain/demo.py --live     # one read-only eth_call to public BSC RPC
```

## Live deployment (19 Nov 2026 — verified on-chain)

- **Contract:** `BountybotRegistry` at
  [`0x32619eba3f351cb555355f6011c9e22782253867`](https://bscscan.com/address/0x32619eba3f351cb555355f6011c9e22782253867)
  on BNB Chain mainnet (chain id 56).
- **Deploy tx:**
  [`0xc62868d8bfd3160751334297dc8dfadfe9e22f3ac6078470826760d85fffdfd9`](https://bscscan.com/tx/0xc62868d8bfd3160751334297dc8dfadfe9e22f3ac6078470826760d85fffdfd9)
  — block 134446887, gas used 1,362,878 at 0.05 gwei ≈ 0.000068 BNB.
- **Funding tx** (BAW → burner, 0.001 BNB):
  [`0x5b90536e28288337ba4906f7266137dd3d2429d3e660fa7f0b89101be4966a24`](https://bscscan.com/tx/0x5b90536e28288337ba4906f7266137dd3d2429d3e660fa7f0b89101be4966a24)
  — block 134446800.
- **On-chain checks passed:** 12,095 bytes of code at the address;
  `agentId()` returns `0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F`
  (the SPACE ID Agent ID contract); `nextBountyId()` = 0 (no bounty yet).
- **Deployer:** burner `0x8dB75794D924E359ea52b929415bD7ed0A06Ad4A`
  (funded 0.001 BNB from the Binance Agentic Wallet after the owner added it
  to the Binance address book). The BAW itself (`0x4Fbb…8713E`) holds the
  Agent ID `kontoru.ai` and is the registered-hunter account for the demo.
- **Compiler:** solc `0.8.24+commit.e11b9ed9`, optimizer on, 200 runs,
  `via_ir` false, license MIT. Constructor argument (ABI-encoded):
  `0x00000000000000000000000060b9262456de011f7d15a54cdd8c48baaa8b022f`.

## Remaining before submission

- [x] Deploy to BNB Chain mainnet — **done 19 Nov 2026** (above).
- [ ] Verify source on BscScan — pack ready (`docs/VERIFICATION.md`),
      web form still to be filled in the browser (no API key held).
- [ ] Prove the loop live on mainnet — runbook ready (`scripts/DEMO.md`),
      **not executed yet** (needs in-app approval for the BAW steps).
- [ ] Publish this repo publicly on GitHub — suggested name
      `kontoru-agent/bountybot-registry`. Demo page `index.html` goes live
      with the repo (e.g. GitHub Pages).
- [ ] 30 Agent ID addresses interacting — 0 so far; real holders only.

## Submission

See `docs/SUBMISSION_CHECKLIST.md` — project name, website, contract
address(es), Agent ID usage description, and the exact materials to submit
during 18 Nov – 9 Dec 2026 08:00 UTC. **Nothing has been submitted yet.**

## Safety red lines (hackathon rules) — compliance

- No web QR-code login for Agentic Wallet; no stored user sessions.
- No bypass of user transaction confirmation; no unauthorized transfers.
- No collection of seed phrases, private keys, API secrets, or pairing codes.
- No impersonation of the Binance/BNB brand (project is "Bountybot", not
  Binance-branded; contract is `BountybotRegistry`).
- No promised returns; no "passive income" language anywhere in this repo.
- Agent ID is used as identity/access control — never as a tool to look up
  other people's wallets by name.
- No fake users or interactions: the 30-address Innovation Award threshold
  must be met with real Agent ID holders only.

## License

MIT — see `LICENSE`.
