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

	end
public
	def initialize filename
		@filename = filename
		@filename_without_extension = File.basename(@filename, File.extname(@filename))
	end

	# generate waveform png
	def generate filename

	end
end