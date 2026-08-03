# State Transitions

After receiving message events or a time events, the player may update some components
of its state.

# New Round

When a player observes that a new round \\( (r, 0) \\) has begun, the player
sets

- \\( \bar{s} := s \\),

- \\( \bar{v} := \bot \\),

- \\( p := 0 \\),

- \\( s := 0 \\).

Specifically, if a new round has begun, then

$$
N((r-i, p, s, \bar{s}, V, P, \bar{v}), L, \ldots)
= ((r, 0, 0, s, V', P', \bot), L', \ldots)
$$

for some \\( i > 0 \\).

> [!IMPORTANT]
> **IMPLEMENTATION:**
>
> New round [reference implementation](https://github.com/algorand/go-algorand/blob/b6e5bcadf0ad3861d4805c51cbf3f695c38a93b7/agreement/player.go#L454).

$$
\newcommand \Soft {\mathit{soft}}
\newcommand \Cert {\mathit{cert}}
\newcommand \Bundle {\mathrm{Bundle}}
$$

# New Period

When a player observes that a new period \\( (r, p) \\) has begun, the player sets

- \\( \bar{s} := s \\),

- \\( s := 0 \\).

Also, the player sets \\( \bar{v} := v \\) if the player has observed \\( \Bundle(r, p-1, s, v) \\)
given some values \\( s > \Cert \\) (or \\( s = \Soft \\)), \\( v \neq \bot \\);
if none exist, the player sets \\( \bar{v} := \sigma(S, r, p-i) \\) if it exists,
where \\( p-i \\) was the player's period immediately before observing the new period;
and if none exist, the player does not update \\( \bar{v} \\).

In other words, if \\( \Bundle(r, p-1, s, v) \in V' \\) for some \\( v \neq \bot, s > \Cert \\)
or \\( s = \Soft \\), then

$$
N((r, p-i, s, \bar{s}, V, P, \bar{v}), L, \ldots)
= ((r, p, 0, s, V', P, v), L', \ldots);
$$

and otherwise, if \\( \Bundle(r, p-1, s, \bot) \in V' \\) for some \\( s > \Cert \\)
with \\( \sigma(S, r, p-i) \\) defined, then

$$
N((r, p-i, s, \bar{s}, V, P, \bar{v}), L, \ldots)
= ((r, p, 0, s, V', P, \sigma(S, r, p-i)), L', \ldots);
$$

and otherwise

$$
N((r, p-i, s, \bar{s}, V, P, \bar{v}), L, \ldots)
= ((r, p, 0, s, V', P, \bar{v}), L', \ldots);
$$

for some \\( i > 0 \\) (where \\( S = (r, p-i, s, \bar{s}, V, P, \bar{v}) \\)).

> [!IMPORTANT]
> **IMPLEMENTATION:**
>
> New period [reference implementation](https://github.com/algorand/go-algorand/blob/b6e5bcadf0ad3861d4805c51cbf3f695c38a93b7/agreement/player.go#L411).

$$
\newcommand \Vote {\mathrm{Vote}}
$$

# Garbage Collection

When a player observes that either a new _round_ or a new _period_
\\( (r, p) \\) has begun, then the player _garbage-collects_ old state.

In other words,

$$
N((r-i, p-i, s, \bar{s}, V, P, \bar{v}), L, \ldots)
= ((r, p, \bar{s}, 0, V' \setminus V^\ast_{r, p}, P' \setminus P^\ast_{r, p}, \bar{v}), L, \ldots)
$$

where

$$
\begin{aligned}
V^\ast_{r, p}
&=    \\{\Vote(I, r', p', \bar{s}, v) | \Vote \in V, r' < r\\} \\\\\\
&\cup \\{\Vote(I, r', p', \bar{s}, v) | \Vote \in V, r' = r, p' + 1 < p\\}
\end{aligned}
$$

and \\( P^\ast_{r, p} \\) is defined similarly.

$$
\newcommand \FilterTimeout {\mathrm{FilterTimeout}}
\newcommand \DeadlineTimeout {\mathrm{DeadlineTimeout}}
\newcommand \Cert {\mathit{cert}}
\newcommand \Next {\mathit{next}}
$$

# New Step

A player may also update its step after receiving a timeout event.

On observing a timeout event of \\( \FilterTimeout(p) \\) for a period \\( p \\),
the player sets \\( s := \Cert \\).

On observing a timeout event of \\( \DeadlineTimeout(p) \\) for a period \\( p \\),
the player sets \\( s := \Next_0 \\).

On observing a timeout event of \\( \DeadlineTimeout(p) + 2^{s_t}\lambda + u \\)
where \\( u \in [0, 2^{s_t}\lambda) \\) sampled uniformly at random, the player sets
\\( s := s_t \\).

> [!IMPORTANT]
> **IMPLEMENTATION:**
>
> New step [reference implementation](https://github.com/algorand/go-algorand/blob/b6e5bcadf0ad3861d4805c51cbf3f695c38a93b7/agreement/player.go#L94).

In other words,

$$
\begin{aligned}
&N((r, p, s, \bar{s}, V, P, \bar{v}), L, t(\FilterTimeout(p), p)) \\\\
&\qquad = ((r, p, \Cert, \bar{s}, V, P, \bar{v}), L', \ldots) \\\\[0.35em]
&N((r, p, s, \bar{s}, V, P, \bar{v}), L, t(\DeadlineTimeout(p), p)) \\\\
&\qquad = ((r, p, \Next_0, \bar{s}, V, P, \bar{v}), L', \ldots) \\\\[0.35em]
&N((r, p, s, \bar{s}, V, P, \bar{v}), L, t(\DeadlineTimeout(p) + 2^{s_t}\lambda + u, p)) \\\\
&\qquad = ((r, p, \Next_{s_t}, \bar{s}, V, P, \bar{v}), L', \ldots).
\end{aligned}
$$
