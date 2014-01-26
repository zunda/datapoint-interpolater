#!/usr/bin/ruby
# usage: ruby process_test.rb
# Run test cases for process.rb
require 'test/unit'

$:.unshift(File.expand_path(File.dirname(__FILE__)))
require 'process'

class TestGridScanner < Test::Unit::TestCase
	def test_scan_2d
		target = [[-1,-1],[0,-1],[1,-1],[-1,0],[0,0],[1,0],[-1,1],[0,1],[1,1]]
		result = Array.new
		GridScanner.new(2).scan do |delta|
			result << delta
		end
		assert_equal(target.size, result.size)
		assert_equal(target.sort, result.sort)
	end
end

