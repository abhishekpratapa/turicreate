#ifndef TURI_STYLE_TRANSFER_RESIDUAL_H_
#define TURI_STYLE_TRANSFER_RESIDUAL_H_

#import <Accelerate/Accelerate.h>
#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>

#include <toolkits/style_transfer/utils.h>

API_AVAILABLE(macos(10.14))
@interface Residual : NSObject {
  MPSCNNConvolutionNode *conv_1;
  MPSCNNInstanceNormalizationNode *inst_norm_1;
  MPSCNNNeuronReLUNNode *relu;

  MPSCNNConvolutionNode *conv_2;
  MPSCNNInstanceNormalizationNode *inst_norm_2;
  MPSNNAdditionNode *add;

  MPSNNImageNode *m_output;
}

- (id _Nonnull) initWithParameters:(NSString * _Nullable)name
                         inputNode:(MPSNNImageNode * _Nonnull)inputNode
                            device:(id<MTLDevice> _Nonnull)dev
                         cmd_queue:(id<MTLCommandQueue> _Nonnull)cmd_q
                       initWeights:(struct ResidualWeights)weights;

- (MPSNNImageNode * _Nullable) forwardPass;
- (MPSNNImageNode * _Nullable) backwardPass:(MPSNNImageNode * _Nonnull)inputNode;

@end

#endif