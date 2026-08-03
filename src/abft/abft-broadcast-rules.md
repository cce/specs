$$
\newcommand \pk {\mathrm{pk}}
\newcommand \sk {\mathrm{sk}}
\newcommand \Vote {\mathrm{Vote}}
\newcommand \fv {\text{first}}
\newcommand \Record {\mathrm{Record}}
\newcommand \lv {\text{last}}
\newcommand \Stake {\mathrm{Stake}}
\newcommand \Seed {\mathrm{Seed}}
\newcommand \CommitteeThreshold {\mathrm{CommitteeThreshold}}
\newcommand \CommitteeSize {\mathrm{CommitteeSize}}
\newcommand \Sign {\mathrm{Sign}}
$$

# Broadcast Rules

Upon observing messages or receiving timeout events, the player state
machine emits network outputs, which are externally visible. The
player may also append an entry to the ledger.

A correct player emits only valid votes. Suppose the player is
identified with the address \\( I \\) and possesses the secret key \\( \sk \\),
and the agreement is occurring on the ledger \\(L\\). Then the player
constructs a vote \\( \Vote(I, r, p, s, v) \\) by doing the following:

- Let
  - \\(( \pk, B, r_\fv, r_\lv) = \Record(L, r - \delta_b, I) \\),
  - \\( \bar{B} = \Stake(L, r - \delta_b) \\),
  - \\( Q = \Seed(L, r - \delta_s) \\),
  - \\( \tau = \CommitteeThreshold(s) \\),
  - \\( \bar{\tau} = \CommitteeSize(s) \\).

