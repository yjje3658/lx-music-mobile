#import <React/RCTBridgeModule.h>
#import <React/RCTConvert.h>
#import <CommonCrypto/CommonDigest.h>
#import <zlib.h>
#import <Foundation/Foundation.h>

@interface RNFSModule : NSObject <RCTBridgeModule>
@end

@implementation RNFSModule

RCT_EXPORT_MODULE(FileSystemModule);

+ (BOOL)requiresMainQueueSetup { return NO; }

- (NSDictionary *)constantsToExport {
  NSString *cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
  NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
  NSString *mainBundle = [[NSBundle mainBundle] bundlePath];
  return @{
    @"CacheDir": cacheDir ?: @"",
    @"DocumentDir": docDir ?: @"",
    @"MainBundleDir": mainBundle ?: @"",
    @"SDCardDir": docDir ?: @"", // iOS 无 SD 卡，映射到 Documents
  };
}

#pragma mark - FileType helper

- (NSDictionary *)fileTypeForPath:(NSString *)path {
  NSFileManager *fm = [NSFileManager defaultManager];
  NSDictionary *attrs = [fm attributesOfItemAtPath:path error:nil];
  BOOL isDir = NO;
  [fm fileExistsAtPath:path isDirectory:&isDir];
  NSDate *modDate = attrs[NSFileModificationDate];
  return @{
    @"name": [path lastPathComponent] ?: @"",
    @"path": path,
    @"isDirectory": @(isDir),
    @"isFile": @(!isDir),
    @"lastModified": modDate ? @([modDate timeIntervalSince1970] * 1000) : @0,
    @"canRead": @([fm isReadableFileAtPath:path]),
    @"data": @"",
    @"mimeType": @"",
    @"size": attrs[NSFileSize] ?: @0,
  };
}

#pragma mark - Files

RCT_EXPORT_METHOD(cp:(NSString *)source target:(NSString *)target resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  NSError *error = nil;
  BOOL ok = [[NSFileManager defaultManager] copyItemAtPath:source toPath:target error:&error];
  if (ok) resolve(@(YES)); else reject(@"cp_failed", error.localizedDescription ?: @"copy failed", error);
}

RCT_EXPORT_METHOD(exists:(NSString *)path resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  resolve(@([[NSFileManager defaultManager] fileExistsAtPath:path]));
}

RCT_EXPORT_METHOD(ls:(NSString *)path resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  NSError *error = nil;
  NSArray *names = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&error];
  if (error) { reject(@"ls_failed", error.localizedDescription, error); return; }
  NSMutableArray *result = [NSMutableArray array];
  for (NSString *name in names) {
    [result addObject:[self fileTypeForPath:[path stringByAppendingPathComponent:name]]];
  }
  resolve(result);
}

