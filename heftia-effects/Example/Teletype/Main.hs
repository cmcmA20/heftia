{-# LANGUAGE PartialTypeSignatures #-}
{-# LANGUAGE TemplateHaskell #-}

-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

{- |
The original of this example can be found at polysemy.
<https://hackage.haskell.org/package/polysemy>
-}
module Main where

import Control.Effect.Class (type (~>))
import Control.Effect.Class.Embed (Embed, embed)
import Control.Effect.Class.Machinery.TH (makeEffectF)
import Control.Effect.Freer (Fre, interpose, interpret, interpreted, type (<:))
import Control.Effect.Handler.Heftia.Embed (runEmbedIO)

class Teletype f where
    readTTY :: f String
    writeTTY :: String -> f ()

makeEffectF ''Teletype

teletypeToIO :: (Embed IO (Fre es m), Monad m) => Fre (TeletypeI ': es) m ~> Fre es m
teletypeToIO = interpret \case
    ReadTTY -> embed getLine
    WriteTTY msg -> embed $ putStrLn msg

echo :: (Teletype m, Monad m) => m ()
echo = do
    i <- readTTY
    case i of
        "" -> pure ()
        _ -> writeTTY i >> echo

strong :: (TeletypeI <: es, Monad m) => Fre es m ~> Fre es m
strong =
    interpose \case
        ReadTTY -> readTTY
        WriteTTY msg -> writeTTY $ msg <> "!"

main :: IO ()
main = interpreted . runEmbedIO $ do
    embed $ putStrLn "Please enter something..."
    teletypeToIO $ strong . strong $ echo