module RailsAdmin
  module Config
    module Actions

      class Translate < RailsAdmin::Config::Actions::Base

        register_instance_option :visible? do
          if authorized?
            model = bindings[:abstract_model].model rescue nil
            model.try(:data_type).present?
          else
            false
          end
        end

        register_instance_option :http_methods do
          [:get, :post]
        end

        register_instance_option :controller do
          proc do

            @bulk_ids = (@object && [@object.id]) || params.delete(:bulk_ids)
            if object_ids = params.delete(:object_ids)
              @bulk_ids = object_ids
            end
            translation_config = RailsAdmin::Config.model(Forms::Translation)
            translator_type = @action.class.translator_type
            done = false

            if model = @abstract_model.model rescue nil
              data_type = model.data_type
              data_type_selector = data_type.is_a?(Setup::BuildInDataType) ? nil : data_type
              if data = params[translation_config.abstract_model.param_key]
                translator = Setup::Translator.where(id: data[:translator_id]).first
                if (@form_object = Forms::Translation.new(
                  translator_type: translator_type,
                  bulk_source: (@bulk_ids.nil? && model.count != 1) || (@bulk_ids && @bulk_ids.size != 1),
                  data_type: data_type_selector,
                  translator: translator)).valid?

                  begin
                    do_flash_process_result Setup::Translation.process(translator_id: translator.id,
                                                                       bulk_ids: @bulk_ids,
                                                                       data_type_id: data_type.id)
                    done = true
                  rescue Exception => ex
                    flash[:error] = ex.message
                  end
                end
              end
            end
            if done
              redirect_to back_or_index
            else
              @model_config = translation_config
              @form_object ||= Forms::Translation.new(
                translator_type: translator_type,
                bulk_source: (@bulk_ids.nil? && (model.nil? || model.count != 1)) || (@bulk_ids && @bulk_ids.size != 1),
                data_type: data_type_selector,
                translator: translator)

              if @form_object.errors.present?
                do_flash_now(:error, 'There are errors in the export data specification', @form_object.errors.full_messages)
              end
              render :form
            end

          end
        end

        class << self

          def translator_type
            nil
          end

          def disable_buttons?
            true
          end
        end

      end
    end
  end
end