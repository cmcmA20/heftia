{-# LANGUAGE QuantifiedConstraints #-}
{-# LANGUAGE UndecidableInstances #-}

-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

module Control.Heftia.Trans.Final where

import Control.Applicative (Alternative)
import Control.Effect.Class (LiftIns (LiftIns), type (~>))
import Control.Effect.Class.HFunctor (HFunctor, hfmap)
import Control.Heftia.Final (HeftiaFinal (HeftiaFinal), liftSigFinal, weakenHeftiaFinal)
import Control.Monad (MonadPlus)
import Data.Hefty.Sum (type (+) (L, R))

newtype HeftiaFinalT c h f a = HeftiaFinalT
    {unHeftiaFinalT :: HeftiaFinal c (h + LiftIns f) a}

data InterpreterT h f g = InterpreterT
    { interpretLower :: f ~> g
    , interpreter :: h g ~> g
    }

runHeftiaFinalT :: c g => InterpreterT h f g -> HeftiaFinalT c h f a -> g a
runHeftiaFinalT InterpreterT{..} (HeftiaFinalT (HeftiaFinal f)) = f \case
    L e -> interpreter e
    R (LiftIns a) -> interpretLower a

heftiaFinalT :: (forall g. c g => InterpreterT h f g -> g a) -> HeftiaFinalT c h f a
heftiaFinalT f = HeftiaFinalT $ HeftiaFinal \i -> f $ InterpreterT (i . R . LiftIns) (i . L)

liftSigFinalT :: HFunctor h => h (HeftiaFinalT c h f) a -> HeftiaFinalT c h f a
liftSigFinalT = HeftiaFinalT . liftSigFinal . L . hfmap unHeftiaFinalT

weakenHeftiaFinalT :: (forall g. c' g => c g) => HeftiaFinalT c h f a -> HeftiaFinalT c' h f a
weakenHeftiaFinalT = HeftiaFinalT . weakenHeftiaFinal . unHeftiaFinalT

deriving newtype instance
    (forall g. c g => Functor g, c (HeftiaFinal c (h + LiftIns f))) =>
    Functor (HeftiaFinalT c h f)

deriving newtype instance
    ( forall g. c g => Applicative g
    , c (HeftiaFinal c (h + LiftIns f))
    , c (HeftiaFinalT c h f)
    ) =>
    Applicative (HeftiaFinalT c h f)

deriving newtype instance
    ( forall g. c g => Alternative g
    , c (HeftiaFinal c (h + LiftIns f))
    , c (HeftiaFinalT c h f)
    ) =>
    Alternative (HeftiaFinalT c h f)

deriving newtype instance
    ( forall n. c n => Monad n
    , c (HeftiaFinal c (h + LiftIns m))
    , c (HeftiaFinalT c h m)
    ) =>
    Monad (HeftiaFinalT c h m)

deriving newtype instance
    ( forall n. c n => MonadPlus n
    , c (HeftiaFinal c (h + LiftIns m))
    , c (HeftiaFinalT c h m)
    ) =>
    MonadPlus (HeftiaFinalT c h m)
