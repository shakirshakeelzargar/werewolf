{-|
Module      : Werewolf.Command.Reveal
Description : Handler for the reveal subcommand.

Copyright   : (c) Henry J. Wylde, 2016
License     : BSD3
Maintainer  : public@hjwylde.com

Handler for the reveal subcommand.
-}

{-# LANGUAGE OverloadedStrings #-}

module Werewolf.Command.Reveal (
    -- * Handle
    handle,
) where

import Control.Monad.Except
import Control.Monad.Extra
import Control.Monad.State
import Control.Monad.Writer

import Data.Text (Text)

import Game.Werewolf

import Werewolf.Game
import Werewolf.Messages

handle :: MonadIO m => Text -> m ()
handle callerName = do
    unlessM doesGameExist $ exitWith failure
        { messages = [noGameRunningMessage callerName]
        }

    game <- readGame

    let command = revealCommand callerName

    case runExcept (runWriterT $ execStateT (apply command >> checkStage >> checkGameOver) game) of
        Left errorMessages      -> exitWith failure { messages = errorMessages }
        Right (game', messages) -> writeGame game' >> exitWith success { messages = messages }