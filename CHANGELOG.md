## 3.0.6
  - Fix processing when item.author is not present
  - Explicitly depend on rss gem for JRuby versions that don't include it

## 3.0.5
  - Docs: Set the default_codec doc attribute.

## 3.0.4
  - Update gemspec summary

## 3.0.3
  - Fix some documentation issues

## 3.0.1
  - Relax constraint on logstash-core-plugin-api to >= 1.60 <= 2.99

## 3.0.0
  - Breaking: Updated plugin to use new Java Event APIs.
## 2.0.6
  - Fixes the case when there is an invalid feed, exceptions are now
    catched and logged. Fixes https://github.com/logstash-plugins/logstash-input-rss/issues/1
  - Also add test for normal, valid but empty and invalid feeds use
    cases.

## 2.0.5
  - Depend on logstash-core-plugin-api instead of logstash-core, removing the need to mass update plugins on major releases of logstash

## 2.0.4
  - New dependency requirements for logstash-core for the 5.0 release

## 2.0.3
 - Fixed bug where `queue` variable was being used but not initialized in `handle_response`.
   Ref: https://github.com/logstash-plugins/logstash-input-rss/pull/14

## 2.0.0
 - Plugins were updated to follow the new shutdown semantic, this mainly allows Logstash to instruct input plugins to terminate gracefully, 
   instead of using Thread.raise on the plugins' threads. Ref: https://github.com/elastic/logstash/pull/3895
 - Dependency on logstash-core update to 2.0

