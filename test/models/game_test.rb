require "test_helper"

class GameTest < ActiveSupport::TestCase

  # ── Helpers ─────────────────────────────────────────────────────────────────

  def new_game(balance: 1000)
    Game.create!(bankroll: balance)
  end

  def card(rank, suit = "♠")
    { "rank" => rank, "suit" => suit }
  end

  def deal_game(player_cards:, dealer_cards:, bet: 100)
    game = new_game
    game.place_wager(bet)
    game.update!(
      player_hand: player_cards,
      house_hand: dealer_cards,
      shoe: build_stub_shoe,
      round_phase: "player_turn"
    )
    game
  end

  def build_stub_shoe
    [card("5"), card("6"), card("7"), card("8"), card("9")]
  end


  # ── Validations ─────────────────────────────────────────────────────────────

  test "is valid with default attributes" do
    game = Game.new(bankroll: 1000)
    assert game.valid?
  end

  test "is invalid without bankroll" do
    game = Game.new(bankroll: nil)
    assert game.invalid?
    assert_includes game.errors[:bankroll], "can't be blank"
  end

  test "is invalid with negative bankroll" do
    game = Game.new(bankroll: -1)
    assert game.invalid?
  end

  test "is invalid with negative wager" do
    game = Game.new(bankroll: 1000, wager: -1)
    assert game.invalid?
  end

  test "is invalid when not betting and wager is 0" do
    game = new_game
    game.round_phase = "player_turn"
    game.wager = 0
    assert game.invalid?
    assert_includes game.errors[:wager], "must be greater than 0 when game is in progress"
  end


  # ── Default state ────────────────────────────────────────────────────────────

  test "starts in betting phase" do
    assert new_game.betting?
  end

  test "starts with empty hands" do
    game = new_game
    assert_empty game.player_hand
    assert_empty game.house_hand
  end

  test "starts with zero wager" do
    assert_equal 0, new_game.wager
  end


  # ── place_wager ────────────────────────────────────────────────────────────────

  test "places a valid bet and deducts from balance" do
    game = new_game(balance: 1000)
    game.place_wager(200)
    assert_equal 200, game.wager
    assert_equal 800, game.bankroll
  end

  test "raises when bet is zero" do
    assert_raises(ArgumentError) { new_game.place_wager(0) }
  end

  test "raises when bet is negative" do
    assert_raises(ArgumentError) { new_game.place_wager(-50) }
  end

  test "raises when bet exceeds balance" do
    assert_raises(ArgumentError) { new_game.place_wager(1001) }
  end

  test "raises when placing a bet outside betting phase" do
    game = new_game
    game.update!(round_phase: "player_turn", wager: 100)
    assert_raises(StandardError) { game.place_wager(50) }
  end


  # ── deal_initial_cards ───────────────────────────────────────────────────────

  test "deals two cards to player and dealer" do
    game = new_game
    game.place_wager(100)
    game.deal_initial_cards
    assert_equal 2, game.player_hand.length
    assert_equal 2, game.house_hand.length
  end

  test "transitions to player_turn after deal" do
    game = new_game
    game.place_wager(100)
    game.deal_initial_cards
    assert game.player_turn?
  end

  test "shoe has 48 cards remaining after deal" do
    game = new_game
    game.place_wager(100)
    game.deal_initial_cards
    assert_equal 48, game.shoe.length
  end


  # ── player_score / dealer_score ──────────────────────────────────────────────

  test "scores a basic numeric hand" do
    game = deal_game(player_cards: [card("7"), card("8")], dealer_cards: [card("2"), card("3")])
    assert_equal 15, game.player_score
  end

  test "scores face cards as 10" do
    game = deal_game(player_cards: [card("K"), card("Q")], dealer_cards: [card("2"), card("3")])
    assert_equal 20, game.player_score
  end

  test "scores ace as 11 when it does not bust" do
    game = deal_game(player_cards: [card("A"), card("9")], dealer_cards: [card("2"), card("3")])
    assert_equal 20, game.player_score
  end

  test "scores ace as 1 when 11 would bust" do
    game = deal_game(player_cards: [card("A"), card("9"), card("5")], dealer_cards: [card("2"), card("3")])
    assert_equal 15, game.player_score
  end

  test "handles two aces correctly" do
    game = deal_game(player_cards: [card("A"), card("A")], dealer_cards: [card("2"), card("3")])
    assert_equal 12, game.player_score
  end

  test "returns 0 for empty hand" do
    game = new_game
    assert_equal 0, game.player_score
  end


  # ── dealer_hidden_card? ──────────────────────────────────────────────────────

  test "dealer card is hidden during betting phase" do
    assert new_game.dealer_hidden_card?
  end

  test "dealer card is hidden during player turn" do
    game = deal_game(player_cards: [card("7"), card("8")], dealer_cards: [card("K"), card("6")])
    assert game.dealer_hidden_card?
  end

  test "dealer card is revealed during dealer turn" do
    game = deal_game(player_cards: [card("7"), card("8")], dealer_cards: [card("K"), card("6")])
    game.update!(round_phase: "dealer_turn")
    assert_not game.dealer_hidden_card?
  end

  test "dealer card is revealed when game is finished" do
    game = deal_game(player_cards: [card("7"), card("8")], dealer_cards: [card("K"), card("6")])
    game.update!(round_phase: "finished")
    assert_not game.dealer_hidden_card?
  end


  # ── upcard_value ─────────────────────────────────────────────────────

  test "shows only first card value during player turn" do
    game = deal_game(player_cards: [card("7"), card("8")], dealer_cards: [card("K"), card("6")])
    assert_equal 10, game.upcard_value
  end

  test "shows full dealer score when card is revealed" do
    game = deal_game(player_cards: [card("7"), card("8")], dealer_cards: [card("K"), card("6")])
    game.update!(round_phase: "finished")
    assert_equal 16, game.upcard_value
  end


  # ── player_hit ───────────────────────────────────────────────────────────────

  test "adds a card to player hand on hit" do
    game = deal_game(player_cards: [card("7"), card("8")], dealer_cards: [card("K"), card("6")])
    game.player_hit
    assert_equal 3, game.player_hand.length
  end

  test "game finishes with dealer_wins when player busts" do
    game = deal_game(player_cards: [card("9"), card("8")], dealer_cards: [card("K"), card("6")])
    # Next card from stub shoe will push score over 21
    game.update!(shoe: [card("9")])
    game.player_hit
    assert game.finished?
    assert game.outcome_dealer_wins?
  end

  test "balance unchanged when player busts" do
    game = deal_game(player_cards: [card("9"), card("8")], dealer_cards: [card("K"), card("6")], bet: 100)
    game.update!(shoe: [card("9")])
    game.player_hit
    assert_equal 900, game.bankroll
  end


  # ── no_more (stand) ──────────────────────────────────────────────────────────

  test "game finishes after player stands" do
    game = deal_game(player_cards: [card("K"), card("9")], dealer_cards: [card("K"), card("8")])
    game.no_more
    assert game.finished?
  end

  test "dealer draws until reaching 17 or above" do
    game = deal_game(
      player_cards: [card("K"), card("9")],
      dealer_cards: [card("5"), card("6")],  # 11 — must draw
      bet: 100
    )
    game.update!(shoe: [card("7")])  # dealer hits to 18
    game.no_more
    assert game.dealer_score >= 17
  end


  # ── Outcomes & payout ────────────────────────────────────────────────────────

  test "player blackjack pays 3:2" do
    game = deal_game(
      player_cards: [card("A"), card("K")],
      dealer_cards: [card("5"), card("7")],
      bet: 100
    )
    game.no_more
    assert game.outcome_player_blackjack?
    # Started with 1000, bet 100 (balance 900), blackjack pays 2.5x wager = +250
    assert_equal 1150, game.bankroll
  end

  test "player win pays 1:1" do
    game = deal_game(
      player_cards: [card("K"), card("9")],  # 19
      dealer_cards: [card("K"), card("7")],  # 17
      bet: 100
    )
    game.update!(shoe: [])
    game.no_more
    assert game.outcome_player_wins?
    assert_equal 1100, game.bankroll
  end

  test "dealer win returns no payout" do
    game = deal_game(
      player_cards: [card("K"), card("7")],  # 17
      dealer_cards: [card("K"), card("9")],  # 19
      bet: 100
    )
    game.update!(shoe: [])
    game.no_more
    assert game.outcome_dealer_wins?
    assert_equal 900, game.bankroll
  end

  test "push returns the bet" do
    game = deal_game(
      player_cards: [card("K"), card("9")],  # 19
      dealer_cards: [card("K"), card("9")],  # 19
      bet: 100
    )
    game.update!(shoe: [])
    game.no_more
    assert game.outcome_push?
    assert_equal 1000, game.bankroll
  end

  test "dealer blackjack beats player" do
    game = deal_game(
      player_cards: [card("K"), card("9")],  # 19
      dealer_cards: [card("A"), card("K")],  # blackjack
      bet: 100
    )
    game.no_more
    assert game.outcome_dealer_blackjack?
    assert_equal 900, game.bankroll
  end

  test "both blackjack is a push" do
    game = deal_game(
      player_cards: [card("A"), card("K")],
      dealer_cards: [card("A"), card("Q")],
      bet: 100
    )
    game.no_more
    assert game.outcome_push?
    assert_equal 1000, game.bankroll
  end

  test "player wins when dealer busts" do
    game = deal_game(
      player_cards: [card("K"), card("8")],  # 18
      dealer_cards: [card("K"), card("6")],  # 16 — must hit
      bet: 100
    )
    game.update!(shoe: [card("K")])  # dealer busts at 26
    game.no_more
    assert game.outcome_player_wins?
    assert_equal 1100, game.bankroll
  end
end
