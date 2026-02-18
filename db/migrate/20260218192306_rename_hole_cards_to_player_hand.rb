class RenameHoleCardsToPlayerHand < ActiveRecord::Migration[8.0]
  def change
    rename_column :games, :hole_cards, :player_hand
  end
end