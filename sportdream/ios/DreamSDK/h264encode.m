//
//  h264encode.m
//  sportdream
//
//  Created by lili on 2017/12/24.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "h264encode.h"
#import <VideoToolbox/VideoToolbox.h>

@interface h264encode()
{
  int spsppsFound;
}
@end

@implementation h264encode
{
  int width;
  int height;
  int framerate;
  int bitrate;
  int64_t encodingTimeMills;
  VTCompressionSessionRef _encodeSession;
  dispatch_queue_t                            aQueue;
  BOOL isSmall;
}

// h264编码回调，每当系统编码完一帧之后，会异步掉用该方法，此为c语言方法
void encodeCallback(void *userData, void *sourceFrameRefCon, OSStatus status, VTEncodeInfoFlags infoFlags,
                          CMSampleBufferRef sampleBuffer )
{
  if (status != noErr) {
    NSLog(@"didCompressH264 error: with status %d, infoFlags %d", (int)status, (int)infoFlags);
    return;
  }
  if (!CMSampleBufferDataIsReady(sampleBuffer))
  {
    NSLog(@"didCompressH264 data is not ready ");
    return;
  }
  
  h264encode* vc = (__bridge h264encode*)userData;
  CFArrayRef cfArr = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true);
  CFDictionaryRef cfDict = (CFDictionaryRef)CFArrayGetValueAtIndex(cfArr, 0);
  bool keyframe = !CFDictionaryContainsKey(cfDict, kCMSampleAttachmentKey_NotSync);
  if(keyframe && !vc->spsppsFound){
    //获得sps,pps数据
    size_t spsSize,spsCount;
    size_t ppsSize,ppsCount;
    const uint8_t *spsData,*ppsData;
    CMFormatDescriptionRef formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer);
    OSStatus err0 = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(formatDesc, 0, &spsData, &spsSize, &spsCount, 0);
    OSStatus err1 = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(formatDesc, 1, &ppsData, &ppsSize, &ppsCount, 0);
    if(err0 == noErr && err1 == noErr){
      vc->spsppsFound = 1;
      if(!vc->isSmall){
        [vc->_delegate dataEncodeToH264:spsData length:spsSize];
        [vc->_delegate dataEncodeToH264:ppsData length:ppsSize];
      }
      double timeMills = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer))*1000;
      if(!vc->isSmall){
        [vc->_delegate rtmpSpsPps:ppsData ppsLen:ppsSize sps:spsData spsLen:spsSize timestramp:timeMills];
      }else{
        [vc->_delegate rtmpSmallSpsPps:ppsData ppsLen:ppsSize sps:spsData spsLen:spsSize timestramp:timeMills];
      }
    }
  }
  
  //获得编码后的数据
  size_t lengthAtOffset,totalLength;
  char* data;
  CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
  OSStatus error = CMBlockBufferGetDataPointer(dataBuffer, 0, &lengthAtOffset, &totalLength, &data);
  if(error == noErr){
    size_t offset = 0;
    const int lengthInfoSize = 4;// 返回的nalu数据前四个字节不是0001的startcode，而是大端模式的帧长度length
    while(offset<totalLength){
      uint32_t naluLength = 0;
      memcpy(&naluLength, data+offset, lengthInfoSize);
      naluLength = CFSwapInt32BigToHost(naluLength);
      if(!vc->isSmall){
        [vc->_delegate dataEncodeToH264:data+offset+lengthInfoSize length:naluLength];
      }
      CMTime presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
      double presentationTimeMills = CMTimeGetSeconds(presentationTimeStamp)*1000;
      //NSLog(@"presentationTimeMills:%f",presentationTimeMills);
      int64_t pts = presentationTimeMills / 1000.0f * 1000;
      int64_t dts = pts;
      if(!vc->isSmall){
        [vc->_delegate rtmpH264:data+offset+lengthInfoSize length:naluLength isKeyFrame:keyframe timestramp:presentationTimeMills pts:pts dts:dts];
      }else{
        [vc->_delegate rtmpSmallH264:data+offset+lengthInfoSize length:naluLength isKeyFrame:keyframe timestramp:presentationTimeMills pts:pts dts:dts];
      }
      offset += lengthInfoSize+naluLength;
    }
  }
}

