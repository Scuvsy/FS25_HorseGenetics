-- Default horse-genetics data. Replaces data/horses.json so dedicated hosts
-- do not flag an unknown .json file type. Savegames still store live horses
-- in the mission XML.
HorseGenetics = HorseGenetics or {}

HorseGenetics.HORSE_DATA = {
    version = 1,
    nextHorseId = 1,
    horses = {},
    coatColours = {
        "Bay",
        "Black",
        "Chestnut",
        "Grey",
        "Palomino",
        "Buckskin",
        "Pinto",
        "Seal Brown"
    }
}
