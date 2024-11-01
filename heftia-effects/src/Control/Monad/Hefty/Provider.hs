{-# LANGUAGE UndecidableInstances #-}

-- SPDX-License-Identifier: MPL-2.0

{- |
Copyright   :  (c) 2024 Sayo Koyoneda
License     :  MPL-2.0 (see the LICENSE file)
Maintainer  :  ymdfield@outlook.jp
-}
module Control.Monad.Hefty.Provider (
    module Control.Monad.Hefty.Provider,
    module Data.Effect.Provider,
)
where

import Control.Monad.Hefty (
    Eff,
    HFunctor,
    KeyH (KeyH),
    MemberHBy,
    interpretH,
    tag,
    tagH,
    transEffHF,
    untag,
    untagH,
    weaken,
    weakenNH,
    type (#),
    type (##),
    type (~>),
 )
import Data.Effect.Provider
import Data.Functor.Identity (Identity (Identity))

type Provide ctx i sh sf eh ef = Provider ctx i (ProviderEff ctx i sh sf eh ef)
type Provide_ i sh sf eh ef = Provide Identity i sh sf eh ef

newtype ProviderEff ctx i sh sf eh ef a
    = ProviderEff {unProviderEff :: Eff (sh ': Provide ctx i sh sf eh ef ': eh) (sf ': ef) a}

runProvider
    :: forall ctx i sh sf eh ef
     . ( forall x
          . i
         -> Eff (sh ': Provide ctx i sh sf eh ef ': eh) (sf ': ef) x
         -> Eff (Provide ctx i sh sf eh ef ': eh) ef (ctx x)
       )
    -> Eff (Provide ctx i sh sf eh ef ': eh) ef ~> Eff eh ef
runProvider run =
    interpretH \(KeyH (Provide i f)) ->
        runProvider run $
            run i (unProviderEff $ f $ ProviderEff . transEffHF (weakenNH @2) weaken)

runProvider_
    :: forall i sh sf eh ef
     . ( forall x
          . i
         -> Eff (sh ': Provide_ i sh sf eh ef ': eh) (sf ': ef) x
         -> Eff (Provide_ i sh sf eh ef ': eh) ef x
       )
    -> Eff (Provide_ i sh sf eh ef ': eh) ef ~> Eff eh ef
runProvider_ run = runProvider \i a -> run i (Identity <$> a)

scope
    :: forall tag ctx i eh ef a sh sf bh bf
     . ( MemberHBy
            (ProviderKey ctx i)
            (Provider' ctx i (ProviderEff ctx i sh sf bh bf))
            eh
       , HFunctor sh
       )
    => i
    -> ( Eff eh ef ~> Eff (sh ## tag ': Provide ctx i sh sf bh bf ': bh) (sf # tag ': bf)
         -> Eff (sh ## tag ': Provide ctx i sh sf bh bf ': bh) (sf # tag ': bf) a
       )
    -> Eff eh ef (ctx a)
scope i f =
    i ..! \runInScope ->
        ProviderEff $ untagH . untag $ f (tagH . tag . unProviderEff . runInScope)

scope_
    :: forall tag i eh ef a sh sf bh bf
     . ( MemberHBy
            (ProviderKey Identity i)
            (Provider' Identity i (ProviderEff Identity i sh sf bh bf))
            eh
       , HFunctor sh
       )
    => i
    -> ( Eff eh ef ~> Eff (sh ## tag ': Provide_ i sh sf bh bf ': bh) (sf # tag ': bf)
         -> Eff (sh ## tag ': Provide_ i sh sf bh bf ': bh) (sf # tag ': bf) a
       )
    -> Eff eh ef a
scope_ i f =
    i .! \runInScope ->
        ProviderEff $ untagH . untag $ f (tagH . tag . unProviderEff . runInScope)
