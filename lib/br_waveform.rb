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

	# read wave file
	def read_wav

		convert_to_wav

		gem 'wav-file'
		require 'wav-file'

		# read wavefile
		puts "BrWaveForm: Processing #{@filename_without_extension}.wav" if @debug
		f = open("#{@filename_without_extension}.wav")
		@format = WavFile::readFormat(f)

		dataChunk = WavFile::readDataChunk(f)
		f.close
		bit = 's*' if @format.bitPerSample == 16 # int16_t
		bit = 'c*' if @format.bitPerSample == 8 # signed char
		wavs = dataChunk.data.unpack(bit) # read binary
	end

	def spectrum_data numberOfBar

		puts "BrWaveForm: Processing waveform" if @debug
		wavs = read_wav

		@spectrum_array = []

		samples = (wavs.length / numberOfBar).to_i

		i = 0
		until i > wavs.length
			istart = i
			iend = i + samples
			pos = []
			wavs[istart..iend].each do |v|
				pos.push(v.abs)
			end
			avg = 0
			unless pos.length == 0
				avg = (pos.inject{ |sum, el| sum + el }.to_f / pos.size.to_f) / 32768.0
			else
				break
			end

			# increase
			avg *= 1.2

			avg = 1 if avg > 1
			@spectrum_array.push(avg)
			i += samples
		end
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