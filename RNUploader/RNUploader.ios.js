/**
 * @providesModule RNUploader
 * @flow
 */
'use strict';

var NativeRNUploader = require('NativeModules').RNUploader;

/**
 * High-level docs for the RNUploader iOS API can be written here.
 */

var RNUploader = {
  test: function() {
    NativeRNUploader.test();
  }
};

module.exports = RNUploader;