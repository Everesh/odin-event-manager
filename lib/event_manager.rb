require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def legislators_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_number(phone_number)
  return nil if phone_number.nil?

  trunked_phone_number = phone_number.scan(/[0-9]/).join('')
  case trunked_phone_number.length
  when 10
    trunked_phone_number
  when 11 && trunked_phone_number[0] == '1'
    trunked_phone_number[1..]
  else
    nil
  end
end

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

reg_time = []
reg_date = []

puts 'Event Manager Initialized!'

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
contents = CSV.open('event_attendees.csv', headers: true, header_converters: :symbol)
contents.each do |row|
  id = row[0]
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  phone_number = clean_phone_number(row[:homephone])

  reg_time.push(Time.strptime(row[:regdate], '%m/%d/%y %H:%M').hour) unless row[:regdate].nil?
  reg_date.push(Date.strptime(row[:regdate], '%m/%d/%y %H:%M').wday) unless row[:regdate].nil?

  legislator_names = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
end

# Sort hours by occurence
reg_time_distribution = reg_time.reduce(Hash.new(0)) do |acc, hour|
  acc[hour] += 1
  acc
end.sort_by { |_key, value| value }.reverse.map { |key, _value| key }
puts "The most common registartion hours were #{reg_time_distribution.first(3).join(', ')}"

# Sort days by occurance
reg_date_distribution = reg_date.reduce(Hash.new(0)) do |acc, hour|
  acc[hour] += 1
  acc
end.sort_by { |_key, value| value }
reg_date_first_3 = reg_date_distribution.reverse.map { |key, _value| key }.first(3).map do |day|
    case day
    when 0
      'Monday'
    when 1
      'Tuesday'
    when 2
      'Wednesday'
    when 3
      'Thursday'
    when 4
      'Friday'
    when 5
      'Saturday'
    when 6
      'Sunday'
    end
  end.join(', ')
puts "The most common registartion days were #{reg_date_first_3}"
