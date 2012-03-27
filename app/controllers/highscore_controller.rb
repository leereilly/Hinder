class HighscoreController < ApplicationController
  def index
    if params[:moves] && params[:level]
      @h = Highscore.new()
      @h.moves = params[:moves].to_i
      @h.level = params[:level].downcase
      if @h.save
        respond_to do |format|
          format.js do
            render :json => @h
            #render @h.to_json:layout => false
          end
        end
      end
    else
      if params[:level]
        @highscore = Highscore.where("level = ?", params[:level].downcase).order("moves ASC").first
        respond_to do |format|
          format.js do
            render :json => @highscore
            #render @h.to_json:layout => false
          end
        end
      end
    end
    #@highscores = Highscore.all
  end


  def show
    respond_to do |format|
      format.js do
        render :json => @h
      end
    end
  end

end
