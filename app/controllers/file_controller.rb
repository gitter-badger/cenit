class FileController < ApplicationController

  def index
    file_path = request.path.from(request.path.index('/', 1))
    model = nil
    if model_desc = params[:model]
      model = Object
      model_desc.split('~').each do |token|
        next unless model
        model = model.const_get(token.camelize) rescue nil
      end
    end
    if model &&
      (record = model.where(id: params[:id]).first)
      if Ability.new(current_user).can?(:show, record)
        if (uploader = record.try(params[:field])).is_a?(CarrierWave::Uploader::Base) &&
          (uploader = find_version(uploader, file_path)) &&
          content = uploader.read
          send_data content, type: uploader.file.content_type, disposition: 'inline'
        else
          not_found
        end
      else
        unauthorized
      end
    else
      not_found
    end
  end

  private

  def find_version(uploader, path)
    if uploader.path == path
      return uploader
    else
      uploader.versions.values.each do |uploader_version|
        if uploader = find_version(uploader_version, path)
          return uploader
        end
      end
      nil
    end
  end

  def not_found
    render plain: 'Not found', status: :not_found
  end

  def unauthorized
    render plain: 'Unauthorized', status: :unauthorized
  end
end