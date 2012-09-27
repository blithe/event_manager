# Dependencies
require "csv"
require 'sunlight'

# Class Definition
class EventManager
	INVALID_ZIPCODE = "00000"
	INVALID_NUMBER = "0000000000"
	Sunlight::Base.api_key = "e179a6973728c4dd3fb1204283aaccb5"


	def initialize(filename)
		puts "EventManager Initialized."
		
		@file = CSV.open(filename, {:headers => true, :header_converters => :symbol})
	end

	def print_names
		@file.each do |line|
			#puts line.inspect
			puts line[:first_name] + " " + line[:last_name]
		end
	end

	def clean_number(original)
		number = original.delete(". ()-")
		if number.nil?
			number = INVALID_NUMBER # If it is nil, it's junk
		end
		if number.length == 10
				# Do nothing
		elsif number.length == 11
			if number.start_with?("1")
				number = number[1..-1]
			else 
				number = INVALID_NUMBER
			end
		else
			number = INVALID_NUMBER
		end
		return number # Send the variable 'number' back to the method that called this method
	end	

	def print_numbers
		@file.each do |line|
			number = clean_number(line[:homephone])
			puts number
		end
	end

	def clean_zipcode(original)
		if original.nil?
			zipcode = INVALID_ZIPCODE # If it is nil, it's junk
		elsif original.length < 5
				while original.length < 5
					original = "0" + original
				end
				zipcode = original	
		else
			zipcode = original
		end
		return zipcode # Send the variable 'zipcode' back to the method that called this method
	end	

	def print_zipcodes
		@file.each do |line|
			zipcode = clean_zipcode(line[:zipcode])
			puts zipcode
		end
	end

	def output_data(filename)
		output = CSV.open(filename, "w")
		@file.each do |line|
			# if this is the first line, output the headers
			if @file.lineno == 2
				output << line.headers
			end	
			line[:homephone] = clean_number(line[:homephone])
			line[:zipcode] = clean_zipcode(line[:zipcode])
			output << line
		end
	end

	def rep_lookup
		20.times do
			line = @file.readline

			representative = "unknown"
			# API lookup goes here
			legislators = Sunlight::Legislator.all_in_zipcode(clean_zipcode(line[:zipcode]))
			names = legislators.collect do |leg|
				first_name = leg.firstname
				first_initial = first_name[0]
				last_name = leg.lastname
				party = leg.party
				title = leg.title
				title + " " + first_initial + ". " + last_name + " (" + party + ")"
			end
			puts "#{line[:last_name]}, #{line[:first_name]}, #{line[:zipcode]}, #{names.join(", ")}"
		end
	end

	def create_form_letters
		letter = File.open("form_letter.html", "r").read
		20.times do
			line = @file.readline

			# Do string substitutions here
			custom_letter = letter.gsub("#first_name", "#{line[:first_name]}")
			custom_letter = custom_letter.gsub("#last_name", "#{line[:last_name]}")
			custom_letter = custom_letter.gsub("#street", "#{line[:street]}")
			custom_letter = custom_letter.gsub("#city", "#{line[:city]}")
			custom_letter = custom_letter.gsub("#state", "#{line[:state]}")
			custom_letter = custom_letter.gsub("#zipcode", "#{line[:zipcode]}")
			filename = "output/thanks_#{line[:last_name]}_#{line[:first_name]}.html"
			output = File.new(filename, "w")
			output.write(custom_letter)
		end
	end

	def rank_times
		hours = Array.new(24){0}
		@file.each do |line|
			# Do the counting here
			hour = line[:regdate].split(" ")[1].split(":")[0]
			hours[hour.to_i] = hours[hour.to_i] + 1
		end
		hours.each_with_index{|counter,hour| puts "#{hour}\t#{counter}"}
	end

	def day_stats
		days = Array.new(7){0}
		@file.each do |line|
			# Do the counting here
			date = Date.strptime(line[:regdate].split(" ")[0], "%m/%d/%y")
			day = date.wday
			days[day.to_i] = days[day.to_i] + 1
		end
		days.each_with_index{|counter,day| puts "#{day}\t#{counter}"}
	end

	def state_stats
		state_data = {}
		@file.each do |line|
			state = line[:state] # Find the state
			if state_data[state].nil? # Does the state's bucket exist in state_data?
				state_data[state] = 1
			else
				state_data[state] = state_data[state] + 1 # If the bucket exists, add 1
			end
		end
		ranks = state_data.sort_by{|state, counter| -counter}.collect{|state, counter| state}
		state_data = state_data.select{|state, counter| state}.sort_by{|state, counter| state unless state.nil?}
		state_data.each do |state, counter|
			puts "#{state}:\t#{counter}\t(#{ranks.index(state) + 1})"
		end

	end		
end


# Script
manager = EventManager.new("event_attendees_clean.csv")
manager.state_stats
#manager.output_data("event_attendees_clean.csv")