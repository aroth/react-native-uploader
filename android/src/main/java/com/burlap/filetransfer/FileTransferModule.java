package com.burlap.filetransfer;

import android.app.DownloadManager;
import android.content.Context;
import android.database.Cursor;
import android.provider.MediaStore;
import android.util.Log;
import android.net.Uri;

import com.facebook.react.bridge.NativeModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.ReadableMapKeySetIterator;
import com.facebook.react.bridge.ReadableType;

import org.json.*;

import java.util.Map;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.FileNotFoundException;
import java.util.HashMap;

import okhttp3.MediaType;
import okhttp3.MultipartBody;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.RequestBody;
import okhttp3.Response;


public class FileTransferModule extends ReactContextBaseJavaModule {

  private final OkHttpClient client = new OkHttpClient();

  private static String siteUrl = "http://joinbevy.com";
  private static String apiUrl = "http://api.joinbevy.com";
  private static Integer port = 80;

  private String TAG = "ImageUploadAndroid";

  public FileTransferModule(ReactApplicationContext reactContext) {
    super(reactContext);
  }

  @Override
  public String getName() {
    // match up with the IOS name
    return "FileTransfer";
  }

  @ReactMethod
  public void upload(ReadableMap options, Callback complete) {

    final Callback completeCallback = complete;

    try {
      MultipartBody.Builder mRequestBody = new MultipartBody.Builder()
              .setType(MultipartBody.FORM);

      ReadableArray files = options.getArray("files");
      String url = options.getString("url");

      if(options.hasKey("params")){
        ReadableMap data = options.getMap("params");
        ReadableMapKeySetIterator iterator = data.keySetIterator();

        while(iterator.hasNextKey()){
          String key = iterator.nextKey();
          if(ReadableType.String.equals(data.getType(key))) {
            mRequestBody.addFormDataPart(key, data.getString(key));
          }
        }
      }




      if(files.size() != 0){
        for(int fileIndex=0 ; fileIndex<files.size(); fileIndex++){
          ReadableMap file = files.getMap(fileIndex);
          String uri = file.getString("filepath");

          Uri file_uri;
          if(uri.substring(0,10).equals("content://") ){
            file_uri = Uri.parse(convertMediaUriToPath(Uri.parse(uri)));
          }
          else{
            file_uri = Uri.parse(uri);
          }

          File imageFile = new File(file_uri.getPath());

          if(imageFile == null){
            Log.d(TAG, "FILE NOT FOUND");
            completeCallback.invoke("FILE NOT FOUND", null);
              return;
          }

          String mimeType = "image/png";
          if(file.hasKey("filetype")){
            mimeType = file.getString("filetype");
          }
          MediaType mediaType = MediaType.parse(mimeType);
          String fileName = file.getString("filename");
          String name = fileName;
          if(file.hasKey("name")){
            name = file.getString("name");
          }
          

          mRequestBody.addFormDataPart(name, fileName, RequestBody.create(mediaType, imageFile));
        }
      }



        MultipartBody requestBody = mRequestBody.build();
        Request request = new Request.Builder()
                .header("Accept", "application/json")
                .url(url)
                .post(requestBody)
                .build();

        Response response = client.newCall(request).execute();
        if (!response.isSuccessful()) {
            Log.d(TAG, "Unexpected code" + response);
            completeCallback.invoke(response, null);
            return;
        }

        completeCallback.invoke(null, response.body().string());
    } catch(Exception e) {
      Log.d(TAG, e.toString());
    }
  }

   public String convertMediaUriToPath(Uri uri) {
    Context context = getReactApplicationContext();
    String [] proj={MediaStore.Images.Media.DATA};
    Cursor cursor = context.getContentResolver().query(uri, proj,  null, null, null);
    int column_index = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATA);
    cursor.moveToFirst();
    String path = cursor.getString(column_index);
    cursor.close();
    return path;
  }
}
