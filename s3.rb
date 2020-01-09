# frozen_string_literal: true

require "aws-sdk-s3"

class S3
  def tag_buckets_with_bucket_name
    bucket_names.each do |name|
      puts %[tagging bucket "#{name}" with `s3_bucket_name: #{name.inspect}]
      client.put_bucket_tagging({
        bucket: name,
        tagging: {
          tag_set: [
            {
              key: "s3_bucket_name",
              value: name,
            },
          ],
        },
      })
    end
  end

  private

  def bucket_names
    client.list_buckets.each_page.flat_map(&:buckets).map(&:name)
  end

  def client
    @client ||= Aws::S3::Client.new
  end
end
