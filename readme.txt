Horse Genetics for Farming Simulator 25
Author: Scuvsy
Version: 1.0.20.0
Platform: PC only — NOT console compatible (Xbox / PlayStation)
Multiplayer: Compatible on PC

This file explains how the mod works in more detail than the ModHub listing.


================================================================================
WHAT THE MOD DOES
================================================================================

Every horse gets three genetic stats: Speed, Stamina and Health. Each stat is a
whole number from 0 to 100.

Average is the mean of those three stats:

    Average = (Speed + Stamina + Health) / 3

Those stats do two things:

  1. They change the horse's sale price.
  2. They are inherited when two horses breed.

Shop-bought horses become foundation stock. The first time the mod sees a live
horse, it assigns random Speed, Stamina and Health between 35 and 75 for each
stat, plus a coat colour. That record is saved with your game and kept even if
you later sell the horse.

Bred foals do not use that random 35-75 range. They inherit an average of both
parents, then a random variation is applied.

Vanilla automatic horse births are turned off. Horse Genetics owns horse
pregnancies, gestation, the reproduction bar, and foal births. Other animal
species are left alone.


================================================================================
HOW TO OPEN THE MENU
================================================================================

Open the Esc menu and select Horse Genetics. There are four pages.

MY HORSES
  Lists horses you currently own, with age, stats, sale modifier and live shop
  value. Click a name to see the profile, genetic bars, coat, generation,
  puberty or reproduction, and sale-value breakdown.

BREEDING
  Click a horse on the left to set Horse 1, click another for Horse 2. Click a
  selected horse again to remove it from the pairing. The page shows each
  parent's stats, the average of the pair, and a preview of possible foal
  ranges. This page does not create foals.

GENETIC INFO
  Lists every horse the mod has ever recorded, including sold horses. Select a
  horse to see a simple family tree: parents, the selected horse, and
  offspring, with Speed, Stamina, Health and Average. Click a parent or foal in
  the tree to move to that horse. Wheel over the left list to scroll all
  horses. If a horse has more than four foals, wheel over the right side to
  scroll offspring.

SETTINGS
  Gestation time (default 11 months, vanilla), puberty time (default 22 months,
  vanilla), and sale-value modifier strength (default 100%). Both month settings
  use 1, 3, 6, 8, 11, 14, 16, 18 or 22 months. In multiplayer the host's
  settings apply.


================================================================================
HOW REAL BREEDING WORKS
================================================================================

The Breeding tab is a planner. Births happen in the stable after a gestation
period.

Default gestation is 11 months, matching vanilla horses. Change it in Esc,
Horse Genetics, Settings. Options are 1, 3, 6, 8, 11, 14, 16, 18 and 22 months.

When the month changes the mod looks at each horse husbandry:

  - If a pregnancy is already running, one month is counted and the animals
    menu reproduction bar is updated. The bar already shows the first slice
    when the pregnancy starts, not 0% until the next month.
  - When elapsed months reach the chosen gestation and two stalls are free,
    both foals are born.
  - If no pregnancy is running, a new one can start when there are at least
    two horses at or above the Settings puberty age in the same building. The
    two oldest eligible horses are paired. Default puberty is 22 months.

A pregnancy can start even if the stable is full. Birth still needs two empty
stalls, because each parent produces one foal.

Foal names come from the base game's random horse names, not from the parents.
You can rename any horse afterwards. Stats stay on the genetic ID.

Both foals use the same two parents for inheritance. Each foal still rolls its
own stats, coat and variation independently, so the twins will not be clones.


================================================================================
REPRODUCTION AND PUBERTY BARS
================================================================================

The animals menu bar is driven by this mod.

Foals (under the Settings puberty age)
  A puberty bar fills with age until that age. Default is 22 months, matching
  vanilla horses. Options are 1, 3, 6, 8, 11, 14, 16, 18 and 22 months.

Adults
  The bar stays empty until a Horse Genetics pregnancy starts. As soon as it
  starts, the bar shows the first slice using your Settings gestation. Example:
  3-month gestation is about 33% when pregnancy begins, 67% after the next
  month, then birth. Last birth on the parents is set when the foals appear.

