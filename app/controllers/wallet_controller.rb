# frozen_string_literal: true
class WalletController < ApplicationController
  def show
    last_game = Game.where(round_phase: "finished").order(created_at: :desc).first
    @balance = last_game&.bankroll || 1000
    @balance = 1000 if @balance <= 0
  end
end
