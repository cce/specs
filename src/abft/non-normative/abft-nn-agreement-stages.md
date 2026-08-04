$$
\newcommand \EventHandler {\mathrm{EventHandler}}
\newcommand \BlockProposal {\mathrm{BlockProposal}}
\newcommand \BlockAssembly {\mathrm{BlockAssembly}}
\newcommand \SoftVote {\mathrm{SoftVote}}
\newcommand \CertificationVote {\mathrm{CertificationVote}}
\newcommand \Commitment {\mathrm{Commitment}}
\newcommand \Recovery {\mathrm{Recovery}}
\newcommand \FastRecovery {\mathrm{FastRecovery}}
\newcommand \DeadlineTimeout {\mathrm{DeadlineTimeout}}
\newcommand \Bundle {\mathrm{Bundle}}
\newcommand \HandleProposal {\mathrm{HandleProposal}}
\newcommand \HandleVote {\mathrm{HandleVote}}
\newcommand \HandleBundle {\mathrm{HandleBundle}}
\newcommand \Propose {\mathit{propose}}
\newcommand \Soft {\mathit{soft}}
\newcommand \Cert {\mathit{cert}}
\newcommand \Next {\mathit{next}}
\newcommand \Late {\mathit{late}}
\newcommand \Redo {\mathit{redo}}
\newcommand \Down {\mathit{down}}
\newcommand \ev {\mathit{ev}}
\newcommand \tme {\mathit{time}}
\newcommand \s {\mathit{step}}
\newcommand \data {\mathit{msg}_\text{data}}
\newcommand \TimeoutEvent {\texttt{TimeoutEvent}}
\newcommand \MessageEvent {\texttt{MessageEvent}}
\newcommand \DynamicFilterTimeout {\mathrm{DynamicFilterTimeout}}
$$

# Agreement Stages

The Algorand Agreement Protocol can be split into a series of stages.

In the normative section, these stages are univocally associated with infinite subsets
of protocol states. These subsets are disjoint and together represent the whole
space of possible states for the node state machine to be in.

The stages are, in chronological order within a given round:

- \\( \BlockProposal \\),
- \\( \SoftVote \\),
- \\( \CertificationVote \\), which includes a final \\( \Commitment \\).

If \\( \Commitment \\) is not possible because of external reasons (i.e., a network
partition), two fallback stages:

- \\( \FastRecovery \\),
- \\( \Recovery \\).

By abstracting away some implementation-specific complexity, we propose a model for
the Agreement Protocol state machine that captures how and when transitions between
different states happen.

## Algorithm

We may model the state machine’s main algorithm in the following way:

```pseudocode
\begin{algorithm}
\caption{Main State Machine}
\begin{algorithmic}
\Function{EventHandler}{$ev$}
  \If{$\ev$ is a $\TimeoutEvent$}
    \State $\tme \gets \ev_\tme$
    \If{$\tme = 0$} \Comment{Last round should have left us with s := propose}
      \State $\BlockProposal()$
      \If{finished a block $\lor \mathrm{CurrentTime}() = \mathrm{AssemblyDeadline}()$}
        \State $\s \gets \Soft$
      \EndIf
    \ElsIf{$time = \DynamicFilterTimeout(p)$}
      \State $\SoftVote()$
      \State $\s \gets \Cert$
    \ElsIf{$\tme = \DeadlineTimeout(p)$}
      \State $\s \gets \Next_0$
      \State $\Recovery()$
    \ElsIf{$\tme = \DeadlineTimeout(p) + 2^{s_t - 3}\lambda$ for $4 \le s_t \le 252$}
      \State $\s \gets \Next_{s_t}$
      \State $\Recovery()$
    \ElsIf{$\tme = k\lambda_f + rnd$ for $k, rnd \in \mathbb{Z}, k > 0, 0 \le rnd \le \lambda_f$}
      \State $\FastRecovery()$
    \EndIf
  \Else \Comment{MessageEvent could trigger a commitment and round advancement}
    \State $msg \gets ev_{msg}$
    \If{$\data$ is of type \texttt{Proposal} $pp$}
      \State $\HandleProposal(pp)$
    \ElsIf{$\data$ is of type \texttt{Vote} $v$}
      \State $\HandleVote(v)$
    \ElsIf{$\data$ is of type \texttt{Bundle} $b$}
      \State $\HandleBundle(b)$
    \EndIf
  \EndIf
\EndFunction
\end{algorithmic}
\end{algorithm}
```

The first three steps (\\( \Propose, \Soft, \Cert \\)) are the fundamental parts,
and will be the only steps run in regular “healthy” functioning conditions.

The following steps are _recovery procedures_ if there’s no observable consensus
before their trigger times.

