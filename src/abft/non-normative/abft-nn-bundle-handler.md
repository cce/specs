$$
\newcommand \Bundle {\mathrm{Bundle}}
\newcommand \HandleBundle {\mathrm{HandleBundle}}
\newcommand \VerifyBundle {\mathrm{VerifyBundle}}
\newcommand \HandleVote {\mathrm{HandleVote}}
\newcommand \SenderPeer {\mathrm{SenderPeer}}
\newcommand \DisconnectFromPeer {\mathrm{DisconnectFromPeer}}
\newcommand \vt {\mathit{vote}}
\newcommand \bdl {\mathit{bundle}}
$$

# Bundle Handler

The node runs a bundle handler when receiving a message with a _full bundle_.

## Algorithm

```pseudocode
\begin{algorithm}
\caption{Handle Bundle}
\begin{algorithmic}
\Function{HandleBundle}{$\bdl$}
  \If{$\lnot \VerifyBundle(\bdl)$}
    \State $\DisconnectFromPeer(\SenderPeer(\bdl))$
    \Return
  \EndIf
  \If{$\bdl_r = r \land \bdl_p + 1 \ge p$}
    \For{$\vt \in \bdl$}
      \State $\HandleVote(\vt)$
    \EndFor
  \EndIf
\EndFunction
\end{algorithmic}
\end{algorithm}
```

> [!IMPORTANT]
> **IMPLEMENTATION:**
>
> Bundle verification [reference implementation](https://github.com/algorand/go-algorand/blob/1f5c06b559ffe6485a47b623997684430bc18337/agreement/bundle.go#L147).
>
> Bundle handling in [general message handler](https://github.com/algorand/go-algorand/blob/55011f93fddb181c643f8e3f3d3391b62832e7cd/agreement/player.go#L753-L770).

The bundle handler is invoked whenever a bundle message is received.

The received bundle is immediately discarded if it is invalid (Line 2). The node
may penalize the malicious sending peer (e.g., disconnecting from or “blacklisting”
it).

If the received bundle (Line 6):

- Is for round equal to the node’s _current round_, and
- Is for at most one period behind the node’s _current period_.

Then the bundle is processed, calling the vote handler _for each vote_ in the bundle
(Lines 7 and 8).

Note that multiple bundles can be processed concurrently. Therefore, while handling
votes from a bundle \\( b \\) for _proposal-value_ \\( v \\) _separately_, if another
bundle \\( \bdl\prime = \Bundle(\bdl_r, \bdl_p, \bdl_s, v\prime) \\) is formed and observed
first (with \\( v\prime \\) not necessarily equal to \\( v \\)[^1]), votes in
\\( \bdl\prime \\) are relayed individually, and any output or state changes caused
by observing \\( \bdl\prime \\) is produced.

All leftover votes in \\( b \\) are then processed according to the new node state
determined by \\( \bdl\prime \\) observation (e.g., votes are discarded if the executing
step was _certification_ and a new round has started, and so \\( b_r < r \\)).

If \\( \bdl \\) does not pass the previous check (Line 6), then no output is produced,
and the bundle is ignored and discarded.

---

[^1]: Consider what would happen if equivocation votes contained in \\( b \\) cause
a bundle for \\( v\prime \\) to reach the required threshold before the player may
finish observing every single vote in \\( b \\).
