class CreateGames < ActiveRecord::Migration[8.0]
  def change
    create_table :games do |t|
      t.json :shoe, default: []
      t.json :hole_cards, default: []
      t.json :house_hand, default: []
      t.integer :bankroll, default: 1000, null: false
      t.integer :wager, default: 0, null: false
      t.string :round_phase, default: "betting", null: false
      t.string :outcome

      t.timestamps
    end
  end
end