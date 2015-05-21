require "csv"

class Property
	attr_accessor :rooms, :area, :type

	def initialize(options = {})
		options = {
			rooms: 1,
			area: 500,
			type: false
		}.merge(options)

		@rooms = options[:rooms]
		@area = options[:area]
		@type = options[:type]

		@neighbors = []
		@distance = nil
		@guess = nil
	end

	def neighbors
		@neighbors
	end

	def neighbors=(properties)
		if properties.is_a? Array
			properties.each do |property|
				@neighbors << property.dup
			end
		else
			@neighbors << properties.dup
		end
	end

	def distance
		@distance
	end

	def distance=(dist)
		@distance = dist
	end

	def calculate_neighbor_distances(room_range, area_range)
		@neighbors.each do |neighbor|
			rooms_delta = neighbor.rooms - self.rooms
			area_delta = neighbor.area - self.area
			rooms_delta = rooms_delta / room_range.to_f
			area_delta = area_delta / area_range.to_f

			neighbor.distance = Math.sqrt(rooms_delta*rooms_delta + area_delta*area_delta)
		end
	end
	
	def sort_neigbors_by_distance
		@neighbors.sort { |a, b| a.distance <=> b.distance }
	end

	def guess_type(k)
		guess_hash = gen_guess_hash(self.sort_neigbors_by_distance.take(k))
		@guess = assign_guess(guess_hash)

		msg = %Q{ 

			Property attrs => rooms: #{ @rooms }, area: #{ @area }
			The property type is guessed to be: #{ @guess }
	
		}	

		puts msg

		return @guess
	end

	def gen_guess_hash(properties)
		guess_hash = Hash.new(0)
		
		properties.each do |property|
			guess_hash[property.type] += 1
		end

		return guess_hash
	end

	def assign_guess(guess_hash)
		highest = 0
		guess = ""

		guess_hash.each do |key, value|
			if value > highest
				highest = value
				guess = key
			end
		end

		return guess
	end
end

class Orchestrator
	def initialize(k)
		@property_list = []
		@k = k
		@rooms = { max: 0, min: 10000, range: 0 }
		@area = { max: 0, min: 10000, range: 0 }
	end

	def property_list
		@property_list
	end

	def k
		@k
	end

	def add(property)
		@property_list << property
	end

	def scale_features
		rooms_array = self.filter_knowns.map { |property| property.rooms }
		area_array = self.filter_knowns.map { |property| property.area }

		@rooms[:min] = rooms_array.min
		@rooms[:max] = rooms_array.max
		@rooms[:range] = rooms_array.max - rooms_array.min
		@area[:min] = area_array.min
		@area[:max] = area_array.max
		@area[:range] = area_array.max - area_array.min
	end

	def rooms
		@rooms
	end

	def area
		@area
	end

	def filter_unknowns
		property_list.select { |property| property.type == false }
	end

	def filter_knowns
		property_list.select { |property| property.type }
	end

	def load_training_data
		file = CSV.read("data.csv", { headers: true })

		file.each do |line|
			property = Property.new({ rooms: line["rooms"].to_i, area: line["area"].to_i, type: line["type"]})

			add(property)
		end
	end

	def determine_unknowns
		self.filter_unknowns.each do |property|
			property.neighbors = self.filter_knowns
			
			property.calculate_neighbor_distances(self.rooms[:range], self.area[:range])

			property.guess_type(self.k)
		end
	end
end

property_list = Orchestrator.new(3)
property_list.load_training_data
property_list.scale_features
property_list.add( Property.new({ rooms: 2, area: 1550, type: false }) )
property_list.add( Property.new({ rooms: 4, area: 1750, type: false }) )
property_list.determine_unknowns
