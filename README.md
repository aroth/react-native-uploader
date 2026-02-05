# react-native-uploader

> **This package is no longer maintained and is not needed for modern React Native.**

## Deprecation Notice

This package was created in 2015 when React Native's networking capabilities were limited. File uploads with progress tracking required native code, and uploading from the camera roll was particularly challenging.

**Good news:** React Native has matured significantly. Everything this package does can now be accomplished with built-in React Native APIs. You no longer need a native module for file uploads.

---

## Modern React Native Alternatives

### Basic File Upload with Progress

Use `XMLHttpRequest` with the `upload.onprogress` event:

```typescript
const uploadFile = async (fileUri: string, uploadUrl: string) => {
  const formData = new FormData();

  formData.append('file', {
    uri: fileUri,
    type: 'image/jpeg',
    name: 'photo.jpg',
  } as unknown as Blob);  // React Native requires this cast

  return new Promise((resolve, reject) => {
    const xhr = new XMLHttpRequest();

    xhr.upload.onprogress = (event) => {
      if (event.lengthComputable) {
        const progress = Math.round((event.loaded / event.total) * 100);
        console.log(`Upload progress: ${progress}%`);
      }
    };

    xhr.onload = () => {
      if (xhr.status >= 200 && xhr.status < 300) {
        resolve(JSON.parse(xhr.responseText));
      } else {
        reject(new Error(`Upload failed with status ${xhr.status}`));
      }
    };

    xhr.onerror = () => reject(new Error('Upload failed'));

    xhr.open('POST', uploadUrl);
    xhr.setRequestHeader('Accept', 'application/json');
    xhr.send(formData);
  });
};
```

### Multiple File Upload with Progress

```typescript
interface FileToUpload {
  uri: string;
  type?: string;
  name?: string;
}

const uploadMultipleFiles = async (files: FileToUpload[], uploadUrl: string) => {
  const formData = new FormData();

  files.forEach((file, index) => {
    formData.append('files[]', {
      uri: file.uri,
      type: file.type || 'application/octet-stream',
      name: file.name || `file_${index}`,
    } as unknown as Blob);
  });

  // Add additional form fields
  formData.append('user_id', '123');

  return new Promise((resolve, reject) => {
    const xhr = new XMLHttpRequest();

    xhr.upload.onprogress = (event) => {
      if (event.lengthComputable) {
        const progress = Math.round((event.loaded / event.total) * 100);
        console.log(`Upload progress: ${progress}%`);
      }
    };

    xhr.onload = () => {
      if (xhr.status >= 200 && xhr.status < 300) {
        resolve(JSON.parse(xhr.responseText));
      } else {
        reject(new Error(`Upload failed with status ${xhr.status}`));
      }
    };

    xhr.onerror = () => reject(new Error('Upload failed'));

    xhr.open('POST', uploadUrl);
    xhr.setRequestHeader('Accept', 'application/json');
    xhr.send(formData);
  });
};
```

### Cancellable Upload

```typescript
const createCancellableUpload = (fileUri: string, uploadUrl: string) => {
  const xhr = new XMLHttpRequest();

  const promise = new Promise((resolve, reject) => {
    const formData = new FormData();
    formData.append('file', {
      uri: fileUri,
      type: 'image/jpeg',
      name: 'photo.jpg',
    } as unknown as Blob);

    xhr.upload.onprogress = (event) => {
      if (event.lengthComputable) {
        const progress = Math.round((event.loaded / event.total) * 100);
        console.log(`Upload progress: ${progress}%`);
      }
    };

    xhr.onload = () => {
      if (xhr.status >= 200 && xhr.status < 300) {
        resolve(JSON.parse(xhr.responseText));
      } else {
        reject(new Error(`Upload failed with status ${xhr.status}`));
      }
    };

    xhr.onerror = () => reject(new Error('Upload failed'));
    xhr.onabort = () => reject(new Error('Upload cancelled'));

    xhr.open('POST', uploadUrl);
    xhr.send(formData);
  });

  return {
    promise,
    cancel: () => xhr.abort(),
  };
};

// Usage
const upload = createCancellableUpload(fileUri, 'https://api.example.com/upload');

// To cancel:
upload.cancel();

// To await result:
const result = await upload.promise;
```

### Uploading from Camera Roll / Media Library

Use `expo-image-picker` or `react-native-image-picker` to get the file URI, then upload as shown above:

```javascript
import * as ImagePicker from 'expo-image-picker';

const pickAndUpload = async () => {
  const result = await ImagePicker.launchImageLibraryAsync({
    mediaTypes: ['images'],  // Use array syntax (MediaTypeOptions is deprecated)
    quality: 0.8,
  });

  if (!result.canceled) {
    const asset = result.assets[0];
    await uploadFile(asset.uri, 'https://api.example.com/upload');
  }
};
```

