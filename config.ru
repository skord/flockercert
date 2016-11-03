require './app.rb'
$stdout.sync = true
puts "------------------------------------------------------------------------------------------------"
puts "Use this auth token to get at your creds: #{AUTH_TOKEN}"
puts "------------------------------------------------------------------------------------------------"
run Sinatra::Application
