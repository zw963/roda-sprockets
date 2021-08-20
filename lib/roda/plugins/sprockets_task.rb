require 'rake'
require 'rake/tasklib'
require 'rake/sprocketstask'

class Roda
  module RodaPlugins
    module Sprockets
      class Task < Rake::SprocketsTask
        def initialize(app_klass)
          @app_klass = app_klass
          super() { update_values }
        end

        def update_values
          @environment = sprockets_options[:sprockets]
          @output = sprockets_options[:public_path]
          @assets = sprockets_options[:precompile]
        end

        def sprockets_options
          @app_klass.sprockets_options
        end

        def define
          namespace :assets do
            desc "Precompile assets"
            task :precompile do
              with_logger do
                manifest.compile(assets)
              end
            end

            desc "Clean assets"
            task :clean do
              with_logger do
                manifest.clobber
              end
            end
          end
        end

        def self.define!(app_klass)
          self.new app_klass
        end
      end
    end
  end
end
