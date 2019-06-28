#ifndef TURI_STYLE_TRANSFER_PRE_PROCESSING_H_
#define TURI_STYLE_TRANSFER_PRE_PROCESSING_H_

#import <Accelerate/Accelerate.h>
#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>


API_AVAILABLE(macos(10.14))
@interface PreProcessing : NSObject {
  MPSNNImageNode *m_output;
}

- (id _Nonnull) initWithParameters:(NSString * _Nullable)name
                         inputNode:(MPSNNImageNode * _Nonnull)inputNode
                         scaleNode:(MPSNNImageNode * _Nonnull)scaleNode
                          meanNode:(MPSNNImageNode * _Nonnull)meanNode
                            device:(id<MTLDevice> _Nonnull)dev
                         cmd_queue:(id<MTLCommandQueue> _Nonnull)cmd_q;

- (MPSNNImageNode * _Nullable) forwardPass;
- (MPSNNImageNode * _Nullable) backwardPass:(MPSNNImageNode * _Nonnull) inputNode;

@end

#endif