# react-native-uploader
A React Native module for uploading files and camera roll assets. Supports progress notification.

## Install

### iOS
1. `npm install react-native-uploader --save`

2. Link the native modules:

If you're using React-Native >= 0.29:
* Link the library with the command `react-native link`

If you're using React-Native < 0.29:
* Install rnpm using the command `npm install -g rnpm`
* Link the library with the command `rnpm link`

If you have any issues, you can install the library manually:
* In XCode, in the project navigator, right click `Libraries` ➜ `Add Files to [your project's name]`
* Go to `node_modules` ➜ `react-native-uploader` ➜ `RNUploader` and add `RNUploader.xcodeproj`
* In XCode, in the project navigator, select your project. Add `libRNUploader.a` to your project's `Build Phases` ➜ `Link Binary With Libraries`

3. Run your project (`Cmd+R`)


## Example
See ./examples/UploadFromCameraRoll

![Example](https://raw.githubusercontent.com/aroth/react-native-uploader/master/examples/UploadFromCameraRoll/uploader.gif)


## Usage
```javascript
var RNUploader = require('NativeModules').RNUploader;

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
			filepath: "data:image/gif;base64,R0lGODlhEAAQAMQAAORHHOVSKudfOulrSOp3WOyDZu6QdvCchPGolfO0o/XBs/fNwfjZ0frl3/zy7////wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAkAABAALAAAAAAQABAAAAVVICSOZGlCQAosJ6mu7fiyZeKqNKToQGDsM8hBADgUXoGAiqhSvp5QAnQKGIgUhwFUYLCVDFCrKUE1lBavAViFIDlTImbKC5Gm2hB0SlBCBMQiB0UjIQA7",
			filetype: 'image/gif',
		},
	];

	let opts = {
		url: 'http://my.server/api/upload',
		files: files, 
		method: 'POST',                             // optional: POST or PUT
		headers: { 'Accept': 'application/json' },  // optional
		params: { 'user_id': 1 },                   // optional
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
	});
}

```

## API
#### RNUploader.upload( options, callback )

`options` is an object with values:

||type|required|description|example|
|---|---|---|---|---|
|`url`|string|required|URL to upload to|`http://my.server/api/upload`|
|`method`|string|optional|HTTP method, values: [PUT,POST], default: POST|`POST`|
|`headers`|object|optional|HTTP headers|`{ 'Accept': 'application/json' }`|
|`params`|object|optional|Query parameters|`{ 'user_id': 1  }`|
|`files`|array|required|Array of file objects to upload. See below.| `[{ name: 'file', filename: 'image1.png', filepath: 'assets-library://...', filetype: 'image/png' } ]` |

`callback` is a method with two parameters:

||type|description|example|
|---|---|---|---|
|error|string|String detailing the error|`A server with the specified hostname could not be found.`|
|response|object{status:Number, data:String}|Object returned with a status code and data.|`{ status: 200, data: '{ success: true }' }`|


#### `files`
`files` is an array of objects with values:

||type|required|description|example|
|---|---|---|---|---|
|name|string|optional|Form parameter key for the specified file. If missing, will use `filename`.|`file[]`|
|filename|string|required|filename|`image1.png`|
|filepath|string|required|File URI<br>Supports `assets-library:`, `data:` and `file:` URIs and file paths.|`assets-library://...`<br>`data:image/gif;base64,R0lGODlhEAAQAMQAAORHHOV...`<br>`file:/tmp/image1.png`<br>`/tmp/image1.png`|
|filetype|string|optional|MIME type of file. If missing, will infer based on the extension in `filepath`.|`image/png`|

### Progress
To monitor upload progress simply subscribe to the `RNUploaderProgress` event using DeviceEventEmitter.

```
DeviceEventEmitter.addListener('RNUploaderProgress', (data)=>{
  let bytesWritten = data.totalBytesWritten;
  let bytesTotal   = data.totalBytesExpectedToWrite;
  let progress     = data.progress;
  
  console.log( "upload progress: " + progress + "%");
});
```

### Cancel
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

## License

MIT
