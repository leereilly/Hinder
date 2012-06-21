class HomeController < ApplicationController
  	before_filter :detect_device_request

	def index
		@start_note = "False."
		@canvassize = 570
		@canvassize = 645 unless @using_ipad.blank?
		@start_note = "Swipe to move." if not @using_ipad.blank? and not @using_iphone.blank?
		respond_to do |format|
	  		format.html # index.html.erb
	  		format.iphone {@canvassize = 495} #index.iphone.erb
		end
	end
	def show
		redirect_to :action => 'index'
	end
	 
	protected  
	def detect_device_request
		if iphone_request?
		  @using_iphone = true
		  request.format = :iphone
		end
		if ipad_request?
		  @using_ipad = true
		end
	end

	def ipad_request?
		request.env["HTTP_USER_AGENT"] && request.user_agent.include?("iPad")
	end

	def iphone_request?
		request.env["HTTP_USER_AGENT"] && request.user_agent.include?("iPhone")
	end
end