Settings
  Changing gestation while a pregnancy is running rescales the remaining time
  and the bar from months already elapsed. Changing puberty age updates the
  foal bar and when a horse can start a pregnancy.


================================================================================
HOW INHERITED STATS ARE GENERATED
================================================================================

For each stat (Speed, Stamina and Health) the foal is rolled separately.

Step 1 - Parental average
  The two parents contribute equally:

      parentalAverage = (parent1Stat + parent2Stat) / 2

Step 2 - Random variation
  A random whole number from -8 to +8 is added. Every integer in that range is
  equally likely, including 0.

Step 3 - High-quality pairing bonus
  Pairing score is the average of both parents' overall averages. If that score
  is 70 or higher, each stat has a 20% chance to gain an extra +1, +2 or +3.

Step 4 - Clamp
  The result is rounded to the nearest whole number and limited to 0-100.

So the real formula for each stat is:

    foalStat = clamp0to100( parentalAverage + variation[-8 to +8] + bonus[0 to +3] )

Example
  Parent A Speed 85, Parent B Speed 71.
  Parental average = 78.
  If variation is -4 and there is no bonus, the foal's Speed is 74.
  If variation is +8 and a +2 bonus rolls, the foal's Speed is 88.


================================================================================
WHAT THE BREEDING PREVIEW SHOWS
================================================================================

Preview ranges are a guide, not a guarantee.

For each stat the preview shows:

    (parentalAverage - 8)  to  (parentalAverage + 11)

The -8 is the worst variation. The +11 is the best variation (+8) plus the
best high-quality bonus (+3). The bonus only exists when pairing score is 70
or more, and even then it only happens 20% of the time per stat. Average foals
will land nearer the middle of the range.

The preview also shows a possible average range from those min/max stats. The
foal's real average is whatever it actually rolls.


================================================================================
HOW COAT COLOUR IS INHERITED
================================================================================

Supported coats: Bay, Black, Chestnut, Grey, Palomino, Buckskin, Pinto,
Seal Brown.

When a foal is born the mod rolls 1 to 100:

  1-45   inherit parent 1's coat (45%)
  46-90  inherit parent 2's coat (45%)
  91-100 a different coat from the list above (10%)

If both parents already share the same coat, the 45% + 45% simply makes that
colour very likely, with a 10% chance of something else.

The Breeding tab summarises this as "likely" parent colours, or other (10%).


================================================================================
HOW SALE PRICE MODIFIERS WORK
================================================================================

The game still starts from the horse's normal base sale price. Horse Genetics
then multiplies that price.

There are two parts: a base multiplier from overall average, and extra bonuses
from exceptional individual stats.

1) Base multiplier from Average
  This is a straight line:

      baseMultiplier = 0.75 + (Average / 125)

  That means:

      Average 0   ->  0.750x   (-25%)
      Average 50  ->  1.000x   (no change)
      Average 100 ->  1.400x   (+40%)

  Examples:

      Average 83.3 -> 0.75 + (83.3 / 125) = 1.416x
      Average 51.3 -> 0.75 + (51.3 / 125) = 1.160x

2) Exceptional-stat bonuses
  Each of Speed, Stamina and Health is checked on its own:

      80 to 89  adds +2.5%  (0.025)
      90 to 100 adds +5.0%  (0.05)

  A horse can get a bonus on none, one, two or all three stats.

  Example (Speed 85, Stamina 95, Health 70):
      Speed 85  -> +2.5%
      Stamina 95 -> +5.0%
      Health 70  -> no bonus
      Exceptional bonus total = +7.5%