Note that in the case of \\( \Propose \\), if a block is not assembled and finalized
in time for the \\( \BlockAssembly() \\) timeout, this might trigger advancement
to the next step.

> [!NOTE]
> For more information on this process, refer to the Algorand Ledger
> [non-normative section](../../ledger/non-normative/ledger-nn-txpool-block-assembly.md).

The \\( \Next_{s-3} \\) with \\( s \in [3, 252] \\) are _recovery_ steps, while
the last three (\\( \Late, \Redo, \Down \\)) are special _fast recovery_ steps.

A _period_ is an execution of a subset of steps, executed in order until one of
them achieves a _bundle_ for a specific _value_.

A round always starts with a \\( \Propose \\) step and finishes with a \\( \Cert \\)
step (when a block becomes commitable, it is certified and committed to the Ledger).

However, multiple periods might be executed inside a round until:

- A _certification bundle_ (\\( \Bundle(r,p,s,v) \\) where \\( s = \Cert \\)) is
observable by the network, and

- The corresponding _proposal_ \\( Proposal(v) \\) has been received and validated,
and

- The _proposal payload_ is available at the moment of commitment.

## Events

Events are _the only way_ for the node state machine to transition internally and
produce output.

> [!IMPORTANT]
> **IMPLEMENTATION:**
>
> Events [reference implementation](https://github.com/algorand/go-algorand/blob/c60db8dbc4b0dd164f0bb764e1464d4ebef38bb4/agreement/events.go#L76).

If an event is not identified as _misconstrued_ or _malicious_, it will produce
a state change. Also, it will almost certainly cause a receiving node to
produce and then broadcast or relay an output, consumed by its peers in the network.

There are two main kinds of events:

- \\( \TimeoutEvent \\), which are produced once the _internal clock_ of a node
reaches a specific time since the start of the _current period_;

- \\( \MessageEvent \\), which are outputs produced by nodes in response to some
stimulus (including the receiving node itself).

Internally, we consider the structure of an event to be composed of:

- A floating point number, representing time (in seconds) from the start of the
_current period_, in which the event has been triggered;

- An _event type_, from an enumeration;

- A _data type_;

- Some _attached data_, plain bytes to be cast and interpreted according to the attached
data type, or empty in case of a timeout event.

### Time Events

\\( \TimeoutEvent \\) are triggered when a specific time has elapsed after the start
of a new period.

- \\( \Soft \\) timeout (a.k.a. Filtering): is run after a timeout of \\( \DynamicFilterTimeout(p) \\)
is observed (where \\( p \\) is the currently running period). Note that it only
depends on the period, whether it’s the first period in the round or a later one.
In response to this, the node state machine will perform a filtering action, finding
the highest priority proposal observed to produce a _soft vote_ (as detailed in
the \\( \SoftVote \\) algorithm).

- \\( \Next_0 \\) timeout: it triggers the first recovery step, only executed if
no consensus for a specific value was observed, and no \\( \Cert \\) bundle is
constructible with observed votes. It plays after observing a timeout of \\( \DeadlineTimeout(p) \\).
In this step, the node will _next vote_ a value and attempt to reach a consensus
for a \\( \Next_0 \\) bundle, that would kickstart a new period.

- \\( \Next_s \\) timeout: this family of timeouts runs whenever the elapsed time
since the start of the _current period_ reaches \\( \DeadlineTimeout(p) + 2^{s_t-3}\lambda \\)
for some \\( 4 \le s_t \le 252 \\). The algorithm run is the same as in the \\( \Next_0 \\)
step.

> [!IMPORTANT]
> **IMPLEMENTATION:**
>
> Next vote ranges [to reference implementation](https://github.com/algorand/go-algorand/blob/55011f93fddb181c643f8e3f3d3391b62832e7cd/agreement/types.go#L103C15-L103C29).

- (\\( \Late, \Redo, \Down \\)) fast recovery timeouts: on observing a timeout of
\\( k\lambda_f + rnd \\) with \\( rnd \\) a uniform random sample in \\( [0, \lambda_f] \\)
and \\( k \\) a positive integer, the fast recovery algorithm is executed. It works
very similarly to \\( \Next_k \\) timeouts, with some subtle differences (besides
trigger time).

> [!NOTE]
> For a detailed description, refer to its [subsection](./abft-nn-fast-recovery.md).

### Message Events

\\( \MessageEvent \\) are events triggered after observing a specific message carrying
data.

In the _Main State Machine_ algorithm, we focused on three kinds of messages:

- \\( \texttt{Proposal} \\),
- \\( \texttt{Vote} \\),
- \\( \texttt{Bundle} \\),

Each carries the corresponding construct (coinciding with their attached data type
field).
