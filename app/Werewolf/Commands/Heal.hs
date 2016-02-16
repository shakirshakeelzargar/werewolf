{-|
Module      : Werewolf.Commands.Heal
Description : Handler for the heal subcommand.

Copyright   : (c) Henry J. Wylde, 2015
License     : BSD3
Maintainer  : public@hjwylde.com

Handler for the heal subcommand.
-}

{-# LANGUAGE OverloadedStrings #-}

module Werewolf.Commands.Heal (
    -- * Handle
    handle,
) where

import Control.Monad.Except
import Control.Monad.Extra
import Control.Monad.State
import Control.Monad.Writer

import Data.Text (Text)

import Game.Werewolf.Command
import Game.Werewolf.Engine
import Game.Werewolf.Response

handle :: MonadIO m => Text -> m ()
handle callerName = do
    unlessM doesGameExist $ exitWith failure
        { messages = [noGameRunningMessage callerName]
        }

    game <- readGame

    let command = healCommand callerName

    case runExcept (runWriterT $ execStateT (apply command >> checkStage >> checkGameOver) game) of
        Left errorMessages      -> exitWith failure { messages = errorMessages }
        Right (game', messages) -> writeGame game' >> exitWith success { messages = messages }