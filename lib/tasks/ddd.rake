# frozen_string_literal: true

namespace :ddd do
  desc "Dump IR (Intermediate Representation) to docs/ir.json"
  task :ir, [:output] => :environment do |_t, args|
    require "ddd"
    output = args[:output] || "docs/ir.json"

    resources = DDD::SchemaRegistry.collect
    json = DDD::IR.to_json(resources)

    FileUtils.mkdir_p(File.dirname(output))
    File.write(output, json)

    puts "IR dumped to #{output} (#{resources.size} resources)"
  end

  desc "Emit spec file from IR. Usage: rake ddd:emit[openapi]"
  task :emit, [:format, :output] => :environment do |_t, args|
    require "ddd"
    format = args[:format]&.to_sym

    unless format
      puts "Usage: rake ddd:emit[format]"
      puts "Available formats: #{DDD::Emitter.formats.join(', ')}"
      exit 1
    end

    output_map = { openapi: "docs/openapi.yaml" }
    output = args[:output] || output_map[format] || "docs/#{format}.out"

    resources = DDD::SchemaRegistry.collect
    content = DDD::Emitter.emit(format, resources)

    FileUtils.mkdir_p(File.dirname(output))
    File.write(output, content)

    puts "Emitted #{format} to #{output} (#{resources.size} resources)"
  rescue DDD::Emitter::UnknownFormatError => e
    puts e.message
    exit 1
  end
end
