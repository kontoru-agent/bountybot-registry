# Submission checklist — Agent ID Hackathon

**Submission period: 18 Nov 2026 08:00 UTC – 9 Dec 2026 08:00 UTC.**
No registration needed. Submit project name, website, contract address(es),
Agent ID usage description, and other required materials during the period.
**Nothing has been submitted yet. This checklist is the exact work left.**

## Before submitting (all must be true)

- [x] **Deploy `BountybotRegistry` to BNB Chain mainnet** — **DONE 19 Nov 2026**:
      contract `0x32619eba3f351cb555355f6011c9e22782253867`, deploy tx
      `0xc62868d8bfd3160751334297dc8dfadfe9e22f3ac6078470826760d85fffdfd9`
      (block 134446887, gas 1,362,878 ≈ 0.000068 BNB). On-chain verified:
      12,095 B code, `agentId()` = `0x60B9…022F`, `nextBountyId()` = 0.
- [ ] **Verify source on BscScan** — pack ready: `docs/VERIFICATION.md`
      (exact form inputs) + `flattened/BountybotRegistry.flattened.sol`.
      Flattened source compiles; runtime bytecode matches on-chain except the
      expected immutable + metadata-hash bytes. Web form still to be filled
      in the browser (no BscScan API key held). After verifying, confirm
      `agentId()` returns `0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F`.
- [ ] **Prove the loop live on mainnet** — runbook ready (`scripts/DEMO.md`,
      exact commands, not executed): `registerHunter("kontoru.ai")` from BAW,
      post a 0.0001 BNB test bounty from the burner, submit a test finding
      from BAW, accept it from the burner. Record tx hashes. BAW steps need
      in-app approval.
- [ ] **Publish this repo publicly on GitHub** — open-source requirement.
      Suggested name: `kontoru-agent/bountybot-registry`.
      Include: `src/`, `test/`, `script/`, `offchain/`, `docs/`, `index.html`,
      `flattened/`, `README.md`, `LICENSE`. Do NOT include: `out/`, `cache/`,
      `broadcast/`, keys.
- [x] **Website / demo page** — `index.html` built (static, vanilla JS, reads
      live on-chain state via the public BSC RPC; logic tested against live
      RPC 19 Nov 2026). Needs a public URL — publish with the repo
      (e.g. GitHub Pages) so it is reachable during review.
- [ ] **30 Agent ID addresses interacting** — Innovation Award eligibility
      minimum. Real holders only, during the Submission Period. Plan the
      outreach (X posts, Bountybot community) — no fake users, no mass
      registration, no volume manipulation (disqualification risk).
- [ ] **X promotion (optional, Community Promotion Award)** — original posts
      with `#BinanceWalletHackathon` + `#AgenticWallet`; submit links via the
      official campaign survey. 20 winners share 2,000 USDC. Post text needs
      owner approval first (standing rule).

## Submission form materials

| Field | Value |
|---|---|
| Project name | Bountybot — Agent ID-gated bug-bounty registry |
| Website | GitHub repo URL (public) + demo page |
| Contract address(es) | `BountybotRegistry` `0x32619eba3f351cb555355f6011c9e22782253867` on BNB Chain mainnet (deployed 19 Nov 2026, deploy tx `0xc62868d8bfd3160751334297dc8dfadfe9e22f3ac6078470826760d85fffdfd9`) |
| Agent ID usage description | See `docs/INTEGRATION.md`: registration, submission, and payout are all gated on Agent ID holding (`balanceOf > 0`); the declared `name.ai` is stored per hunter and verified against SPACE ID; escrow pays the hunter wallet on accept |
| Other materials | README, test results (23 Foundry + 16 Python, all passing), gas report, dry-run evidence |

## Award lane

**Innovation Award** (panel-judged, top 10, 1st 10,000 USDC):
- Agent ID Application Depth 30% — Agent ID gates register/submit/claim.
- Practicality & Feasibility 25% — real bug-bounty market, live-tested flow.
- Product Completion 25% — contract + gate + tests + docs done; needs the
  mainnet deployment + 30 interacting addresses to be fully live.
- Innovation 20% — Agent ID as the identity layer for an agent workforce.

Pioneer Award (on-chain metrics) is the secondary lane — same contract
generates the on-chain interactions, but the project can only receive
**one award**, so the submission should lead with Innovation.

## Dates

- Submission: 18 Nov 2026 08:00 UTC – **9 Dec 2026 08:00 UTC**
- Internal review: 9–17 Dec 2026
- Public review: 17–20 Dec 2026
- Distribution: within 14 business days after announcement (December —
  **not** November)

## Safety red lines (do not violate)

- No web QR-code login; no stored user sessions.
- No bypass of user tx confirmation; no unauthorized transfers.
- No seed phrases / private keys / API secrets / pairing codes collected.
- No Binance/BNB brand impersonation in names or domains.
- No promised returns; no "passive income" language.
- Agent ID never packaged as "look up other people's wallets by name."
- No abnormal behavior (volume manipulation, mass account registration).
