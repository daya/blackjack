class Game < ApplicationRecord
  RANKS = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]
  SUITS = ["♠", "♥", "♦", "♣"]
  SHOE = Game::RANKS.product(Game::SUITS).map { |el| { 'rank' => el.first, 'suit' => el.last } }

  enum :round_phase, {
    betting: "betting",
    finished: "finished",
    player_turn: "player_turn",
    dealer_turn: "dealer_turn" }, default: "betting"

  enum :outcome, {
    dealer_blackjack: "dealer_blackjack",
    dealer_wins: "dealer_wins",
    player_blackjack: "player_blackjack",
    player_wins: "player_wins",
    push: "push" }, prefix: true

  validate :wager_must_be_positive_when_playing
  validates :bankroll, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :wager, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :round_phase, presence: true

  def no_more
    self.round_phase = "dealer_turn"
    save!

    while dealer_hits?
      self.house_hand << draw_card
    end

    settle_round
    save!
  end

  def place_wager(amount)
    raise StandardError, "Cannot place wager at this time" unless betting?
    raise ArgumentError, "Wager must be greater than 0" if amount <= 0
    raise ArgumentError, "Insufficient balance" if amount > bankroll

    self.wager = amount
    self.bankroll -= amount
    save!
  end

  def deal_initial_cards
    build_shoe

    self.player_hand << draw_card
    self.house_hand << draw_card

    self.player_hand << draw_card
    self.house_hand << draw_card

    self.round_phase = "player_turn"
    save!
  end

  def player_hit
    self.player_hand << draw_card

    if player_score > 21
      self.round_phase = "finished"
      self.outcome = "dealer_wins"
      payout
    end

    save!
  end

  def player_score = tally_hand(player_hand)

  def dealer_score = tally_hand(house_hand)

  def upcard_value
    if dealer_hidden_card?
      tally_hand([house_hand.first])
    else
      dealer_score
    end
  end

  def dealer_hidden_card? = betting? || player_turn?

  private

  def build_shoe = self.shoe = SHOE.shuffle

  def draw_card = self.shoe.pop

  def tally_hand(hand)
    return 0 if hand.empty?

    aces, total = hand.partition { |card| card["rank"] == "A" }
                      .then do |ace_cards, others|
      [
        ace_cards.count,
        others.sum { |card| ["K", "Q", "J"].include?(card["rank"]) ? 10 : card["rank"].to_i }
      ]
    end

    total += aces * 11

    aces.times { total -= 10 if total > 21 }

    total
  end

  def dealer_hits? = dealer_score < 17

  def settle_round
    self.round_phase = "finished"
    self.outcome = determine_outcome
    payout
  end

  def determine_outcome
    player_bj = blackjack?(player_hand)
    dealer_bj = blackjack?(house_hand)

    return "push"             if player_bj && dealer_bj
    return "player_blackjack" if player_bj
    return "dealer_blackjack" if dealer_bj
    return "dealer_wins"      if player_score > 21
    return "player_wins"      if dealer_score > 21

    case player_score <=> dealer_score
      when  1 then "player_wins"
      when -1 then "dealer_wins"
      else         "push"
    end
  end

  def payout
    case outcome
    when "player_blackjack"
      self.bankroll += (wager * 2.5).to_i
    when "player_wins"
      self.bankroll += wager * 2
    when "push"
      self.bankroll += wager
    when "dealer_wins", "dealer_blackjack"
      # Wager already deducted, no payout
    end
  end

  def blackjack?(hand)
    return false unless hand.length == 2
    tally_hand(hand) == 21
  end

  def wager_must_be_positive_when_playing
    if !betting? && wager <= 0
      errors.add(:wager, "must be greater than 0 when game is in progress")
    end
  end
end