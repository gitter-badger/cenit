module Xsd
  class Any < AttributedTag
    include BoundedTag

    tag 'any'

    attr_reader :name

    def to_json_schema
      {}
    end
  end
end