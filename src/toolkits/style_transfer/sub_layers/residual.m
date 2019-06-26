#include <toolkits/style_transfer/sub_layers/residual.h>
#include <ml/neural_net/mps_layer_helper.h>

@implementation Residual

- (id _Nonnull) initWithParameters:(NSString * _Nullable)name
                         inputNode:(MPSNNImageNode * _Nonnull)inputNode
                            device:(id<MTLDevice> _Nonnull)dev
                         cmd_queue:(id<MTLCommandQueue> _Nonnull)cmd_q
                       initWeights:(struct ResidualWeights)weights {
  @autoreleasepool {
    self = [super init];

    conv_1 = [TCMPSLayerHelper createConvolutional:inputNode
                                       kernelWidth:weights.conv_1.kernelWidth
                                      kernelHeight:weights.conv_1.kernelHeight
                              inputFeatureChannels:weights.conv_1.inputFeatureChannels
                             outputFeatureChannels:weights.conv_1.outputFeatureChannels
                                       strideWidth:weights.conv_1.strideWidth
                                      strideHeight:weights.conv_1.strideHeight
                                      paddingWidth:weights.conv_1.paddingWidth
                                     paddingHeight:weights.conv_1.paddingHeight
                                           weights:weights.conv_1.weights
                                            biases:weights.conv_1.biases
                                             label:weights.conv_1.label
                                     updateWeights:weights.conv_1.updateWeights
                                            device:dev
                                         cmd_queue:cmd_q];

    inst_norm_1 = [TCMPSLayerHelper createInstanceNormalization:[conv_1 resultImage]
                                                       channels:weights.inst_1.channels
                                                         styles:weights.inst_1.styles
                                                          gamma:weights.inst_1.gamma
                                                           beta:weights.inst_1.beta
                                                          label:weights.inst_1.label
                                                         device:dev
                                                      cmd_queue:cmd_q];

    relu = [MPSCNNNeuronReLUNNode nodeWithSource: [inst_norm_1 resultImage]];

    conv_2 = [TCMPSLayerHelper createConvolutional:[relu resultImage]
                                       kernelWidth:weights.conv_2.kernelWidth
                                      kernelHeight:weights.conv_2.kernelHeight
                              inputFeatureChannels:weights.conv_2.inputFeatureChannels
                             outputFeatureChannels:weights.conv_2.outputFeatureChannels
                                       strideWidth:weights.conv_2.strideWidth
                                      strideHeight:weights.conv_2.strideHeight
                                      paddingWidth:weights.conv_2.paddingWidth
                                     paddingHeight:weights.conv_2.paddingHeight
                                           weights:weights.conv_2.weights
                                            biases:weights.conv_2.biases
                                             label:weights.conv_2.label
                                     updateWeights:weights.conv_2.updateWeights
                                            device:dev
                                         cmd_queue:cmd_q];

    inst_norm_2 = [TCMPSLayerHelper createInstanceNormalization:[conv_2 resultImage]
                                                       channels:weights.inst_2.channels
                                                         styles:weights.inst_2.styles
                                                          gamma:weights.inst_2.gamma
                                                           beta:weights.inst_2.beta
                                                          label:weights.inst_2.label
                                                         device:dev
                                                      cmd_queue:cmd_q];
 
    add = [MPSNNAdditionNode nodeWithSources:@[inputNode, [inst_norm_2 resultImage]]];

    m_output = [add resultImage];

    return self;
  }
}

- (MPSNNImageNode * _Nullable) forwardPass {
  return m_output;
}

- (MPSNNImageNode * _Nullable) backwardPass:(MPSNNImageNode * _Nonnull)inputNode {
  NSArray<MPSNNGradientFilterNode *>* add_grad = [add gradientFiltersWithSources: @[inputNode]];
  MPSNNGradientFilterNode* inst_2_grad = [inst_norm_2 gradientFilterWithSource: [add_grad[0] resultImage]];
  MPSNNGradientFilterNode* conv_2_grad = [conv_2 gradientFilterWithSource: [inst_2_grad resultImage]];
  MPSNNGradientFilterNode* relu_grad = [relu gradientFilterWithSource: [conv_2_grad resultImage]];
  MPSNNGradientFilterNode* inst_1_grad = [inst_norm_1 gradientFilterWithSource: [relu_grad resultImage]];;
  MPSNNGradientFilterNode* conv_1_grad = [conv_1 gradientFilterWithSource: [inst_1_grad resultImage]];

  return [conv_1_grad resultImage];
}

@end