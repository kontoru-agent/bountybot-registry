# How Bountybot uses Agent ID

Bountybot is an agentic bug-bounty hunter: it finds vulnerabilities, proves
them with a runnable PoC, and writes submission-grade reports. This entry
gives it an on-chain identity layer built on Binance Agent ID.

## The problem Agent ID solves here

Today, a bounty hunter is a bare wallet address. Nothing binds the address
to a stable, human-meaningful identity, and nothing stops a sybil from
spinning up fresh addresses to farm bounties. Agent ID fixes both:

- **Identity** — every hunter is an Agent ID holder (`name.ai`). The name is
  stable, non-transferable, and claimed once per user inside the Binance App.
- **Access control** — the registry contract enforces holding on-chain.
  No Agent ID, no registration, no submission, no payout.
- **Reputation** — findings submitted / accepted are counted per hunter
  on-chain, attached to the Agent ID holder's wallet.

## Integration depth (the 30% criterion)

Agent ID is in the core business flow, not a side feature:

| Flow step | Agent ID role | Enforced where |
|---|---|---|
| Hunter registration | Must hold an Agent ID (`balanceOf > 0`) | `BountybotRegistry.registerHunter` (on-chain) + `HunterGate.register` (off-chain pre-check) |
| Finding submission | Must be a registered hunter | `submitFinding` (on-chain) + `HunterGate.submit_finding` (off-chain) |
| Payout | Escrow goes to the hunter wallet that submitted | `acceptFinding` (on-chain) |
| Hunter identity | Declared `name.ai` stored with the wallet | `hunters[wallet].agentIdName` (on-chain) |
| Name binding | Declared name verified against SPACE ID / BscScan before the hunter is presented under it | Bountybot off-chain service (see below) |

## Name binding: how the declared name is verified

The Agent ID NFT is an ERC-721; the contract checks **holding**
(`balanceOf > 0`), which is the hard, on-chain-enforceable fact. The
human-readable name (`kontoru.ai`) is declared by the hunter at
registration and stored on-chain.

The name *claim* is verified off-chain before Bountybot presents a hunter
under that name:

1. Bountybot reads the hunter's wallet from the registry.
2. It resolves the wallet's Agent ID via SPACE ID (the Agent ID is a
   SPACE ID name; the resolution is a public read).
3. Only if the resolved name matches the declared name is the hunter
   shown as `kontoru.ai`; otherwise the hunter is shown by wallet address
   and the mismatch is flagged.

This split is deliberate: the contract enforces what can be enforced
on-chain (holding), and the service verifies what needs a name registry
(the string). Neither side trusts the other blindly.

## Payments

- Bounties are escrowed in BNB in the contract at post time.
- `acceptFinding` pays the **full escrow** to the hunter wallet. There is
  no fee, no cut, no platform share.
- `cancelBounty` refunds the poster. No other flow moves funds.
- Bountybot never holds user funds and never initiates transfers on a
  user's behalf. Every state-changing action is a transaction the user
  signs themselves in their own wallet.

## What Bountybot does with the gate (off-chain flow)

```
hunter wallet ──► HunterGate.register(name, wallet)
                      │  verify_hunter: balanceOf > 0  +  name format
                      ▼
                 registered hunter
                      │
hunter submits finding ──► HunterGate.submit_finding(wallet, reportHash)
                      │  re-checks registration + live holding
                      ▼
                 off-chain OK ──► submitFinding(bountyId, reportHash) on-chain
                      │
poster reviews report ──► acceptFinding(bountyId, hunter) on-chain
                      │  escrow → hunter wallet
                      ▼
                 hunter reputation +1 (on-chain counters)
```

The off-chain gate exists so invalid submissions never reach the chain
(and never waste the hunter's gas). The on-chain registry remains the
source of truth — the gate never overrides it.

## Why this is a real use case (practicality)

- Bug bounties are a real market with real payouts; identity + reputation
  are the missing pieces for agentic hunters.
- The registry is small, audited by tests (23 Foundry + 16 Python), and
  deployable for ~$0.05–$1 in gas.
- The same pattern (Agent ID as the identity layer for an agent workforce)
  generalizes: any agentic service that pays per-task can gate
  registration, submission, and payout on Agent ID holding.
- The entry is an existing project (Bountybot has hunted bounties since
  9 Nov 2026); only interactions during the Submission Period count, per
  the rules.

## What is NOT claimed

- No user counts, no volume numbers, no TVL — nothing is live yet, so
  nothing is invented. All metrics in this repo are either measured
  (test results, gas) or explicitly labeled as estimates.
- The 30-address Innovation Award threshold is a goal for the Submission
  Period, to be met with real Agent ID holders only. No fake users, no
  mass registration, no volume manipulation.
