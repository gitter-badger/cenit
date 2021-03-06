module Setup
  class Library
    include CenitScoped
    include Slug

    Setup::Models.exclude_actions_for self, :delete, :bulk_delete, :delete_all

    BuildInDataType.regist(self).embedding(:schemas, :data_types).referenced_by(:name)

    field :name, type: String

    has_many :schemas, class_name: Setup::Schema.to_s, inverse_of: :library, dependent: :destroy
    has_many :data_types, class_name: Setup::DataType.to_s, inverse_of: :library, dependent: :destroy

    validates_presence_of :name
    validates_uniqueness_of :name

    after_initialize { @schemas_scope = {} }

    #TODO Delete these method
    def find_data_type_by_name(name)
      if data_type = Setup::DataType.where(library: self, name: name).first
        data_type
      else
        if (schema = Setup::Schema.where(library: self, uri: name).first) && schema.data_types.count == 1
          schema.data_types.last
        else
          nil
        end
      end
    end

    def run_after_initialized
      set_schemas_scope(schemas)
    end

    def set_schemas_scope(schemas)
      @schemas_scope = {}
      schemas.each { |schema| @schemas_scope[schema.uri] = schema }
    end

    def schema_for(base_uri, relative_uri)
      uri = Cenit::Utility.abs_uri(base_uri, relative_uri)
      if schema = @schemas_scope[uri]
        schema
      else
        schemas.where(uri: uri).first
      end
    end
  end
end
