#ifndef TURI_VGG_16_H_
#define TURI_VGG_16_H_

#import <Accelerate/Accelerate.h>
#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>

#include <toolkits/style_transfer/utils.h>

#include <toolkits/style_transfer/sub_layers/block_1.h>
#include <toolkits/style_transfer/sub_layers/block_2.h>

API_AVAILABLE(macos(10.14))
@interface VGG16Model : NSObject {
  Block1 *block_1;
  Block1 *block_2;
  Block2 *block_3;
  Block2 *block_4;

  MPSNNImageNode *m_output;
}

- (id _Nonnull) initWithParameters:(NSString * _Nullable)name
                         inputNode:(MPSNNImageNode * _Nonnull)inputNode
                            device:(id<MTLDevice> _Nonnull)dev
                         cmd_queue:(id<MTLCommandQueue> _Nonnull)cmd_q
                       initWeights:(struct Vgg16Weights)weights;

- (MPSNNImageNode * _Nullable) forwardPass;
- (MPSNNImageNode * _Nullable) backwardPass:(MPSNNImageNode * _Nonnull) inputNode;

@end

#endif