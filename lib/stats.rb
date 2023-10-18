# frozen_string_literal: true

class Stats
  def self.all
    core_stats.merge(plugin_stats)
  end

  def self.exposable
    private_stat_keys =
      DiscoursePluginRegistry.stats.select { |stat| stat[:private] }.map { |stat| stat[:name] }
    all.select { |key, _| !private_stat_keys.any? { |x| key.start_with?(x) } }
  end

  private

  def self.core_stats
    {
      topic_count: Topic.listable_topics.count,
      topics_last_day: Topic.listable_topics.where("created_at > ?", 1.days.ago).count,
      topics_7_days: Topic.listable_topics.where("created_at > ?", 7.days.ago).count,
      topics_30_days: Topic.listable_topics.where("created_at > ?", 30.days.ago).count,
      post_count: Post.count,
      posts_last_day: Post.where("created_at > ?", 1.days.ago).count,
      posts_7_days: Post.where("created_at > ?", 7.days.ago).count,
      posts_30_days: Post.where("created_at > ?", 30.days.ago).count,
      user_count: User.real.count,
      users_last_day: User.real.where("created_at > ?", 1.days.ago).count,
      users_7_days: User.real.where("created_at > ?", 7.days.ago).count,
      users_30_days: User.real.where("created_at > ?", 30.days.ago).count,
      active_users_last_day: User.where("last_seen_at > ?", 1.days.ago).count,
      active_users_7_days: User.where("last_seen_at > ?", 7.days.ago).count,
      active_users_30_days: User.where("last_seen_at > ?", 30.days.ago).count,
      like_count: UserAction.where(action_type: UserAction::LIKE).count,
      likes_last_day:
        UserAction.where(action_type: UserAction::LIKE).where("created_at > ?", 1.days.ago).count,
      likes_7_days:
        UserAction.where(action_type: UserAction::LIKE).where("created_at > ?", 7.days.ago).count,
      likes_30_days:
        UserAction.where(action_type: UserAction::LIKE).where("created_at > ?", 30.days.ago).count,
    }
  end

  def self.plugin_stats
    final_plugin_stats = {}
    DiscoursePluginRegistry.stats.each do |stat_group|
      stat = Stat.new(stat_group)
      final_plugin_stats.merge!(stat.values)
    end
    final_plugin_stats
  end

  private_class_method :core_stats, :plugin_stats
end

class Stat
  def initialize(hash)
    @name = hash[:name]
    @show_in_ui = hash[:show_in_ui]
    @private = hash[:private]
    @block = hash[:block]
  end

  def values
    result = {}

    begin
      stats = @block.call

      if !stats.key?(:last_day) || !stats.key?("7_days") || !stats.key?("30_days") ||
           !stats.key?(:count)
        Rails.logger.warn(
          "Plugin stat group #{@name} for About stats does not have all required keys, skipping.",
        )
      else
        result.merge!(stats.transform_keys { |key| "#{@name}_#{key}".to_sym })
      end
    rescue StandardError => err
      puts "ERROR ERROR"
      Discourse.warn_exception(
        err,
        message: "Unexpected error when collecting #{@name} About stats.",
      )
    end
    result
  end
end
