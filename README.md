# react-native-uploader
A React Native module for uploading files and camera roll assets. Supports progress notification.

## Install
### Use rnpm
1. `npm install react-native-uploader --save`
2. `rnpm link react-native-uploader`


If you don't want use rnpm, do this
### iOS
1. `npm install react-native-uploader --save`
2. In XCode, in the project navigator, right click `Libraries` ➜ `Add Files to [your project's name]`
3. Go to `node_modules` ➜ `react-native-uploader` ➜ `RNUploader` and add `RNUploader.xcodeproj`
4. In XCode, in the project navigator, select your project. Add `libRNUploader.a` to your project's `Build Phases` ➜ `Link Binary With Libraries`
5. Run your project (`Cmd+R`)

### Android
1. Add to your settings.gradle:
```
include ':RNFileTransfer', ':app'
project(':RNFileTransfer').projectDir = new File(rootProject.projectDir, '../node_modules/react-native-file-transfer-android/android')
```

2. Add to your android/build.gradle:
```
dependencies {
  ...
  compile project(':RNFileTransfer')
}
```

3. Add to MainActivity.java
```
import com.burlap.filetransfer.FileTransferPackage;
...
mReactInstanceManager = ReactInstanceManager.builder()
        .setApplication(getApplication())
        .setBundleAssetName("index.android.bundle")
        .setJSMainModuleName("index.android")
        .addPackage(new MainReactPackage())
        .addPackage(new FileTransferPackage())
```

## Example
See ./examples/UploadFromCameraRoll

![Example](https://raw.githubusercontent.com/aroth/react-native-uploader/master/examples/UploadFromCameraRoll/uploader.gif)


## Usage
```javascript
var RNUploader = require('react-native-uploader');

var {
	StyleSheet, 
	Component,
	View,
	DeviceEventEmitter,
} = React;
```

```javascript
componentDidMount(){
	// upload progress
	DeviceEventEmitter.addListener('RNUploaderProgress', (data)=>{
	  let bytesWritten = data.totalBytesWritten;
	  let bytesTotal   = data.totalBytesExpectedToWrite;
	  let progress     = data.progress;
	  
	  console.log( "upload progress: " + progress + "%");
	});
}
```

```javascript
doUpload(){
	let files = [
		{
			name: 'file[]',
			filename: 'image1.png',
			filepath: 'assets-library://....',  // image from camera roll/assets library
			filetype: 'image/png',
		},
		{
			name: 'file[]',
			filename: 'image2.gif',
			filepath: "data:image/gif;base64,R0lGODlhEAAQAMQAAORHHOVSKudfOulrSOp3WOyDZu6QdvCchPGolfO0o/XBs/fNwfjZ0frl3/zy7////wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAkAABAALAAAAAAQABAAAAVVICSOZGlCQAosJ6mu7fiyZeKqNKToQGDsM8hBADgUXoGAiqhSvp5QAnQKGIgUhwFUYLCVDFCrKUE1lBavAViFIDlTImbKC5Gm2hB0SlBCBMQiB0UjIQA7", // base64 only support ios
			filetype: 'image/gif',
		},
	];

	let opts = {
		url: 'http://my.server/api/upload',
		files: files, 
		method: 'POST',                             // optional: POST or PUT, only support ios, android always have POST
		headers: { 'Accept': 'application/json' },  // optional, only support ios, android always have  { 'Accept': 'application/json' }
		params: { 'user_id': 1 },                   // optional, Android support this only string. If you want this in Android use params: { 'user_id': '1' }
	};

	RNUploader.upload( opts, (err, response) => {
		if( err ){
			console.log(err);
			return;
		}
  
		let status = response.status;
		let responseString = response.data;
		let json = JSON.parse( responseString );

		console.log('upload complete with status ' + status);

		// android's response is response.body.string.
	});
}

```

## API
#### RNUploader.upload( options, callback )

`options` is an object with values:

||type|required|description|example|
|---|---|---|---|---|
|`url`|string|required|URL to upload to|`http://my.server/api/upload`|
|`method(only iOS)`|string|optional|HTTP method, values: [PUT,POST], default: POST|`POST`|
|`headers(only iOS)`|object|optional|HTTP headers|`{ 'Accept': 'application/json' }`|
|`params(iOS)`|object|optional|Query parameters|`{ 'user_id': 1  }`|
|`params(Android)`|object|optional|Query parameters|`{ 'user_id': '1'  }`<br> only support string value. You can't use int, boolean, etc..|
|`files`|array|required|Array of file objects to upload. See below.| `[{ name: 'file', filename: 'image1.png', filepath: 'assets-library://...', filetype: 'image/png' } ]` |

`callback` is a method with two parameters:

||type|description|example|
|---|---|---|---|
|error|string|String detailing the error|`A server with the specified hostname could not be found.`|
|response(iOS)|object{status:Number, data:String}|Object returned with a status code and data.|`{ status: 200, data: '{ success: true }' }`|
|response(Android)|String|String returned with responseBody.|`success: true`|


#### `files`
`files` is an array of objects with values:

||type|required|description|example|
|---|---|---|---|---|
|name|string|optional|Form parameter key for the specified file. If missing, will use `filename`.|`file[]`|
|filename|string|required|filename|`image1.png`|
|filepath|string|required|File URI<br>Supports `assets-library:`, `data:` and `file:` URIs and file paths.|`assets-library://...(iOS)`<br>`content://...(Android)`<br>`data:image/gif;base64,R0lGODlhEAAQAMQAAORHHOV...(only iOS)`<br>`file:/tmp/image1.png`<br>`/tmp/image1.png`|
|filetype|string|optional|MIME type of file. If missing, will infer based on the extension in `filepath`.|`image/png`|

### Progress (only support iOS)
To monitor upload progress simply subscribe to the `RNUploaderProgress` event using DeviceEventEmitter.

```
DeviceEventEmitter.addListener('RNUploaderProgress', (data)=>{
  let bytesWritten = data.totalBytesWritten;
  let bytesTotal   = data.totalBytesExpectedToWrite;
  let progress     = data.progress;
  
  console.log( "upload progress: " + progress + "%");
});
```

### Cancel (only support iOS)
To cancel an upload in progress:
```
RNUploader.cancel()
```

### Notes

Inspired by similiar projects:
* https://github.com/booxood/react-native-file-upload
* https://github.com/kamilkp/react-native-file-transfer

...with noteable enhancements:
* uploads are performed asynchronously on the native side
* progress reporting
* packaged as a static library
* support for multiple files at a time
* support for files from the assets library, base64 `data:` or `file:` paths 
* no external dependencies (ie: AFNetworking)
* support Android

## License

MIT
