class BrWaveForm
private
	# Convert audio file to wav for reading
	def convert_to_wav
		# check if file exists?
		if File.exist? @filename
			fork { exec "ffmpeg -y -i \"#{@filename}\" -f wav \"#{@filename_without_extension}.wav\"" }
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
		f = open("#{@filename_without_extension}.wav")
		@format = WavFile::readFormat(f)

		dataChunk = WavFile::readDataChunk(f)
		f.close
		bit = 's*' if @format.bitPerSample == 16 # int16_t
		bit = 'c*' if @format.bitPerSample == 8 # signed char
		wavs = dataChunk.data.unpack(bit) # read binary
	end

	def spectrum_data numberOfBar

		wavs = read_wav

		@spectrum_array = []

		samples = (wavs.length / numberOfBar).to_i
		puts @format
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
	def initialize filename
		@filename = filename
		@filename_without_extension = File.basename(@filename, File.extname(@filename))
	end

	# generate waveform png
	def generate filename, numberOfBar: 100
		data = spectrum_data numberOfBar
		# generate png

		array = array[0..(numberOfBar-1)]
		# clean up files
		puts "[ProcessVideos] cleaning up files #{filename}, #{filename}.wav"
		File.delete(filename + ".wav")
		puts "[ProcessVideos] done cleaning up files"

		max = array.max
		width = numberOfBar * 4 + (numberOfBar - 1) * 2
		png = ChunkyPNG::Image.new(width, 56, ChunkyPNG::Color::TRANSPARENT)
		x = 0
		array.each do |d|
			# drawing 4px bar
			# calc start y
			(1..4).each do |i|
				maxY = ((d / max) * 54).to_i + 1
				y = -1
				until y == maxY
					y += 1
					if y < maxY - 2
						png[x, y] = ChunkyPNG::Color::rgba(255, 255, 255, 255)
					end
					# draw circle
					if y == maxY - 2
						if i == 1 || i == 4
							png[x, y] = ChunkyPNG::Color::rgba(255, 255, 255, 247)
						else
							png[x, y] = ChunkyPNG::Color::rgba(255, 255, 255, 255)
						end
					end
					if y == maxY - 1
						if i == 1 || i == 4
							# transparent level 1
							png[x, y] = ChunkyPNG::Color::rgba(254, 254, 254, 158)
						else
							png[x, y] = ChunkyPNG::Color::rgba(255, 255, 255, 255)
						end
					end
					if y == maxY
						if i == 2 || i == 3
							# transparent level 2
							png[x, y] = ChunkyPNG::Color::rgba(253, 253, 253, 79)
						end
					end
				end
				# move to next column
				x += 1
			end
			# move to next column with spacing
			x += 2
		end
		pngFilename = "waveform-#{youtubeId}-#{Time.now.to_i}.png"
		png.save(pngFilename, :interlace => true)

		puts 
	end
end