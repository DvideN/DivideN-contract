> -- -*- fill-column: 70; -*-

\ignore{
\begin{code}

{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE GADTs #-}
module Money.Theory.PaymentPrimitives
    -- $intro
    --
    ( MoneyDistributionModel
    , ð
    , ð' (..)
    , semð
    ) where

import Data.Coerce ( coerce )

import Money.Theory.MoneyDistribution
\end{code}
}

\begin{haddock}
\begin{code}
{- $intro

Here is the denotational semantics of payment primitives of modern
payment system.

-}
\end{code}
\end{haddock}

\begin{code}
-- | Type synonym for â¦ðâ§.
type MoneyDistributionModel' md = forall Î½ t u.
    ( MoneyDistribution md
    , Î½ ~ MD_MVAL md
    , t ~ MD_TS md
    , u ~ MD_MU md
    ) => u -> t -> Î½

-- | â¦ðâ§ - methematical model of meaning in money distribution.
data MoneyDistributionModel md = MkMoneyDistributionModel
    (MoneyDistributionModel' md)
\end{code}

\begin{code}
-- | Semigroup class instance â¦ðâ§.
instance ( MoneyDistribution md
         ) => Semigroup (MoneyDistributionModel md) where
    -- â: monoid binary operator
    (MkMoneyDistributionModel ma) <> (MkMoneyDistributionModel mb) =
        MkMoneyDistributionModel (\u -> \t -> ma u t + mb u t)

-- | Monoid class instance â¦ðâ§.
instance ( MoneyDistribution md
         ) => Monoid (MoneyDistributionModel md) where
    -- â: monoid empty set
    mempty = MkMoneyDistributionModel (\_ -> \_ -> 0)
\end{code}

\begin{code}
-- | Index abstraction.
class Eq u => Index k u | k -> u where
    Ï :: k -> u -> Double

-- | Universal index.
data UniversalIndex u = MkUniversalIndex u
instance Eq u => Index (UniversalIndex u) u where
    Ï (MkUniversalIndex u) u' = if u == u' then 1 else 0
\end{code}

\begin{code}
-- | ð' - syntactic category using index abstraction.
data ð' Î½ t u =
    forall k1 k2. (Index k1 u, Index k2 u) => TransferI k1 k2 Î½ |
    forall k1 k2. (Index k1 u, Index k2 u) => FlowI k1 k2 Î½ t

-- | Type synonym for ð' using type family.
type ð md = forall Î½ t u.
    ( MoneyDistribution md
    , Î½ ~ MD_MVAL md
    , t ~ MD_TS md
    , u ~ MD_MU md
    ) => ð' Î½ t u

-- | â¦.â§ - semantic function of ð.
sem :: MoneyDistribution md
    => ð md -> MoneyDistributionModel' md
sem (TransferI ka kb amount) = \u -> \_ ->
    let x = fromIntegral amount
    in ceiling $ -x * Ï ka u + x * Ï kb u
sem (FlowI ka kb r t') = \u -> \t ->
    let x = fromIntegral $ -r * coerce(t - t')
    in ceiling $ -x * Ï ka u + x * Ï kb u
-- GHC 9.4.2 bug re non-exhaustive pattern matching?
sem _ = error "huh?"

-- | â¦.â§ - semantic function of ð.
semð :: MoneyDistribution md
     => ð md -> MoneyDistributionModel md
semð s = MkMoneyDistributionModel (sem s)
\end{code}
