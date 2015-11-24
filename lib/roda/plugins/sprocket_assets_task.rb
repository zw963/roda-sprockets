require 'rake'
require 'rake/tasklib'
require 'rake/sprocketstask'

class Roda
  module RodaPlugins
    module SprocketAssets
      class Task < Rake::TaskLib
        def initialize(app_klass)
          namespace :assets do
            desc "Precompile assets"
            task :precompile do
              opts = app_klass.sprocket_assets_opts
              environment = opts[:sprockets]
              manifest = Sprockets::Manifest.new(environment.index, opts[:public_path])
              manifest.compile(opts[:precompile])
            end

            desc "Clean assets"
            task :clean do
              FileUtils.rm_rf(app_klass.sprocket_assets_opts[:public_path])
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