### Uploading Base64 Data

> **Warning:** Data URIs work on iOS but **do not work on Android**. On Android, you must write the base64 data to a temporary file first. See [GitHub issue #25790](https://github.com/facebook/react-native/issues/25790).

**iOS only (data URI):**

```typescript
// This works on iOS but NOT on Android
const uploadBase64iOS = async (
  base64Data: string,
  mimeType: string,
  uploadUrl: string
) => {
  const formData = new FormData();

  formData.append('file', {
    uri: `data:${mimeType};base64,${base64Data}`,
    type: mimeType,
    name: 'file.png',
  } as unknown as Blob);

  const response = await fetch(uploadUrl, {
    method: 'POST',
    body: formData,
  });

  return response.json();
};
```

**Cross-platform (write to temp file first):**

Using [expo-file-system](https://docs.expo.dev/versions/latest/sdk/filesystem/):

```typescript
// For Expo SDK 54+, use the legacy import for writeAsStringAsync
import * as FileSystem from 'expo-file-system/legacy';

const uploadBase64CrossPlatform = async (
  base64Data: string,
  mimeType: string,
  uploadUrl: string
) => {
  // Write base64 to a temporary file
  const tempUri = FileSystem.cacheDirectory + 'temp_upload.png';
  await FileSystem.writeAsStringAsync(tempUri, base64Data, {
    encoding: FileSystem.EncodingType.Base64,
  });

  const formData = new FormData();
  formData.append('file', {
    uri: tempUri,
    type: mimeType,
    name: 'file.png',
  } as unknown as Blob);

  try {
    const response = await fetch(uploadUrl, {
      method: 'POST',
      body: formData,
    });
    return response.json();
  } finally {
    // Clean up temp file
    await FileSystem.deleteAsync(tempUri, { idempotent: true });
  }
};
```

Or using [react-native-fs](https://github.com/itinance/react-native-fs):

```typescript
import RNFS from 'react-native-fs';

const uploadBase64CrossPlatform = async (
  base64Data: string,
  mimeType: string,
  uploadUrl: string
) => {
  const tempPath = `${RNFS.CachesDirectoryPath}/temp_upload.png`;
  await RNFS.writeFile(tempPath, base64Data, 'base64');

  const formData = new FormData();
  formData.append('file', {
    uri: `file://${tempPath}`,
    type: mimeType,
    name: 'file.png',
  } as unknown as Blob);

  try {
    const response = await fetch(uploadUrl, {
      method: 'POST',
      body: formData,
    });
    return response.json();
  } finally {
    await RNFS.unlink(tempPath).catch(() => {});
  }
};
```

### Using a Custom Hook

Here's a reusable hook that provides the same functionality:

```typescript
import { useState, useCallback, useRef } from 'react';

interface UploadFile {
  uri: string;
  type?: string;
  name?: string;
  fieldName?: string;
}

interface UploadOptions {
  method?: 'POST' | 'PUT';
  headers?: Record<string, string>;
  params?: Record<string, string>;
}

interface UploadResult {
  status: number;
  data: string;
}

export const useFileUpload = () => {
  const [progress, setProgress] = useState(0);
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState<Error | null>(null);
  const xhrRef = useRef<XMLHttpRequest | null>(null);

  const upload = useCallback(async (
    files: UploadFile | UploadFile[],
    url: string,
    options: UploadOptions = {}
  ): Promise<UploadResult> => {
    setUploading(true);
    setProgress(0);
    setError(null);

    const formData = new FormData();

    const fileArray = Array.isArray(files) ? files : [files];
    fileArray.forEach((file, index) => {
      formData.append(file.fieldName || 'file', {
        uri: file.uri,
        type: file.type || 'application/octet-stream',
        name: file.name || `file_${index}`,
      } as unknown as Blob);
    });

    // Add extra params
    if (options.params) {
      Object.entries(options.params).forEach(([key, value]) => {
        formData.append(key, value);
      });
    }

    return new Promise((resolve, reject) => {
      const xhr = new XMLHttpRequest();
      xhrRef.current = xhr;

      xhr.upload.onprogress = (event) => {
        if (event.lengthComputable) {
          const pct = Math.round((event.loaded / event.total) * 100);
          setProgress(pct);
        }
      };

      xhr.onload = () => {
        setUploading(false);
        xhrRef.current = null;

        if (xhr.status >= 200 && xhr.status < 300) {
          resolve({ status: xhr.status, data: xhr.responseText });
        } else {
          const err = new Error(`Upload failed: ${xhr.status}`);
          setError(err);
          reject(err);
        }
      };

      xhr.onerror = () => {
        setUploading(false);
        xhrRef.current = null;
        const err = new Error('Network error');
        setError(err);
        reject(err);
      };

      xhr.open(options.method || 'POST', url);

      if (options.headers) {
        Object.entries(options.headers).forEach(([key, value]) => {
          xhr.setRequestHeader(key, value);
        });
      }

      xhr.send(formData);
    });
  }, []);

  const cancel = useCallback(() => {
    if (xhrRef.current) {
      xhrRef.current.abort();
      xhrRef.current = null;
      setUploading(false);
    }
  }, []);

  return { upload, cancel, progress, uploading, error };
};

