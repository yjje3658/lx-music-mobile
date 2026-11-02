#import <React/RCTBridgeModule.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <Foundation/Foundation.h>

@interface LMMModule : NSObject <RCTBridgeModule>
@end

@implementation LMMModule

RCT_EXPORT_MODULE(LocalMediaMetadata);

+ (BOOL)requiresMainQueueSetup { return NO; }

RCT_EXPORT_METHOD(readMetadata:(NSString *)filePath resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  NSURL *url = [NSURL fileURLWithPath:filePath];
  AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:@{AVURLAssetPreferPreciseDurationAndTimingKey: @YES}];
  [asset loadValuesAsynchronouslyForKeys:@[@"commonMetadata", @"duration", @"estimatedBitrate"] completionHandler:^{
    NSString *title = nil, *artist = nil, *album = nil;
    for (NSString *format in [asset availableMetadataFormats]) {
      for (AVMetadataItem *item in [asset metadataForFormat:format]) {
        NSString *key = item.commonKey;
        if ([key isEqualToString:AVMetadataCommonKeyTitle]) title = item.stringValue;
        else if ([key isEqualToString:AVMetadataCommonKeyArtist]) artist = item.stringValue;
        else if ([key isEqualToString:AVMetadataCommonKeyAlbumName]) album = item.stringValue;
      }
    }
    NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
    NSString *ext = [filePath pathExtension];
    CMTime duration = asset.duration;
    NSNumber *interval = CMTIME_IS_NUMERIC(duration) ? @(CMTimeGetSeconds(duration)) : @0;
    NSNumber *bitrate = @(asset.estimatedBitrate);
    resolve(@{
      @"type": ext ?: @"",
      @"bitrate": bitrate ? [bitrate stringValue] : @"",
      @"interval": interval,
      @"size": attrs[NSFileSize] ?: @0,
      @"ext": ext ?: @"",
      @"albumName": album ?: @"",
      @"singer": artist ?: @"",
      @"name": title ?: [filePath lastPathComponent] ?: @"",
    });
  }];
}

RCT_EXPORT_METHOD(writeMetadata:(NSString *)filePath metadata:(NSDictionary *)metadata isOverwrite:(BOOL)isOverwrite resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  // iOS 写音频内嵌元数据需要 AVAssetExportSession 重封装，暂不实现（不崩即可）
  resolve(nil);
}

RCT_EXPORT_METHOD(readPic:(NSString *)filePath picDir:(NSString *)picDir resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  NSURL *url = [NSURL fileURLWithPath:filePath];
  AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
  [asset loadValuesAsynchronouslyForKeys:@[@"commonMetadata"] completionHandler:^{
    NSData *artwork = nil;
    for (AVMetadataItem *item in [asset commonMetadata]) {
      if (![item.commonKey isEqualToString:AVMetadataCommonKeyArtwork]) continue;
      id value = item.value;
      if ([value isKindOfClass:[NSData class]]) {
        artwork = value;
      } else if ([value isKindOfClass:[NSDictionary class]]) {
        id data = [(NSDictionary *)value objectForKey:@"data"];
        if ([data isKindOfClass:[NSData class]]) artwork = data;
      }
      if (artwork) break;
    }
    if (!artwork) { resolve(@""); return; }
    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:picDir withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *name = [[[filePath lastPathComponent] stringByDeletingPathExtension] stringByAppendingString:@"_cover.jpg"];
    NSString *outPath = [picDir stringByAppendingPathComponent:name];
    BOOL ok = [artwork writeToFile:outPath options:NSDataWritingAtomic error:&error];
    if (ok) resolve(outPath);
    else reject(@"readPic_failed", error.localizedDescription ?: @"write pic failed", error);
  }];
}

RCT_EXPORT_METHOD(writePic:(NSString *)filePath picPath:(NSString *)picPath resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  // iOS 写封面需要重封装，暂不实现（不崩即可）
  resolve(nil);
}

RCT_EXPORT_METHOD(readLyric:(NSString *)filePath isReadLrcFile:(BOOL)isReadLrcFile resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  if (isReadLrcFile) {
    NSString *lrcPath = [[filePath stringByDeletingPathExtension] stringByAppendingPathExtension:@"lrc"];
    NSString *content = [NSString stringWithContentsOfFile:lrcPath encoding:NSUTF8StringEncoding error:nil];
    resolve(content ?: @"");
    return;
  }
  resolve(@"");
}

RCT_EXPORT_METHOD(writeLyric:(NSString *)filePath lyric:(NSString *)lyric resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  // iOS 写内嵌歌词需要重封装，暂不实现（不崩即可）
  resolve(nil);
}

@end
