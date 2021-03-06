local object = require("object")
local kAttack = {}

-- kAttack[unitType.id]={
--
-- goldCost = integer or nil
--      amount of gold it costs to generate a unit
--      absent means 0
-- minTreasury = integer or nil
--      minimum amount of gold in treasury to generate a unit
--      absent means refer to gold cost
--      (tribe will generate and be set to 0 if treasury is less than goldCost)
-- treasuryFailMessage = string or nil
--      A message to be displayed if the unit fails to spawn a unit due to an 
--      insufficient treasury
--      nil means no message

-- There are three ways to specify move costs, in full movement points,
-- in "atomic" movement points, and as a fraction of total movement points for the
-- unit type.  Use only one kind per unit type

-- moveCost = integer or nil
--      movement points to be expended generating the unit
--      "full" movement points
--      absent means 0
-- minMove = integer or nil
--      minimum remaining movement points to be allowed to generate a unit
--      "full" movement points
--      absent means any movement points for land/sea, 2 "atomic" for air units
-- postGenMinMove = integer or nil
--      a unit will be left with at least this many movement points after
--      the generation function
--      absent means 0 for land/sea, 1 "atomic" for air units
-- moveCostAtomic = integer or nil
--      movement points to be expended generating the unit
--      refers to the unit.moveSpent movement points
--      absent means 0
-- minMoveAtomic = integer or nil
--      minumum remaining movement points to be allowed to generate a unit
--      referes to the unit.moveSpent movement points
--      absent means any movement points for land, 2 "atomic" for air units
-- postGenMinMoveAtomic = integer or nil
--      a unit will be left with at least this many movement points after
--      the generation function
--      absent means 0 for land/sea, 1 "atomic" for air units
-- moveCostFraction = number in [0,1] or nil
--      fraction of unit's total movement points expended generating the unit
--      round up to nearest "atomic" movement point
--      absent means 0
-- minMoveFraction = number in [0,1] or nil
--      fraction of unit's total movement points that must remain to be allowed
--      to generate a unit
--      absent means any movement points for land, 2 "atomic" for air units
--      round up to nearest "atomic" movement point
-- postGenMinMoveFraction = number in [0,1] or nil
--      a unit will be left with at least this many movement points after
--      the generation function, round up to nearest "atomic" move point
--      absent means 0 for land/sea, 1 "atomic" for air units
-- roundFractionFull = bool or nil
--      fractional movement cost and minimum are rounded up to full movement point
--      instead of atomic movement point
--      nil/false means don't
-- roundFractionFullDown = bool or nil
--      fractional cost and minimum are rounded down to full move point
--      nil/false means don't
-- minMoveFailMessage = string or nil
--      a message to be displayed if a unit is not generated due to insufficient
--      movement points.
--      nil means no message

-- allowedTerrainTypes = table of integers or nil
--      a unit may only be generated if the tile it is standing on
--      corresponds to one of numbers in the table
--      nil means the unit can be generated on any terrain type
-- terrainTypeFailMessage = string or nil
--      message to be displayed if a unit is not generated due to standing
--      on the incorrect terrain

-- requiredTech = tech object or nil
--      the generating civ must have this technology in order to generate
--      the unit
--      nil means no requirement
-- techFailMessage = string or nil
--      message to be displayed if a unit is not generated due to not having
--      the correct technology

-- payload = boolean or nil
--      if true, unit must have a home city in order to generate munitions
--      and generating munitions sets the home city to NONE
-- payloadFailMessage = string or nil
--      message to be displayed if a unit is not generated due to the 
--      payload restriction
-- payloadRestrictionCheck = nil or function(unit)-->boolean
--      If function returns false, the home city is not valid for giving the
--      unit a payload.  This will be checked when the unit is activated, when
--      the unit is given a new home city with the 'h' key and when the unit
--      tries to generate a munition
--      nil means no restriction
-- payloadRestrictionMessage = nil or string
--      message to show if a unit fails the payloadRestrictionCheck

-- canGenerateFunction = nil or function(unit)-->boolean 
--      This function applied to the generating unit must return true in order
--      for a unit to be spawned.  All other conditions still apply.
--      any failure message should be part of canGenerateFunction
--      absent means no extra conditions

-- generateUnitFunction = nil or function(unit)-->table of unit
--      This function creates the unit or units to be generated
--      and returns a table containing those units
--      Ignore any specifications prefixed with * if this is used
--      nil means use other specifications

--*generatedUnitType = unitType
--      The type of unit to be generated
--      can't be nil unless generateUnitFunction is used instead

--*giveVeteran = bool or nil
--      generated unit(s) given veteran status if true
--      nil or false means don't give vet status
--      if true, overrides copyVeteranStatus

--*copyVeteranStatus = bool or nil
--      generated unit(s) copy veteran status of generating unit if true
--      nil or false means don't give vet status

--*setHomeCityFunction = nil or function(generatingUnit)-->cityObject
--      determines what home city the spawned unit should have
--      nil means a home city of NONE

--*numberToGenerate = nil or number or thresholdTable or function(generatingUnit)-->number
--      if nil, generate 1 unit in all circumstances
--      if integer, generate that many units (generate 0 if number less than 0)
--      if number not integer, generate floor(number), and 1 more with
--      probability number-floor(number)
--      if thresholdTable, use remaining hp as the key, to get the number to create
--      if function, get the number as the returned value of the function 

-- activate = bool or nil
--      Activates one of the generated units if true.  If generateUnitFunction was used,
--      the unit at index 1 is activated, if index 1 has a value.  (if not, any unit in
--      the list might be chosen)
--      
--  successMessage = string or nil
--  message to show if a unit (or units) is created
--

kAttack[object.uSubmarine.id] = {goldCost = 500,moveCost = 3,allowedTerrainTypes={10,},
        treasuryFailMessage = "This munition requires 500 gold to fire.",
        terrainTypeFailMessage = object.uSubmarine.name.." units can only fire "..object.uCruiseMsl.name.." units at sea.",
        requiredTech = object.aRocketry,
        techFailMessage = object.uSubmarine.name.." units cannot fire fire "..object.uCruiseMsl.name.." units until we have discovered "..object.aRocketry.name..".",
        generatedUnitType = object.uCruiseMsl, activate = true,}

return kAttack
