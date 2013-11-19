require 'sprockets/helpers/rails_helper'

module Sprockets
  module Helpers
    module RailsHelper
      def javascript_include_tag(*sources)
        binding.pry
        if enforce_precompile?
          sources_without_options(sources).each do |source|
            ensure_asset_will_be_precompiled!(source, 'js')
          end
        end

        super *sources
      end

      def stylesheet_link_tag(*sources)
        if enforce_precompile?
          sources_without_options(sources).each do |source|
            ensure_asset_will_be_precompiled!(source, 'css')
          end
        end

        super *sources
      end


      private

      def sources_without_options(sources)
        sources.last.is_a?(Hash) && sources.last.extractable_options? ? sources[0..-2] : sources
      end

      def enforce_precompile?
        Rails.application.config.assets.enforce_precompile
      end

      def asset_list
        ignored = Rails.application.config.assets.ignore_for_precompile || []
        precompile = Rails.application.config.assets.precompile || []
        precompile + ignored
      end

      def ensure_asset_will_be_precompiled!(source, ext)
        source = source.to_s
        return if asset_paths.is_uri?(source)
        asset_file = asset_environment.resolve(asset_paths.rewrite_extension(source, nil, ext))
        unless asset_environment.send(:logical_path_for_filename, asset_file, asset_list)

          # Allow user to define a custom error message
          error_message_proc = Rails.application.config.assets.precompile_error_message_proc

          error_message = if error_message_proc
            error_message_proc.call(asset_file)
          else
            "#{File.basename(asset_file)} must be added to config.assets.precompile, otherwise it won't be precompiled for production!"
          end

          raise AssetPaths::AssetNotPrecompiledError.new(error_message)
        end
      end
    end
  end
end
