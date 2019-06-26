#include <toolkits/style_transfer/sub_layers/encoding.h>
#include <ml/neural_net/mps_layer_helper.h>

@implementation Encoding

- (id _Nonnull) initWithParameters:(NSString * _Nullable)name
                         inputNode:(MPSNNImageNode * _Nonnull)inputNode
                            device:(id<MTLDevice> _Nonnull)dev
                         cmd_queue:(id<MTLCommandQueue> _Nonnull)cmd_q
                       initWeights:(struct EncodingWeights) weights {
  @autoreleasepool {
    
    self = [super init];

    conv = [TCMPSLayerHelper createConvolutional:inputNode
                                     kernelWidth:weights.conv.kernelWidth
                                    kernelHeight:weights.conv.kernelHeight
                            inputFeatureChannels:weights.conv.inputFeatureChannels
                           outputFeatureChannels:weights.conv.outputFeatureChannels
                                     strideWidth:weights.conv.strideWidth
                                    strideHeight:weights.conv.strideHeight
                                    paddingWidth:weights.conv.paddingWidth
                                   paddingHeight:weights.conv.paddingHeight
                                         weights:weights.conv.weights
                                          biases:weights.conv.biases
                                           label:weights.conv.label
                                   updateWeights:weights.conv.updateWeights
                                          device:dev
                                       cmd_queue:cmd_q];

    inst_norm = [TCMPSLayerHelper createInstanceNormalization:[conv resultImage]
                                                     channels:weights.inst.channels
                                                       styles:weights.inst.styles
                                                        gamma:weights.inst.gamma
                                                         beta:weights.inst.beta
                                                        label:weights.inst.label
                                                       device:dev
                                                    cmd_queue:cmd_q];

    relu = [MPSCNNNeuronReLUNNode nodeWithSource: [inst_norm resultImage]];

    m_output = [relu resultImage];

    return self;
  }
}

- (MPSNNImageNode * _Nullable) forwardPass {
  return m_output;
}

- (MPSNNImageNode * _Nullable) backwardPass:(MPSNNImageNode * _Nonnull) inputNode {
  MPSNNGradientFilterNode* conv_grad = [conv gradientFilterWithSource: inputNode];
  MPSNNGradientFilterNode* inst_norm_grad = [inst_norm gradientFilterWithSource: [conv_grad resultImage]];
  MPSNNGradientFilterNode* relu_grad = [relu gradientFilterWithSource: [inst_norm_grad resultImage]];
  return [relu_grad resultImage];
}

@end