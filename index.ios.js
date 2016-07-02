/**
 * @providesModule RNUploader
 * @flow
 */
'use strict';
var { NativeModules } = require('react-native');
var NativeRNUploader = NativeModules.RNUploader;

/**
 * High-level docs for the RNUploader iOS API can be written here.
 */

class RNUploader {
    constructor() {
    }

    static upload(opts, callback) {
        NativeRNUploader.upload(opts, callback);
    }
    static cancel(){
        NativeRNUploader.cancel()
    }
    static test() {
        NativeRNUploader.test()
    }
}

module.exports = RNUploader;