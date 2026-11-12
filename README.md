# Complete In Box

A Balatro/CloverPit-style roguelike about hunting, flipping and hoarding retro games.
Built in Godot 4.3.

**Play the latest build:** https://humble-house-studios.github.io/Complete-in-Box/

Hold your phone upright for the mobile layout; turn it sideways for the Steam layout.
Every push to `main` rebuilds that link (see `.github/workflows/deploy.yml`).

## How a run works
- **8 antes, 3 stops each:** The Hunt (garage sale → flea market, estate sale,
  storage units), The Shop (retro store → pawn shop, Collector Con), Online
  (eBuy → Heritage auction house). New venues unlock as you go.
- At each stop: buy, haggle and dig (those cost Time), open mystery lots, sell,
  list items for auction, bid, grade and repair.
- Leaving a stop **appraises your shelf**: each item adds its value, then sets
  (3+ of a platform, console + game + accessory), grails and perks add Mult.
  Miss the target and you're out of business.
- **Short vs long term:** flip now for cash, or hold collectibles that gain value
  each stop (fads lose it). Hot/cold trends and rumors move prices. Grading is a
  one-stop gamble worth up to x3.
- Between stops: a perk shop (28 perks), an upgrade, and interest on savings.

Project rules are in `CLAUDE.md`; tuning numbers in `scripts/engine/balance.gd`.

## Tests
    godot --headless -s addons/gut/gut_cmdln.gd
    godot --headless -s res://tools/sim.gd
