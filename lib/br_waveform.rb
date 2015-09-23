module WavSpectrum
	def self.read(filename, numberOfBar)
		numberOfBar ||= 97

		f = File.open(filename)
		f.binmode
		f.seek(0)
		header = f.read(12)
		riff = header.slice(0,4)
		data_size = header.slice(4,4).unpack('V')[0].to_i
		wave = header.slice(8,4)
		raise(WavFormatError) if riff != 'RIFF' or wave != 'WAVE'
		@name = f.read(4)
		@size = f.read(4).unpack("V")[0].to_i
		# read format data
		formatData = f.read(16)
		@id = formatData.slice(0,2).unpack('c')[0]
		@channel = formatData.slice(2,2).unpack('c')[0]
		@hz = formatData.slice(4,4).unpack('V').join.to_i
		@bytePerSec = formatData.slice(8,4).unpack('V').join.to_i
		@blockSize = formatData.slice(12,2).unpack('c')[0]
		@bitPerSample = formatData.slice(14,2).unpack('c')[0]
		# seek back
		@samples = 0
		bars = []
		currentBar = 0.0
		index = 0
		bit = 's*' if @bitPerSample == 16 # int16_t
		bit = 'c*' if @bitPerSample == 8 # signed char
		data = false
		while !f.eof?
			if !data
				@name = f.read(4)
				@size = f.read(4).unpack("V")[0].to_i
			end
			if @name == "data" || data
				data = true
				# calc sample
				if @samples == 0
					@samples = (@size / numberOfBar).to_i
					puts @samples
				end
				if index < @samples
					@data = f.read(2)
					unless @data.nil?
						arr = @data.unpack(bit)
						arr.each do |v|
							currentBar += v.abs
						end
						index += 2
					end
				else
					bars.push(currentBar / (@samples / 2))
					currentBar = 0.0
					index = 0
				end
			else
				f.seek(@size, IO::SEEK_CUR)
			end
		end

        max = bars.max
        bars.map { |v| v /= max }
	end
end

class BrWaveForm
private
	# Convert audio file to wav for reading
	def convert_to_wav
		# check if file exists?
		if File.exist? @filename
			puts "BrWaveForm: Converting #{@filename} to #{@filename_without_extension}.wav" if @debug
			`ffmpeg -y -i "#{@filename}" -f wav "#{@filename_without_extension}.wav" -hide_banner -loglevel quiet`
			File.delete(@filename)
		else
			raise IOError, "File #{@filename} not found"
		end
	end

	def spectrum_data numberOfBar

		puts "BrWaveForm: Processing waveform" if @debug

		@spectrum_array = WavSpectrum.read("#{@filename_without_extension}.wav", numberOfBar)

		# clean up wav
		File.delete("#{@filename_without_extension}.wav")

		@spectrum_array
	end
public
	@debug = false

	def initialize filename
		@filename = filename
		@filename_without_extension = File.basename(@filename, File.extname(@filename))
	end

	# generate waveform png
	def generate filename, height: 60, numberOfBar: 100, barWidth: 4, spacing: 2, flip: false

		if barWidth < 1
			raise ArgumentError, "barWidth must be larger than 0"
		end

		if spacing < 1
			raise ArgumentError, "spacing must be larger than 0"
		end

		waveform_array = spectrum_data numberOfBar

		# generate png
		puts "BrWaveForm: Generating #{filename}" if @debug
		waveform_array = waveform_array[0..(numberOfBar-1)]

		gem 'chunky_png'
		require 'chunky_png'

		max = waveform_array.max
		width = numberOfBar * 4 + (numberOfBar - 1) * 2
		png = ChunkyPNG::Image.new(width, height, ChunkyPNG::Color::TRANSPARENT)
		x = 0
		puts
		waveform_array.each do |d|
			# drawing 4px bar
			# calc start y
			(1..barWidth).each do |i|
				maxY = ((d / max) * height - 2).to_i + 1
				maxY = ((1 - d / max) * height - 2).to_i + 1 if !flip
				y = -1
				y = maxY if !flip
				stopY = maxY
				stopY = height - 1 if !flip
				until y == stopY
					# puts "#{x},#{y}"
					y += 1

					puts "Y: #{y}, MaxY: #{maxY}, StopY: #{stopY}"

					# if y < stopY - 2 && flip || y > maxY + 2 && !flip
					png[x, y] = ChunkyPNG::Color::rgba(255, 255, 255, 255)
					# end
					# draw circle
					# if y == stopY - 2 && flip || y == maxY + 3 && !flip
					# 	if i == 1 || i == 4
					# 		png[x, y] = ChunkyPNG::Color::rgba(255, 255, 255, 247)
					# 	else
					# 		png[x, y] = ChunkyPNG::Color::rgba(255, 255, 255, 255)
					# 	end
					# end
					# if y == stopY - 1 && flip || y == maxY + 2 && !flip
					# 	if i == 1 || i == 4
					# 		# transparent level 1
					# 		png[x, y] = ChunkyPNG::Color::rgba(254, 254, 254, 158)
					# 	else
					# 		png[x, y] = ChunkyPNG::Color::rgba(255, 255, 255, 255)
					# 	end
					# end
					# if y == stopY && flip || y == maxY + 1 && !flip
					# 	if i == 2 || i == 3
					# 		# transparent level 2
					# 		png[x, y] = ChunkyPNG::Color::rgba(253, 253, 253, 79)
					# 	end
					# end
				end
				# move to next column
				x += 1
			end
			# move to next column with spacing
			x += spacing
		end
		png.save(filename, :interlace => true)

		puts "BrWaveForm: PNG generated #{filename}"
	end
end