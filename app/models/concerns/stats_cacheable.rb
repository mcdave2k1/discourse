# frozen_string_literal: true

module StatsCacheable
  extend ActiveSupport::Concern

  module ClassMethods
    def stats_cache_key
      raise "Stats cache key has not been set."
    end

    def fetch_stats
      raise "Not implemented."
    end

    def public_stats
      private_stat_keys =
        DiscoursePluginRegistry.stats.select { |stat| stat[:private] }.map { |stat| stat[:name] }
      fetch_cached_stats.select { |key, _| !private_stat_keys.any? { |x| key.start_with?(x) } }
    end

    # Could be configurable, multisite need to support it.
    def recalculate_stats_interval
      30 # minutes
    end

    def fetch_cached_stats
      # The scheduled Stats job is responsible for generating and caching this.
      stats = nil # Discourse.redis.get(stats_cache_key)
      stats = refresh_stats if !stats
      JSON.parse(stats).with_indifferent_access
    end

    def refresh_stats
      stats = fetch_stats.to_json
      set_cache(stats)
      stats
    end

    private

    def set_cache(stats)
      # Add some extra time to the expiry so that the next job run has plenty of time to
      # finish before previous cached value expires.
      Discourse.redis.setex stats_cache_key, (recalculate_stats_interval + 5).minutes, stats
    end
  end
end
