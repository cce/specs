$$
\newcommand \Recovery {\mathrm{Recovery}}
\newcommand \FastRecovery {\mathrm{FastRecovery}}
\newcommand \Resync {\mathrm{Resync}}
\newcommand \Sortition {\mathrm{Sortition}}
\newcommand \Broadcast {\mathrm{Broadcast}}
\newcommand \IsCommittable {\mathrm{IsCommittable}}
\newcommand \Vote {\mathrm{Vote}}
\newcommand \Bundle {\mathrm{Bundle}}
\newcommand \Cert {\mathit{cert}}
\newcommand \Late {\mathit{late}}
\newcommand \Redo {\mathit{redo}}
\newcommand \Down {\mathit{down}}
\newcommand \Next {\mathit{next}}
\newcommand \vt {\mathit{vote}}
\newcommand \creds {\mathit{credentials}}
\newcommand \s {\mathit{step}}
$$

# Fast Recovery

The fast recovery algorithm is executed periodically every integer multiple of
\\( \lambda_f \\) seconds (plus finite random variance).

This results in an approximately linear execution rate, while the network partitioning
continues.

The algorithm uses the last three steps (named \\( \Late, \Redo, \Down \\) respectively)
for \\( \s \in [253, 254, 255] \\).

These steps are, by nature, mutually exclusive:

- A \\( \Late \\)-vote will be attempted if a staged value \\( \sigma \\) is available
(for the current round and period),

- Otherwise, a \\( \Redo \\)-vote will be attempted if the current period \\( p > 0 \\),
and the last period was completed with a \\( \Next \\)-threshold for a proposal-value
_different_ from \\( \bot \\),

- Finally, as a fallback, a \\( \Down \\)-vote is attempted if none of the above
conditions were met.

> [!NOTE]
> A \\( \Down \\)-vote is always a vote for the \\( \bot \\) proposal-value, while
> \\( \Late \\) and \\( \Redo \\) must vote for a proposal-value _different_ from
> \\( \bot \\).

## Algorithm

```pseudocode
\begin{algorithm}
\caption{Fast Recovery}
\begin{algorithmic}
\Function{FastRecovery}{}
  \State $\Resync()$
  \For{$a \in A$}
    \If{$\IsCommittable(\bar{v})$}
      \State $\creds \gets \Sortition(a_I, r, p, \Late)$
      \If{$\creds_j > 0$}
        \State $\Broadcast(\Vote(r, p, \Late, \bar{v}, \creds))$
      \EndIf
    \ElsIf{$\nexists s_0 > \Cert \mid \Bundle(r, p - 1, s_0, \bot) \subseteq V \land \exists s_1 > \Cert \mid \Bundle(r, p - 1, s_1, \bar{v}) \subseteq V$}
      \State $\creds \gets \Sortition(a_I, r, p, \Redo)$
      \If{$\creds_j > 0$}
        \State $\Broadcast(\Vote(r, p, \Redo, \bar{v}, \creds))$
      \EndIf
    \Else
      \State $\creds \gets \Sortition(a_I, r, p, \Down)$
      \If{$\creds_j > 0$}
        \State $\Broadcast(\Vote(r, p, \Down, \bot, \creds))$
      \EndIf
    \EndIf
  \EndFor
  \For{$\vt \in V \text{ such that } \vt_s \geq 253$}
    \State $\Broadcast(\vt)$
  \EndFor
\EndFunction
\end{algorithmic}
\end{algorithm}
```

> [!IMPORTANT]
> **IMPLEMENTATION:**
>
> Fast recovery vote issuance [reference implementation](https://github.com/algorand/go-algorand/blob/d52e3dd8b31a17dfebac3d9158a76e8e62617462/agreement/player.go#L244).

\\( \FastRecovery \\) is functionally very close to the regular \\( \Recovery \\)
algorithm (outlined in the previous section), performing the same checks and similar outputs.

The main difference is that it emits votes for any of the three different steps
\\( \Late, \Redo, \Down \\), according to \\( \Sortition \\) results for every
selected account.

Nodes are forbidden to equivocate for \\( \Late, \Redo, \Down \\) votes.

Finally, the node broadcasts all fast recovery votes observed. That is, all votes
\\( \vt \in V \\) for which \\( \vt_s \\) is a fast recovery step (\\( \Late, \Redo, \Down \\)).

> [!NOTE]
> For a formal definition of this functionality, refer to the ABFT [normative section](../abft-broadcast-rules.md#fast-recovery).
