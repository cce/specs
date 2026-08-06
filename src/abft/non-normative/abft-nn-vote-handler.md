$$
\newcommand \ValidateVote {\mathrm{ValidateVote}}
\newcommand \VerifyVote {\mathrm{VerifyVote}}
\newcommand \SenderPeer {\mathrm{SenderPeer}}
\newcommand \DisconnectFromPeer {\mathrm{DisconnectFromPeer}}
\newcommand \Equivocation {\mathrm{Equivocation}}
\newcommand \IsEquivocation {\mathrm{IsEquivocation}}
\newcommand \IsSecondEquivocation {\mathrm{IsSecondEquivocation}}
\newcommand \HandleVote {\mathrm{HandleVote}}
\newcommand \Relay {\mathrm{Relay}}
\newcommand \RetrieveProposal {\mathrm{RetrieveProposal}}
\newcommand \Broadcast {\mathrm{Broadcast}}
\newcommand \Bundle {\mathrm{Bundle}}
\newcommand \Vote {\mathrm{Vote}}
\newcommand \Sortition {\mathrm{Sortition}}
\newcommand \RequestProposal {\mathrm{RequestProposal}}
\newcommand \StartNewPeriod {\mathrm{StartNewPeriod}}
\newcommand \GarbageCollect {\mathrm{GarbageCollect}}
\newcommand \StartNewRound {\mathrm{StartNewRound}}
\newcommand \Commit {\mathrm{Commit}}
\newcommand \Prop {\mathit{propose}}
\newcommand \Next {\mathit{next}}
\newcommand \Soft {\mathit{soft}}
\newcommand \Cert {\mathit{cert}}
\newcommand \sk {\mathrm{sk}}
\newcommand \vt {\mathit{vote}}
\newcommand \creds {\mathit{credentials}}
$$

# Vote Handler

The algorithms presented in this section abstract away a series of behaviors as
a single vote handler for ease of understanding and to provide an implementation-agnostic
engineering overview.

In the reference implementation, the vote verification and vote observation, although
dependent on each other, are performed by separate processes.

Note that an _equivocation vote_ is a pair of votes that differ only in their _proposal
values_ \\( v \\). In other words, given a player \\( I \\) and a node’s context
tuple \\((r, p, s)\\), \\( \Equivocation(I, r, p, s) = (\Vote(I, r, p, s, v_1), \Vote(I, r, p, s, v_2)) \\)
for some \\( v_1 \neq v_2 \\).

## Algorithms

```pseudocode
\begin{algorithm}
\caption{Validate Vote}
\begin{algorithmic}
\Function{ValidateVote}{$\vt$}
  \If{$\lnot \VerifyVote(\vt)$}
    \State $\DisconnectFromPeer(\SenderPeer(\vt))$
    \Return \Comment{Ignore invalid vote}
  \EndIf
  \If{$\vt_s = 0 \land (\vt \in V \lor \IsEquivocation(\vt))$}
    \Return \Comment{Ignore vote, equivocation not allowed in proposal votes}
  \EndIf
  \If{$\vt_s > 0 \land \IsSecondEquivocation(\vt)$}
    \Return \Comment{Ignore vote if it’s a second equivocation}
  \EndIf
  \If{$\vt_r < r$}
    \Return \Comment{Ignore vote of past round}
  \EndIf
  \If{$\vt_r = r + 1 \land (\vt_p > 0 \lor \vt_s \in \{\Next_0, \dots, \Next_{249}\})$}
    \Return \Comment{Ignore vote of next round if non-zero period or next-k step}
  \EndIf
  \If{$\vt_r = r \land (\vt_p \notin \{p-1, p, p+1\} \lor (\vt_p = p+1 \land \vt_s \in \{\Next_1, \dots, \Next_{249}\}) \lor (\vt_p = p \land \vt_s \in \{\Next_1, \dots, \Next_{249}\} \land \vt_s \notin \{s-1, s, s+1\}) \lor (\vt_p = p-1 \land \vt_s \in \{\Next_1, \dots, \Next_{249}\} \land \vt_s \notin \{\bar{s}-1, \bar{s}, \bar{s}+1\}))$}
    \Return \Comment{Ignore vote}
  \EndIf
\EndFunction
\end{algorithmic}
\end{algorithm}
```

Votes that pass validation are then handled as follows:

```pseudocode
\begin{algorithm}
\caption{Handle Vote}
\begin{algorithmic}
\Function{HandleVote}{$\vt$}
  \State $\ValidateVote(\vt)$ \Comment{Check the validity of the vote}
  \State $V \gets V \cup \vt$ \Comment{Observe the vote}
  \State $\Relay(\vt)$
  \If{$\vt_s = \Prop$}
    \If{$\RetrieveProposal(\vt_v) \neq \bot$}
      \State $\Broadcast(\RetrieveProposal(\vt_v))$
    \EndIf
  \ElsIf{$\vt_s = \Soft$}
    \If{$\exists v : \Bundle(\vt_r, \vt_p, \Soft, v) \subset V$}
      \For{$a \in A$}
        \State $\creds \gets \Sortition(a_{\sk}, r, p, \Cert)$
        \If{$\creds_j > 0$}
          \State $\Broadcast(\Vote(a_I, r, p, \Cert, v, \creds))$
        \EndIf
      \EndFor
    \EndIf
  \ElsIf{$\vt_s = \Cert$}
    \If{$\exists v : \Bundle(\vt_r, \vt_p, \Cert, v) \subset V$}
      \If{$\RetrieveProposal(v) = \bot$}
        \State $\RequestProposal(v)$
        \If{$p < \vt_p$}
          \State $p_{old} \gets p$
          \State $\StartNewPeriod(\vt_p)$
          \State $\GarbageCollect(r, p_{old})$
        \EndIf
      \EndIf
      \State $\Commit(v)$
      \State $r_{old} \gets r$
      \State $\StartNewRound(\vt_r + 1)$
      \State $\GarbageCollect(r_{old}, p)$
    \EndIf
  \ElsIf{$\vt_s > \Cert$}
    \If{$\exists v : \Bundle(\vt_r, \vt_p, \vt_s, v) \subset V$}
      \State $p_{old} \gets p$
      \State $\StartNewPeriod(\vt_p + 1)$
      \State $\GarbageCollect(r, p_{old})$
    \EndIf
  \EndIf
\EndFunction
\end{algorithmic}
\end{algorithm}
```

