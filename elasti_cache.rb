# frozen_string_literal: true

require "aws-sdk-elasticache"

class ElastiCache
  TAGS = {
    "combined-ec-redis5" => { cost_owner: "sre", stage: "qa" },
    "combined-elasticache" => { cost_owner: "sre", stage: "qa" },
    "free-ring-redis" => { cost_owner: "tiger", stage: "production" },
    "prod-errors-redis" => { cost_owner: "sre", stage: "production" },
    "prod-mentions-redis" => { cost_owner: "panda", stage: "production" },
    "prod-ring-queues" => { cost_owner: "penguin", stage: "production" },
    "prod-suppression" => { cost_owner: "tiger", stage: "production" },
  }

  def tag_clusters
    client.describe_cache_clusters.cache_clusters.each do |cluster|
      next unless cluster.replication_group_id # skip Memcached

      cluster = Cluster.new(cluster)

      tags = [
        {
          key: "cost_owner",
          value: cluster.cost_owner,
        },
        {
          key: "stage",
          value: cluster.stage,
        },
        {
          key: "elasticache_replication_group_id",
          value: cluster.replication_group_id,
        },
      ]
      puts "Tagging #{cluster.arn} with #{tags.inspect}"
      client.add_tags_to_resource(
        resource_name: cluster.arn,
        tags: tags,
      )
    end
  end

  def client
    @client ||= Aws::ElastiCache::Client.new
  end

  class Cluster
    attr_reader :cluster

    def initialize(cluster)
      @cluster = cluster
    end

    def arn
      account_id = Aws::STS::Client.new.get_caller_identity.account
      zone = cluster.preferred_availability_zone.chop
      "arn:aws:elasticache:#{zone}:#{account_id}:cluster:#{cluster.cache_cluster_id}"
    end

    def cost_owner
      tags.fetch(:cost_owner)
    end

    def stage
      tags.fetch(:stage)
    end

    def tags
      @tags ||= TAGS.fetch(replication_group_id)
    end

    def replication_group_id
      cluster.replication_group_id
    end
  end
end
