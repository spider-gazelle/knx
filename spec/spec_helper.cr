require "spec"
require "bindata"
require "../src/knx"
require "../src/knx/object_server"

::Log.setup("*", :trace)

Spec.before_suite do
  ::Log.setup("*", :trace)
end
