{-|
Module      : Werewolf.Command.End
Description : Handler for the end subcommand.

Copyright   : (c) Henry J. Wylde, 2016
License     : BSD3
Maintainer  : public@hjwylde.com

Handler for the end subcommand.
-}

{-# LANGUAGE OverloadedStrings #-}

module Werewolf.Command.End (
    -- * Handle
    handle,
) where

import Control.Monad.Extra
import Control.Monad.IO.Class

import           Data.Text (Text)
import qualified Data.Text as T

import Game.Werewolf

import Werewolf.Game
import Werewolf.Messages

handle :: MonadIO m => Text -> m ()
handle callerName = do
    unlessM doesGameExist $ exitWith failure { messages = [noGameRunningMessage callerName] }

    game <- readGame

    unless (doesPlayerExist callerName game) $
        exitWith failure { messages = [playerCannotDoThatMessage callerName] }

    deleteGame

    exitWith success { messages = [gameEndedMessage] }
    where
        gameEndedMessage = publicMessage $ T.concat ["Game ended by ", callerName, "."]