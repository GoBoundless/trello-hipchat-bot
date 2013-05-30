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
    hipchat_room = hipchat[ENV['HIPCHAT_ROOM']]

    board = Trello::Board.find(ENV["TRELLO_BOARD"])

    scheduler = Rufus::Scheduler.start_new

    last_timestamp = Time.now.utc

    dedupe = Dedupe.new

    scheduler.every '5s' do
      puts "Querying Trello at #{Time.now.to_s}"
      actions = board.actions(:filter => :all, :since => last_timestamp.iso8601)
      actions.each do |action|
        if last_timestamp < action.date
          card_link = "<a href='https://trello.com/card/#{action.data['board']['id']}/#{action.data['card']['idShort']}'>#{action.data['card']['name']}</a>"
          message = case action.type.to_sym
          when :updateCard
            if action.data['listBefore']
              "#{action.member_creator.full_name} moved #{card_link} from #{action.data['listBefore']['name']} to #{action.data['listAfter']['name']}"
            end

          when :createCard
            "#{action.member_creator.full_name} added #{card_link} to #{action.data['list']['name']}"

          when :moveCardToBoard
            "#{action.member_creator.full_name} moved #{card_link} from the #{action.data['boardSource']['name']} board to #{action.data['board']['name']}"

          when :updateCheckItemStateOnCard
            if action.data["checkItem"]["state"] == 'complete'
              "#{action.member_creator.full_name} checked off \"#{ action.data['checkItem']['name']}\" on #{card_link}"
            else
              "#{action.member_creator.full_name} added \"#{action.data['checkItem']['name']}\" to #{card_link}"
            end

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
      last_timestamp = actions.first.date if actions.length > 0
    end

    scheduler.join
  end

end

if __FILE__ == $0
  Bot.run
end

