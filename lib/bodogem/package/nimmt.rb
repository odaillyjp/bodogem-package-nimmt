require "bodogem/package/nimmt/version"

class Numeric
  def repdigit?
    (self >= 10) && (self.to_s.chars.uniq.size == 1)
  end
end

module Bodogem
  module Package
    module Nimmt
      class << self
        def title
          'ニムト'
        end

        def routes
          Mapping.new
        end

        def start
          Game.new.start
        end
      end

      class Mapping < Application::Router::Mapping
        def initialize
          super

          draw "#{Nimmt.title}をおわる" do
            Thread.exit
          end
        end
      end

      class Game
        def initialize
          @players = []
          @players << Player.new('あなた')
          @routes = Mapping.new
          @rows = Row.all
        end

        def start
          setup_players
          setup_cards
          show_player_cards
          show_rows

          10.times do
            # TODO
          end
        end

        private

        def setup_players
          Bodogem.application.client.puts "何人で遊ぶか教えてください。\n例えば、5人ならば「5人で遊ぶ」と発言してください。"
          coms_count = Bodogem.application.client.input(format: /\A(\d+)人で遊ぶ\z/)[1].to_i - 1
          coms_count.times { |num| @players << ComputerPlayer.new("コンピュータ#{num}") }
          Bodogem.application.client.puts "#{@players.size}人で遊ぶのですね。"
        end

        def setup_cards
          Bodogem.application.client.puts 'カードを配ります...'
          cards = Card.all.shuffle
          @players.each { |player| player.set_hand_cards(cards.shift(10)) }
          @rows.each { |row| row.set_card(cards.shift) }
        end

        def show_player_cards
          @players.select(&:human?).each do |player|
            Bodogem.application.client.puts "#{player.name}の状態はこのようになっています。"
            Bodogem.application.client.puts "```\n#{player.inspect}\n```"
          end
        end

        def show_rows
          Bodogem.application.client.puts '場札はこのようになっています。'
          Bodogem.application.client.puts "```\n#{@rows.map(&:inspect).join("\n")}\n```"
        end
      end

      class Player
        attr_reader :name

        def initialize(name)
          @hand_cards = []
          @took_cards = []
          @name = name
        end

        def set_hand_cards(cards)
          cards.each { |card| card.owner = self }
          @hand_cards.concat(cards)
          @hand_cards.sort!
        end

        def has_card?(number)
          @hand_cards.any? { |card| card.number == number }
        end

        def take_cards(cards)
          @took_cards.concat(cards)
        end

        def choice_play_card
        end

        def inspect
          "手札: #{@hand_cards.map(&:number).join(' ')}\n失点: #{penalty_point}"
        end

        def human?
          true
        end

        def penalty_point
          @took_cards.map(&:penalty_point).inject(0, :+)
        end
      end

      class ComputerPlayer < Player
        def human?
          false
        end
      end

      class Card
        attr_reader   :number, :penalty_point
        attr_accessor :owner

        include Comparable

        def self.all
          (1..104).map { |number| Card.new(number) }
        end

        def initialize(number)
          @number = number
          @penalty_point = calc_penalty_point
          @owner = nil
        end

        def <=>(other)
          number <=> other.number
        end

        private

        def calc_penalty_point
          case
          when number == 55     then 7
          when number.repdigit? then 5
          when number % 10 == 0 then 3
          when number % 5 == 0  then 2
          else 1
          end
        end
      end

      class Row
        attr_reader :idx

        def self.all
          4.times.each_with_object([]) do |idx, ary|
            ary << Row.new(idx + 1)
          end
        end

        def initialize(idx)
          @cards = []
          @idx   = idx
        end

        def set_card(card)
          @cards.push(card)
        end

        def has_card?(card)
          @cards.any? { |c| c == card }
        end

        def clear
          @cards.clear
        end

        def penalty_point
          @cards.map(&:penalty_point).inject(0, :+)
        end

        def inspect
          "#{idx}列目 (失点#{penalty_point}): #{@cards.map(&:number).join(' ')}"
        end
      end
    end
  end

  Bodogem.application.packages << Bodogem::Package::Nimmt
end
