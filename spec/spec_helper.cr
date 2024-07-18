require "spec"
require "bindata"
require "../src/knx"
require "../src/knx/object_server"
require "../src/knx/tunnel_client"

::Log.setup("*", :trace)

Spec.before_suite do
  ::Log.setup("*", :trace)
end
