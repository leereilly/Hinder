class HomeController < ApplicationController
	def index
    @canvassize = 600
    respond_to do |format|
      format.html # index.html.erb
      format.iphone {@canvassize = 495} #index.iphone.erb
     end
	end
end
