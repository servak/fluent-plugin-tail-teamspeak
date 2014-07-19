require "helper"

class TeamspeakTailInputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
    FileUtils.rm_rf(TMP_DIR)
    FileUtils.mkdir_p(TMP_DIR)
  end

  TMP_DIR = File.dirname(__FILE__) + "/../tmp/tail#{ENV['TEST_ENV_NUMBER']}"

  CONFIG = %[
    path #{TMP_DIR}/tail_teamspeak.txt
    tag t1.teamspeak
    rotate_wait 2s
    pos_file #{TMP_DIR}/tail_teamspeak.pos
  ]

  def create_driver(conf=CONFIG)
    Fluent::Test::InputTestDriver.new(Fluent::TeamspeakTailInput).configure(conf)
  end

  def test_configure
    d = create_driver
    assert_equal ["#{TMP_DIR}/tail_teamspeak.txt"], d.instance.paths
    assert_equal "t1.teamspeak", d.instance.tag
    assert_equal 2, d.instance.rotate_wait
    assert_equal "#{TMP_DIR}/tail_teamspeak.pos", d.instance.pos_file
  end

  def test_emit
    File.open("#{TMP_DIR}/tail_teamspeak.txt", "w") {|f|
      f.puts "test1"
      f.puts "test2"
    }

    d = create_driver

    d.run do
      sleep 1

      File.open("#{TMP_DIR}/tail_teamspeak.txt", "a") {|f|
        f.puts "2014-07-19 07:14:30.122862|INFO    |VirtualServerBase|  1| client connected 'serveradmin'(id:1) from 127.0.0.1:42232"
        f.puts "2014-07-19 07:14:32.919097|INFO    |VirtualServerBase|  1| client connected '&#39080;&#26089;&#12367;&#12435;'(id:2) from 203.0.113.0:54220"
        f.puts "2014-07-19 07:14:34.476123|INFO    |VirtualServerBase|  1| client disconnected '&#39080;&#26089;&#12367;&#12435;'(id:2) reason 'reasonmsg=leaving'"
        f.puts "2014-07-19 13:27:49.082128|INFO    |VirtualServer |  1| query client connected 'serveradmin from 127.0.0.1:37809'(id:1)"
        f.puts "2014-07-19 13:27:49.119593|INFO    |VirtualServerBase|  1| query client disconnected 'serveradmin from 127.0.0.1:37809'(id:1) reason 'reasonmsg=disconnecting'"
        f.puts "2014-07-19 20:03:03.829109|INFO    |VirtualServer |  1| file download from (id:3), '/foo/&#39080;&#26089;&#12367;&#12435;.txt' by client '&#39080;&#26089;&#12367;&#12435;'(id:2)"
      }
      sleep 1
    end

    emits = d.emits
    assert_equal(true, emits.length > 0)

    assert_equal(1405754070, emits[0][1])
    actual = emits[0][2]
    assert_equal("127.0.0.1", actual[:ip])
    assert_equal("connected", actual[:action])
    assert_equal("client", actual[:type])
    assert_equal("serveradmin", actual[:user])
    assert_equal(1, actual[:id])
    assert_equal(nil, actual[:msg])

    assert_equal(1405754072, emits[1][1])
    actual = emits[1][2]
    assert_equal("203.0.113.0", actual[:ip])
    assert_equal("connected", actual[:action])
    assert_equal("client", actual[:type])
    assert_equal("風早くん", actual[:user])
    assert_equal(2, actual[:id])
    assert_equal(nil, actual[:msg])

    assert_equal(1405754074, emits[2][1])
    actual = emits[2][2]
    assert_equal(nil, actual[:ip])
    assert_equal("disconnected", actual[:action])
    assert_equal("client", actual[:type])
    assert_equal("風早くん", actual[:user])
    assert_equal(2, actual[:id])
    assert_equal('leaving', actual[:msg])

    assert_equal(1405776469, emits[3][1])
    actual = emits[3][2]
    assert_equal("127.0.0.1", actual[:ip])
    assert_equal("connected", actual[:action])
    assert_equal("query_client", actual[:type])
    assert_equal("serveradmin", actual[:user])
    assert_equal(1, actual[:id])
    assert_equal(nil, actual[:msg])

    assert_equal(1405776469, emits[4][1])
    actual = emits[4][2]
    assert_equal("127.0.0.1", actual[:ip])
    assert_equal("disconnected", actual[:action])
    assert_equal("query_client", actual[:type])
    assert_equal("serveradmin", actual[:user])
    assert_equal(1, actual[:id])
    assert_equal('disconnecting', actual[:msg])

    assert_equal(1405800183, emits[5][1])
    actual = emits[5][2]
    assert_equal(nil, actual[:ip])
    assert_equal("download", actual[:action])
    assert_equal("file", actual[:type])
    assert_equal("風早くん", actual[:user])
    assert_equal(2, actual[:id])
    assert_equal("/foo/風早くん.txt", actual[:msg])
  end
end
