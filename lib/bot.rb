# coding: utf-8

require 'recastai'

def bot(payload)
  connect = RecastAI::Connect.new(ENV['REQUEST_TOKEN'], ENV['LANGUAGE'])
  request = RecastAI::Request.new(ENV['REQUEST_TOKEN'])
  connect.handle_message(payload) do |message|
    replies = []
    response = request.converse_text(message.content, conversation_token: message.sender_id)

    if response.intent
      if response.intent.slug == 'summoner-info'
        summoner_name = response.entities.first.raw
        riot_response = get_summoner_info(summoner_name)

        if riot_response.code == 200
          summoner_id = riot_response['id']
          replies = [{ type: 'text', content: "#{summoner_name} is level #{riot_response['summonerLevel']} his id is #{summoner_id}" }]
        else
          replies = [{ type: 'text', content: riot_response['status']['message'] }]
        end

      elsif response.intent.slug == 'yes' && !response.memory.empty?
        summoner_name = response.memory.first.raw
        riot_response = get_summoner_info(summoner_name)
        summoner_id = riot_response['id']
        riot_response = get_active_game(summoner_id)
        if riot_response.code == 200
          replies = [{ type: 'text', content: '%{summoner_name} is currently playing' % { summoner_name: summoner_name } }]
        else
          replies = [{ type: 'text', content: '%{summoner_name} is not playing for now' % { summoner_name: summoner_name } }]
        end
      end
    end

    response.replies.map do |r|
      replies.push({ type: 'text', content: r })
    end

    replies.each do |rep|
      connect.send_message([rep], message.conversation_id)
    end
  end

  200
end

def get_summoner_info(user_name)
  path = URI.escape('https://euw1.api.riotgames.com/lol/summoner/v3/summoners/by-name/%{user_name}' % { user_name: user_name })
  HTTParty.get(
      path,
      headers: { 'X-Riot-Token': ENV['RIOT_TOKEN'] }
  )
end

def get_active_game(user_id)
  path = URI.escape('https://euw1.api.riotgames.com/lol/spectator/v3/active-games/by-summoner/%{user_id}' % { user_id: user_id })
  HTTParty.get(
      path,
      headers: { 'X-Riot-Token': ENV['RIOT_TOKEN'] }
  )
end