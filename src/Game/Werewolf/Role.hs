{-|
Module      : Game.Werewolf.Role
Description : Simplistic role data structure and instances.

Copyright   : (c) Henry J. Wylde, 2015
License     : BSD3
Maintainer  : public@hjwylde.com

The roles are split into four categories:

* The Ambiguous.
* The Loners.
* The Villagers.
* The Werewolves.
-}

{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell   #-}

module Game.Werewolf.Role (
    -- * Role
    Role, name, allegiance, description, advice,

    Allegiance(..),

    -- ** Instances
    allRoles, restrictedRoles,
    allAllegiances,

    -- *** The Ambiguous
    -- | The Ambiguous may change allegiance during the game.
    wildChildRole, wolfHoundRole,

    -- *** The Loners
    -- | The Loners have their own win condition.
    angelRole,

    -- *** The Villagers
    -- | The Villagers must lynch all of the Werewolves.
    defenderRole, scapegoatRole, seerRole, simpleVillagerRole, villagerVillagerRole, witchRole,

    -- *** The Werewolves
    -- | The Werewolves must devour all of the Villagers.
    simpleWerewolfRole,
) where

import Control.Lens

import           Data.Function
import           Data.List
import           Data.Text     (Text)
import qualified Data.Text     as T

import Prelude hiding (all)

-- | Role definitions require only a few pieces of information.
--   Most of the game logic behind a role is implemented in "Game.Werewolf.Command" and
--   "Game.Werewolf.Engine".
--
--   N.B., role equality is defined on just the @name@ as a role's @allegiance@ may change
--   throughout the game.
data Role = Role
    { _name        :: Text
    , _allegiance  :: Allegiance
    , _description :: Text
    , _advice      :: Text
    } deriving (Read, Show)

-- | The Loner allegiances are seldom used, rather they are present for correctness.
data Allegiance = Angel | Villagers | Werewolves
    deriving (Eq, Read, Show)

makeLenses ''Role

instance Eq Role where
    (==) = (==) `on` view name

-- | A list containing all the roles defined in this file.
allRoles :: [Role]
allRoles =
    [ angelRole
    , defenderRole
    , scapegoatRole
    , seerRole
    , simpleVillagerRole
    , simpleWerewolfRole
    , villagerVillagerRole
    , wildChildRole
    , witchRole
    , wolfHoundRole
    ]

-- | A list containing roles that are restricted to a single instance per game.
--
--   @restrictedRoles = allRoles \\\\ [simpleVillagerRole, simpleWerewolfRole]@
restrictedRoles :: [Role]
restrictedRoles = allRoles \\ [simpleVillagerRole, simpleWerewolfRole]

-- | A list containing all the allegiances defined in this file.
--
--   TODO (hjw): use reflection to get this list
allAllegiances :: [Allegiance]
allAllegiances = [Angel, Villagers, Werewolves]

-- | /Abandoned in the woods by his parents at a young age, he was raised by wolves. As soon as he/
--   /learned how to walk on all fours, the Wild-child began to wander around Miller's Hollow. One/
--   /day, fascinated by an inhabitant of the village who was walking upright with grace and/
--   /presence, he made them his secret role model. He then decided to integrate himself into the/
--   /community of Miller's Hollow and entered, worried, in the village. The community was moved by/
--   /his frailty, adopted him, and welcomed him in their fold. What will become of him: honest/
--   /Villager or terrible Werewolf? For all of his life, the heart of the Wild-child will swing/
--   /between these two alternatives. May his model confirm him in his newfound humanity./
--
--   On the first night, the Wild-child may choose a player to become his role model. If during the
--   game the chosen player is eliminated, the Wild-child becomes a Werewolf. He will then wake up
--   the next night with his peers and will devour with them each night until the end of the game.
--
--   However for as long as the Wild-child's role model is alive, he remains a Villager.
wildChildRole :: Role
wildChildRole = Role
    { _name         = "Wild-child"
    , _allegiance   = Villagers
    , _description  = T.unwords
        [ "Abandoned in the woods by his parents at a young age, he was raised by wolves."
        , "As soon as he learned how to walk on all fours,"
        , "the Wild-child began to wander around Miller's Hollow."
        , "One day, fascinated by an inhabitant of the village who was walking upright"
        , "with grace and presence, he made them his secret role model."
        , "He then decided to integrate himself into the community of Miller's Hollow and entered,"
        , "worried, in the village."
        , "The community was moved by his frailty, adopted him, and welcomed him in their fold."
        , "What will become of him: honest Villager or terrible Werewolf?"
        , "For all of his life,"
        , "the heart of the Wild-child will swing between these two alternatives."
        , "May his model confirm him in his newfound humanity."
        ]
    , _advice       = T.unwords
        [ "Nothing is keeping you from taking part in the elimination of your role model,"
        , "if you so wish..."
        ]
    }

-- | /All dogs know in the depths of their soul that their ancestors were wolves and that it's/
--   /mankind who has kept them in the state of childishness and fear, the faithful and generous/
--   /companions. In any case, only the Wolf-hound can decide if he'll obey his human and civilized/
--   /master or if he'll listen to the call of wild nature buried within him./
--
--   On the first night, he chooses if he wants to be a Simple Villager or Werewolf. The choice is
--   final.
wolfHoundRole :: Role
wolfHoundRole = Role
    { _name         = "Wolf-hound"
    , _allegiance   = Villagers
    , _description  = T.unwords
        [ "All dogs know in the depths of their soul that their ancestors were wolves"
        , "and that it's mankind who has kept them in the state of childishness and fear,"
        , "the faithful and generous companions."
        , "In any case, only the Wolf-hound can decide if he'll obey his human and civilized master"
        , "or if he'll listen to the call of wild nature buried within him."
        ]
    , _advice       =
        "The choice of being a Simple Villager or Werewolf is final, so decide carefully!"
    }

-- | /The muddy life of a village infested with evil creatures repulses him; he wishes to believe/
--   /he's the victim of a terrible nightmare, in order to finally wake up in his comfortable bed./
--
--   When the Angel is in play, the game always begins with the village's debate followed by an
--   elimination vote, and then the first night.
--
--   The Angel wins if he manages to get eliminated on the first round (day or night).
--   If he fails, then he becomes a Simple Villager for the rest of the game.
angelRole :: Role
angelRole = Role
    { _name         = "Angel"
    , _allegiance   = Angel
    , _description  = T.unwords
        [ "The muddy life of a village infested with evil creatures repulses him;"
        , "he wishes to believe he's the victim of a terrible nightmare,"
        , "in order to finally wake up in his comfortable bed."
        ]
    , _advice       = T.unwords
        [ "It's going to take all your guile and wits to con the village into eliminating you."
        , "Pretending to be a Werewolf is one tactic, but if it doesn't work then you may have just"
        , "dug yourself a hole for the rest of the game..."
        ]
    }

-- | /This character can save the Villagers from the bite of the Werewolves./
--
--   Each night the Defender is called before the Werewolves to select a player deserving of his
--   protection. That player is safe during the night (and only that night) against the Werewolves.
defenderRole :: Role
defenderRole = Role
    { _name         = "Defender"
    , _allegiance   = Villagers
    , _description  =
        "This character can save the Villagers from the bite of the Werewolves."
    , _advice       = T.unwords
        [ "Be careful: you can protect yourself,"
        , "but you're not allowed to protect the same player two nights in a row."
        ]
    }

-- | /It's sad to say, but in Miller's Hollow, when something doesn't go right it's always him who/
--   /unjustly suffers the consequences./
--
--   If the village's vote ends in a tie, it's the Scapegoat who is eliminated instead of no-one.
scapegoatRole :: Role
scapegoatRole = Role
    { _name         = "Scapegoat"
    , _allegiance   = Villagers
    , _description  = T.unwords
        [ "It's sad to say, but in Miller's Hollow, when something doesn't go right"
        , "it's always him who unjustly suffers the consequences."
        ]
    , _advice       = "Cross your fingers that the votes don't end up tied."
    }

-- | /A fortunate teller by other names, with the ability to see into fellow townsfolk and/
--   /determine their allegiance./
--
--   Each night the Seer sees the allegiance of a player of her choice.
seerRole :: Role
seerRole = Role
    { _name         = "Seer"
    , _allegiance   = Villagers
    , _description  = T.unwords
        [ "A fortunate teller by other names, with the ability to see into fellow"
        , "townsfolk and determine their allegiance."
        ]
    , _advice       = T.unwords
        [ "You should help the other Villagers,"
        , "but try to remain discreet so as to not arouse suspicion from any of the Werewolves."
        ]
    }

-- | /A simple, ordinary townsperson in every way. Their only weapons are the ability to analyze/
--   /behaviour to identify Werewolves, and the strength of their conviction to prevent the/
--   /execution of the innocents like themselves./
simpleVillagerRole :: Role
simpleVillagerRole = Role
    { _name         = "Simple Villager"
    , _allegiance   = Villagers
    , _description  = T.unwords
        [ "A simple, ordinary townsperson in every way."
        , "Their only weapons are the ability to analyze behaviour to identify Werewolves,"
        , "and the strength of their conviction to prevent"
        , "the execution of the innocents like themselves."
        ]
    , _advice       =
        "Bluffing can be a good technique, but you had better be convincing about what you say."
    }

-- | /This person has a soul as clear and transparent as the water from a mountain stream. They/
--   /will deserve the attentive ear of their peers and will make their word decisive in crucial/
--   /moments./
--
--   When the game begins, the village is told the identity of the Villager-Villager, thus ensuring
--   certainty that its owner is truly an innocent Villager.
villagerVillagerRole :: Role
villagerVillagerRole = Role
    { _name         = "Villager-Villager"
    , _allegiance   = Villagers
    , _description  = T.unwords
        [ "This person has a soul as clear and transparent as the water from a mountain stream."
        , "They will deserve the attentive ear of their peers"
        , "and will make their word decisive in crucial moments."
        ]
    , _advice       = "You'll make friends quickly, but be wary about whom you trust."
    }

-- | /She knows how to brew two extremely powerful potions: a healing potion, to resurrect the/
--   /player devoured by the Werewolves, and a poison potion, used at night to eliminate a player./
--
--   The Witch is called after the Werewolves. She is allowed to use both potions in the same night
--   and is also allowed to heal herself.
witchRole :: Role
witchRole = Role
    { _name         = "Witch"
    , _allegiance   = Villagers
    , _description  = T.unwords
        [ "She knows how to brew two extremely powerful potions:"
        , "a healing potion, to resurrect the player devoured by the Werewolves,"
        , "and a poison potion, used at night to eliminate a player."
        ]
    , _advice       = T.unwords
        [ "Each potion may only be used once per game,"
        , "but there are no restrictions on using both of your potions in the same night."
        ]
    }

-- | /Each night they devour a Villager. During the day they try to hide their nocturnal identity/
--   /to avoid mob justice./
--
--   A Werewolf may never devour another Werewolf.
simpleWerewolfRole :: Role
simpleWerewolfRole = Role
    { _name         = "Simple Werewolf"
    , _allegiance   = Werewolves
    , _description  = T.unwords
        [ "Each night they devour a Villager."
        , "During the day they try to hide their nocturnal identity to avoid mob justice."
        ]
    , _advice       =
        "Voting to lynch your partner can be a good way to deflect suspicion from yourself."
    }