> [!IMPORTANT]
> **IMPLEMENTATION:**
>
> Relevant parts of the reference implementation related to vote handling:
>
> - [Vote verification](https://github.com/algorand/go-algorand/blob/b6e5bcadf0ad3861d4805c51cbf3f695c38a93b7/agreement/vote.go#L97).
> - [Vote handling in the vote tracker](https://github.com/algorand/go-algorand/blob/55011f93fddb181c643f8e3f3d3391b62832e7cd/agreement/voteTracker.go#L97).
> - [Vote handling in the proposal manager](https://github.com/algorand/go-algorand/blob/c60db8dbc4b0dd164f0bb764e1464d4ebef38bb4/agreement/proposalManager.go#L57).
> - [Threshold handling](https://github.com/algorand/go-algorand/blob/b6e5bcadf0ad3861d4805c51cbf3f695c38a93b7/agreement/player.go#L355).
> - [Certification vote issuance](https://github.com/algorand/go-algorand/blob/d52e3dd8b31a17dfebac3d9158a76e8e62617462/agreement/player.go#L209).
> - [Equivocation vote verification](https://github.com/algorand/go-algorand/blob/df0613a04432494d0f437433dd1efd02481db838/agreement/vote.go#L193-L223).

The vote handler is triggered when a node receives a _message_ containing a _vote_
for a given _proposal value_, _round_, _period_, or _step_.

It first performs a series of checks, and if the received vote passes all of them,
then it is broadcast by all accounts selected as the appropriate committee members.

### Vote Validation

On Line 2, the \\( \ValidateVote \\) function checks if the vote is valid. If invalid,
this is considered adversarial behavior. Therefore, a node may disconnect from the
vote sender node (Line 3), retrieving the network ID of the original message sender
with the \\( \SenderPeer \\) helper network module function.

> [!NOTE]
> For more details on disconnection actions and the definition of a _peer_, refer
> to the Algorand Network Layer [non-normative section](../../network/network-overview.md).

Equivocation votes on a proposal step are not allowed, so a check for this condition
is performed (Line 6).

Furthermore, second equivocations are never allowed (Line 9).

Any votes for rounds _before_ the current round are discarded (Line 12).

In the special case of receiving a message vote for a round _immediately after_
the _current_ round, the node observes it only if it is related to the _first period_
(\\( p = 0 \\)), in any of the following _steps_: proposal, soft, cert, late, down,
or redo (ignoring votes for further periods \\( p > 0 \\) or for \\( \Next_k \\)
steps).

Finally, the node checks that (Line 18) if the vote’s round is for the _currently executing_
round, and one of the following:

- Vote’s _period_ is not the _current node period_, the _period before_, or the _next period_, or

- Vote’s _period_ is the _next period_, and
  - Its _step_ is \\( \Next_k \\) with \\( k \geq 1 \\), or

- Vote’s _period_ is the _current node period_, and
  - Its _step_ is \\( \Next_k \\) with \\( k \geq 1 \\), and
  - Its _step_ is not the _current step_, the _step before_, or the _next step_, or

- Vote’s _period_ is the _period before_, and
  - Its _step_ is \\( \Next_k \\) with \\( k \geq 1 \\), and
  - Its _step_ distance is not one or less from the node’s _last finished step_.

Then the vote is ignored and discarded. Note that the _equivocation vote_ verification
uses the same verification functions, but verifies that both constituent votes are
valid separately.

### Vote Handling

Once finished with the series of validation checks, the vote is observed, relayed,
and then processed by the node according to its _current context_ and the vote’s
_step_:

- If the vote’s step is \\( \Prop \\), and the proposal corresponding to the proposal-value
\\( v \\) has already been observed, the proposal is broadcast (that is, the node
performs a re-proposal payload broadcast).

- If the vote’s step is \\( Soft \\), and a \\( \Soft \Bundle \\) has been
observed with the addition of the vote, the \\( \Sortition \\) sub-procedure
is run for every _online_ account managed by the node. Then, a \\( Cert \\) vote
is cast for each account the lottery selects.

- If the vote’s step is \\( Cert \\), and observing the vote causes the node to
observe a \\( Cert \Bundle \\) for a proposal-value \\( v \\), then it checks if
the full proposal associated with the critical value has been observed. Simultaneous
observation of a \\( Cert \Bundle \\) for a value \\( v \\) and of a proposal
equal to \\( RetrieveProposal(v) \\) implies the associated entry is committable.
If the full proposal has not yet been observed, the node may stall and request the
full proposal from the network. Once the desired proposal can be committed, the
node proceeds to commit, start a new round, and garbage collects all transient
data from the round it just finished.

- Finally, if the vote is that of a _recovery step_ (\\( s > \Cert \\)), and a
\\( \Bundle \\) has been observed for a given proposal-value \\( v \\), then a
_new period_ is started, and the currently executing period-specific data is garbage
collected.
