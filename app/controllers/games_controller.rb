class GamesController < ApplicationController
  before_action :find_game, only: [:hit, :no_more, :show]

  def new = @balance = resolve_balance

  def create
    @game = Game.new(bankroll: resolve_balance)

    begin
      @game.place_wager(params[:bet].to_i)
      @game.deal_initial_cards
      redirect_to game_path(@game)
    rescue ArgumentError, StandardError => e
      @balance = @game.bankroll
      flash.now[:alert] = e.message
      render :new, status: :unprocessable_entity
    end
  end

  def hit = @game.player_hit.then { redirect_to game_path(@game) }

  def no_more = @game.no_more.then { redirect_to game_path(@game) }

  private

  def resolve_balance
    return 1000 if params[:new_game]

    last_finished_game = Game.where(round_phase: "finished").order(created_at: :desc).first
    balance = last_finished_game&.bankroll || 1000
    balance > 0 ? balance : 1000
  end

  def find_game = @game = Game.find(params[:id])
end
