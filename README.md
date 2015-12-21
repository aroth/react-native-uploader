# react-native-uploader
A React Native module for uploading files and camera roll assets. Supports progress notification.

## Install

### iOS
1. `npm install react-native-uploader --save`
2. In XCode, in the project navigator, right click `Libraries` ➜ `Add Files to [your project's name]`
3. Go to `node_modules` ➜ `react-native-uploader` ➜ `RNUploader` and add `RNUploader.xcodeproj`
4. In XCode, in the project navigator, select your project. Add `libRNUploader.a` to your project's `Build Phases` ➜ `Link Binary With Libraries`
5. Run your project (`Cmd+R`)

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
			filename: 'image2.png',
			filepath: "data:image/gif;base64,R0lGODlhEAAQAMQAAORHHOVSKudfOulrSOp3WOyDZu6QdvCchPGolfO0o/XBs/fNwfjZ0frl3/zy7////wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAkAABAALAAAAAAQABAAAAVVICSOZGlCQAosJ6mu7fiyZeKqNKToQGDsM8hBADgUXoGAiqhSvp5QAnQKGIgUhwFUYLCVDFCrKUE1lBavAViFIDlTImbKC5Gm2hB0SlBCBMQiB0UjIQA7",
			filetype: 'image/png',
		},
	];

	let opts = {
		url: 'http://my.server/api/upload',
		files: files, 
		method: 'POST',                             // optional: POST or PUT
		headers: { 'Accept': 'application/json' },  // optional
		params: { 'user_id': 1 },                   // optional
	};

	RNUploader.upload( opts, ( err, res )=>{
		if( err ){
			console.log(err);
			return;
		}
  
		let status = res.status;
		let responseString = res.data;
		let json = JSON.parse( responseString );

		console.log('upload complete with status ' + status);
	});
}

```

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