3) Final multiplier
  The two parts are added, then clamped for the default 100% setting:

      multiplier = baseMultiplier + exceptionalBonus
      at 100%:  0.75x to 1.60x

  Sale value modifiers in Settings then scale the difference from 1.00x.
  100% is the default. Off (0%) uses the vanilla horse price. 200% doubles
  that difference, then clamps again.

  Using the example above at 100% strength:

      1.416 + 0.075 = 1.491x  ->  +49.1%

  That is the "Total sale modifier" shown in My Horses. The Value column is
  the live shop sell price after this multiplier is applied.

  After the strength slider is applied, the game still clamps the result:

      100% (default)  0.75x to 1.60x
      200%            0.50x to 2.20x
      Off             1.00x (vanilla)

Low-average horses without exceptional stats sit below 1.00x. At the default
100% setting a poor horse cannot fall below 0.75x and a superb horse cannot
exceed 1.60x.


================================================================================
FAMILY TREE AND SAVED DATA
================================================================================

Each horse record stores:

  - Genetic ID (for example HG-000004). This ID is the identity for stats.
    Renaming a horse in the animals menu only changes the label.
  - Name, generation, coat
  - Speed, Stamina, Health
  - Parent IDs when the horse was bred (shop horses have none)

Offspring are found by looking for later horses that list this horse as a
parent. Sold horses stay in Genetic Info so bloodlines remain visible.

Generation 1 is typical for shop horses. A foal's generation is one higher
than the higher of its two parents.

Pregnancies, Settings, and recent stable breeding history are saved with the
savegame.


================================================================================
MULTIPLAYER COMPATIBILITY
================================================================================

The host or dedicated server owns the genetics data:

  - Shop horses and foals get their stats on the server only. Clients receive
    those records; they do not roll their own Speed, Stamina or Health.
  - Dedicated servers scan horse pastures and stables for live horses even
    though they have no GUI. Bought horses are registered there and synced
    to the owning farm. Refresh on MY HORSES asks the server for a new list.
  - Horse Genetics IDs travel with the live animal, so sale prices match for
    every player.
  - Saves are written on the server. Joining players are sent the current
    registry when they connect.
  - MY HORSES, BREEDING and GENETIC INFO show the local farm's horses. Other
    farms' bloodlines stay on that farm.
  - Real births still happen on the monthly tick. Gestation and sale-modifier
    settings are owned by the host.

Every player in the session needs the same version of the mod, including the
dedicated server. Farming Simulator 25 only loads this mod as a zip in
multiplayer. Keep FS25_HorseGenetics.zip in the server mods folder, with
modDesc.xml at the zip root (not inside a nested folder).


================================================================================
OTHER MODS
================================================================================

Horse Genetics only changes horses. Cows, pigs, sheep, chickens and other
animals keep their own mods.

Enhanced Animal System (FS25_EnhancedAnimalSystem) is supported together with
this mod:

  - Horse pregnancies, gestation, genetics, names and sale values stay on
    Horse Genetics. Do not expect Enhanced Animal System's horse insemination
    or automatic horse births to replace that.
  - Other species stay on Enhanced Animal System.
  - When both mods are loaded, Horse Genetics portraits in MY HORSES, BREEDING
    and GENETIC INFO use foal-age horse visuals from the animal system.
  - New foals still get genetics from this mod, and they are created so they
    continue to work with Enhanced Animal System's extra cluster fields
    (including male/female offspring when a breed has a male subtype).

The animals menu reproduction bar for horses still follows Horse Genetics
pregnancy and Settings gestation, including when Enhanced Animal System is
installed.


================================================================================
TIPS
================================================================================

- Pair high averages together if you want the 70+ pairing bonus to be possible.
- The bonus is not guaranteed. Even a 90+ pairing can still roll -8 variation.
- Two free stalls are required at birth. One empty stall is not enough.
- A pregnancy can start while the stable is full. Clear two stalls before the
  gestation finishes if you want the foals to appear on time.
- Both parents must be at least the Settings puberty age (default 22 months).
- Watch the animals menu bar: empty adults are waiting to pair, filling adults
  are pregnant, filling foals are still in puberty.
- Preview Horse 1 Foal and Horse 2 Foal are two independent rolls of the same
  pairing, matching the two real foals born in the stable.

================================================================================
END
================================================================================
