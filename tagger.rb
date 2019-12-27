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

  def add_tag(server_classes:, stages:, regions: REGIONS, key:, value:)
    each_instance(server_classes: server_classes, stages: stages, regions: regions) do |instance, _region|
      instance.create_tags(tags: [{ key: key, value: value }])
    end
  end

  def remove_tag(server_classes:, stages:, regions: REGIONS, key:, value:)
    each_instance(server_classes: server_classes, stages: stages, regions: regions) do |instance, region|
      Aws::EC2::Tag.new(
        resource_id: instance.id,
        key: key,
        value: value,
        region: region,
      ).delete
    end
  end

  def each_instance(server_classes:, stages:, regions:)
    regions.each do |region|
      ec2 = Aws::EC2::Resource.new(region: region)

      ec2.instances(filters: [
        { name: "tag:server_class", values: Array(server_classes) },
        { name: "tag:stage", values: Array(stages) },
      ]).each do |instance|
        yield instance, region
      end
    end
  end
end
