#import <AssetsLibrary/AssetsLibrary.h>
#import <Foundation/Foundation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <UIKit/UIKit.h>

#import <React/RCTBridgeModule.h>
#import <React/RCTEventDispatcher.h>
#import <React/RCTLog.h>

@interface RNUploader : NSObject <RCTBridgeModule, NSURLConnectionDelegate, NSURLConnectionDataDelegate>
    @property NSMutableData *responseData;
    @property NSInteger responseStatusCode;

    @property NSURLConnection *connection;
    @property NSMutableURLRequest *request;
    @property NSMutableData *requestBody;
    @property NSMutableArray *files;

    @property NSString *formBoundaryString;
    @property NSData *formBoundaryData;

    @property dispatch_group_t fgroup;
@end

@implementation RNUploader

@synthesize bridge = _bridge;
RCTResponseSenderBlock _callback;


RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(cancel){
    [self.connection cancel];
}

RCT_EXPORT_METHOD(upload:(NSDictionary *)obj callback:(RCTResponseSenderBlock)callback)
{
    _callback = callback;

    NSString *uploadURL   = obj[@"url"];
    NSDictionary *headers = obj[@"headers"];
    NSDictionary *params  = obj[@"params"];
    NSArray *files        = obj[@"files"];
    NSString *method      = obj[@"method"];

    NSURL *url = [NSURL URLWithString:uploadURL];

    self.formBoundaryString = [self generateBoundaryString];
    self.formBoundaryData   = [[NSString stringWithFormat:@"--%@\r\n", self.formBoundaryString] dataUsingEncoding:NSUTF8StringEncoding];

    self.request      = [NSMutableURLRequest requestWithURL:url];
    self.responseData = [[NSMutableData alloc] init];
    self.requestBody  = [[NSMutableData alloc] init];
    self.files        = [[NSMutableArray alloc] init];
    self.fgroup       = dispatch_group_create();

    [self setMethod:method];
    [self setHeaders:headers];
    [self setParams:params];
    [self prepareFiles:files];

    dispatch_group_notify(self.fgroup, dispatch_get_main_queue(), ^{
        [self appendFiles];
        [self sendRequest];
    });
}

//
// Action Methods
//

- (void)setMethod:(NSString *)method {
    if( [method isEqualToString:@"POST"] || [method isEqualToString:@"PUT"] ){
        [self.request setHTTPMethod:method];
    }else{
        [self.request setHTTPMethod:@"POST"];
    }
}

- (void)setHeaders:(NSDictionary *)headers {
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", self.formBoundaryString];
    [self.request setValue:contentType forHTTPHeaderField:@"Content-Type"];
    for (NSString *key in headers) {
        id val = [headers objectForKey:key];
        if ([val respondsToSelector:@selector(stringValue)]) {
            val = [val stringValue];
        }
        if (![val isKindOfClass:[NSString class]]) {
            continue;
        }
        [self.request setValue:val forHTTPHeaderField:key];
    }
}

- (void)setParams:(NSDictionary *)params {
    for (NSString *key in params) {
        id value = [params objectForKey:key];
        if ([value respondsToSelector:@selector(stringValue)]) {
            value = [value stringValue];
        }
        //
        // TODO: handle objects
        //
        if (![value isKindOfClass:[NSString class]]) {
            continue;
        }

        [self.requestBody appendData:self.formBoundaryData];
        [self.requestBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
        [self.requestBody appendData:[value dataUsingEncoding:NSUTF8StringEncoding]];
        [self.requestBody appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }
}

- (void)prepareFiles:(NSArray *)files {
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];

    for (NSDictionary *file in files) {
        dispatch_group_enter(self.fgroup);

        NSMutableDictionary *_file = [[NSMutableDictionary alloc] initWithDictionary:file];
        [self.files addObject:_file];

        if( [_file[@"filepath"] hasPrefix:@"assets-library:"]) {
            NSURL *assetURL = [[NSURL alloc] initWithString:file[@"filepath"]];

            [library assetForURL:assetURL resultBlock:^(ALAsset *asset) {


                ALAssetRepresentation *representation = [asset defaultRepresentation];

                    NSString *fileName = [representation filename];
                    //Getting MIMEType
                    NSString *MIMEType = (__bridge_transfer NSString*)UTTypeCopyPreferredTagWithClass
                    ((__bridge CFStringRef)[representation UTI], kUTTagClassMIMEType);


                ALAssetRepresentation *rep = [asset defaultRepresentation];

                //testing RegExp (video|image)
                if([MIMEType rangeOfString:@"video" options:NSRegularExpressionSearch].location != NSNotFound){

                    //buffering output
                    Byte *buffer = (Byte*)malloc((NSUInteger)rep.size);
                    NSUInteger buffered = [rep getBytes:buffer fromOffset:0.0 length:(NSUInteger)rep.size error:nil];
                    NSData *data = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES];
                    
                    _file[@"data"] = data;

                }else if([MIMEType rangeOfString:@"image" options:NSRegularExpressionSearch].location != NSNotFound){

                    CGImageRef fullScreenImageRef = [rep fullScreenImage];
                    UIImage *image = [UIImage imageWithCGImage:fullScreenImageRef];

                    _file[@"data"] = UIImagePNGRepresentation(image);
                }

                dispatch_group_leave(self.fgroup);

            } failureBlock:^(NSError *error) {
                NSLog(@"Getting file from library failed: %@", error);
                dispatch_group_leave(self.fgroup);
            }];


        }else{
            NSString *filepath = _file[@"filepath"];
            NSURL *fileUrl = [[NSURL alloc] initWithString:filepath];

            if ( [filepath hasPrefix:@"data:"] || [filepath hasPrefix:@"file:"]) {
                _file[@"data"] = [NSData dataWithContentsOfURL: fileUrl];
            } else {
                _file[@"data"] = [NSData dataWithContentsOfFile:filepath];
            }

            dispatch_group_leave(self.fgroup);
        }
    }

}

