# frozen_string_literal: true

RSpec.shared_examples_for "stats cacheable" do
  describe "fetch_cached_stats" do
    after { Discourse.redis.del(described_class.stats_cache_key) }

    it "returns the cached stats" do
      stats = described_class.fetch_stats.to_json
      Discourse.redis.set(described_class.stats_cache_key, stats)
      expect(described_class.fetch_cached_stats).to eq(JSON.parse(stats))
    end

    it "returns fetches the stats if stats has not been cached" do
      freeze_time

      Discourse.redis.del(described_class.stats_cache_key)
      expect(described_class.fetch_cached_stats).to eq(
        JSON.parse(described_class.fetch_stats.to_json),
      )
    end
  end

  describe "fetch_stats" do
    it "has not been implemented" do
      expect { described_class.fetch_stats }.to_not raise_error
    end
  end

  describe "public_stats" do
    it "doesn't adds private stats to the output" do
      private_stat = { :last_day => 1, "7_days" => 2, "30_days" => 3, :count => 4 }
      public_stat = { :last_day => 42, "7_days" => 43, "30_days" => 44, :count => 45 }
      register_stat("private_stat", Proc.new { private_stat }, private: true)
      register_stat("public_stat", Proc.new { public_stat })

      expect(described_class.public_stats.with_indifferent_access).to match(
        hash_including(
          public_stat_last_day: 42,
          public_stat_7_days: 43,
          public_stat_30_days: 44,
          public_stat_count: 45,
        ),
      )

      expect(described_class.public_stats.with_indifferent_access).not_to match(
        hash_including(
          private_stat_last_day: 1,
          private_stat_7_days: 2,
          private_stat_30_days: 3,
          private_stat_count: 4,
        ),
      )
    end
  end
end
