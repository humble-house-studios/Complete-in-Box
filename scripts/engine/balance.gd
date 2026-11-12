class_name Balance
extends RefCounted
## All the tuning numbers in one place.

const ANTES_TO_WIN := 8
## Appraisal target for stop 1 of each ante; later stops multiply it.
const ANTE_TARGET := [30, 70, 160, 350, 750, 1600, 3400, 7000]
const ENDLESS_GROWTH := 2.2
const STOP_TARGET_MULT := [1.0, 1.4, 1.8]

const START_CASH := 25
const START_SHELF := 7
const START_PERK_SLOTS := 4
const START_INTEREST_CAP := 5
const STARTER_ITEMS := 3

## How many platforms a run's market deals in (picked at random each run).
const ACTIVE_PLATFORMS := 8

## Cash for clearing a stop: base by stop, plus the ante number.
const STOP_REWARD := [5, 7, 10]
const TIME_LEFT_REWARD := 1
const INTEREST_PER := 5

const PERK_OFFERS := 3
const REROLL_START := 2
const DUMP_VALUE := 1

## Rarity weights [common, uncommon, rare, grail] by effective level (ante + venue boost).
const TIER_WEIGHTS := [
	[80, 18, 2, 0],
	[80, 18, 2, 0],
	[70, 25, 5, 0],
	[58, 30, 11, 1],
	[48, 34, 15, 3],
	[38, 36, 21, 5],
	[30, 36, 26, 8],
	[24, 34, 31, 11],
	[18, 32, 36, 14],
	[12, 30, 40, 18],
	[8, 28, 42, 22],
	[5, 25, 44, 26],
]

## Pull luck. Each pull without a rare adds PITY_RARE to the rare weight (and
## PITY_GRAIL to grails from ante 2), up to PITY_CAP pulls. After a grail,
## grail odds drop to GRAIL_COOL_MULT for GRAIL_COOL pulls.
const PITY_RARE := 0.9
const PITY_GRAIL := 0.12
const PITY_CAP := 24
const GRAIL_COOL := 12
const GRAIL_COOL_MULT := 0.25
## Venue taste inside a tier.
const HUNT_OLD_BIAS := 1.35
const SHOP_HW_BIAS := 1.3
const ONLINE_NEW_BIAS := 1.25
## Supply: hot platforms are picked over, cold ones flood in.
const HOT_SUPPLY := 0.75
const COLD_SUPPLY := 1.3

## Market
const HOT := 1.5
const COLD := 0.7
const RUMOR_ACCURACY := 0.75
const APPRECIATE_COLLECTIBLE := 0.06  # per stop held, uncommon+ or Mint/Sealed
const APPRECIATE_COMMON := 0.03
const APPRECIATE_SEALED_EXTRA := 0.03
const FAD_DECAY := 0.12
const FAD_FLOOR := 0.35

## Grading: [grade, weight, value multiplier]
const GRADES := [[10, 8, 3.0], [9, 20, 2.0], [8, 35, 1.5], [7, 25, 1.15], [6, 12, 0.9]]
const GRADE_FEE := 8
const GRADE_FEE_SHARE := 0.1

const REPAIR_FEE := 3
const REPAIR_SHARE := 0.3

## Online
const DAMAGE_RISK := 0.15
const SCAM_RISK := 0.35
const OPENING_BID := 0.4
const RIVAL_RANGE := [0.7, 1.3]
const SNIPE_CHANCE := 0.3
const SNIPE_BOOST := 1.2
const BID_STEP := 1.15

## Garage-style guesses: shown range around the true value.
const EST_LOW := [0.5, 0.85]
const EST_HIGH := [1.2, 1.8]

const LOT_PRICE := [0.45, 0.85]

## Changing markets: at Home before these antes you may sell your whole shelf
## (at PIVOT_RATE of market value) and deal in cards / coins from then on.
const PIVOT_CARDS_ANTE := 5
const PIVOT_COINS_ANTE := 7
const PIVOT_RATE := 0.8
const PIVOT_STARTERS := 2
const PIVOT_TIME := 1
## Cards per sealed product when you rip it, and the condition the pulls come in.
const OPEN_PACK := 3
const OPEN_DECK := 4
const OPEN_BOX := 5
const PULL_COND := [0, 8, 50, 34, 8]
const OVERFLOW_SELL := 0.4


static func target(ante: int, stop: int) -> int:
	var base: float
	if ante <= ANTE_TARGET.size():
		base = float(ANTE_TARGET[ante - 1])
	else:
		base = float(ANTE_TARGET[-1]) * pow(ENDLESS_GROWTH, ante - ANTE_TARGET.size())
	return int(round(base * float(STOP_TARGET_MULT[clampi(stop, 0, 2)])))


static func tier_weights(level: int) -> Array:
	return TIER_WEIGHTS[clampi(level, 0, TIER_WEIGHTS.size() - 1)]
