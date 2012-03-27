class CreateHighscores < ActiveRecord::Migration
  def change
    create_table :highscores do |t|
      t.string :level
      t.integer :moves
      t.timestamp :date

      t.timestamps
    end
  end
end
