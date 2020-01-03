# To use:
# require_relative 'team_cost_owners'
# include TeamCostOwners
# tag_ec2_cost_owners!(server_classes_by_team, stages: stage or [stage1, ...])

require 'csv'
require_relative 'tagger'

module TeamCostOwners
  def server_classes_to_tag
    CSV.read('server_classes_to_tag.csv')
  end

  def server_classes_by_team
    server_classes_to_tag.to_h.group_by {|k,v| v}.transform_values {|a| a.map(&:first)}
  end

  def tag_ec2_cost_owners!(server_classes_by_team, stages:)
    server_classes_by_team.each do |team, server_classes|
      Tagger.new(key: 'cost_owner', value: team, server_classes: server_classes, stages: stages).tag
    end
  end
end
