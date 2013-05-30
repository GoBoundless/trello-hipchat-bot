require './app'

map "/" do
  run App
end

$stdout.sync = true