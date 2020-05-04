require 'rake'
require 'rake/tasklib'
require 'rake/sprocketstask'

class Roda
  module RodaPlugins
    module Sprockets
      class Task < Rake::TaskLib
        def initialize(app_klass)
          namespace :assets do
            desc "Precompile assets"
            task :precompile do
              options = app_klass.sprockets_options
              environment = options[:sprockets]
              manifest = Sprockets::Manifest.new(environment.index, options[:public_path])
              manifest.compile(options[:precompile])
            end

            desc "Clean assets"
            task :clean do
              FileUtils.rm_rf(app_klass.sprockets_options[:public_path])
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
