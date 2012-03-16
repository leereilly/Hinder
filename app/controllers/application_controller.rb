class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
 
  before_filter :detect_iphone_request
 
  protected  
  def detect_iphone_request
    if iphone_request?
      @using_iphone = true
      request.format = :iphone
    end
  end
 
  def iphone_request?
	#request.subdomains.first == 'iphone'
    request.env["HTTP_USER_AGENT"] && request.env["HTTP_USER_AGENT"][/(Mobile\/.+Safari)/]
  end 
end
