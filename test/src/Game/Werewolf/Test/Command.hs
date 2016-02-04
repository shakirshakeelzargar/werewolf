{-|
Module      : Game.Werewolf.Test.Command
Copyright   : (c) Henry J. Wylde, 2015
License     : BSD3
Maintainer  : public@hjwylde.com
-}

{-# OPTIONS_HADDOCK hide, prune #-}

module Game.Werewolf.Test.Command (
    -- * devourVoteCommand
    prop_devourVoteCommandErrorsWhenGameIsOver, prop_devourVoteCommandErrorsWhenCallerDoesNotExist,
    prop_devourVoteCommandErrorsWhenTargetDoesNotExist,
    prop_devourVoteCommandErrorsWhenCallerIsDead, prop_devourVoteCommandErrorsWhenTargetIsDead,
    prop_devourVoteCommandErrorsWhenNotWerewolvesTurn,
    prop_devourVoteCommandErrorsWhenCallerNotWerewolf,
    prop_devourVoteCommandErrorsWhenCallerHasVoted, prop_devourVoteCommandErrorsWhenTargetWerewolf,
    prop_devourVoteCommandUpdatesVotes,

    -- * healCommand
    prop_healCommandErrorsWhenGameIsOver, prop_healCommandErrorsWhenCallerDoesNotExist,
    prop_healCommandErrorsWhenCallerIsDead, prop_healCommandErrorsWhenNoTargetIsDevoured,
    prop_healCommandErrorsWhenNotWitchsTurn, prop_healCommandErrorsWhenCallerHasHealed,
    prop_healCommandErrorsWhenCallerNotWitch, prop_healCommandSetsHeal,
    prop_healCommandSetsHealUsed,

    -- * lynchVoteCommand
    prop_lynchVoteCommandErrorsWhenGameIsOver, prop_lynchVoteCommandErrorsWhenCallerDoesNotExist,
    prop_lynchVoteCommandErrorsWhenTargetDoesNotExist, prop_lynchVoteCommandErrorsWhenCallerIsDead,
    prop_lynchVoteCommandErrorsWhenTargetIsDead, prop_lynchVoteCommandErrorsWhenNotVillagesTurn,
    prop_lynchVoteCommandErrorsWhenCallerHasVoted, prop_lynchVoteCommandUpdatesVotes,

    -- * passCommand
    prop_passCommandErrorsWhenGameIsOver, prop_passCommandErrorsWhenCallerDoesNotExist,
    prop_passCommandErrorsWhenCallerIsDead, prop_passCommandErrorsWhenNotWitchsTurn,
    prop_passCommandUpdatesPasses,

    -- * poisonCommand
    prop_poisonCommandErrorsWhenGameIsOver, prop_poisonCommandErrorsWhenCallerDoesNotExist,
    prop_poisonCommandErrorsWhenTargetDoesNotExist, prop_poisonCommandErrorsWhenCallerIsDead,
    prop_poisonCommandErrorsWhenTargetIsDead, prop_poisonCommandErrorsWhenTargetIsDevoured,
    prop_poisonCommandErrorsWhenNotWitchsTurn, prop_poisonCommandErrorsWhenCallerHasPoisoned,
    prop_poisonCommandErrorsWhenCallerNotWitch, prop_poisonCommandSetsPoison,
    prop_poisonCommandSetsPoisonUsed,

    -- * quitCommand
    prop_quitCommandErrorsWhenGameIsOver, prop_quitCommandErrorsWhenCallerDoesNotExist,
    prop_quitCommandErrorsWhenCallerIsDead, prop_quitCommandKillsPlayer,
    prop_quitCommandClearsHealWhenCallerIsWitch, prop_quitCommandClearsHealUsedWhenCallerIsWitch,
    prop_quitCommandClearsPoisonWhenCallerIsWitch,
    prop_quitCommandClearsPoisonUsedWhenCallerIsWitch, prop_quitCommandClearsPlayersDevourVote,
    prop_quitCommandClearsPlayersLynchVote,

    -- * seeCommand
    prop_seeCommandErrorsWhenGameIsOver, prop_seeCommandErrorsWhenCallerDoesNotExist,
    prop_seeCommandErrorsWhenTargetDoesNotExist, prop_seeCommandErrorsWhenCallerIsDead,
    prop_seeCommandErrorsWhenTargetIsDead, prop_seeCommandErrorsWhenNotSeersTurn,
    prop_seeCommandErrorsWhenCallerNotSeer, prop_seeCommandSetsSee,
) where

import Control.Lens hiding (elements)

import           Data.Either.Extra
import qualified Data.Map          as Map
import           Data.Maybe

import Game.Werewolf.Command
import Game.Werewolf.Engine         (checkStage)
import Game.Werewolf.Game
import Game.Werewolf.Player
import Game.Werewolf.Test.Arbitrary
import Game.Werewolf.Test.Util

import Test.QuickCheck

prop_devourVoteCommandErrorsWhenGameIsOver :: Game -> Property
prop_devourVoteCommandErrorsWhenGameIsOver game =
    forAll (arbitraryDevourVoteCommand game') $ verbose_runCommandErrors game'
    where
        game' = game { _stage = GameOver }

prop_devourVoteCommandErrorsWhenCallerDoesNotExist :: Game -> Player -> Property
prop_devourVoteCommandErrorsWhenCallerDoesNotExist game caller =
    not (doesPlayerExist (caller ^. name) (game ^. players))
    ==> forAll (arbitraryPlayer game) $ \target ->
        verbose_runCommandErrors game (devourVoteCommand (caller ^. name) (target ^. name))

prop_devourVoteCommandErrorsWhenTargetDoesNotExist :: Game -> Player -> Property
prop_devourVoteCommandErrorsWhenTargetDoesNotExist game target =
    not (doesPlayerExist (target ^. name) (game ^. players))
    ==> forAll (arbitraryWerewolf game) $ \caller ->
        verbose_runCommandErrors game (devourVoteCommand (caller ^. name) (target ^. name))

prop_devourVoteCommandErrorsWhenCallerIsDead :: Game -> Property
prop_devourVoteCommandErrorsWhenCallerIsDead game =
    forAll (arbitraryWerewolf game) $ \caller ->
    forAll (arbitraryPlayer game) $ \target -> do
        let game'   = killPlayer game caller
        let command = devourVoteCommand (caller ^. name) (target ^. name)

        verbose_runCommandErrors game' command

prop_devourVoteCommandErrorsWhenTargetIsDead :: Game -> Property
prop_devourVoteCommandErrorsWhenTargetIsDead game =
    forAll (arbitraryWerewolf game) $ \caller ->
    forAll (arbitraryPlayer game) $ \target -> do
        let game'   = killPlayer game target
        let command = devourVoteCommand (caller ^. name) (target ^. name)

        verbose_runCommandErrors game' command

prop_devourVoteCommandErrorsWhenNotWerewolvesTurn :: Game -> Property
prop_devourVoteCommandErrorsWhenNotWerewolvesTurn game =
    not (isWerewolvesTurn game)
    ==> forAll (arbitraryDevourVoteCommand game) $ verbose_runCommandErrors game

prop_devourVoteCommandErrorsWhenCallerNotWerewolf :: Game -> Property
prop_devourVoteCommandErrorsWhenCallerNotWerewolf game =
    forAll (suchThat (arbitraryPlayer game) (not . isWerewolf)) $ \caller ->
    forAll (arbitraryPlayer game) $ \target ->
    verbose_runCommandErrors game (devourVoteCommand (caller ^. name) (target ^. name))

prop_devourVoteCommandErrorsWhenCallerHasVoted :: Game -> Property
prop_devourVoteCommandErrorsWhenCallerHasVoted game =
    forAll (arbitraryWerewolf game') $ \caller ->
    forAll (suchThat (arbitraryPlayer game') (not . isWerewolf)) $ \target -> do
        let command = devourVoteCommand (caller ^. name) (target ^. name)
        let game''  = run_ (apply command) game'

        verbose_runCommandErrors game'' command
    where
        game' = game { _stage = WerewolvesTurn }

prop_devourVoteCommandErrorsWhenTargetWerewolf :: Game -> Property
prop_devourVoteCommandErrorsWhenTargetWerewolf game =
    forAll (suchThat (arbitraryPlayer game) isWerewolf) $ \target ->
    forAll (arbitraryPlayer game) $ \caller ->
    verbose_runCommandErrors game (devourVoteCommand (caller ^. name) (target ^. name))

prop_devourVoteCommandUpdatesVotes :: Game -> Property
prop_devourVoteCommandUpdatesVotes game =
    forAll (arbitraryDevourVoteCommand game') $ \command -> do
        let game'' = run_ (apply command) game'

        Map.size (game'' ^. votes) == 1
    where
        game' = game { _stage = WerewolvesTurn }

prop_healCommandErrorsWhenGameIsOver :: Game -> Property
prop_healCommandErrorsWhenGameIsOver game =
    forAll (arbitraryWitch game') $ \witch ->
    verbose_runCommandErrors game' (healCommand $ witch ^. name)
    where
        game' = game { _stage = GameOver }

prop_healCommandErrorsWhenCallerDoesNotExist :: Game -> Player -> Property
prop_healCommandErrorsWhenCallerDoesNotExist game caller =
    not (doesPlayerExist (caller ^. name) (game ^. players))
    ==> verbose_runCommandErrors game (healCommand (caller ^. name))

prop_healCommandErrorsWhenCallerIsDead :: Game -> Property
prop_healCommandErrorsWhenCallerIsDead game =
    forAll (arbitraryPlayer game) $ \caller -> do
        let game'   = killPlayer game caller
        let command = healCommand (caller ^. name)

        verbose_runCommandErrors game' command

prop_healCommandErrorsWhenNoTargetIsDevoured :: Game -> Property
prop_healCommandErrorsWhenNoTargetIsDevoured game =
    forAll (arbitraryWitch game) $ \witch ->
    verbose_runCommandErrors game (healCommand $ witch ^. name)

prop_healCommandErrorsWhenNotWitchsTurn :: Game -> Property
prop_healCommandErrorsWhenNotWitchsTurn game =
    not (isWitchsTurn game)
    ==> forAll (arbitraryWitch game) $ \witch ->
        verbose_runCommandErrors game (healCommand $ witch ^. name)

prop_healCommandErrorsWhenCallerHasHealed :: Gen Property
prop_healCommandErrorsWhenCallerHasHealed = do
    game <- arbitraryGameWithDevourEventForVillager

    return $ forAll (arbitraryHealCommand game) $ \command -> do
        let game' = run_ (apply command) game

        verbose_runCommandErrors game' command

prop_healCommandErrorsWhenCallerNotWitch :: Game -> Property
prop_healCommandErrorsWhenCallerNotWitch game =
    forAll (suchThat (arbitraryPlayer game) (not . isWitch)) $ \caller ->
    verbose_runCommandErrors game (healCommand (caller ^. name))

prop_healCommandSetsHeal :: Gen Property
prop_healCommandSetsHeal = do
    game <- arbitraryGameWithDevourEventForVillager

    return $ forAll (arbitraryHealCommand game) $ \command ->
        (run_ (apply command) game) ^. heal

prop_healCommandSetsHealUsed :: Gen Property
prop_healCommandSetsHealUsed = do
    game <- arbitraryGameWithDevourEventForVillager

    return $ forAll (arbitraryHealCommand game) $ \command ->
        (run_ (apply command) game) ^. healUsed

prop_lynchVoteCommandErrorsWhenGameIsOver :: Game -> Property
prop_lynchVoteCommandErrorsWhenGameIsOver game =
    forAll (arbitraryLynchVoteCommand game') $ verbose_runCommandErrors game'
    where
        game' = game { _stage = GameOver }

prop_lynchVoteCommandErrorsWhenCallerDoesNotExist :: Game -> Player -> Property
prop_lynchVoteCommandErrorsWhenCallerDoesNotExist game caller =
    not (doesPlayerExist (caller ^. name) (game ^. players))
    ==> forAll (arbitraryPlayer game) $ \target ->
        verbose_runCommandErrors game (lynchVoteCommand (caller ^. name) (target ^. name))

prop_lynchVoteCommandErrorsWhenTargetDoesNotExist :: Game -> Player -> Property
prop_lynchVoteCommandErrorsWhenTargetDoesNotExist game target =
    not (doesPlayerExist (target ^. name) (game ^. players))
    ==> forAll (arbitraryPlayer game) $ \caller ->
        verbose_runCommandErrors game (lynchVoteCommand (caller ^. name) (target ^. name))

prop_lynchVoteCommandErrorsWhenCallerIsDead :: Game -> Property
prop_lynchVoteCommandErrorsWhenCallerIsDead game =
    forAll (arbitraryPlayer game) $ \caller ->
    forAll (arbitraryPlayer game) $ \target -> do
        let game'   = killPlayer game caller
        let command = lynchVoteCommand (caller ^. name) (target ^. name)

        verbose_runCommandErrors game' command

prop_lynchVoteCommandErrorsWhenTargetIsDead :: Game -> Property
prop_lynchVoteCommandErrorsWhenTargetIsDead game =
    forAll (arbitraryPlayer game) $ \caller ->
    forAll (arbitraryPlayer game) $ \target -> do
        let game'   = killPlayer game target
        let command = lynchVoteCommand (caller ^. name) (target ^. name)

        verbose_runCommandErrors game' command

prop_lynchVoteCommandErrorsWhenNotVillagesTurn :: Game -> Property
prop_lynchVoteCommandErrorsWhenNotVillagesTurn game =
    not (isVillagesTurn game)
    ==> forAll (arbitraryLynchVoteCommand game) $ verbose_runCommandErrors game

prop_lynchVoteCommandErrorsWhenCallerHasVoted :: Game -> Property
prop_lynchVoteCommandErrorsWhenCallerHasVoted game =
    forAll (arbitraryPlayer game') $ \caller ->
    forAll (arbitraryPlayer game') $ \target -> do
        let command = lynchVoteCommand (caller ^. name) (target ^. name)
        let game''  = run_ (apply command) game'

        verbose_runCommandErrors game'' command
    where
        game' = game { _stage = VillagesTurn }

prop_lynchVoteCommandUpdatesVotes :: Game -> Property
prop_lynchVoteCommandUpdatesVotes game =
    forAll (arbitraryLynchVoteCommand game') $ \command -> do
        let game'' = run_ (apply command) game'

        Map.size (game'' ^. votes) == 1
    where
        game' = game { _stage = VillagesTurn }

prop_passCommandErrorsWhenGameIsOver :: Game -> Property
prop_passCommandErrorsWhenGameIsOver game =
    forAll (arbitraryPassCommand game') $ verbose_runCommandErrors game'
    where
        game' = game { _stage = GameOver }

prop_passCommandErrorsWhenCallerDoesNotExist :: Game -> Player -> Property
prop_passCommandErrorsWhenCallerDoesNotExist game caller =
    not (doesPlayerExist (caller ^. name) (game ^. players))
    ==> verbose_runCommandErrors game (passCommand (caller ^. name))

prop_passCommandErrorsWhenCallerIsDead :: Game -> Property
prop_passCommandErrorsWhenCallerIsDead game =
    forAll (arbitraryPlayer game) $ \caller -> do
        let game'   = killPlayer game caller
        let command = passCommand (caller ^. name)

        verbose_runCommandErrors game' command

prop_passCommandErrorsWhenNotWitchsTurn :: Game -> Property
prop_passCommandErrorsWhenNotWitchsTurn game =
    not (isWitchsTurn game)
    ==> forAll (arbitraryPassCommand game) $ verbose_runCommandErrors game

prop_passCommandUpdatesPasses :: Game -> Property
prop_passCommandUpdatesPasses game =
    forAll (arbitraryPassCommand game') $ \command -> do
        let game'' = run_ (apply command) game'

        length (game'' ^. passes) == 1
    where
        game' = game { _stage = WitchsTurn }

prop_poisonCommandErrorsWhenGameIsOver :: Game -> Property
prop_poisonCommandErrorsWhenGameIsOver game =
    forAll (arbitraryPoisonCommand game') $ verbose_runCommandErrors game'
    where
        game' = game { _stage = GameOver }

prop_poisonCommandErrorsWhenCallerDoesNotExist :: Game -> Player -> Property
prop_poisonCommandErrorsWhenCallerDoesNotExist game caller =
    not (doesPlayerExist (caller ^. name) (game ^. players))
    ==> forAll (arbitraryPlayer game) $ \target ->
        verbose_runCommandErrors game (poisonCommand (caller ^. name) (target ^. name))

prop_poisonCommandErrorsWhenTargetDoesNotExist :: Game -> Player -> Property
prop_poisonCommandErrorsWhenTargetDoesNotExist game target =
    not (doesPlayerExist (target ^. name) (game ^. players))
    ==> forAll (arbitraryPlayer game) $ \caller ->
        verbose_runCommandErrors game (poisonCommand (caller ^. name) (target ^. name))

prop_poisonCommandErrorsWhenCallerIsDead :: Game -> Property
prop_poisonCommandErrorsWhenCallerIsDead game =
    forAll (arbitraryPlayer game) $ \caller ->
    forAll (arbitraryPlayer game) $ \target -> do
        let game'   = killPlayer game caller
        let command = poisonCommand (caller ^. name) (target ^. name)

        verbose_runCommandErrors game' command

prop_poisonCommandErrorsWhenTargetIsDead :: Game -> Property
prop_poisonCommandErrorsWhenTargetIsDead game =
    forAll (arbitraryPlayer game) $ \caller ->
    forAll (arbitraryPlayer game) $ \target -> do
        let game'   = killPlayer game target
        let command = poisonCommand (caller ^. name) (target ^. name)

        verbose_runCommandErrors game' command

prop_poisonCommandErrorsWhenTargetIsDevoured :: Game -> Property
prop_poisonCommandErrorsWhenTargetIsDevoured game =
    forAll (runArbitraryCommands n game') $ \game'' ->
    length (getVoteResult game'') == 1
    ==> forAll (arbitraryWitch game'') $ \caller ->
        let game''' = run_ checkStage game''
            votee   = head (getVoteResult game'')
        in verbose_runCommandErrors game''' (poisonCommand (caller ^. name) (votee ^. name))
    where
        game'   = game { _stage = WerewolvesTurn }
        n       = length . filterWerewolves $ game' ^. players

prop_poisonCommandErrorsWhenNotWitchsTurn :: Game -> Property
prop_poisonCommandErrorsWhenNotWitchsTurn game =
    not (isWitchsTurn game)
    ==> forAll (arbitraryPoisonCommand game) $ verbose_runCommandErrors game

prop_poisonCommandErrorsWhenCallerHasPoisoned :: Game -> Property
prop_poisonCommandErrorsWhenCallerHasPoisoned game =
    forAll (arbitraryWitch game') $ \caller ->
    forAll (arbitraryPlayer game') $ \target ->
    let command = poisonCommand (caller ^. name) (target ^. name)
    in verbose_runCommandErrors (run_ (apply command) game') command
    where
        game' = game { _stage = WitchsTurn }

prop_poisonCommandErrorsWhenCallerNotWitch :: Game -> Property
prop_poisonCommandErrorsWhenCallerNotWitch game =
    forAll (suchThat (arbitraryPlayer game) (not . isWitch)) $ \caller ->
    forAll (arbitraryPlayer game) $ \target ->
    verbose_runCommandErrors game (poisonCommand (caller ^. name) (target ^. name))

prop_poisonCommandSetsPoison :: Game -> Property
prop_poisonCommandSetsPoison game =
    forAll (arbitraryPoisonCommand game') $ \command ->
    isJust (run_ (apply command) game' ^. poison)
    where
        game' = game { _stage = WitchsTurn }

prop_poisonCommandSetsPoisonUsed :: Game -> Property
prop_poisonCommandSetsPoisonUsed game =
    forAll (arbitraryPoisonCommand game') $ \command ->
    run_ (apply command) game' ^. poisonUsed
    where
        game' = game { _stage = WitchsTurn }

prop_quitCommandErrorsWhenGameIsOver :: Game -> Property
prop_quitCommandErrorsWhenGameIsOver game =
    forAll (arbitraryQuitCommand game') $ verbose_runCommandErrors game'
    where
        game' = game { _stage = GameOver }

prop_quitCommandErrorsWhenCallerDoesNotExist :: Game -> Player -> Property
prop_quitCommandErrorsWhenCallerDoesNotExist game caller =
    not (doesPlayerExist (caller ^. name) (game ^. players))
    ==> verbose_runCommandErrors game (quitCommand $ caller ^. name)

prop_quitCommandErrorsWhenCallerIsDead :: Game -> Property
prop_quitCommandErrorsWhenCallerIsDead game =
    forAll (arbitraryPlayer game) $ \caller ->
    verbose_runCommandErrors (killPlayer game caller) (quitCommand $ caller ^. name)

prop_quitCommandKillsPlayer :: Game -> Property
prop_quitCommandKillsPlayer game =
    not (isGameOver game)
    ==> forAll (arbitraryQuitCommand game) $ \command ->
        length (filterDead $ run_ (apply command) game ^. players) == 1

prop_quitCommandClearsHealWhenCallerIsWitch :: Game -> Property
prop_quitCommandClearsHealWhenCallerIsWitch game =
    forAll (runArbitraryCommands n game') $ \game'' ->
    length (getVoteResult game'') == 1
    ==> let target = head $ getVoteResult game''
        in not (isWitch target)
        ==> forAll (arbitraryWitch game'') $ \caller ->
            let command = healCommand (caller ^. name)
                game''' = run_ (apply command) $ run_ checkStage game''
            in not $ run_ (apply $ quitCommand (caller ^. name)) game''' ^. heal
    where
        game'   = game { _stage = WerewolvesTurn }
        n       = length . filterWerewolves $ game' ^. players

prop_quitCommandClearsHealUsedWhenCallerIsWitch :: Game -> Property
prop_quitCommandClearsHealUsedWhenCallerIsWitch game =
    forAll (runArbitraryCommands n game') $ \game'' ->
    length (getVoteResult game'') == 1
    ==> let target = head $ getVoteResult game''
        in not (isWitch target)
        ==> forAll (arbitraryWitch game'') $ \caller ->
            let command = healCommand (caller ^. name)
                game''' = run_ (apply command) $ run_ checkStage game''
            in not $ run_ (apply $ quitCommand (caller ^. name)) game''' ^. healUsed
    where
        game'   = game { _stage = WerewolvesTurn }
        n       = length . filterWerewolves $ game' ^. players

prop_quitCommandClearsPoisonWhenCallerIsWitch :: Game -> Property
prop_quitCommandClearsPoisonWhenCallerIsWitch game =
    forAll (arbitraryWitch game') $ \caller ->
    forAll (arbitraryPlayer game') $ \target ->
    let game'' = run_ (apply $ poisonCommand (caller ^. name) (target ^. name)) game'
    in isNothing $ run_ (apply $ quitCommand (caller ^. name)) game'' ^. poison
    where
        game' = game { _stage = WitchsTurn }

prop_quitCommandClearsPoisonUsedWhenCallerIsWitch :: Game -> Property
prop_quitCommandClearsPoisonUsedWhenCallerIsWitch game =
    forAll (arbitraryWitch game') $ \caller ->
    forAll (arbitraryPlayer game') $ \target ->
    let game'' = run_ (apply $ poisonCommand (caller ^. name) (target ^. name)) game'
    in not $ run_ (apply $ quitCommand (caller ^. name)) game'' ^. poisonUsed
    where
        game' = game { _stage = WitchsTurn }

prop_quitCommandClearsPlayersDevourVote :: Game -> Property
prop_quitCommandClearsPlayersDevourVote game =
    forAll (arbitraryWerewolf game') $ \caller ->
    forAll (suchThat (arbitraryPlayer game') (not . isWerewolf)) $ \target ->
    let game'' = run_ (apply $ devourVoteCommand (caller ^. name) (target ^. name)) game'
    in Map.null $ run_ (apply $ quitCommand (caller ^. name)) game'' ^. votes
    where
        game' = game { _stage = WerewolvesTurn }

prop_quitCommandClearsPlayersLynchVote :: Game -> Property
prop_quitCommandClearsPlayersLynchVote game =
    forAll (arbitraryPlayer game') $ \caller ->
    forAll (arbitraryPlayer game') $ \target ->
    let game'' = run_ (apply $ lynchVoteCommand (caller ^. name) (target ^. name)) game'
        in Map.null $ run_ (apply $ quitCommand (caller ^. name)) game'' ^. votes
    where
        game' = game { _stage = VillagesTurn }

prop_seeCommandErrorsWhenGameIsOver :: Game -> Property
prop_seeCommandErrorsWhenGameIsOver game =
    forAll (arbitrarySeeCommand game') $ verbose_runCommandErrors game'
    where
        game' = game { _stage = GameOver }

prop_seeCommandErrorsWhenCallerDoesNotExist :: Game -> Player -> Property
prop_seeCommandErrorsWhenCallerDoesNotExist game caller =
    not (doesPlayerExist (caller ^. name) (game ^. players))
    ==> forAll (arbitraryPlayer game) $ \target ->
        verbose_runCommandErrors game (seeCommand (caller ^. name) (target ^. name))

prop_seeCommandErrorsWhenTargetDoesNotExist :: Game -> Player -> Property
prop_seeCommandErrorsWhenTargetDoesNotExist game target =
    not (doesPlayerExist (target ^. name) (game ^. players))
    ==> forAll (arbitrarySeer game) $ \caller ->
        verbose_runCommandErrors game (seeCommand (caller ^. name) (target ^. name))

prop_seeCommandErrorsWhenCallerIsDead :: Game -> Property
prop_seeCommandErrorsWhenCallerIsDead game =
    forAll (arbitrarySeer game) $ \caller ->
    forAll (arbitraryPlayer game) $ \target ->
    verbose_runCommandErrors (killPlayer game caller) (seeCommand (caller ^. name) (target ^. name))

prop_seeCommandErrorsWhenTargetIsDead :: Game -> Property
prop_seeCommandErrorsWhenTargetIsDead game =
    forAll (arbitrarySeer game) $ \caller ->
    forAll (arbitraryPlayer game) $ \target ->
    verbose_runCommandErrors (killPlayer game target) (seeCommand (caller ^. name) (target ^. name))

prop_seeCommandErrorsWhenNotSeersTurn :: Game -> Property
prop_seeCommandErrorsWhenNotSeersTurn game =
    not (isSeersTurn game)
    ==> forAll (arbitrarySeeCommand game) $ verbose_runCommandErrors game

prop_seeCommandErrorsWhenCallerNotSeer :: Game -> Property
prop_seeCommandErrorsWhenCallerNotSeer game =
    forAll (suchThat (arbitraryPlayer game) (not . isSeer)) $ \caller ->
    forAll (arbitraryPlayer game) $ \target ->
    verbose_runCommandErrors game (seeCommand (caller ^. name) (target ^. name))

prop_seeCommandSetsSee :: Game -> Property
prop_seeCommandSetsSee game =
    forAll (arbitrarySeeCommand game') $ \command ->
    isJust $ run_ (apply command) game' ^. see
    where
        game' = game { _stage = SeersTurn }

verbose_runCommandErrors :: Game -> Command -> Property
verbose_runCommandErrors game command = whenFail (mapM_ putStrLn [show game, show . fromRight $ run (apply command) game]) (isLeft $ run (apply command) game)
