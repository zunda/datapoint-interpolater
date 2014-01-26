#!/usr/bin/ruby

class DataPoint
	attr_reader :location
	attr_reader :data

	# accepts Arrays of location and data
	def initialize(location, data)
		@location = location
		@data = data
	end

	def distance_sq_to(p)
		return @location.zip(p).map{|x| (x[0] - x[1])**2}.inject(0.0, :+)
	end
end

# Set of DataPoints
class DataSet < Array
	attr_reader :env_min
	attr_reader :env_max
	attr_reader :grid_size

	def <<(datapoint)
		super
		@env_min ||= Array.new(datapoint.location.size, 0.0)
		@env_max ||= Array.new(datapoint.location.size, 0.0)
		0.upto(datapoint.location.size - 1) do |i|
			env_min[i] = datapoint.location[i] if datapoint.location[i] < env_min[i]
			env_max[i] = datapoint.location[i] if datapoint.location[i] > env_max[i]
		end
	end

	# Create index to quickly find data near a location
	def index!(division = 10)
		@grid_division = division
		@grid_size = env_max.zip(env_min).map{|x| (x[0] - x[1]).abs}.max / division
		@db = Hash.new
		self.each do |e|
			h = self.hash(e.location)
			@db[h] ||= Array.new
			@db[h] << e
		end
		return self
	end

	# Hash function for indexing data
	def hash(p)
		p.map{|x| (x/@grid_size).round.to_i}
	end

	# Find datapoints around location p
	def around(p)
		result = Array.new
		origin = hash(p)
		GridScanner.new(origin.size).scan do |delta|
			h = origin.zip(delta).map{|x| x[0] + x[1]}
			result += @db[h] if @db[h]
		end
		return result
	end

	# Find and sort datapoints near location p
	def near_to(p)
		return around(p).sort_by{|e| e.distance_sq_to(p)}
	end

	# Interpolate data around location p
	def interpolate_at(p)
		n = near_to(p)[0..1]
		return nil if n.size < 1

		# Check if we have a datapoint at the desired location
		if n[0].distance_sq_to(p) < 1e-10
			return n[0].data
		end

		# Weighed average of each element of data with weight as 1/distance^2
		w = n.map{|x| 1.0/x.distance_sq_to(p)}
		w_sum = w.inject(0.0){|sum, wi| sum += wi}
		weighed_data = n.zip(w).map{|e, wi| e.data.map{|x| x * wi / w_sum}}
		average = weighed_data.transpose.map{|x| x.inject(0.0, :+)}
		return average
	end
end

class GridScanner
	def initialize(dimension)
		@delta = Array.new(dimension, -1)
	end

	def scan(&block)
		_next(0, &block)
	end

	def _next(dim, &block)
		return if @delta.size <= dim
		yield(@delta)
		@delta[dim] += 1
		if @delta[dim] > 1
			@delta[dim] = -1
			_next(dim + 1, &block)
		else
			_next(dim, &block)
		end
	end
end

# Read data from stdinput or as specified in command line option
x_i = 0	# index of positoin x
b_i = 8	# index of data vector x
src = DataSet.new
ARGF.each do |line|
	next if /^#/ =~ line
	data = line.strip.split(',').map{|e| e.to_f}
	loc = [data[x_i], data[x_i+1], data[x_i+2]]
	data = [data[b_i], data[b_i+1], data[b_i+2]]
	p = DataPoint.new(loc, data)
	src << p
end
src.index!(20)

# Show data on xz plane
step = 0.1
half_width = 3
n = (half_width / step).ceil
y = 0.0
(-n).upto(n) do |zi|
	(-n).upto(n) do |xi|
		x = xi*step
		z = zi*step
		p = [x, y, z]
		data = src.interpolate_at(p)
		puts "#{p.join(',')},#{data ? data.join(',') : '*,*,*'}"
	end
end

