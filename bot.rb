#!/usr/bin/env ruby
require 'bundler'
Bundler.require

require 'time'
require 'pp'
require 'dedupe'

Trello.configure do |config|
  config.developer_public_key = ENV['TRELLO_OAUTH_PUBLIC_KEY']
  config.member_token = ENV['TRELLO_TOKEN']
end

class Bot

  def self.run

    hipchat = HipChat::Client.new(ENV["HIPCHAT_API_TOKEN"])

    dedupe = Dedupe.new

    hipchat_rooms = ENV["HIPCHAT_ROOM"].split(',')
    boards = ENV["TRELLO_BOARD"].split(',').each_with_index.map {|board, i| [Trello::Board.find(board), hipchat_rooms[i]] }
    now = Time.now.utc
    timestamps = {}

    boards.each do |board_with_room|
      timestamps[board_with_room.first.id] = now
    end

    scheduler = Rufus::Scheduler.new

    scheduler.every '5s' do
      puts "Querying Trello at #{Time.now.to_s}"
      boards.each do |board_with_room|
        board = board_with_room.first
        hipchat_room = hipchat[board_with_room.last]
        last_timestamp = timestamps[board.id]
        actions = board.actions(:filter => :all, :since => last_timestamp.iso8601)
        actions.each do |action|
          if last_timestamp < action.date
            board_link = "<a href='https://trello.com/board/#{action.data['board']['id']}'>#{action.data['board']['name']}</a>"
            card_link = "#{board_link} : <a href='https://trello.com/card/#{action.data['board']['id']}/#{action.data['card']['idShort']}'>#{action.data['card']['name']}</a>"
            message = case action.type.to_sym
            when :updateCard
              if action.data['listBefore']
                "#{action.member_creator.full_name} moved #{card_link} from #{action.data['listBefore']['name']} to #{action.data['listAfter']['name']}"
              elsif action.data['card']['closed'] && !action.data['old']['closed']
                "#{action.member_creator.full_name} archived #{card_link}"
              elsif !action.data['card']['closed'] && action.data['old']['closed']
                "#{action.member_creator.full_name} has been put back #{card_link} to the board"
              elsif action.data['old']['name']
                "#{action.member_creator.full_name} renamed \"#{action.data['old']['name']}\" to #{card_link}"
              end

            when :createCard
              "#{action.member_creator.full_name} added #{card_link} to #{action.data['list']['name']}"

            when :moveCardToBoard
              "#{action.member_creator.full_name} moved #{card_link} from the #{action.data['boardSource']['name']} board to #{action.data['board']['name']}"

            when :updateCheckItemStateOnCard
              if action.data["checkItem"]["state"] == 'complete'
                "#{action.member_creator.full_name} checked off \"#{ action.data['checkItem']['name']}\" on #{card_link}"
              else
                "#{action.member_creator.full_name} unchecked \"#{action.data['checkItem']['name']}\" on #{card_link}"
              end

            when :commentCard
              "#{action.member_creator.full_name} commented on #{card_link}: #{action.data['text']}"

            when :deleteCard
              "#{action.member_creator.full_name} deleted card ##{action.data['card']['idShort']}"

            # when :addChecklistToCard
            #   "#{action.member_creator.full_name} added the checklist \"#{action.data['checklist']['name']}\" to #{card_link}"

            # when :removeChecklistFromCard
            #   "#{action.member_creator.full_name} removed the checklist \"#{action.data['checklist']['name']}\" from #{card_link}"

            else
              STDERR.puts action.inspect
              ""
            end

            if dedupe.new? message
              puts "Sending: #{message}"
              hipchat_room.send('Trello', message, :color => :purple)
            else
              puts "Supressing duplicate message: #{message}"
            end
          end
        end
        timestamps[board.id] = actions.first.date if actions.length > 0
      end
    end

    scheduler.join
  end

end

if __FILE__ == $0
  Bot.run
end

