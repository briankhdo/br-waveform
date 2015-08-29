class BrWaveForm
private
	# Convert audio file to wav for reading
	def convert_to_wav
		# check if file exists?
		if File.exist? @filename
			`ffmpeg -y -i "#{@filename}" -f wav "#{@filename_without_extension}.wav"`
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
		puts data
		# generate png
	end
end