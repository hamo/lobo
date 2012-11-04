$: << File.absolute_path( File.dirname __FILE__ )
require "init"

use Rack::LiveReload  if RACK_ENV == 'development'

Main.set :run, false
#Main.set :environment, :production

run Main
