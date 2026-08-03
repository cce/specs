{{#include ../_include/tex-macros/domain-separators.md}}

$$
\newcommand \BonusDecayInterval {B_{b,\mathrm{decay}}}
\newcommand \MaxProposedExpiredOnlineAccounts {B_{N_\mathrm{e},\max}}
\newcommand \MinBalance {b_{\min}}
\newcommand \PayoutsMaxBalance {A_{r,\max}}
\newcommand \PayoutsMinBalance {A_{r,\min}}
\newcommand \Heartbeat {\mathrm{hb}}
\newcommand \PayoutsChallengeBits {\Heartbeat_\mathrm{bits}}
\newcommand \PayoutsChallengeGracePeriod {\Heartbeat_\mathrm{grace}}
\newcommand \PayoutsChallengeInterval {\Heartbeat_r}
\newcommand \PayoutMaxMarkAbsent {B_{N_\mathrm{a},\max}}
\newcommand \MaxTxnBytesPerBlock {B_{\max}}
\newcommand \Genesis {\mathrm{Genesis}}
\newcommand \GenesisID {\Genesis{\mathrm{ID}}}
\newcommand \Hash {\mathrm{Hash}}
\newcommand \GenesisHash {\Genesis\Hash}
\newcommand \Prev {\mathrm{Prev}}
\newcommand \MaxVersionStringLen {V_{\max}}
\newcommand \DefaultUpgradeWaitRounds {\delta_x}
\newcommand \MaxUpgradeWaitRounds {\delta_{x_{\max}}}
\newcommand \MinUpgradeWaitRounds {\delta_{x_{\min}}}
\newcommand \UpgradeThreshold {\tau}
\newcommand \UpgradeVoteRounds {\delta_d}
\newcommand \MaxTimestampIncrement {\Delta t_{\max}}
\newcommand \Seed {\mathrm{Seed}}
\newcommand \Tx {\mathrm{Tx}}
\newcommand \TxID {\Tx\mathrm{ID}}
\newcommand \TxSeq {\Tx\mathrm{Seq}}
\newcommand \TxCommit {\Tx\mathrm{Commit}}
\newcommand \TxTail {\Tx\mathrm{Tail}}
\newcommand \SHATFS {\mathrm{SHA256}}
\newcommand \SHAFOT {\mathrm{SHA512}}
\newcommand \Sig {\mathrm{Sig}}
\newcommand \STIB {\mathrm{STIB}}
\newcommand \ApplyData {\mathrm{ApplyData}}
\newcommand {\abs}[1] {\lvert #1 \rvert}
\newcommand \MaxTxTail {\mathrm{TxTail}_{\max}}
$$

# Blocks

A _block_ is a data structure that specifies the transition between states.

The data in a block is divided between the _block header_ and its _block body_.

## Block Header

The block header contains the following components:

### Round

The block’s _round_, which matches the round of the state it is transitioning
into. (The block with round \\( 0 \\) is special in that this block specifies not
a transition but rather the entire initial state, which is called the _genesis state_.
This block is correspondingly called the [_genesis block_](./ledger-genesis.md)).
The round is stored under msgpack key `rnd`.

### Genesis Identifier

The block’s _genesis identifier_ and _genesis hash_, which match the genesis identifier
and hash of the states it transitions between (i.e., they stay constant since the
initial state forwards). The genesis identifier is stored under msgpack key `gen`,
and the genesis hash is stored under msgpack key `gh`.

### Upgrade Vote

The block’s _upgrade vote_, which results in the new upgrade state. The block also
duplicates the upgrade state of the state it transitions into. The msgpack representations
of the upgrade vote components are described in detail below.

### Timestamp

The block's _timestamp_, which matches the timestamp of the state it transitions
into. The timestamp is stored under msgpack key `ts`.

### Seed

The block's [_seed_](../abft/abft-messages.md#seed), which matches the seed of the
state it transitions into. The seed is stored under msgpack key `seed`.

### Reward Updates

The block's _reward updates_, which results in the new reward state. The block
also duplicates the reward state of the state it transitions into. The msgpack representations
of the reward updates components are described in detail below.

### Transaction Commitments

Cryptographic commitments to the block’s _transaction sequence_, described below
(referred also as _payset_), using:

- [SHA-512/256 hash function](../crypto/crypto-sha512-256.md), stored under msgpack
key `txn`;

- [SHA-256 hash function](../crypto/crypto-sha256.md), stored under msgpack key
`txn256`;

- [SHA512 hash function](../crypto/crypto-sha512.md), stored under msgpack key
`txn512`.

### Previous Hash

The block’s _previous hash_, which is the cryptographic hash of the previous Block
Header in the sequence, using:

- [SHA-512/256 hash function](../crypto/crypto-sha512-256.md), stored under msgpack
key `prev`;

- [SHA512 hash function](../crypto/crypto-sha512.md), stored under msgpack key `prev512`.

The _previous hash_ of the [genesis block](./ledger-genesis.md) is \\( 0 \\)).

### Transaction Counter

The block’s _transaction counter_, which is the total number of transactions issued
prior to this block. This count starts from the first block with a protocol version
that supports the transaction counter. The counter is stored in msgpack field `tc`.

### Proposer

The block’s _proposer_, which is the address of the account that proposed the
block. The proposer is stored in msgpack field `prp`.

### Fees Collected

The block’s _fees collected_ is the sum of all fees paid by transactions in the
block and is stored in msgpack field `fc`.

### Bonus

The potential _bonus incentive_ is the amount, in μALGO, that may be paid to the
proposer of this block beyond the amount available from fees. It is stored in msgpack
field `bi`. It may be set during a consensus upgrade, or else it must be equal to
the value from the previous block in most rounds, or be \\( 99 \\% \\) of the previous
value (rounded down) if the round of this block is \\( 0 \mod \BonusDecayInterval \\).

### Proposer Payout

The _proposer payout_ is the actual amount that is moved from the \\( I_f \\) to
the proposer, and is stored in msgpack field `pp`. If the proposer is not eligible,
as described below, the _proposer payout_ **MUST** be \\( 0 \\). The proposer payout
**MUST NOT** exceed

- The sum of the _bonus incentive_ and half of the _fees collected_.
- The fee sink balance minus \\( \MinBalance \\).

### Load

The block's _load_ measures how full the block is, based on the total size of its
transactions relative to the maximum permitted. It is stored in msgpack field `ld`
as a fixed-point value in millionths (six digits of precision), so that
\\( 1{,}000{,}000 \\) denotes a completely full block. The _load_ **MUST** equal

$$
\min\left( \left\lfloor \frac{1{,}000{,}000 \cdot s}{\MaxTxnBytesPerBlock} \right\rfloor, 1{,}000{,}000 \right)
$$

where \\( s \\) is the sum of the byte lengths of the canonical msgpack encoding
of each `SignedTxnInBlock` in the block's payset. The payset's array framing is
not included. This is the same total used to enforce
\\( \MaxTxnBytesPerBlock \\), the [maximum number of transaction bytes in a
block](./ledger-parameters.md).

### Congestion Tax

The block's _congestion tax_ measures network congestion. It is stored in msgpack
field `ct` as a fixed-point value in millionths, and is derived deterministically
from the previous block's _load_ and _congestion tax_: it rises when the previous
block was more than half full, falls when it was less than half full, and remains
unchanged when it was exactly half full. The congestion tax currently does not
affect the fee required by any transaction.

Let \\( L \\) and \\( C \\) be the _load_ and _congestion tax_ of the previous block,
and let

$$
d = \left\lfloor \frac{100{,}000 \cdot (500{,}000 - L)}{500{,}000} \right\rfloor, \qquad
u = \left\lfloor \frac{100{,}000 \cdot (L - 500{,}000)}{500{,}000} \right\rfloor.
$$

The _congestion tax_ of this block **MUST** equal

$$
\begin{cases}
\max\left( \left\lfloor \dfrac{C \cdot (1{,}000{,}000 - d)}{1{,}000{,}000} \right\rfloor - d, 0 \right),
& L \le 500{,}000, \\\\
\left\lfloor \dfrac{C \cdot (1{,}000{,}000 + u)}{1{,}000{,}000} \right\rfloor + u, & L > 500{,}000.
\end{cases}
$$

In the second case, the result saturates at the maximum representable value. The
target _load_ is half full (\\( 500{,}000 \\)); the multiplicative factor changes the
tax by at most \\( 10\\% \\) per block, while the additive term (at most
\\( 100{,}000 \\)) lets the tax grow away from, and return to, \\( 0 \\).

### Expired Participation Accounts

The block’s _expired participation accounts_, which contains an _optional_ list of
account addresses. These accounts’ [participation key](../keys/keys-participation.md)
expire by the end of the _current_ round, with exact rules below. The list is stored
in msgpack key `partupdrmv`.

### Suspended Participation Accounts

The block’s _suspended participation accounts_, which contains an _optional_ list
of account addresses. These accounts have not recently demonstrated that they are
available and participating, with exact rules below. The list is stored in msgpack
key `partupdabs`.

A proposer is _eligible_ for bonus payouts if the account’s `IncentiveEligible`
flag is true _and_ its online balance is between \\( \PayoutsMinBalance \\) and
\\( \PayoutsMaxBalance \\).

The _expired participation accounts_ list is valid as long as:

- The participation keys of all the accounts in the slice are expired by the end
of the round;

- The accounts themselves would have been online at the end of the round if they
were not included in the list;

- The number of elements in the list is less than or equal to \\( \MaxProposedExpiredOnlineAccounts \\).
A block proposer may not include all such accounts in the list and may even omit
the list completely.

The _suspended participation accounts_ list is valid if, for each included address,
the account is:

- _Online_;
- Incentive _eligible_;
- Either _absent_ or _failing a challenge_ as of the current round.

An account is _absent_ if its `LastHeartbeat` and `LastProposed` rounds are both
more than \\( 20n \\) rounds before `current`, where \\( n \\) is the reciprocal
of the account’s fraction of online stake.

An account is _failing a challenge_ if:

- The first \\( \PayoutsChallengeBits \\) bits of the account’s address matches the
first \\( \PayoutsChallengeBits \\) bits of an active challenge round’s block seed;
- The active challenge round is between \\( \PayoutsChallengeGracePeriod \\) and
\\( 2\PayoutsChallengeGracePeriod \\) rounds before the current round.

An active challenge round is a round that is \\( 0 \mod \PayoutsChallengeInterval \\).

The length of the list **MUST** not exceed \\( \PayoutMaxMarkAbsent \\).

A block proposer **MAY NOT** include all such accounts in the list and **MAY** even
omit the list completely.

## Block Body

The block body is the block’s transaction sequence (also known as _payset_), which
describes the sequence of updates (transactions) to the account state and box state.

## Block Validity

A block is _valid_ if each component is also _valid_. (The genesis block is always
valid).

_Applying_ a _valid_ block to a state produces a new state by updating each of its
components.

The rest of this document defines block validity and state transitions by describing
them for each component.

## Round {#round-definition}

The round or _round number_ is a 64-bit unsigned integer that indexes into the
sequence of states and blocks.

The round \\( r \\) of each block is one greater than the round of the previous block
(\\( r_i = r_{i-1} + 1 \\)).

Given a Ledger \\( L \\), the round of a block _exclusively_ identifies it.

The rest of this document describes components of states and blocks with respect
to some implicit Ledger. Thus, the round exclusively describes some component, and
we denote the round of a component with a subscript. For instance, the timestamp
of state/block \\( r \\) is denoted \\( t_r \\).

## Genesis

### Genesis Identifier {#genesis-identifier-definition}

The _genesis identifier_ is a short string that identifies an instance of a Ledger
\\( L \\).

The genesis identifier of a valid block is the identifier of the block in the previous
round. In other words, \\( \GenesisID_{r+1} = \GenesisID_{r} \\).

### Genesis Hash

The _genesis hash_ is a cryptographic hash of the genesis configuration, used to unambiguously
identify an instance of the Ledger \\( L \\).

The genesis hash is set in the genesis block (or the block at which an upgrade to
a protocol supporting \\( \GenesisHash \\) occurs), and **MUST** be preserved identically
in all subsequent blocks.

## Previous Hash {#previous-hash-definition}

The [_previous hash_](./ledger-block.md#previous-hash) is a cryptographic hash of
the previous block header in the sequence of blocks.

The sequence of previous hashes in each block header forms an authenticated, linked-list
of the reversed sequence.

Let \\( B_r \\) represent the block header in round \\( r \\), and let \\( \Hash \\)
be some cryptographic hash function.

Then the previous hash \\( \Prev_{r+1} \\) in the block for round \\( r+1 \\) is
\\( \Prev_{r+1} = \Hash(B_r) \\).

> [!NOTE]
> In the reference implementation, \\( \Hash \\) is the [SHA512/256 hash function](../crypto/crypto-sha512-256.md).

## Protocol Upgrade State

A protocol version \\( v \\) is a string no more than \\( \MaxVersionStringLen \\)
bytes long. It corresponds to parameters used to execute some version of the Algorand
protocol.

The upgrade vote in each block consists of:

- A protocol version \\( v_r \\);
- A 64-bit unsigned integer \\( x_r \\) which indicates the delay between the acceptance
of a protocol version and its execution;
- A single bit \\( b \\) indicating whether the block proposer supports the given
protocol version.

The upgrade state in each block/state consists of:

- The _current_ protocol version \\( v_r^{\ast} \\);
- The _next proposed_ protocol version \\( v_r^{\prime} \\);
- A 64-bit round number \\( s_r \\) counting the number of votes for the next protocol
version;
- A 64-bit round number \\( d_r \\) specifying the deadline for voting on the next
protocol version;
- A 64-bit round number \\( x_r^{\prime} \\) specifying when the next proposed protocol
version would take effect, if passed.

An upgrade vote \\( (v_r, x_r, b) \\) is _valid_ given the upgrade state
\\( (v_r^{\ast}, v_r^{\prime}, s_r, d_r, x_r^{\prime}) \\) if \\( v_r \\) is the
_empty_ string or \\( v_r^{\prime} \\) is the _empty_ string,
\\( \MinUpgradeWaitRounds \leq x_r \leq \MaxUpgradeWaitRounds \\), and either:

- \\( b = 0 \\) or
- \\( b = 1 \\) with \\( r < d_r \\) and either
  - \\( v_r^{\prime} \\) is not the empty string or
  - \\( v_r \\) is not the empty string.

If the vote is valid, then the new upgrade state is

$$
(v_{r+1}^{\ast}, v_{r+1}^{\prime}, s_{r+1}, d_{r+1}, x_{r+1})
$$

Where

- \\( v_{r+1}^{\ast} \\) is \\( v_r^{\prime} \\) if \\( r = x_r^{\prime} \\) and \\( v_r^{\ast} \\)
otherwise.

- \\( v^{\prime}_{r+1} \\) is
  - the empty string if \\( r = x_r^{\prime} \\) or both \\( r = s_r \\) and
  \\( s_r + b < \UpgradeThreshold \\),
  - \\( v_r \\) if \\( v_r^{\prime} \\) is the empty string, and
  - \\( v_r^{\prime} \\) otherwise.

- \\( s_{r+1} \\) is
  - \\( 0 \\) if \\( r = x_r^{\prime} \\) or both \\( r = s_r \\) and \\( s_r + b < \UpgradeThreshold \\), and
  - \\( s_r + b \\) otherwise

- \\( d_{r+1} \\) is
  - \\( 0 \\) if \\( r = x_r^{\prime} \\) or both \\( r = s_r \\) and \\( s_r + b < \UpgradeThreshold \\),
  - \\( r + \UpgradeVoteRounds \\) if \\( v_r^{\prime} \\) is the empty string and
  \\( v_r \\) is not the empty string, and
  - \\( d_r \\) otherwise.

- \\( x_{r+1} \\) is
  - \\( 0 \\) if \\( r = x_r^{\prime} \\) or both \\( r = s_r \\) and \\( s_r + b < \UpgradeThreshold \\),
  - \\( r + \UpgradeVoteRounds + \delta \\) if \\( v_r^{\prime} \\) is the empty string and \\( v_r \\) is not
  the empty string (where \\( \delta = \DefaultUpgradeWaitRounds \\) if \\( x_r = 0 \\)
  and \\( \delta = x_r \\) if \\( x_r \neq 0 \\)), and
  - \\( x_r^{\prime} \\) otherwise.

## Timestamp {#timestamp-definition}

The timestamp \\( t \\) is a 64-bit signed integer.

The timestamp is purely informational and states when a block was first proposed,
expressed in the number of seconds since the Unix epoch (00:00:00 UTC on Thursday,
1 January 1970).

The timestamp \\( t_{r+1} \\) of a block in round \\( r \\) is valid if:

- \\( t_{r} = 0 \\) or
- \\( t_{r+1} > t_{r} \\) and \\( t_{r+1} < t_{r} + \MaxTimestampIncrement \\).

> [!TIP]
> **EXAMPLE:**
>
> Suppose the block production stalls on round \\( r \\) for a prolonged time. When
> correct operations resume, a certain number \\( n \\) of blocks has to be committed
> until the timestamp catches up to external time references. If \\( t^{\ast} \\)
> is the current external time reference, then:
>
> $$
> n = \left\lceil \frac{t^{\ast} - t_{r}}{\MaxTimestampIncrement} \right\rceil
> $$

## Cryptographic Seed

The seed is a 256-bit integer.

Seeds are validated and updated according to the [specification of the Algorand
Byzantine Fault Tolerance protocol](../abft/abft.md).

The \\( \Seed \\) procedure specified there returns the seed from the desired round.

## Transaction Sequences, Sets, and Tails

### Transaction Sequence

Each block contains a _transaction sequence_, an ordered sequence of transactions
in that block.

The transaction sequence of block \\( r \\) is denoted \\( \TxSeq_r \\).

Each valid block contains a _transaction commitment_ \\( \TxCommit_r \\) which is
a [Merkle Tree Commitment](../crypto/crypto-merkle-tree.md) to this sequence.

The leaves in the Merkle Tree are hashed as:

$$
\Hash(\Domain{TL}, \TxID, \Hash(\STIB))
$$

Where:

- \\( \Hash \\) is the cryptographic [SHA-512-256](../crypto/crypto-sha512-256.md)
hash function;

- The \\( \TxID \\) is the 32-byte transaction identifier;

- The \\( \Hash(\STIB) \\) is a 32-byte hash of the _signed transaction_ and [ApplyData](./ledger-apply-data.md)
for the transaction, hashed with the [domain-separation prefix](../crypto/crypto-domain-separators.md)
\\( \\Domain{STIB} \\) (_signed transaction in block_).

_Signed transactions in a block_ \\( \STIB \\) are encoded in a slightly different
way than _standalone transactions_ \\( \Tx \\), for efficiency:

If a standalone transaction \\( \Tx \\) contains a \\( \GenesisID \\) value, then:

- The transaction’s \\( \GenesisID \\) **MUST** match the block’s \\( \GenesisID \\);

- The transaction’s \\( \GenesisID \\) value **MUST** be omitted from the \\( \STIB \\)
transaction’s msgpack encoding in the block;

- The \\( \STIB \\) transaction’s msgpack encoding in the block **MUST** indicate
the \\( \GenesisID \\) value was omitted by including a key `hgi` with the boolean
value `True`.

Since transactions **MUST** include a \\( \GenesisHash \\) value, the \\( \GenesisHash \\)
value of each transaction in a block **MUST** match the block’s \\( \GenesisHash \\),
and the \\( \GenesisHash \\) value is omitted from the \\( \STIB \\) transaction
as encoded in a block.

- Signed transactions in a block are also augmented with the \\( \ApplyData \\)
that reflect how that transaction was applied to the [Account State](./ledger-account-state.md).

The _transaction commitment_ (\\( \TxCommit \\)) for a block covers the transaction
encodings with the changes described above.

Individual _transaction signatures_ cover the original encoding of transactions as
standalone transactions (\\( \Tx \\)).

In addition to the _transaction commitment_, each block contains _[SHA-256](../crypto/crypto-sha256.md)
and [SHA-512](../crypto/crypto-sha512.md) transaction commitments_. They allow a
verifier not supporting [SHA-512/256](../crypto/crypto-sha512-256.md) function to
verify proof of membership for transactions.

To construct these commitments, we use a [Vector Commitment](../crypto/crypto-vector-commitment.md).

The leaves in the Vector Commitment tree are hashed respectively as:

$$
\SHATFS(\Domain{TL}, \SHATFS(\TxID), \SHATFS(\STIB))
$$

and

$$
\SHAFOT(\Domain{TL}, \SHAFOT(\TxID), \SHAFOT(\STIB))
$$

Where:

- \\( \SHATFS \\) is the cryptographic [SHA-256](../crypto/crypto-sha256.md) hash
function;

- \\( \SHATFS(\TxID) = \SHATFS(\Domain{TX} || \Tx) \\)

- \\( \SHATFS(\STIB) = \SHATFS(\Domain{STIB} || \Sig(\Tx) || \ApplyData) \\)

- \\( \SHAFOT \\) is the cryptographic [SHA-512](../crypto/crypto-sha512.md) hash
function;

- \\( \SHAFOT(\TxID) = \SHAFOT(\Domain{TX} || \Tx) \\)

- \\( \SHAFOT(\STIB) = \SHAFOT(\Domain{STIB} || \Sig(\Tx) || \ApplyData) \\)

These Vector Commitments use [SHA-256](../crypto/crypto-sha256.md) and [SHA-512](../crypto/crypto-sha512.md)
for internal nodes as well.

A _valid transaction sequence_ \\( \TxSeq \\) contains no duplicates: each transaction
in the transaction sequence **MUST** appear exactly once.

We can call the set of these transactions the _transaction set_ (for convenience,
we may also write \\( \TxSeq_r \\) to refer unambiguously to the set in this block).

For a block to be valid, its transaction sequence \\( \TxSeq_r \\) **MUST** be valid
(i.e., no duplicate transactions may appear there).

All transactions have a _size_ in bytes. The size of the transaction \\( \Tx \\)
is denoted \\( \abs{\Tx} \\).

For a block to be _valid_, the sum of the sizes of each transaction in a transaction
sequence **MUST NOT** exceed \\( \MaxTxnBytesPerBlock \\); in other words:

$$
\sum_{\Tx \in \TxSeq_r} \abs{\Tx} \leq \MaxTxnBytesPerBlock
$$

### Transaction Tails

The _transaction tail_ \\( \TxTail \\) for a given round \\( r \\) is a set produced
from the union of the transaction identifiers \\( \TxID \\) of each transaction in
the last \\( \MaxTxTail \\) transaction sets and is used to detect _duplicate_ transactions.

In other words,

$$
\TxTail_r = \bigcup_{r-\MaxTxTail \leq s \leq r-1} \{\Hash(\Tx) | \Tx \in \TxSeq_s\}.
$$

As a result, the _transaction tail_ for round \\( r+1 \\) is computed as follows:

$$
\TxTail_{r+1} = \TxTail_r \setminus \{\Hash(\Tx) | \Tx \in \TxSeq_{r-T_{\max}}\} \cup \{\Hash(\Tx) | \Tx \in \TxSeq_r\}.
$$

The transaction tail is part of the Ledger state but is _distinct_ from the account
state and is _not committed_ to in the block.
