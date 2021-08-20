require 'roda'

class App < Roda
   plugin :sprockets, precompile: %w(application.js),
                      prefix: %w(app/),
                      root: __dir__,
                      public_path: 'public/assets/',
                      opal: true,
                      debug: ENV['RACK_ENV'] != 'production'
   plugin :public

   route do |r|
     r.public
     r.sprockets

     r.root do
       <<~END
         <!doctype html>
         <html>
           <head>
             #{ javascript_tag 'application' }
             #{ opal_require 'application' }
           </head>
         </html>
       END
     end
   end     
end
