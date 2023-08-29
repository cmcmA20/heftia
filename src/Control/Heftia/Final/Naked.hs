-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

module Control.Heftia.Final.Naked where

import Control.Effect.Class (Signature, type (~>))
import Control.Effect.Class.HFunctor (HFunctor, hfmap)
import Control.Freer (Freer, liftIns, retractF)
import Control.Heftia.Final (HeftiaFinal (HeftiaFinal), Noop)
import Data.Hefty.Sum (type (+) (L, R))

newtype HeftiaFinalN (h :: Signature) a = HeftiaFinalN {unHeftiaFinalN :: forall f. (h f ~> f) -> f a}

runHeftiaFinalN :: (h f ~> f) -> HeftiaFinalN h a -> f a
runHeftiaFinalN i (HeftiaFinalN f) = f i

liftSigFinalN :: HFunctor h => h (HeftiaFinalN h) a -> HeftiaFinalN h a
liftSigFinalN e = HeftiaFinalN \i -> i $ hfmap (runHeftiaFinalN i) e

wearHeftiaFinal :: HeftiaFinalN h a -> HeftiaFinal Noop h a
wearHeftiaFinal (HeftiaFinalN f) = HeftiaFinal f

nakeHeftiaFinal :: HeftiaFinal Noop h a -> HeftiaFinalN h a
nakeHeftiaFinal (HeftiaFinal f) = HeftiaFinalN f

wearHeftiaFinalF :: Freer c f => HeftiaFinalN (f + h) a -> HeftiaFinal c h a
wearHeftiaFinalF (HeftiaFinalN f) =
    HeftiaFinal \i -> f \case
        L m -> retractF m
        R e -> i e

nakeHeftiaFinalF :: (Freer c f, HFunctor h) => HeftiaFinal c h a -> HeftiaFinalN (f + h) a
nakeHeftiaFinalF (HeftiaFinal f) =
    HeftiaFinalN \i -> i . L $ f $ liftIns . i . R . hfmap (i . L)
