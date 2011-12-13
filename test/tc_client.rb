require "test/unit"
require "ostruct"
require "splunk-sdk/client"

ADMIN_LOGIN = "admin"
ADMIN_PSW = "sk8free"
TEST_APP_NAME = "sdk-tests"
TEST_INDEX_NAME = "sdk-tests"

def wait_event_count(index, count, secs)
  done = false
  while !done and secs > 0 do
    sleep 1
    secs -= 1
    done = index['totalEventCount'] == count
  end
end

class TcClient < Test::Unit::TestCase
  def setup
    @service = Service.new(:username => ADMIN_LOGIN, :password => ADMIN_PSW)
  end

=begin

  def test_apps
    @service.apps.each do |app|
      app.read
    end

    if @service.apps.list.include?(TEST_APP_NAME)
      @service.apps.delete(TEST_APP_NAME)
    end
    assert(@service.apps.list.include?(TEST_APP_NAME) == false)

    @service.apps.create(TEST_APP_NAME)
    assert(@service.apps.list.include?(TEST_APP_NAME))

    test_app = @service.apps[TEST_APP_NAME]
    test_app['author'] = "Splunk"

    assert(test_app['author'] == "Splunk")

    @service.apps.delete(TEST_APP_NAME)
    assert(@service.apps.list.include?(TEST_APP_NAME) == false)
  end
=end

  def test_capabilities
    expected = [
        "admin_all_objects", "change_authentication",
        "change_own_password", "delete_by_keyword",
        "edit_deployment_client", "edit_deployment_server",
        "edit_dist_peer", "edit_forwarders", "edit_httpauths",
        "edit_input_defaults", "edit_monitor", "edit_roles",
        "edit_scripted", "edit_search_server", "edit_server",
        "edit_splunktcp", "edit_splunktcp_ssl", "edit_tcp",
        "edit_udp", "edit_user", "edit_web_settings", "get_metadata",
        "get_typeahead", "indexes_edit", "license_edit", "license_tab",
        "list_deployment_client", "list_forwarders", "list_httpauths",
        "list_inputs", "request_remote_tok", "rest_apps_management",
        "rest_apps_view", "rest_properties_get", "rest_properties_set",
        "restart_splunkd", "rtsearch", "schedule_search", "search",
        "use_file_operator" ]
    capabilities = @service.capabilities
    expected.each do |item|
      assert(capabilities.include?(item))
    end
  end

  def test_info
    keys = [
    "build", "cpu_arch", "guid", "isFree", "isTrial", "licenseKeys",
    "licenseSignature", "licenseState", "master_guid", "mode",
    "os_build", "os_name", "os_version", "serverName", "version" ]
    @service.info.keys {|key| assert(key.include? keys)}
  end

  def test_indexes
    @service.indexes.each {|index| index.read}
    @service.indexes.create(TEST_INDEX_NAME) if !@service.indexes.list.include?(TEST_INDEX_NAME)
    assert(@service.indexes.contains(TEST_INDEX_NAME))

    attrs = [
      'thawedPath', 'quarantineFutureSecs',
      'isInternal', 'maxHotBuckets', 'disabled', 'homePath',
      'compressRawdata', 'maxWarmDBCount', 'frozenTimePeriodInSecs',
      'memPoolMB', 'maxHotSpanSecs', 'minTime', 'blockSignatureDatabase',
      'serviceMetaPeriod', 'coldToFrozenDir', 'quarantinePastSecs',
      'maxConcurrentOptimizes', 'maxMetaEntries', 'minRawFileSyncSecs',
      'maxMemMB', 'maxTime', 'partialServiceMetaPeriod', 'maxHotIdleSecs',
      'coldToFrozenScript', 'thawedPath_expanded', 'coldPath_expanded',
      'defaultDatabase', 'throttleCheckPeriod', 'totalEventCount',
      'enableRealtimeSearch', 'indexThreads', 'maxDataSize',
      'currentDBSizeMB', 'homePath_expanded', 'blockSignSize',
      'syncMeta', 'assureUTF8', 'rotatePeriodInSecs', 'sync',
      'suppressBannerList', 'rawChunkSizeBytes', 'coldPath',
      'maxTotalDataSizeMB'
    ]
    @service.indexes.each do |index|
      entity = index.read
      attrs.each {|attr| assert(entity.include?(attr))}
    end

    index = @service.indexes[TEST_INDEX_NAME]

    entity = index.read
    assert(index['disabled'], entity.disabled)

    index.disable
    assert(index['disabled'], '1')

    index.enable
    assert(index['disabled'], '0')

    index.clean
    assert(index['totalEventCount'], '0')

    cn = index.attach
    cn.write("Hello World!")
    cn.close
    wait_event_count(index,'1', 30)
    assert(index['totalEventCount'], '1')

    index.submit("Hello again!")
    wait_event_count(index, '2', 30)
    assert(index['totalEventCount'], '2')

    testpath = File.dirname(File.expand_path(__FILE__))
    index.upload(File.join(testpath, "testfile.txt"))
    wait_event_count(index, '3', 30)
    assert(index['totalEventCount'], '3')

    index.clean
    assert(index['totalEventCount'], '0')
  end
end
