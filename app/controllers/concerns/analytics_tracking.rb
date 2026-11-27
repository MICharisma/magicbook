module AnalyticsTracking
  extend ActiveSupport::Concern

  included do
    helper_method :analytics_context
    before_action :assign_analytics_tracker
  end

  private

  def assign_analytics_tracker
    Current.ahoy_tracker = ahoy
  end

  def analytics_context
    {
      page_type: "#{controller_path}.#{action_name}",
      record_id: params[:id],
      path: analytics_path(request.path),
      signed_in: mage_signed_in?,
      enabled: !analytics_excluded?
    }.compact
  end

  def analytics_excluded?
    cookies[:magicbook_analytics_exclude] == "1" || current_mage&.admin?
  end

  def analytics_path(path)
    path.sub(%r{\A/(?:magic[-_]links?|invite|tokens)/[^/]+}, '/magic-link/:token')
  end

  def track_analytics(name, properties = {})
    return if analytics_excluded?

    ahoy.track(name, analytics_context.except(:enabled).merge(properties))
  end
end
