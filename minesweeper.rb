require 'yaml'

class Game
  attr_accessor :game_board

  def initialize
    @game_board = Board.new.rows

    (0..8).each do |row_index|
      (0..8).each do |col_index|
        tile = @game_board[row_index][col_index]
        tile.build_neighbors(@game_board)
      end
    end

  end

  def render_board
    rendered_board = Array.new(9) { Array.new(9) }

    (0..8).map do |row_index|
      (0..8).each do |col_index|
        tile = @game_board[row_index][col_index]
        rendered_tile = "*"
        if tile.fringe? && tile.revealed?
          rendered_tile = tile.neighbor_bomb_count.to_s
        elsif tile.revealed? && tile.bombed?
          rendered_tile = "B"
        elsif tile.flagged?
          rendered_tile = "F"
        elsif tile.revealed?
          rendered_tile = "_"
        end
        rendered_board[row_index][col_index] = rendered_tile
      end
    end
    puts "    0    1    2    3    4    5    6    7    8 "
    rendered_board.each_with_index do |row, index|
      print "#{index} "
      p row
    end
  end

  def reveal_all
    @game_board.each do |row|
      row.each do |element|
        element.revealed = true
        element.flagged = false
      end
    end
  end


  def play
    puts "Welcome to Minesweeper. Good luck!"
    # puts "Would you like to play a new game (n) or load a game (l)?"
    # play_load = gets.chomp.downcase
    #
    # if play_load == "l"
    #   puts "Type a filename to load:"
    #   filename = gets.chomp
    #   old_game = YAML::load
    # end

    until win?

      render_board
      puts "Choose a tile, separating row and column by a space: "
      user_pos_choice = gets.chomp.split(" ").map {|coord| coord.to_i}
      p user_pos_choice
      user_row, user_col = user_pos_choice[0], user_pos_choice[1]
      user_tile = @game_board[user_row][user_col]
      puts "Choose to reveal (r) or flag (f) this tile:"
      move_type = gets.chomp.downcase

      p "Revealed: #{user_tile.revealed?}"
      p "Bombed: #{user_tile.bombed?}"
      p "Flagged: #{user_tile.flagged?}"
      p "Fringe: #{user_tile.fringe?}"

      if move_type == "r"
        if user_tile.bombed?
          puts "You stepped on a bomb! Game over!"
          reveal_all
          render_board
          exit
        elsif user_tile.flagged?
          puts "You've flagged this tile."
          next
        elsif user_tile.revealed?
          puts "You've already revealed this tile."
          next
        else
          user_tile.reveal_tile
        end
      else #move_type is flag
        if user_tile.flagged?
          user_tile.flagged = false
        else
          user_tile.flagged = true
        end
      end
    end

    reveal_all
    render_board
    puts "You won!"

  end

  def num_revealed
    count = 0
    (0..8).each do |row_index|
      (0..8).each do |col_index|
        tile = @game_board[row_index][col_index]
        count += 1 if tile.revealed?
      end
    end
    puts count
    count
  end

  def win?
    self.num_revealed == 71
  end

end

class Tile

  attr_accessor :flagged, :revealed, :position, :neighbors, :fringe

  def initialize(position, bombed = false)
    @bombed = bombed
    @flagged = false
    @revealed = false
    @fringe = false
    @position = position
    @neighbors = []

  end

  def bombed?
    @bombed
  end

  def flagged?
    @flagged
  end

  def revealed?
    @revealed
  end

  def edge_tile?
    return true if position[0] == 0 || position[0] == 8
    return true if position[1] == 0 || position[1] == 8
    false
  end

  def fringe?
    @fringe = true if neighbor_bomb_count > 0
    @fringe
  end

  NEIGHBORS = [
    [1, -1],
    [1, 0],
    [1, 1],
    [0, -1],
    [0, 1],
    [-1, -1],
    [-1, 0],
    [-1, 1]
  ]

  def build_neighbors(board)
    cur_row = position[0]
    cur_col = position[1]
    NEIGHBORS.each do |(dx, dy)|
      neighbor_pos = [cur_row + dx, cur_col + dy]

      if neighbor_pos.all? { |coord| coord.between?(0, 8) }
        @neighbors << board[neighbor_pos[0]][neighbor_pos[1]]
      end
    end
  end

  def show_neighbors
    self.neighbors
  end

  def neighbor_bomb_count
    neighbor_bombs = 0
    @neighbors.each do |neighbor|
      neighbor_bombs += 1 if neighbor.bombed?
    end
    neighbor_bombs
  end

  def reveal_tile
    return if self.bombed? || self.flagged?
    self.revealed = true
    if !self.fringe?
      self.neighbors.each do |neighbor|
        #p neighbor.position
        neighbor.reveal_tile unless neighbor.bombed? || neighbor.flagged? || neighbor.revealed?
      end
    else
      return
    end
  end

end

class Board

  attr_accessor :rows

  def initialize
    @rows = Array.new(9) { Array.new(9) }

    seed_board
  end

  def seed_board
    random_bomb_positions = bomb_positions

    (0..8).each do |row_index|
      (0..8).each do |col_index|
        position = [row_index, col_index]
        if random_bomb_positions.include?(position)
          @rows[row_index][col_index] = Tile.new(position, true)
        else
          @rows[row_index][col_index] = Tile.new(position)
        end
      end
    end
  end

  def show_rows
    game_board = @rows.map do |row|
      row.map do |element|
        element.position
      end
    end

    game_board.each do |row|
      p row
    end
  end

  def bomb_positions
    bomb_positions = []

    while bomb_positions.length < 10
      random_row = rand(9)
      random_col = rand(9)
      random_pos = [random_row, random_col]

      bomb_positions << random_pos unless bomb_positions.include?(random_pos)
    end

    p bomb_positions
    bomb_positions
  end

end

g = Game.new
tile = Tile.new([3, 3])

g.play
