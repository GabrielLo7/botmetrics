class AnalyticsController < ApplicationController
  before_action :authenticate_user!
  before_action :find_bot

  layout 'app'

  helper_method :default_query

  def index
    if @bot.provider == 'facebook'
      flash[:info] = "Analysis for Facebook is coming soon!"
      redirect_to(bot_path(@bot)) && return
    end

    @query_set =
      QuerySetBuilder.new(
        bot: @bot,
        instances_scope: :legit,
        time_zone: current_user.timezone,
        default: default_query,
        params: params
      ).query_set

    @tableized = FilterBotUsersService.new(@query_set).scope.page(params[:page])
  end

  private
  def default_query
    { provider: @bot.provider }
  end

  def mixpanel_tracking
    TrackMixpanelEventJob.perform_async(
      'Viewed Analytics Index Page', current_user.id,
      query_set: @query_set.to_form_params
    )
  end
end