- (void)appendFiles {
    for( NSMutableDictionary *file in self.files ){
        NSString *name     = file[@"name"];
        NSString *filename = file[@"filename"];
        NSString *filetype = file[@"filetype"];
        NSData *data       = file[@"data"];

        [self.requestBody appendData:self.formBoundaryData];
        [self.requestBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", name.length ? name : filename, filename] dataUsingEncoding:NSUTF8StringEncoding]];

        if (filetype) {
            [self.requestBody appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n", filetype] dataUsingEncoding:NSUTF8StringEncoding]];
        } else {
            [self.requestBody appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n", [self mimeTypeForPath:filename]] dataUsingEncoding:NSUTF8StringEncoding]];
        }

        [self.requestBody appendData:[[NSString stringWithFormat:@"Content-Length: %ld\r\n\r\n", (long)[data length]] dataUsingEncoding:NSUTF8StringEncoding]];
        [self.requestBody appendData:data];
        [self.requestBody appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }
}

- (void)sendRequest {
    NSData *endData = [[NSString stringWithFormat:@"--%@--\r\n", self.formBoundaryString] dataUsingEncoding:NSUTF8StringEncoding];

    [self.requestBody appendData:endData];
    [self.request setHTTPBody:self.requestBody];

    // upload
    self.connection = [[NSURLConnection alloc] initWithRequest:self.request delegate:self startImmediately:NO];
    [self.connection scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [self.connection start];
}

//
// Helpers
//

- (NSString *)generateBoundaryString
{
    NSString *uuid = [[NSUUID UUID] UUIDString];
    NSString *boundaryString = [NSString stringWithFormat:@"----%@", uuid];
    return boundaryString;
}

- (NSString *)mimeTypeForPath:(NSString *)filepath
{
    NSString *fileExtension = [filepath pathExtension];
    NSString *UTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)fileExtension, NULL);
    NSString *contentType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI, kUTTagClassMIMEType);

    if (!contentType) {
        contentType = @"application/octet-stream";
    }

    return contentType;
}

//
// Delegate Methods
//

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self.bridge.eventDispatcher sendDeviceEventWithName:@"RNUploaderDidFailWithError" body:[error localizedDescription]];
    _callback(@[[error localizedDescription], [NSNull null]]);
}

#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [self.bridge.eventDispatcher sendDeviceEventWithName:@"RNUploaderDidReceiveResponse" body:nil];
    self.responseStatusCode = [(NSHTTPURLResponse *)response statusCode];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    NSString *resString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [self.bridge.eventDispatcher sendDeviceEventWithName:@"RNUploaderDidReceiveData" body:resString];
    [self.responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSString *responseString = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
    [self.bridge.eventDispatcher sendDeviceEventWithName:@"RNUploaderDataFinishLoading" body:responseString];

    NSDictionary *res= [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInteger:self.responseStatusCode],@"status",responseString,@"data",nil];

    _callback(@[[NSNull null], res]);
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
    NSNumber *progress = @([@(totalBytesWritten) floatValue]/[@(totalBytesExpectedToWrite) floatValue] * 100.0);
    [self.bridge.eventDispatcher sendDeviceEventWithName:@"RNUploaderProgress"
                                                    body:@{ @"totalBytesWritten": @(totalBytesWritten),
                                                            @"totalBytesExpectedToWrite": @(totalBytesExpectedToWrite),
                                                            @"progress": progress }];
}

@end
