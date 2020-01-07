# frozen_string_literal: true

require "aws-sdk-datapipeline"

class DataPipeline
  def tag
    pipeline_ids.each do |id|
      puts "tagging Data Pipeline #{id}"

      client.add_tags(
        pipeline_id: id,
        tags: [
          {
            key: "cost_owner",
            value: "owl",
          }
        ]
      )
    end
  end

  def pipeline_ids
    client.list_pipelines.flat_map do |response|
      response.pipeline_id_list.map(&:id)
    end
  end

  def client
    @client ||= Aws::DataPipeline::Client.new
  end
end