-(id)initEncodeWith:(int)w  height:(int)h framerate:(int)fps bitrate:(int)bt
{
  self = [super init];
  if(self){
    width = w;
    height = h;
    framerate = fps;
    bitrate = bt;
    encodingTimeMills = -1;
    aQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    isSmall = false;
  }
  return self;
}

-(id)initSmallEncodeWith:(int)w  height:(int)h framerate:(int)fps bitrate:(int)bt{
  self = [super init];
  if(self){
    width = w;
    height = h;
    framerate = fps;
    bitrate = bt;
    encodingTimeMills = -1;
    aQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    isSmall = true;
  }
  return self;
}

-(void)dealloc
{
  CFRelease(_encodeSession);
  _encodeSession = NULL;
}

-(int)startH264EncodeSession
{
  spsppsFound = 0;
  //初始化编码器
  OSStatus status;
  VTCompressionOutputCallback cb = encodeCallback;
  status = VTCompressionSessionCreate(kCFAllocatorDefault, width, height, kCMVideoCodecType_H264, NULL, NULL, NULL, cb, (__bridge void *)(self), &_encodeSession);
  if(status != noErr){
    NSLog(@"VTCompressionSessionCreate failed. ret=%d", (int)status);
    return -1;
  }
  // 设置实时编码输出，降低编码延迟
  status = VTSessionSetProperty(_encodeSession, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
  NSLog(@"set realtime  return: %d", (int)status);
  // h264 profile, 直播一般使用baseline，可减少由于b帧带来的延时
  status = VTSessionSetProperty(_encodeSession, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Baseline_AutoLevel);
  NSLog(@"set profile   return: %d", (int)status);
  // 设置编码码率(比特率)，如果不设置，默认将会以很低的码率编码，导致编码出来的视频很模糊
  status = VTSessionSetProperty(_encodeSession, kVTCompressionPropertyKey_AverageBitRate, (__bridge CFTypeRef)@(bitrate));
  status += VTSessionSetProperty(_encodeSession, kVTCompressionPropertyKey_DataRateLimits, (__bridge CFArrayRef)@[@(bitrate*2/8), @1]);
  NSLog(@"set bitrate   return: %d", (int)status);
  // 设置关键帧间隔，即gop size
  status = VTSessionSetProperty(_encodeSession, kVTCompressionPropertyKey_MaxKeyFrameInterval, (__bridge CFTypeRef)@(framerate));
  // 设置帧率，只用于初始化session，不是实际FPS
  status = VTSessionSetProperty(_encodeSession, kVTCompressionPropertyKey_ExpectedFrameRate, (__bridge CFTypeRef)@(framerate));
  NSLog(@"set framerate return: %d", (int)status);
  // 开始编码
  status = VTCompressionSessionPrepareToEncodeFrames(_encodeSession);
   return 0;
}

-(void)YUV2CVPixelBufferRef:(NSData*) yuvData
{
  //现在要把NV12数据放入 CVPixelBufferRef中，因为 硬编码主要调用VTCompressionSessionEncodeFrame函数，此函数不接受yuv数据，但是接受CVPixelBufferRef类型。
  
  //初始化pixelBuf，数据类型是kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange，此类型数据格式同NV12格式相同。
  
}

-(void)encodeBytes:(unsigned char *)BGRAData
{
  dispatch_sync(aQueue, ^{
    CVPixelBufferRef pixelBuf = NULL;
    CVReturn status = CVPixelBufferCreateWithBytes(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, BGRAData, width*4, NULL, NULL, NULL, &pixelBuf);
    int64_t currentTimeMills = CFAbsoluteTimeGetCurrent() * 1000;
    if(-1 == encodingTimeMills){
      encodingTimeMills = currentTimeMills;
    }
    int64_t encodingDuration = currentTimeMills - encodingTimeMills;
    CMTime pts = CMTimeMake(encodingDuration, 1000.); // timestamp is in ms.
    CMTime dur = CMTimeMake(1, framerate);
    VTEncodeInfoFlags flags;
    OSStatus statusCode = VTCompressionSessionEncodeFrame(_encodeSession, pixelBuf, pts, dur, NULL, NULL, &flags);
    if(statusCode != noErr){
      NSLog(@"H264: VTCompressionSessionEncodeFrame failed with %d", (int)statusCode);
    }
    
    CFRelease(pixelBuf);
  });
}

-(void)encodeH264Frame:(NSData*)NV12Data
{
  CVPixelBufferRef pixelBuf = NULL;
  CVPixelBufferCreate(NULL, width, height, kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange, NULL, &pixelBuf);
  if(CVPixelBufferLockBaseAddress(pixelBuf, 0) != kCVReturnSuccess){
    NSLog(@"lock failed");
  }
  //将yuv数据填充到CVPixelBufferRef中
  size_t y_size = width * height;
  size_t uv_size = y_size / 4;
  uint8_t *yuv_frame = (uint8_t *)NV12Data.bytes;
  
  //处理y frame
  uint8_t *y_frame = CVPixelBufferGetBaseAddressOfPlane(pixelBuf, 0);
  memcpy(y_frame, yuv_frame, y_size);
  
  uint8_t *uv_frame = CVPixelBufferGetBaseAddressOfPlane(pixelBuf, 1);
  memcpy(uv_frame, yuv_frame + y_size, uv_size * 2);
  
  
  int64_t currentTimeMills = CFAbsoluteTimeGetCurrent() * 1000;
  if(-1 == encodingTimeMills){
    encodingTimeMills = currentTimeMills;
  }
  int64_t encodingDuration = currentTimeMills - encodingTimeMills;
  CMTime pts = CMTimeMake(encodingDuration, 1000.); // timestamp is in ms.
  CMTime dur = CMTimeMake(1, framerate);
  VTEncodeInfoFlags flags;
  OSStatus statusCode = VTCompressionSessionEncodeFrame(_encodeSession, pixelBuf, pts, dur, NULL, NULL, &flags);
  if(statusCode != noErr){
    NSLog(@"H264: VTCompressionSessionEncodeFrame failed with %d", (int)statusCode);
  }
  CVPixelBufferUnlockBaseAddress(pixelBuf, 0);
  CVPixelBufferRelease(pixelBuf);
  
}

-(void)encodeCMSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    CVImageBufferRef imageBuffer = (CVImageBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
  int64_t currentTimeMills = CFAbsoluteTimeGetCurrent() * 1000;
  if(-1 == encodingTimeMills){
    encodingTimeMills = currentTimeMills;
  }
  int64_t encodingDuration = currentTimeMills - encodingTimeMills;
  CMTime pts = CMTimeMake(encodingDuration, 1000.); // timestamp is in ms.
  CMTime dur = CMTimeMake(1, framerate);
    VTEncodeInfoFlags flags;
    OSStatus statusCode = VTCompressionSessionEncodeFrame(_encodeSession, imageBuffer, pts, dur, NULL, NULL, &flags);
    if(statusCode != noErr){
      NSLog(@"H264: VTCompressionSessionEncodeFrame failed with %d", (int)statusCode);
    }
}

//停止h264编码
-(void)stopH264EncodeSession
{
  VTCompressionSessionCompleteFrames(_encodeSession, kCMTimeInvalid);
  VTCompressionSessionInvalidate(_encodeSession);
  //CFRelease(_encodeSession);
  //_encodeSession = NULL;
}


@end
