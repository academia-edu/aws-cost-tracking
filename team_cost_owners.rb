# To use:
# require_relative 'team_cost_owners'
# include TeamCostOwners
# tag_ec2_cost_owners!(server_classes_by_team, stages: stage or [stage1, ...])

require 'csv'
require 'yaml'
require_relative 'tagger'

module TeamCostOwners
  def server_classes_to_tag
    {
      # for example:
      # "AcademiaZoo::Logging" => "sre",
    }
  end

  def server_classes_by_team
    server_classes_to_tag.
      group_by { |_, v| v }.
      transform_values { |a| a.map(&:first) }
  end

  def tag_ec2_cost_owners!(server_classes_by_team, stages:)
    server_classes_by_team.each do |team, server_classes|
      Tagger.new(key: 'cost_owner', value: team, server_classes: server_classes, stages: stages).tag
    end

    names_by_team.each do |team, names|
      Tagger.new(key: "cost_owner", value: team, names: names).tag
    end
  end

  def names_by_team
    YAML.
      load_file("name_to_tag.yml").
      transform_values { |value| value.fetch("cost_owner") }.
      group_by { |_key, value| value }.
      transform_values { |value| value.map(&:first) }
  end
end