// Usage
import { View, Button, Text } from 'react-native';

const MyComponent = () => {
  const { upload, cancel, progress, uploading } = useFileUpload();

  const handleUpload = async () => {
    try {
      const result = await upload(
        { uri: 'file:///path/to/file.jpg', type: 'image/jpeg', name: 'photo.jpg' },
        'https://api.example.com/upload',
        {
          headers: { Authorization: 'Bearer token' },
          params: { user_id: '123' },
        }
      );
      console.log('Upload complete:', result);
    } catch (err) {
      console.error('Upload failed:', err);
    }
  };

  return (
    <View>
      <Button onPress={handleUpload} title="Upload" disabled={uploading} />
      {uploading && <Text>Progress: {progress}%</Text>}
      <Button onPress={cancel} title="Cancel" disabled={!uploading} />
    </View>
  );
};
```

---

## Known Issues & Compatibility Notes

### TypeScript Type Errors

React Native's FormData accepts a special object format `{ uri, type, name }` for file uploads, but TypeScript's standard FormData types don't recognize this pattern. You'll see errors like:

```
Argument of type '{ uri: string; type: string; name: string; }' is not assignable to parameter of type 'string | Blob'
```

**Workaround:** Cast the file object:

```typescript
formData.append('file', {
  uri: fileUri,
  type: 'image/jpeg',
  name: 'photo.jpg',
} as unknown as Blob);
```

### Android: Data URIs Not Supported

FormData on Android does not support `data:` URIs (base64 encoded data). You'll get an error like:

```
Could not retrieve file for uri data:image/png;base64,iVBO...
```

**Solution:** Write base64 data to a temporary file first, then use the file path. See the "Uploading Base64 Data" section above for a cross-platform example.

Reference: [GitHub issue #25790](https://github.com/facebook/react-native/issues/25790)

### React Native 0.74 - 0.76 FormData Bug

React Native versions 0.74 through 0.76 have a bug where file uploads may fail with "Failed to parse body as FormData" errors. This is due to an invalid `filename*` directive being added to the Content-Disposition header.

**Solutions:**
- Upgrade to React Native 0.77+ (recommended)
- Use a [custom FormData class](https://emreloper.dev/blog/react-native-0-74-plus-and-failing-to-parse-body-as-formdata) that removes the problematic directive

---

## Third-Party Libraries (If You Prefer)

If you'd rather use a maintained library:

- **[react-native-blob-util](https://github.com/RonRadtke/react-native-blob-util)** - Comprehensive file system and networking library with upload progress
- **[axios](https://axios-http.com/)** - Popular HTTP client that works with React Native and supports upload progress via `onUploadProgress`
- **[rn-fetch-blob](https://github.com/joltup/rn-fetch-blob)** - Fork of react-native-fetch-blob with active maintenance

---

## Original Documentation

<details>
<summary>Click to expand original documentation (for historical reference)</summary>

### Install (iOS only)

1. `npm install react-native-uploader --save`

2. Link the native modules:

If you're using React-Native >= 0.29:
* Link the library with the command `react-native link`

If you're using React-Native < 0.29:
* Install rnpm using the command `npm install -g rnpm`
* Link the library with the command `rnpm link`

### Usage

```javascript
import { NativeModules, DeviceEventEmitter } from 'react-native';

const RNUploader = NativeModules.RNUploader;

// Listen for progress
DeviceEventEmitter.addListener('RNUploaderProgress', (data) => {
  console.log(`Upload progress: ${data.progress}%`);
});

// Upload files
const files = [
  {
    name: 'file[]',
    filename: 'image1.png',
    filepath: 'assets-library://....',
    filetype: 'image/png',
  },
];

const opts = {
  url: 'http://my.server/api/upload',
  files: files,
  method: 'POST',
  headers: { 'Accept': 'application/json' },
  params: { 'user_id': 1 },
};

RNUploader.upload(opts, (err, response) => {
  if (err) {
    console.log(err);
    return;
  }
  console.log('Upload complete with status ' + response.status);
});

// Cancel upload
RNUploader.cancel();
```

### Features (circa 2015)

- Asynchronous uploads on the native side
- Progress reporting
- Support for multiple files
- Support for assets library, base64 data, and file paths
- No external dependencies

</details>

---

## License

MIT

## Thank You

Thanks to everyone who used and contributed to this package over the years. It served its purpose well, and now React Native has caught up. Happy coding!
