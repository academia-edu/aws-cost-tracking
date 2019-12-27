# frozen_string_literal: true

require "aws-sdk-ec2"
require "pry"

class Tagger
  REGIONS = [
    # "ap-east-1", # Aws::EC2::Errors::AuthFailure: AWS was not able to validate the provided access credentials
    "ap-northeast-1",
    "ap-northeast-2",
    # "ap-northeast-3", # Aws::EC2::Errors::OptInRequired: You are not subscribed to this service. Please go to http://aws.amazon.com to subscribe.
    "ap-south-1",
    "ap-southeast-1",
    "ap-southeast-2",
    "ca-central-1",
    "eu-central-1",
    "eu-north-1",
    "eu-west-1",
    "eu-west-2",
    "eu-west-3",
    # "me-south-1", # Aws::EC2::Errors::AuthFailure: AWS was not able to validate the provided access credentials
    "sa-east-1",
    "us-east-1",
    "us-east-2",
    "us-west-1",
    "us-west-2",
  ]

  attr_reader :key, :value, :server_classes, :stages, :regions

  def initialize(key:, value:, server_classes:, stages:, regions: REGIONS)
    @key = key
    @value = value
    @server_classes = Array(server_classes)
    @stages = Array(stages)
    @regions = Array(regions)
  end

  def tag
    each_instance(&:tag)
  end

  def untag
    each_instance(&:untag)
  end

  def each_instance
    regions.each do |region|
      ec2 = Aws::EC2::Resource.new(region: region)

      ec2.instances(filters: [
        { name: "tag:server_class", values: server_classes },
        { name: "tag:stage", values: stages },
      ]).each do |instance|
        yield InstanceTagger.new(instance: instance, region: region, key: key, value: value)
      end
    end
  end

  class InstanceTagger
    attr_reader :instance, :region, :key, :value

    def initialize(instance:, region:, key:, value:)
      @instance = instance
      @region = region
      @key = key
      @value = value
    end

    def tag
      tag_ebs_volumes
      tag_instance
    end

    def untag
      untag_ebs_volumes
      untag_instance
    end

    def tag_instance
      instance.create_tags(tags: [{ key: key, value: value }])
    end

    def tag_ebs_volumes
      ebs_volume_ids.each do |volume_id|
        Aws::EC2::Volume.
          new(volume_id, region: region).
          create_tags(tags: [{ key: key, value: value }])
      end
    end

    def untag_ebs_volumes
      ebs_volume_ids.each { |id| untag_resource(id) }
    end

    def untag_instance
      untag_resource(instance.id)
    end

    def ebs_volume_ids
      instance.block_device_mappings.map { |mapping| mapping.ebs.volume_id }
    end

    def untag_resource(resource_id)
      Aws::EC2::Tag.new(
        resource_id: resource_id,
        key: key,
        value: value,
        region: region,
      ).delete
    end
  end
end
