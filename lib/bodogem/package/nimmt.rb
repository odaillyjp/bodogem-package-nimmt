require "bodogem/package/nimmt/version"

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

      class Mapping
        def initialize
          super

          draw "#{Nimmt.title}をおわる" do
            Bodogem.application.exit_package
          end
        end
      end

      class Game
        def initialize
          @players = []
          @players << Player.new('あなた')
          @routes = Mapping.new
        end

        def start
          setup
        end

        def setup
          Bodogem.client.puts "何人で遊ぶか教えてください。\n例えば、5人ならば「5人で遊ぶ」と発言してください。"
          coms_count = Bodogem.client.input(format: /\A(\d+)人で遊ぶ\z/)[1].to_i - 1
          coms_count.times { |num| ComputerPlayer.new("コンピュータ#{num}") }
        end
      end

      class Player
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
      end

      class ComputerPlayer < Player
      end
    end
  end
end
