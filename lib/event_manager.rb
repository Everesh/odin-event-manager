puts 'Event Manager Initialized!'

lines = File.readlines('event_attendees.csv')
lines.each.with_index do |line, index|
  next if index.zero?

  columns = line.split(',')
  name = columns[2]
  p name
end
