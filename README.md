# Blackjack

Bicycle Cards rules based Black Jack game written in RoR

### Payouts

| Outcome | Payout |
|---|---|
| Blackjack (Natural 21) | 3:2 — wager + 1.5× wager |
| Regular Win | 1:1 — wager + wager |
| Push (Tie) | Wager returned |
| Loss | Wager forfeited |

### Features

- Bankroll tracking across multiple rounds
- Dealer upcard visible, second card hidden until player stands
- Live score display for player and dealer
- Wallet summary page on exit
- Input validation for wagers

## Technology Stack

- **Ruby**: 3.3.6
- **Rails**: 8.0.2
- **Database**: SQlite3
- **CSS Framework**: Tailwind CSS
- **Testing**: Minitest

## Prerequisites

- Ruby 3.3.6 or higher
- SQLite3
- Bundler

## Installation

1. **Clone the repository**
   ```bash
   cd blackjack
   ```

2. **Install dependencies**
   ```bash
   bundle install
   ```

3. **Set up the database**
   ```bash
   bin/rails db:create
   bin/rails db:migrate
   ```

4. **Setup tailwind**
   ```bash
   rails tailwindcss:build 
   ```

4. **Start the server**
   ```bash
   bin/dev
   ```

   Or without the Tailwind watcher:
   ```bash
   bin/rails server
   ```

5. **Visit the application**
   ```
   http://localhost:3000
   ```

## How to Play

1. **Start a New Game**
    - You begin with a bankroll of $1,000
    - Enter your wager (minimum $1, maximum your current bankroll)
    - Click "Deal Me In"

2. **Playing Your Hand**
    - You'll see your two cards and the dealer's upcard
    - The dealer's second card remains face-down
    - Your current score is shown beneath your hand

   **Options:**
    - **Hit** — draw another card
    - **No More** — hold your hand and let the dealer play

3. **Dealer's Turn**
    - After you stand, the dealer's hidden card is revealed
    - The dealer draws automatically until reaching 17 or higher
    - The dealer follows fixed rules — no decisions

4. **Outcomes**
    - **Blackjack** — Ace + 10-value card on opening deal pays 3:2
    - **Bust** — going over 21 loses immediately
    - **Higher score** — closest to 21 without busting wins
    - **Push** — equal scores return your wager

5. **Continue or Walk Away**
    - After each round click "Play Another Round" to continue
    - Click "Nope, I'm Done" to visit your wallet and see your final bankroll
    - Your bankroll carries over between rounds automatically

## Running Tests

**Run all tests:**
```bash
bundle exec rails test
```

**Run the Game model tests only:**
```bash
bundle exec rails test test/models/game_test.rb
```

## Design Decisions

### Architecture

- **Single Model**: All game logic lives in the `Game` model for simplicity
- **JSON Storage**: `player_hand`, `house_hand`, and `shoe` stored as JSON columns — no extra tables needed
- **Stateful Rounds**: Each round persists to the database, enabling balance carry-over and game history

### Domain Language

Attribute and method names use blackjack-specific terminology throughout:

| Concept | Name used |
|---|---|
| Deck of cards | `shoe` |
| Dealer's cards | `house_hand` |
| Player's cards | `player_hand` |
| Player's funds | `bankroll` |
| Amount staked | `wager` |
| Game phase | `round_phase` |
| Round result | `outcome` |
| Dealer's face-up card score | `upcard_value` |

### Game Logic

- **Bicycle Cards Rules** — implementation follows the official ruleset
- **Forced Dealer** — dealer has no agency; hits on 16 or below, stands on 17 or above
- **Correct Deal Order** — player card, dealer card, player card, dealer card (second dealer card hidden)
- **Ace Flexibility** — aces score as 11 unless that would bust the hand, in which case they score as 1

## Rules Reference

Based on [Bicycle Cards Official Blackjack Rules](https://bicyclecards.com/how-to-play/blackjack)

### Card Values

- **Number cards (2–10)** — face value
- **Face cards (J, Q, K)** — worth 10
- **Aces** — worth 1 or 11

### Dealer Rules (Mandatory)

- Must draw on 16 or under
- Must stand on 17 or above

### Win Conditions

1. **Blackjack** beats any non-blackjack hand
2. **Both blackjack** results in a push
3. **Bust** (over 21) loses immediately
4. **Higher score** (21 or under) wins
5. **Equal scores** result in a push

### Limitations
Each session supports one player against the house