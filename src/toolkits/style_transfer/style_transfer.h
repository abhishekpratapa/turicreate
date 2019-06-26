#ifndef TURI_STYLE_TRANSFER_H_
#define TURI_STYLE_TRANSFER_H_

#import <Accelerate/Accelerate.h>
#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>

#include <toolkits/style_transfer/utils.h>

#include <toolkits/style_transfer/sub_layers/encoding.h>
#include <toolkits/style_transfer/sub_layers/residual.h>
#include <toolkits/style_transfer/sub_layers/decoding.h>

API_AVAILABLE(macos(10.14))
@interface StyleTransferModel : NSObject {
  Encoding *encoding_1;
  Encoding *encoding_2;
  Encoding *encoding_3;

  Residual *residual_1;
  Residual *residual_2;
  Residual *residual_3;
  Residual *residual_4;
  Residual *residual_5;

  Decoding *decoding_1;
  Decoding *decoding_2;

  MPSCNNConvolutionNode *conv;
  MPSCNNInstanceNormalizationNode *inst_norm;
  MPSCNNNeuronSigmoidNode *sigmoid;

  MPSNNImageNode *m_output;
}

- (id _Nonnull) initWithParameters:(NSString * _Nullable)name
                         inputNode:(MPSNNImageNode * _Nonnull)inputNode
                            device:(id<MTLDevice> _Nonnull)dev
                         cmd_queue:(id<MTLCommandQueue> _Nonnull)cmd_q
                       initWeights:(struct StyleTransferWeights)weights;

- (MPSNNImageNode * _Nullable) forwardPass;
- (MPSNNImageNode * _Nullable) backwardPass:(MPSNNImageNode * _Nonnull) inputNode;

@end

#endif