RCT_EXPORT_METHOD(mkdir:(NSString *)path resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  NSError *error = nil;
  BOOL ok = [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
  if (ok) resolve([self fileTypeForPath:path]); else reject(@"mkdir_failed", error.localizedDescription, error);
}

RCT_EXPORT_METHOD(mv:(NSString *)source target:(NSString *)target resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  NSError *error = nil;
  BOOL ok = [[NSFileManager defaultManager] moveItemAtPath:source toPath:target error:&error];
  if (ok) resolve(@(YES)); else reject(@"mv_failed", error.localizedDescription, error);
}

RCT_EXPORT_METHOD(rename:(NSString *)source name:(NSString *)name resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  NSString *target = [[source stringByDeletingLastPathComponent] stringByAppendingPathComponent:name];
  NSError *error = nil;
  BOOL ok = [[NSFileManager defaultManager] moveItemAtPath:source toPath:target error:&error];
  if (ok) resolve(@(YES)); else reject(@"rename_failed", error.localizedDescription, error);
}

RCT_EXPORT_METHOD(readFile:(NSString *)path encoding:(NSString *)encoding resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  NSError *error = nil;
  NSData *data = [NSData dataWithContentsOfFile:path options:0 error:&error];
  if (!data) { reject(@"read_failed", error.localizedDescription, error); return; }
  BOOL isBase64 = [encoding isEqualToString:@"base64"];
  NSString *result = isBase64
    ? [data base64EncodedStringWithOptions:0]
    : [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  if (!result) { reject(@"read_failed", @"cannot decode file", nil); return; }
  resolve(result);
}

RCT_EXPORT_METHOD(stat:(NSString *)path resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
    reject(@"stat_failed", @"file not exist", nil); return;
  }
  resolve([self fileTypeForPath:path]);
}

RCT_EXPORT_METHOD(unlink:(NSString *)path resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  NSError *error = nil;
  BOOL ok = [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
  if (ok) resolve(@(YES)); else reject(@"unlink_failed", error.localizedDescription, error);
}

RCT_EXPORT_METHOD(writeFile:(NSString *)path data:(NSString *)data encoding:(NSString *)encoding resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  NSData *fileData = [encoding isEqualToString:@"base64"]
    ? [[NSData alloc] initWithBase64EncodedString:data options:0]
    : [data dataUsingEncoding:NSUTF8StringEncoding];
  NSError *error = nil;
  BOOL ok = [fileData writeToFile:path options:NSDataWritingAtomic error:&error];
  if (ok) resolve(nil); else reject(@"write_failed", error.localizedDescription, error);
}

RCT_EXPORT_METHOD(appendFile:(NSString *)path data:(NSString *)data encoding:(NSString *)encoding resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  NSData *append = [encoding isEqualToString:@"base64"]
    ? [[NSData alloc] initWithBase64EncodedString:data options:0]
    : [data dataUsingEncoding:NSUTF8StringEncoding];
  NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:path];
  if (!handle) {
    NSError *error = nil;
    BOOL ok = [append writeToFile:path options:NSDataWritingAtomic error:&error];
    if (ok) resolve(nil); else reject(@"append_failed", error.localizedDescription, error);
    return;
  }
  [handle seekToEndOfFile];
  [handle writeData:append];
  [handle closeFile];
  resolve(nil);
}

#pragma mark - Gzip

- (NSData *)gzipCompress:(NSData *)input {
  if (input.length == 0) return input;
  z_stream strm;
  memset(&strm, 0, sizeof(strm));
  strm.zalloc = Z_NULL; strm.zfree = Z_NULL;
  if (deflateInit2(&strm, Z_DEFAULT_COMPRESSION, Z_DEFLATED, 15 + 16, 8, Z_DEFAULT_STRATEGY) != Z_OK) return nil;
  size_t bound = deflateBound(&strm, input.length);
  NSMutableData *output = [NSMutableData dataWithLength:bound];
  strm.next_in = (Bytef *)input.bytes;
  strm.avail_in = (uInt)input.length;
  strm.next_out = output.mutableBytes;
  strm.avail_out = (uInt)bound;
  int ret = deflate(&strm, Z_FINISH);
  if (ret != Z_STREAM_END) { deflateEnd(&strm); return nil; }
  [output setLength:strm.total_out];
  deflateEnd(&strm);
  return output;
}

- (NSData *)gzipDecompress:(NSData *)input {
  if (input.length == 0) return input;
  z_stream strm;
  memset(&strm, 0, sizeof(strm));
  strm.zalloc = Z_NULL; strm.zfree = Z_NULL;
  if (inflateInit2(&strm, 15 + 32) != Z_OK) return nil; // 15+32 自动识别 gzip/zlib
  strm.next_in = (Bytef *)input.bytes;
  strm.avail_in = (uInt)input.length;
  NSMutableData *output = [NSMutableData data];
  Bytef buffer[16384];
  int ret;
  do {
    strm.next_out = buffer;
    strm.avail_out = sizeof(buffer);
    ret = inflate(&strm, Z_NO_FLUSH);
    if (ret != Z_OK && ret != Z_STREAM_END) { inflateEnd(&strm); return nil; }
    [output appendBytes:buffer length:(sizeof(buffer) - strm.avail_out)];
  } while (ret != Z_STREAM_END);
  inflateEnd(&strm);
  return output;
}

RCT_EXPORT_METHOD(gzipFile:(NSString *)source target:(NSString *)target resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  NSData *input = [NSData dataWithContentsOfFile:source];
  if (!input) { reject(@"gzip_failed", @"read source failed", nil); return; }
  NSData *output = [self gzipCompress:input];
  if (!output) { reject(@"gzip_failed", @"compress failed", nil); return; }
  NSError *error = nil;
  BOOL ok = [output writeToFile:target options:NSDataWritingAtomic error:&error];
  if (ok) resolve(nil); else reject(@"gzip_failed", error.localizedDescription, error);
}

RCT_EXPORT_METHOD(unGzipFile:(NSString *)source target:(NSString *)target resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  NSData *input = [NSData dataWithContentsOfFile:source];
  if (!input) { reject(@"ungzip_failed", @"read source failed", nil); return; }
  NSData *output = [self gzipDecompress:input];
  if (!output) { reject(@"ungzip_failed", @"decompress failed", nil); return; }
  NSError *error = nil;
  BOOL ok = [output writeToFile:target options:NSDataWritingAtomic error:&error];
  if (ok) resolve(nil); else reject(@"ungzip_failed", error.localizedDescription, error);
}

RCT_EXPORT_METHOD(gzipString:(NSString *)data encoding:(NSString *)encoding resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  NSData *input = [encoding isEqualToString:@"base64"]
    ? [[NSData alloc] initWithBase64EncodedString:data options:0]
    : [data dataUsingEncoding:NSUTF8StringEncoding];
  if (!input) { reject(@"gzip_failed", @"encode failed", nil); return; }
  NSData *output = [self gzipCompress:input];
  if (!output) { reject(@"gzip_failed", @"compress failed", nil); return; }
  resolve([output base64EncodedStringWithOptions:0]);
}

RCT_EXPORT_METHOD(unGzipString:(NSString *)data encoding:(NSString *)encoding resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  NSData *input = [[NSData alloc] initWithBase64EncodedString:data options:0];
  if (!input) { reject(@"ungzip_failed", @"decode failed", nil); return; }
  NSData *output = [self gzipDecompress:input];
  if (!output) { reject(@"ungzip_failed", @"decompress failed", nil); return; }
  BOOL isBase64 = [encoding isEqualToString:@"base64"];
  NSString *result = isBase64
    ? [output base64EncodedStringWithOptions:0]
    : [[NSString alloc] initWithData:output encoding:NSUTF8StringEncoding];
  if (!result) { reject(@"ungzip_failed", @"cannot decode", nil); return; }
  resolve(result);
}

#pragma mark - Hash

RCT_EXPORT_METHOD(hash:(NSString *)path algorithm:(NSString *)algorithm resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  NSData *data = [NSData dataWithContentsOfFile:path];
  if (!data) { reject(@"hash_failed", @"read file failed", nil); return; }
  unsigned char digest[CC_SHA512_DIGEST_LENGTH];
  unsigned int len = 0;
  if ([algorithm isEqualToString:@"md5"]) { CC_MD5(data.bytes, (CC_LONG)data.length, digest); len = CC_MD5_DIGEST_LENGTH; }
  else if ([algorithm isEqualToString:@"sha1"]) { CC_SHA1(data.bytes, (CC_LONG)data.length, digest); len = CC_SHA1_DIGEST_LENGTH; }
  else if ([algorithm isEqualToString:@"sha224"]) { CC_SHA224(data.bytes, (CC_LONG)data.length, digest); len = CC_SHA224_DIGEST_LENGTH; }
  else if ([algorithm isEqualToString:@"sha256"]) { CC_SHA256(data.bytes, (CC_LONG)data.length, digest); len = CC_SHA256_DIGEST_LENGTH; }
  else if ([algorithm isEqualToString:@"sha384"]) { CC_SHA384(data.bytes, (CC_LONG)data.length, digest); len = CC_SHA384_DIGEST_LENGTH; }
  else if ([algorithm isEqualToString:@"sha512"]) { CC_SHA512(data.bytes, (CC_LONG)data.length, digest); len = CC_SHA512_DIGEST_LENGTH; }
  else { reject(@"hash_failed", @"unsupported algorithm", nil); return; }
  NSMutableString *hex = [NSMutableString string];
  for (unsigned int i = 0; i < len; i++) [hex appendFormat:@"%02x", digest[i]];
  resolve(hex);
}

#pragma mark - Android-only stubs (iOS 不调用，防 JS 崩)

RCT_EXPORT_METHOD(getAllExternalStoragePaths:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  resolve(@[]);
}
RCT_EXPORT_METHOD(getExternalStoragePaths:(BOOL)isRemovable resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  resolve(@[]);
}
RCT_EXPORT_METHOD(getPersistedUriPermissions:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  resolve(@[]);
}
RCT_EXPORT_METHOD(releasePersistableUriPermission:(NSString *)path resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  resolve(nil);
}
RCT_EXPORT_METHOD(openDocumentTree:(BOOL)isPersist resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  reject(@"unsupported", @"openDocumentTree is Android only", nil);
}
RCT_EXPORT_METHOD(openDocument:(NSDictionary *)options resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  reject(@"unsupported", @"openDocument is Android only", nil);
}

@end
