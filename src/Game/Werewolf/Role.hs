{-|
Module      : Game.Werewolf.Role
Description : Simplistic role data structure and instances.

Copyright   : (c) Henry J. Wylde, 2016
License     : BSD3
Maintainer  : public@hjwylde.com

Roles are split into four categories:

* The Ambiguous.
* The Loners.
* The Villagers.
* The Werewolves.
-}

{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE Rank2Types        #-}
{-# LANGUAGE TemplateHaskell   #-}

module Game.Werewolf.Role (
    -- * Role
    Role,
    name, allegiance, balance, description, rules,

    Allegiance(..),
    _Angel, _Villagers, _Werewolves,

    -- ** Instances
    allRoles, restrictedRoles,
    allAllegiances,

    -- *** The Ambiguous
    -- | No-one knows the true nature of the Ambiguous, sometimes not even the Ambiguous themselves!
    --
    --   The Ambiguous are able to change allegiance throughout the game.
    devotedServantRole, wildChildRole, wolfHoundRole,

    -- *** The Loners
    -- | The Loners look out for themselves and themselves alone.

    --   The Loners must complete their own objective.
    angelRole,

    -- *** The Villagers
    -- | Fraught with fear of the unseen enemy, the Villagers must work together to determine the
    --   truth and eliminate the threat to Fougères. The task before them will not be easy, but a
    --   certain few have learnt some tricks over the years that may turn out rather useful.

    --   The Villagers must lynch all of the Werewolves.
    bearTamerRole, defenderRole, scapegoatRole, seerRole, simpleVillagerRole, villageIdiotRole,
    villagerVillagerRole, witchRole,

    -- *** The Werewolves
    -- | Hiding in plain sight, the Werewolves are not a small trifle.

    --   The Werewolves must devour all of the Villagers.
    simpleWerewolfRole,

    -- * Utility functions
    is, isn't, filteredBy,
) where

import Control.Lens hiding (isn't)

import           Data.Function
import           Data.List
import           Data.Monoid
import           Data.Text     (Text)
import qualified Data.Text     as T

-- | Role definitions require only a few pieces of information.
--   Most of the game logic behind a role is implemented in "Game.Werewolf.Command" and
--   "Game.Werewolf.Engine".
--
--   The @balance@ attribute on a role indicates the allegiance it favours. For example, a Simple
--   Werewolf has a balance of -4 while the Seer has a balance of 2. A balance of 0 means it favours
--   neither allegiance.
--
--   N.B., role equality is defined on just the 'name' as a role's 'allegiance' may change
--   throughout the game.
data Role = Role
    { _name        :: Text
    , _allegiance  :: Allegiance
    , _balance     :: Int
    , _description :: Text
    , _rules       :: Text
    } deriving (Read, Show)

-- | The Loner allegiances are seldom used, rather they are present for correctness.
data Allegiance = Angel | Villagers | Werewolves
    deriving (Eq, Read, Show)

makeLenses ''Role

instance Eq Role where
    (==) = (==) `on` view name

makePrisms ''Allegiance

-- | A list containing all the roles defined in this file.
allRoles :: [Role]
allRoles =
    [ angelRole
    , bearTamerRole
    , defenderRole
    , devotedServantRole
    , scapegoatRole
    , seerRole
    , simpleVillagerRole
    , villageIdiotRole
    , simpleWerewolfRole
    , villagerVillagerRole
    , wildChildRole
    , witchRole
    , wolfHoundRole
    ]

-- | A list containing roles that are restricted to a single instance per 'Game'.
--
--   @
--   'restrictedRoles' = 'allRoles' \\\\ ['simpleVillagerRole', 'simpleWerewolfRole']
--   @
restrictedRoles :: [Role]
restrictedRoles = allRoles \\ [simpleVillagerRole, simpleWerewolfRole]

-- | A list containing all the allegiances defined in this file.
--
--   TODO (hjw): use reflection to get this list
allAllegiances :: [Allegiance]
allAllegiances = [Angel, Villagers, Werewolves]

-- | /Who could dream of a better servant than one willing to give up her life for that of her/
--   /masters? Don't rejoice too fast, as the devouring ambition within her could spell the end of/
--   /the village!/
--
--   Before the revelation of the card of the player eliminated by the village's vote, the Devoted
--   Servant can reveal herself by showing her card and taking on the role of the eliminated player.
--   Upon taking on her master's role, any special abilities are reset and any first turns are
--   replayed.
devotedServantRole :: Role
devotedServantRole = Role
    { _name         = "Devoted Servant"
    , _allegiance   = Villagers
    , _balance      = 2
    , _description  = T.unwords
        [ "Who could dream of a better servant than one willing to give up her life for that of her"
        , "masters? Don't rejoice too fast, as the devouring ambition within her could spell the"
        , "end of the village!"
        ]
    , _rules        = T.unwords
        [ "Before the revelation of the card of the player eliminated by the village's vote, the"
        , "Devoted Servant can reveal herself by showing her card and taking on the role of the"
        , "eliminated player. Upon taking on her master's role, any special abilities are reset and"
        , "any first turns are replayed."
        ]
    }

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
--   However for as long as the Wild-child's role model is alive, he remains a Villager.
wildChildRole :: Role
wildChildRole = Role
    { _name         = "Wild-child"
    , _allegiance   = Villagers
    , _balance      = -1
    , _description  = T.unwords
        [ "Abandoned in the woods by his parents at a young age, he was raised by wolves. As soon"
        , "as he learned how to walk on all fours, the Wild-child began to wander around Miller's"
        , "Hollow. One day, fascinated by an inhabitant of the village who was walking upright"
        , "with grace and presence, he made them his secret role model. He then decided to"
        , "integrate himself into the community of Miller's Hollow and entered, worried, in the"
        , "village. The community was moved by his frailty, adopted him, and welcomed him in their"
        , "fold. What will become of him: honest Villager or terrible Werewolf? For all of his"
        , "life, the heart of the Wild-child will swing between these two alternatives. May his"
        , "model confirm him in his newfound humanity."
        ]
    , _rules        = T.unwords
        [ "On the first night, the Wild-child may choose a player to become his role model. If"
        , "during the game the chosen player is eliminated, the Wild-child becomes a Werewolf. He"
        , "will then wake up the next night with his peers and will devour with them each night"
        , "until the end of the game.  However for as long as the Wild-child's role model is alive,"
        , "he remains a Villager."
        ]
    }

-- | /All dogs know in the depths of their soul that their ancestors were wolves and that it's/
--   /mankind who has kept them in the state of childishness and fear, the faithful and generous/
--   /companions. In any case, only the Wolf-hound can decide if he'll obey his human and civilized/
--   /master or if he'll listen to the call of wild nature buried within him./
--
--   On the first night, the Wolf-hound chooses if he wants to be a Simple Villager or Werewolf. The
--   choice is final.
wolfHoundRole :: Role
wolfHoundRole = Role
    { _name         = "Wolf-hound"
    , _allegiance   = Villagers
    , _balance      = -1
    , _description  = T.unwords
        [ "All dogs know in the depths of their soul that their ancestors were wolves and that it's"
        , "mankind who has kept them in the state of childishness and fear, the faithful and"
        , "generous companions. In any case, only the Wolf-hound can decide if he'll obey his human"
        , "and civilized master or if he'll listen to the call of wild nature buried within him."
        ]
    , _rules        = T.unwords
        [ "On the first night, the Wolf-hound chooses if he wants to be a Simple Villager or"
        , "Werewolf. The choice is final."
        ]
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
    , _balance      = 0
    , _description  = T.unwords
        [ "The muddy life of a village infested with evil creatures repulses him; he wishes to"
        , "believe he's the victim of a terrible nightmare, in order to finally wake up in his"
        , "comfortable bed."
        ]
    , _rules        = T.intercalate "\n"
        [ T.unwords
            [ "When the Angel is in play, the game always begins with the village's debate followed"
            , "by an elimination vote, and then the first night."
            ]
        , T.unwords
            [ "The Angel wins if he manages to get eliminated on the first round (day or night). If"
            , "he fails, then he becomes a Simple Villager for the rest of the game."
            ]
        ]
    }

-- | /Ah! How sweet it is, in my memory, the sound of chains slipping onto the cobblestones of the/
--   /"Three Road" plaza, accompanied by the grunting of Ursus. Ah! How long ago it was that Titan,/
--   /the Bear Tamer, would lead his companion in a ballet so gravious that we'd cry every summer/
--   /in Miller's Hollow. Ursus even had the oh-so-previous ability to detect lycanthropes hidden/
--   /near him./
--
--   Each morning, right after the revelation of any possible nocturnal victims, if at least one
--   Werewolf is or ends up directly next to the Bear Tamer, then Ursus grunts to indicate danger to
--   all of the other players.
bearTamerRole :: Role
bearTamerRole = Role
    { _name         = "Bear Tamer"
    , _allegiance   = Villagers
    , _balance      = 2
    , _description  = T.unwords
        [ "Ah! How sweet it is, in my memory, the sound of chains slipping onto the cobblestones of"
        , "the \"Three Road\" plaza, accompanied by the grunting of Ursus. Ah! How long ago it was"
        , "that Titan, the Bear Tamer, would lead his companion in a ballet so gravious that we'd"
        , "cry every summer in Miller's Hollow. Ursus even had the oh-so-previous ability to detect"
        , "lycanthropes hidden near him."
        ]
    , _rules        = T.unwords
        [ "Each morning, right after the revelation of any possible nocturnal victims, if at least"
        , "one Werewolf is or ends up directly next to the Bear Tamer, then Ursus grunts to"
        , "indicate danger to all of the other players."
        ]
    }

-- | /This character can save the Villagers from the bite of the Werewolves./
--
--   Each night the Defender is called before the Werewolves to select a player deserving of his
--   protection. That player is safe during the night (and only that night) against the Werewolves.
--
--   The Defender may not protect the same person two nights in a row.
defenderRole :: Role
defenderRole = Role
    { _name         = "Defender"
    , _allegiance   = Villagers
    , _balance      = 2
    , _description  =
        "This character can save the Villagers from the bite of the Werewolves."
    , _rules        = T.intercalate "\n"
        [ T.unwords
            [ "Each night the Defender is called before the Werewolves to select a player deserving"
            , "of his protection. That player is safe during the night (and only that night)"
            , "against the Werewolves."
            ]
        , "The Defender may not protect the same person two nights in a row."
        ]
    }

-- | /It's sad to say, but in Miller's Hollow, when something doesn't go right it's always him who/
--   /unjustly suffers the consequences./
--
--   If the village's vote ends in a tie, it's the Scapegoat who is eliminated instead of no-one.
--
--   In this event, the Scapegoat has one last task to complete: he must choose whom is permitted to
--   vote or not on the next day.
scapegoatRole :: Role
scapegoatRole = Role
    { _name         = "Scapegoat"
    , _allegiance   = Villagers
    , _balance      = 0
    , _description  = T.unwords
        [ "It's sad to say, but in Miller's Hollow, when something doesn't go right it's always him"
        , "who unjustly suffers the consequences."
        ]
    , _rules        = T.intercalate "\n"
        [ T.unwords
            [ "If the village's vote ends in a tie, it's the Scapegoat who is eliminated instead of"
            , "no-one."
            ]
        , T.unwords
            [ "In this event, the Scapegoat has one last task to complete: he must choose whom is"
            , "permitted to vote or not on the next day."
            ]
        ]
    }

-- | /Frequently misunderstood and thought to be a fortune teller, the Seer has the ability to see/
--   /into fellow townsfolk and determine their true nature. This ability to see is not given out/
--   /lightly, for certain it is a gift! Visions will always be true, but only for the present as/
--   /not even the Seer knowns what the future holds./
--
--   Each night the Seer sees the allegiance of a player of their choice.
seerRole :: Role
seerRole = Role
    { _name         = "Seer"
    , _allegiance   = Villagers
    , _balance      = 2
    , _description  = T.unwords
        [ "Frequently misunderstood and thought to be a fortune teller, the Seer has the ability to"
        , "see into fellow townsfolk and determine their true nature. This ability to see is not"
        , "given out lightly, for certain it is a gift! Visions will always be true, but only for"
        , "the present as not even the Seer knowns what the future holds."
        ]
    , _rules        = "Each night the Seer sees the allegiance of a player of their choice."
    }

-- | /A simple, ordinary townsperson in every way. Some may be cobblers, others bakers or even/
--   /nobles. No matter their differences though, the plight of Werewolves in Fougères unites them/
--   /in this unfortunate time./
--
--   A Simple Villager has no special abilities, they must use their guile to determine whom among
--   them is not who they say they are.
simpleVillagerRole :: Role
simpleVillagerRole = Role
    { _name         = "Simple Villager"
    , _allegiance   = Villagers
    , _balance      = 1
    , _description  = T.unwords
        [ "A simple, ordinary townsperson in every way. Some may be cobblers, others bakers or even"
        , "nobles. No matter their differences though, the plight of Werewolves in Fougères unites"
        , "them in this unfortunate time."
        ]
    , _rules        = T.unwords
        [ "A Simple Villager has no special abilities, they must use their guile to determine whom"
        , "among them is not who they say they are."
        ]
    }

-- | /What is a village without an idiot? He does pretty much nothing important, but he's so/
--   /charming that no one would want to hurt him./
--
--   If the village votes against the Village Idiot, his identity is revealed. At that moment the
--   Villagers understand their mistake and immediately let him be.
--
--   The Village Idiot continues to play but may no longer vote, as what would the vote of an idiot
--   be worth?
villageIdiotRole :: Role
villageIdiotRole = Role
    { _name         = "Village Idiot"
    , _allegiance   = Villagers
    , _balance      = 0
    , _description  = T.unwords
        [ "What is a village without an idiot? He does pretty much nothing important, but he's so"
        , "charming that no one would want to hurt him."
        ]
    , _rules        = T.intercalate "\n"
        [ T.unwords
            [ "If the village votes against the Village Idiot, his identity is revealed. At that"
            , "moment the Villagers understand their mistake and immediately let him be."
            ]
        , T.unwords
            [ "The Village Idiot continues to play but may no longer vote, as what would the vote"
            , "of an idiot be worth?"
            ]
        ]
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
    , _balance      = 2
    , _description  = T.unwords
        [ "This person has a soul as clear and transparent as the water from a mountain stream."
        , "They will deserve the attentive ear of their peers and will make their word decisive in"
        , "crucial moments."
        ]
    , _rules        = T.unwords
        [ "When the game begins, the village is told the identity of the Villager-Villager, thus"
        , "ensuring certainty that its owner is truly an innocent Villager."
        ]
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
    , _balance      = 3
    , _description  = T.unwords
        [ "She knows how to brew two extremely powerful potions: a healing potion, to resurrect the"
        , "player devoured by the Werewolves, and a poison potion, used at night to eliminate a"
        , "player."
        ]
    , _rules        = T.unwords
        [ "The Witch is called after the Werewolves. She is allowed to use both potions in the same"
        , "night and is also allowed to heal herself."
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
    , _balance      = -4
    , _description  = T.unwords
        [ "Each night they devour a Villager. During the day they try to hide their nocturnal"
        , "identity to avoid mob justice."
        ]
    , _rules        = "A Werewolf may never devour another Werewolf."
    }

-- | The counter-part to 'isn't', but more general as it takes a 'Getting' instead.
is :: Getting Any s a -> s -> Bool
is query = has query

-- | A re-write of 'Control.Lens.Prism.isn't' to be more general by taking a 'Getting' instead.
isn't :: Getting All s a -> s -> Bool
isn't query = hasn't query

-- | A companion to 'filtered' that, rather than using a predicate, filters on the given lens for
-- matches.
filteredBy :: Eq b => Lens' a b -> b -> Traversal' a a
filteredBy lens value = filtered ((value ==) . view lens)
