#ifndef TURI_STYLE_TRANSFER_BLOCK_2_H_
#define TURI_STYLE_TRANSFER_BLOCK_2_H_

#import <Accelerate/Accelerate.h>
#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>

#include <toolkits/style_transfer/utils.h>

API_AVAILABLE(macos(10.14))
@interface Block2 : NSObject {
  MPSCNNConvolutionNode *conv_1;
  MPSCNNNeuronReLUNNode *relu_1;

  MPSCNNConvolutionNode *conv_2;
  MPSCNNNeuronReLUNNode *relu_2;

  MPSCNNConvolutionNode *conv_3;
  MPSCNNNeuronReLUNNode *relu_3;

  MPSCNNPoolingAverageNode *pooling;

  MPSNNImageNode *m_feature;
  MPSNNImageNode *m_output;
}

- (id _Nonnull) initWithParameters:(NSString * _Nullable)name
                         inputNode:(MPSNNImageNode * _Nonnull)inputNode
                            device:(id<MTLDevice> _Nonnull)dev
                         cmd_queue:(id<MTLCommandQueue> _Nonnull)cmd_q
                       initWeights:(struct Block2Weights)weights;

- (MPSNNImageNode * _Nullable) forwardPass;
- (MPSNNImageNode * _Nullable) backwardPass:(MPSNNImageNode * _Nonnull)inputNode;

@end

#endif