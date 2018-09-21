require "uri"
require "open-uri"
require "nkf"

class String	
	def make_group_by_itag
		#make groupes related to itag
		#returnes [["url","itag","resolution","quality"],[... ]]
		return self.scan(/&url=(.+?)&.*?&itag=(\d+?)&.*?&size=(\d+?x\d+?)&.*?&quality_label=(.+?)&/)
	end
	
	def get_video_id
		return self.scan(/youtube.com\/watch\?v=(.*)/)
	end

end

def getinfo(vid)
	#gets video info txt
	info = open("https://youtube.com/get_video_info?video_id=#{vid[0][0]}")
	return URI.unescape(info.read)
	info.close
end
		
def transaction(url)
	begin
		begin
		video_info_raw = getinfo(url.get_video_id)
		video_info = video_info_raw.make_group_by_itag
		save_to = NKF.nkf("-m0 -w8",URI.unescape(video_info_raw).scan(/title=(.+?)&/)[0][0].to_s)
		video_resolution_and_url = [0,"",""]
		
			video_info.each{|array|
				begin
					array[2] = array[2].gsub(/x/,"").to_i
				rescue
					array[2] = 0
				end
		
				if array[2] == 19201080 then
					video_resolution_and_url = [array[2],array[0],array[3]]
					break
				elsif array[2] > video_resolution_and_url[0]
					video_resolution_and_url = [array[2],array[0],array[3]]
				end
			}
		
			if video_resolution_and_url[0].to_s.scan(/#{video_resolution_and_url[2].chop}/).empty? then
				puts video_resolution_and_url
				raise
			end
		rescue
			sleep(3)
			retry
		end
	
		puts("Download started:#{save_to};resolution:#{video_resolution_and_url[0]}")
	
	
		video = open(URI.unescape(video_resolution_and_url[1]))
		saveto = open("#{save_to}.mp4","a+")
		bytes = saveto.write(video.read)
		video.close
		saveto.close
	rescue
		retry
	end
	
	puts("done. #{bytes} bytes saved")
end

urls = `cat #{ARGV[0]}`
urls.split("\n").each{|url|
	transaction(url)
	sleep(2)
}
