'use strict';

var { NativeModules } = require('react-native');
var FileTransfer = NativeModules.FileTransfer

class RNUploader {
  constructor() {
  }

  static upload(opts, callback) {
    FileTransfer.upload(opts, callback);
  }
}

module.exports = RNUploader;