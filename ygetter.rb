require "uri"
require "open-uri"
require "nkf"

class String	
	def make_group_by_itag
		#make groupes related to itag
		#returnes [["itag","resolution","quality"."url"],[... ]]
		return self.scan(/itag=(\d+?)&.*?&size=(\d+?x\d+?)&.*?&quality_label=(.+?)&.+?&url=(.+?)&/)
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
	video_info_raw = getinfo(url.get_video_id)
	video_info = video_info_raw.make_group_by_itag
	save_to = NKF.nkf("-m0 -w8",URI.unescape(video_info_raw).scan(/title=(.+?)&/)[0][0].to_s)
	video_resolution_and_url = [0,""]
	p save_to
	
	video_info.each{|array|
		begin
			array[1] = array[1].gsub(/x/,"").to_i
		rescue
			array[1] = 0
		end
		
		if array[1] == 19201080 then
			video_resolution_and_url = [array[1],array[3]]
			break
		elsif array[1] > video_resolution_and_url[0]
			video_resolution_and_url = [array[1],array[3]]
		end
	}
	
	puts("Download started:#{save_to};resolution:#{video_resolution_and_url[0]}")
	
	
	video = open(URI.unescape(video_resolution_and_url[1]))
	saveto = open("#{save_to[0]}.mp4","a+")
	bytes = saveto.write(video.read)
	
	video.close
	saveto.close
	
	puts("done. #{bytes} bytes saved")
end

urls = `cat #{ARGV[0]}`
urls.split("\n").each{|url|
	transaction(url)
	sleep(2)
}