- Encode \\( x := (I, r, p, s, v), x' := (I, r, p, s) \\).

- Try to set \\( y := \Sign(x, x', \sk, B, \bar{B}, Q, \tau, \bar{\tau}) \\).

If the signing procedure succeeds, the player broadcasts
\\( Vote(I, r, p, s, v) = (I, r, p, s, v, y) \\). Otherwise, the player
does not broadcast anything.

For certain broadcast vote-messages specified here, a node is
forbidden to _equivocate_ (i.e., produce a pair of votes which contain
the same round, period, and step but which vote for different proposal
values). These messages are marked with an asterisk (*) below. To
prevent accidental equivocation after a power failure, nodes **SHOULD**
checkpoint their state to crash-safe storage before sending these
messages.

> [!NOTE]
> For further details on these checkpoint strategies, refer to the
> [non-normative Ledger specification](../ledger/non-normative/ledger-nn.md). For an in-depth
> review of broadcasting functionalities, refer to the [non-normative Network specification](../network/network-overview.md).

$$
\newcommand \Bundle {\mathrm{Bundle}}
\newcommand \Soft {\mathit{soft}}
\newcommand \Cert {\mathit{cert}}
\newcommand \Proposal {\mathrm{Proposal}}
$$

# Resynchronization Attempt

Where specified, a player attempts to resynchronize.

A resynchronization attempt involves the following stages.

First, the player broadcasts its _freshest bundle_, if one exists.

A player's freshest bundle is a complete bundle defined as follows:

- \\( \Bundle(r, p, \Soft, v) \subset V \\) for some \\( v \\), if it exists, or
else

- \\( \Bundle(r, p-1, s, \bot) \subset V \\) for some \\( s > \Cert \\), if it exists,
or else

- \\( \Bundle(r, p-1, s, v) \subset V \\) for some \\( s > \Cert, v \neq \bot \\),
if it exists.

> [!IMPORTANT]
> **IMPLEMENTATION:**
>
> Freshness relation [reference implementation](https://github.com/algorand/go-algorand/blob/b6e5bcadf0ad3861d4805c51cbf3f695c38a93b7/agreement/events.go#L745).

Second, if the player broadcasted a bundle \\( \Bundle(r, p, s, v) \\), and \\( v \neq \bot \\),
then the player broadcasts \\( \Proposal(v) \\) if the player has it.

Specifically, a resynchronization attempt:

- Corresponds to no additional outputs if no freshest bundle exists

$$
N(S, L, \ldots) = (S', L', \ldots),
$$

- Corresponds to a broadcast of the freshest bundle after a relay output and before
any subsequent broadcast outputs, if said bundle exists, no matching proposal exists

$$
N(S, L, \ldots) = (S', L', (\ldots, \Bundle^\ast(r, p, s, v), \ldots)),
$$

- Otherwise corresponds to a broadcast of both a bundle and its associated
proposal after a relay output and before any subsequent broadcast
outputs

$$
N(S, L, \ldots) = (S', L', (\ldots, \Bundle^\ast(r, p, s, v), \Proposal(v), \ldots)).
$$

$$
\newcommand \pk {\mathrm{pk}}
\newcommand \Bundle {\mathrm{Bundle}}
\newcommand \Cert {\mathit{cert}}
\newcommand \Proposal {\mathrm{Proposal}}
\newcommand \Vote {\mathrm{Vote}}
\newcommand \Entry {\mathrm{Entry}}
\newcommand \Seed {\mathrm{Seed}}
\newcommand \Sign {\mathrm{Sign}}
\newcommand \Rand {\mathrm{Rand}}
\newcommand \Hash {\mathrm{Hash}}
\newcommand \Digest {\mathrm{Digest}}
\newcommand \Encoding {\mathrm{Encoding}}
$$

# Proposals

On observing that \\( (r, p) \\) has begun, the player attempts to
resynchronize, and then

- if \\( p = 0 \\) or there exists some \\( s > \Cert \\) where \\( \Bundle(r, p-1, s, \bot) \\)
was observed, then a player generates a new proposal \\( (v', \Proposal(v')) \\) and
then broadcasts \\( (\Vote(I, r, p, 0, v'), \Proposal(v')) \\).

- if \\( p > 0 \\) and there exists some \\( s_0 > \Cert, v \\) where \\( \Bundle(r, p-1, s_0, v) \\)
was observed, while there exists no \\( s_1 > \Cert \\) where \\( \Bundle(r, p-1, s_1, \bot) \\)
was observed, then the player broadcasts \\( \Vote(I, r, p, 0, v) \\). Moreover, if
\\( \Proposal(v) \in P \\), the player then broadcasts \\( \Proposal(v) \\).

A player generates a new proposal by executing the entry-generation
procedure and by setting the fields of the proposal
accordingly. Specifically, the player creates a proposal payload
\\( ((o, s), y) \\) by setting

- \\( o := \Entry(L) \\),

- \\( Q := \Seed(L, r-1) \\),

- \\( y := \Sign(Q, Q, 0, 0, 0, 0, 0, 0) \\),

- and \\( s := \Rand(y, \pk)\\) if \\( p = 0 \\) or \\( s := \Hash(\Seed(L, r-1)) \\)
otherwise.

This consequently defines the matching proposal-value \\( v = (I, p, \Digest(e), \Hash(\Encoding(e))) \\).

> [!NOTE]
> For an in-depth overview of how proposal generation may be implemented, refer
> to the Algorand Ledger [non-normative section](../ledger/non-normative/ledger-nn.md).

In other words, if the player generates a new proposal,

$$
N(S, L, \ldots) = (S', L', (\ldots, \Vote(I, r, p, 0, v'), \Proposal(v'))),
$$

while if the player broadcasts an old proposal,

$$
N(S, L, \ldots) = (S', L', (\ldots, \Vote(I, r, p-1, 0, v), \Proposal(v)))
$$

if \\( \Proposal(v) \in P \\) and

$$
N(S, L, \ldots) = (S', L', (\ldots, \Vote(I, r, p-1, 0, v)))
$$

otherwise.

$$
\newcommand \Vote {\mathrm{Vote}}
\newcommand \Proposal {\mathrm{Proposal}}
$$

# Reproposal Payloads

On observing \\( \Vote(I, r, p, 0, v) \\), if \\( \Proposal(v) \in P \\) then the
player broadcasts \\( \Proposal(v) \\).

In other words, if \\( \Proposal(v) \in P \\),

$$
N(S, L, \Vote(I, r, p, 0, v)) = (S', L', (\Proposal(v))).
$$

$$
\newcommand \FilterTimeout {\mathrm{FilterTimeout}}
\newcommand \Cert {\mathit{cert}}
\newcommand \Soft {\mathit{soft}}
\newcommand \Vote {\mathrm{Vote}}
\newcommand \Bundle {\mathrm{Bundle}}
$$

# Filtering

On observing a timeout event of \\( \FilterTimeout(p) \\) (where
\\( \mu = (H, H', l, p_\mu) = \mu(S, r, p) \\)),

- if \\( \mu \neq \bot \\) and if
  - \\( p_\mu = p \\) or
  - there exists some \\( s > \Cert \\) such that \\( \Bundle(r, p-1, s, \mu) \\)
was observed then the player broadcasts \\( \Vote(I, r, p, \Soft, \mu) \\).

- if there exists some \\( s_0 > \Cert \\) such that \\( \Bundle(r, p-1, s_0, \bar{v}) \\)
was observed and there exists no \\( s_1 > \Cert \\) such that \\( \Bundle(r, p-1, s_1, \bot) \\)
was observed, then the player broadcasts* \\( \Vote(I, r, p, \Soft, \bar{v}) \\).

- otherwise, the player does nothing.

> [!NOTE]
> For a detailed overview of how the filtering step may be implemented, refer to
> the Algorand ABFT [non-normative section](./non-normative/abft-nn.md).

In other words, in the first case above,

$$
N(S, L, t(\FilterTimeout(p), p)) = (S, L, \Vote(I, r, p, \Soft, \mu));
$$

while in the second case above,

$$
N(S, L, t(\FilterTimeout(p), p)) = (S, L, \Vote(I, r, p, \Soft, \bar{v}));
$$

and if neither case is true,

$$
N(S, L, t(\FilterTimeout(p), p)) = (S, L, \epsilon).
$$

$$
\newcommand \Cert {\mathit{cert}}
\newcommand \Soft {\mathit{soft}}
\newcommand \Vote {\mathrm{Vote}}
\newcommand \Bundle {\mathrm{Bundle}}
\newcommand \Proposal {\mathrm{Proposal}}
$$

# Certifying

On observing that some proposal-value \\( v \\) is committable for its
current round \\( r \\), and some period \\( p' \geq p \\) (its current period),
if \\( s \leq \Cert \\), then the player broadcasts*
\\( \Vote(I, r, p, \Cert, v) \\). (It can be shown that this occurs either
after a proposal is received or a soft-vote, which can be part of a
bundle, is received.)

> [!NOTE]
> For a detailed overview of how the certification step may be implemented, refer
> to the Algorand ABFT [non-normative section](./non-normative/abft-nn.md).

In other words, if observing a soft-vote causes a proposal-value to
become committable,

$$
N(S, L, \Vote(I, r, p, \Soft, v)) = (S', L, (\ldots, \Vote(I, r, p, \Cert, v)));
$$

while if observing a bundle causes a proposal-value to become
committable,

$$
N(S, L, \Bundle(r, p, \Soft, v)) = (S', L, (\ldots, \Vote(I, r, p, \Cert, v)));
$$

and if observing a proposal causes a proposal-value to become
committable,

$$
N(S, L, \Proposal(v)) = (S', L, (\ldots, \Vote(I, r, p, \Cert, v)));
$$

as long as \\( s \leq \Cert \\).

$$
\newcommand \Cert {\mathit{cert}}
\newcommand \Vote {\mathrm{Vote}}
\newcommand \Bundle {\mathrm{Bundle}}
\newcommand \Proposal {\mathrm{Proposal}}
$$

# Commitment

On observing \\( \Bundle(r, p, \Cert, v) \\) for some value \\( v \\), the player
_commits_ the entry \\( e \\) corresponding to \\( \Proposal(v) \\); i.e., the
player appends \\( e \\) to the sequence of entries on its ledger \\( L \\).
(Evidently, this occurs either after a vote is received or after a
bundle is received.)

> [!NOTE]
> For further details on how entry commitment may be implemented, refer to the
> Algorand Ledger [non-normative section](../ledger/non-normative/ledger-nn.md).

In other words, if observing a cert-vote causes the player to commit
\\( e \\),

$$
N(S, L, \Vote(I, r, p, \Cert, v)) = (S', L || e, \ldots));
$$

while if observing a bundle causes the player to commit \\( e \\),

$$
N(S, L, \Bundle(r, p, \Cert, v)) = (S', L || e, \ldots)).
$$

> [!NOTE]
> Occasionally, an implementation may not have \\( e \\) at the point \\( e \\)
> becomes committed. In this case, the implementation may wait until it receives
> \\( e \\) somehow (perhaps by requesting peers for \\( e \\)). Alternatively,
> the implementation may continue running the protocol until it receives \\( e \\).
> However, if the protocol chooses to continue running, it may not transmit any
> vote for which \\( v \neq \bot \\) until it has committed \\( e \\).

$$
\newcommand \Cert {\mathit{cert}}
\newcommand \Next {\mathit{next}}
\newcommand \DeadlineTimeout {\mathrm{DeadlineTimeout}}
\newcommand \Vote {\mathrm{Vote}}
\newcommand \Bundle {\mathrm{Bundle}}
$$

# Recovery

On observing a timeout event of

- \\( T = \DeadlineTimeout(p) \\) or

- \\( T = \DeadlineTimeout(p) + 2^{s_t}\lambda + u \\) where
\\( u \in [0, 2^{s_t}\lambda] \\) sampled uniformly at random,

the player attempts to resynchronize and then broadcasts*
\\( \Vote(I, r, p, \Next_h, v) \\) where

- \\( v = \sigma(S, r, p) \\) if \\( v \\) is committable in \\( (r, p) \\),

- \\( v = \bar{v} \\) if there does not exist a \\( s_0 > \Cert \\) such that
\\( \Bundle(r, p-1, s_0, \bot) \\) was observed and there exists an \\( s_1 > \Cert \\)
such that \\( \Bundle(r, p-1, s_1, \bar{v} )\\) was observed,

- and \\( v = \bot \\) otherwise.

> [!IMPORTANT]
> **IMPLEMENTATION:**
>
> Next vote issuance [reference implementation](https://github.com/algorand/go-algorand/blob/b6e5bcadf0ad3861d4805c51cbf3f695c38a93b7/agreement/player.go#L214).
>
> Next vote timeout ranges computation [reference implementation](https://github.com/algorand/go-algorand/blob/5c49e9a54dfea12c6cee561b8611d2027c401163/agreement/types.go#L103).
>
> Call to \\( \Next_0 \\) [reference implementation](https://github.com/algorand/go-algorand/blob/b6e5bcadf0ad3861d4805c51cbf3f695c38a93b7/agreement/player.go#L125).
>
> Subsequent calls to \\( \Next_{st} \\) [reference implementation](https://github.com/algorand/go-algorand/blob/b6e5bcadf0ad3861d4805c51cbf3f695c38a93b7/agreement/player.go#L128).
>
> Step increase in recovery step timeouts [reference implementation](https://github.com/algorand/go-algorand/blob/b6e5bcadf0ad3861d4805c51cbf3f695c38a93b7/agreement/player.go#L131).

> [!NOTE]
> For a detailed overview of how the recovery routine may be implemented, refer
> to the Algorand ABFT [non-normative section](./non-normative/abft-nn.md).

In other words, if a proposal-value \\( v \\) is committable in the current
period,

$$
N(S, L, t(T, p)) = (S', L, (\ldots, \Vote(I, r, p, \Next_h, v)));
$$

while in the second case,

$$
N(S, L, t(T, p)) = (S', L, (\ldots, \Vote(I, r, p, \Next_h, \bar{v})));
$$

and otherwise,

$$
N(S, L, t(T, p)) = (S', L, (\ldots, \Vote(I, r, p, \Next_h, \bot))).
$$

$$
\newcommand \Vote {\mathrm{Vote}}
\newcommand \Bundle {\mathrm{Bundle}}
\newcommand \Cert {\mathit{cert}}
\newcommand \Late {\mathit{late}}
\newcommand \Redo {\mathit{redo}}
\newcommand \Down {\mathit{down}}
$$

# Fast Recovery

On observing a timeout event of \\( T = k\lambda_f + u \\) where \\( k \\) is a positive
integer and \\( u \in [0, \lambda_f] \\) sampled uniformly at random, the player
attempts to resynchronize. Then,

- The player broadcasts* \\( \Vote(I, r, p, \Late, v) \\) if \\( v = \sigma(S, r, p) \\)
is committable in \\( (r, p) \\).

- The player broadcasts* \\( \Vote(I, r, p, \Redo, \bar{v}) \\) if there does not exist
a \\( s_0 > \Cert \\) such that \\( \Bundle(r, p-1, s_0, \bot) \\) was observed and there
exists an \\( s_1 > \Cert \\) such that \\( \Bundle(r, p-1, s_1, \bar{v}) \\) was observed.

- Otherwise, the player broadcasts* \\( \Vote(I, r, p, \Down, \bot) \\).

Finally, the player broadcasts all \\( \Vote(I, r, p, \Late, v) \in V\\), all
\\( \Vote(I, r, p, \Redo, v) \in V\\), and all \\( \Vote(I, r, p, \Down, \bot) \in V \\)
that it has observed.

> [!IMPORTANT]
> **IMPLEMENTATION:**
>
> Fast recovery [reference implementation](https://github.com/algorand/go-algorand/blob/b6e5bcadf0ad3861d4805c51cbf3f695c38a93b7/agreement/player.go#L150).

> [!NOTE]
> For a detailed pseudocode overview of the fast recovery routine, along with protocol
> recovery run examples, refer to the Algorand ABFT [non-normative section](./non-normative/abft-nn.md).
